extends CharacterBody2D

signal health_depleted
signal leveled_up(new_level: int)

const GUN_SCENE := preload("res://weapons/core/gun.tscn")
const PlayerDebuffControllerScript = preload("res://elite/player_debuff_controller.gd")
const EliteBlazingConstantsScript = preload("res://elite/elite_blazing_constants.gd")
const RelicCombatBridgeScript = preload("res://inventory/relic_combat_bridge.gd")
const DASH_SPEED := 1400.0
const BASE_DASH_DURATION := 0.18
const BASE_MOVE_SPEED := 600.0
const BASE_STAMINA_REGEN_DELAY := 2.0
const BASE_STAMINA_REGEN_RATE := 1.0
const DASH_STAMINA_COST := 1.0

@export var pickup_range := 150.0
@export var base_exp_to_level := 5
const DAMAGE_FLOAT_INTERVAL := 0.2
const CONTACT_COLLISION_BUMP_DAMAGE := 1
const REVIVE_HP_RATIO := 0.5
const REVIVE_INVINCIBILITY_SEC := 2.0

var health = 100.0
var level := 1
var experience := 0
var gold := 0
var _owned_weapons: Array[WeaponData] = []
var _weapon_run_state: WeaponRunState = null
var _damage_float_accumulator := 0.0
var _damage_float_timer := 0.0
var _last_move_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _dash_time_remaining := 0.0
var _stamina_current := LoadoutStatApply.BASE_MAX_STAMINA
var _regen_idle_time := 0.0
var _gear_invincibility_remaining := 0.0
var auto_target_enabled := true
var auto_attack_enabled := true
var _health_depleted_emitted := false
var _hurtbox_overlap_mob_ids: Dictionary = {}
var _hit_flash_target: CanvasItem
var _hit_flash_base_modulate := Color.WHITE
var _stats := CharacterStats.new()
var _loadout_registry: ItemRegistry
var _loadout_state: PlayerLoadoutState
var _grant_orbital_nodes: Array = []
var _buff_controller := BuffController.new()
var _debuff_controller = PlayerDebuffControllerScript.new()
var _revive_remaining := 0
var _revive_cap_granted := 0
var _revive_invincible_remaining := 0.0
var _lethal_resolve_physics_frame := -1
var _cached_max_health := 100.0
var _character_visual: Node2D
var _active_visual_scene_path := ""
var _base_move_speed := BASE_MOVE_SPEED


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_buff_controller.buffs_changed.connect(_on_buffs_changed)
	_sync_physics_layers()
	apply_player_class_from_run_config()
	_sync_pickup_range_visual()
	refresh_primary_weapon_range_ring()
	%PickupRange.area_entered.connect(_on_pickup_range_area_entered)
	%DashCooldownBar.visible = false
	%StaminaRegenWaitBar.visible = false
	set_contact_damage_enabled(false)
	_update_health_hud()
	_update_burn_hud()
	_update_experience_hud()
	_update_gold_hud()
	call_deferred("_apply_gameplay_combat_defaults")


# 물리 레이어·마스크 — PhysicsLayers 단일 정의와 동기화.
func _sync_physics_layers() -> void:
	PhysicsLayers.apply_player_body(self)
	PhysicsLayers.apply_player_hurtbox(%HurtBox)
	PhysicsLayers.apply_player_pickup_range(%PickupRange)


# 접촉 DPS Area 감시 — 게임 시작 전·무기 획득 중에는 끕니다.
func set_contact_damage_enabled(enabled: bool) -> void:
	var was_monitoring: bool = %HurtBox.monitoring
	%HurtBox.monitoring = enabled
	if enabled and not was_monitoring:
		_refill_stamina_to_max()


# 발밑 GroundShadow 크기에 맞춰 이동·접촉 판정 충돌체를 맞춥니다.
func _sync_collision_to_ground_shadow() -> void:
	var visual := _get_character_visual_root()
	if visual == null:
		return
	var footprint := GroundShadowFootprint.footprint_size_from_visual(visual)
	if footprint == Vector2.ZERO:
		return
	GroundShadowFootprint.sync_collision_shape_to_shadow(self, $CollisionShape2D, visual)
	GroundShadowFootprint.sync_collision_shape_to_shadow(
		self,
		%HurtBox.get_node("CollisionShape2D") as CollisionShape2D,
		visual
	)


# 조준·접촉·몹 추적에 쓰는 발밑 그림자 중심.
func get_footprint_global_center() -> Vector2:
	var visual := _get_character_visual_root()
	if visual == null:
		return global_position
	return GroundShadowFootprint.footprint_center_global(visual)


# 몹 접촉 거리 계산용 HurtBox 반경(그림자 발밑 박스 기준)
func get_contact_hurtbox_half_extents() -> Vector2:
	var hurt_shape := %HurtBox.get_node("CollisionShape2D").shape as RectangleShape2D
	if hurt_shape:
		return hurt_shape.size * 0.5
	var visual := _get_character_visual_root()
	if visual == null:
		return Vector2.ZERO
	return GroundShadowFootprint.footprint_half_extents_from_visual(visual)


# 범위 공격(몹별 쿨다운) + HurtBox 겹침 진입 시 충돌 1 피해.
func _apply_contact_damage(delta: float) -> void:
	if _health_depleted_emitted or not %HurtBox.monitoring or is_damage_immune():
		return

	var damage := 0
	var current_overlap_ids: Dictionary = {}

	for body in %HurtBox.get_overlapping_bodies():
		if not body is Mob:
			continue
		var mob := body as Mob
		if not mob.is_contact_damage_active():
			continue
		var mob_id := mob.get_instance_id()
		current_overlap_ids[mob_id] = true
		if not _hurtbox_overlap_mob_ids.has(mob_id):
			damage += CONTACT_COLLISION_BUMP_DAMAGE

	_hurtbox_overlap_mob_ids = current_overlap_ids

	for node in get_tree().get_nodes_in_group("mobs"):
		if node is Mob:
			var mob := node as Mob
			if mob.is_player_in_contact_attack_range(get_footprint_global_center()):
				damage += mob.tick_contact_attack(delta)

	if damage <= 0:
		return

	var taken := _resolve_incoming_damage(damage)
	if taken <= 0:
		return

	_apply_damage_taken(taken, true)


# PickupRange 충돌·반투명 링을 pickup_range 반경에 맞춥니다.
func _sync_pickup_range_visual() -> void:
	var pickup_shape := %PickupRange.get_node("CollisionShape2D").shape as CircleShape2D
	pickup_shape.radius = pickup_range
	var ring := get_node_or_null("%PickupRangeRing") as Sprite2D
	if not ring or not ring.texture:
		return
	var tex_radius := maxf(ring.texture.get_width(), ring.texture.get_height()) * 0.5
	if tex_radius <= 0.0:
		return
	var ring_scale := pickup_range / tex_radius
	ring.scale = Vector2(ring_scale, ring_scale)


# 첫 번째 무기(슬롯 0) 공격 사거리 링 — GameplaySettings·무기 변경 시 갱신.
func refresh_primary_weapon_range_ring() -> void:
	var ring := get_node_or_null("%PrimaryWeaponRangeRing") as Sprite2D
	if not ring:
		return
	var guns := %Weapons.get_children()
	if guns.is_empty():
		ring.visible = false
		return
	var gun := guns[0]
	if not gun.has_method("get_display_attack_range"):
		ring.visible = false
		return
	var attack_range: float = gun.get_display_attack_range()
	if attack_range <= 0.0 or not is_finite(attack_range):
		ring.visible = false
		return
	if not ring.texture:
		ring.visible = false
		return
	var tex_radius := maxf(ring.texture.get_width(), ring.texture.get_height()) * 0.5
	if tex_radius <= 0.0:
		ring.visible = false
		return
	var ring_scale := attack_range / tex_radius
	ring.scale = Vector2(ring_scale, ring_scale)
	ring.visible = GameplaySettings.is_primary_weapon_range_visible()


# Game._ready 설정 로드 이후 게임플레이 기본값(자동 타겟·공격)을 적용합니다.
func _apply_gameplay_combat_defaults() -> void:
	set_auto_target_enabled(GameplaySettings.is_default_auto_target_enabled())
	set_auto_attack_enabled(GameplaySettings.is_default_auto_attack_enabled())


func is_auto_target_enabled() -> bool:
	return auto_target_enabled


# 기존 호출부 호환용 — 동결 중에는 자동 공격·궤도 타격도 중단합니다.
func is_auto_attack_enabled() -> bool:
	return auto_attack_enabled and not is_elite_debuff_frozen()


# F키로 자동 타겟 on/off를 전환합니다.
func set_auto_target_enabled(enabled: bool) -> void:
	if auto_target_enabled == enabled:
		return
	auto_target_enabled = enabled
	_apply_auto_target_to_weapons()
	_update_auto_target_hud()


# G키·설정 기본값으로 자동 공격 on/off를 전환합니다.
func set_auto_attack_enabled(enabled: bool) -> void:
	if auto_attack_enabled == enabled:
		return
	auto_attack_enabled = enabled
	_apply_auto_attack_to_weapons()
	_update_auto_attack_hud()


func toggle_auto_target() -> void:
	set_auto_target_enabled(not auto_target_enabled)


func toggle_auto_attack() -> void:
	set_auto_attack_enabled(not auto_attack_enabled)


func _apply_auto_target_to_weapons() -> void:
	for gun in %Weapons.get_children():
		if gun.has_method("refresh_targeting_mode"):
			gun.refresh_targeting_mode()


func _apply_auto_attack_to_weapons() -> void:
	for gun in %Weapons.get_children():
		if gun.has_method("refresh_auto_attack"):
			gun.refresh_auto_attack()


func get_owned_weapons() -> Array[WeaponData]:
	return _owned_weapons.duplicate()


func has_weapon(weapon_data: WeaponData) -> bool:
	var key := weapon_data.get_unique_key()
	for owned in _owned_weapons:
		if owned.get_unique_key() == key:
			return true
	return false


# 테스트 아레나 등에서 무기 슬롯을 비울 때 사용합니다.
func clear_weapons() -> void:
	for gun in %Weapons.get_children():
		gun.free()
	_owned_weapons.clear()
	refresh_primary_weapon_range_ring()


# RunConfig 직업 stat_modifiers·비주얼을 적용하고 체력·스태미나 상한을 맞춥니다.
func apply_player_class_from_run_config() -> void:
	var player_class := RunConfig.get_player_class()
	if player_class == null:
		apply_player_class_with_modifiers({})
	else:
		apply_player_class_with_modifiers(player_class.build_stat_modifiers())


# F6 등 — 튜닝된 stat_modifiers로 직업 스탯·비주얼을 적용합니다.
func apply_player_class_with_modifiers(stat_modifiers: Dictionary) -> void:
	var player_class := RunConfig.get_player_class()
	_stats.set_class_modifiers(stat_modifiers)
	_apply_character_visual(player_class)
	_sync_health_bar_max()
	health = get_max_health()
	_refill_stamina_to_max()


# F6 등 — 선택 직업 비주얼·스탯으로 스폰 지점에 플레이어를 재생성합니다.
func recreate_at(spawn_global_position: Vector2) -> void:
	global_position = spawn_global_position
	velocity = Vector2.ZERO
	_dash_direction = Vector2.ZERO
	_dash_time_remaining = 0.0
	_hurtbox_overlap_mob_ids.clear()
	reset_health_depleted_state()
	clear_player_debuffs()
	apply_player_class_from_run_config()
	_update_health_hud()


func get_player_class_id() -> StringName:
	return RunConfig.get_player_class_id()


func _apply_character_visual(player_class: PlayerClassData) -> void:
	if player_class == null or player_class.visual_scene == null:
		return
	var scene_path := player_class.visual_scene.resource_path
	if (
		scene_path == _active_visual_scene_path
		and _character_visual != null
		and is_instance_valid(_character_visual)
	):
		return
	for child in %VisualMount.get_children():
		child.free()
	_character_visual = player_class.visual_scene.instantiate() as Node2D
	if _character_visual == null:
		return
	%VisualMount.add_child(_character_visual)
	_active_visual_scene_path = scene_path
	_bind_character_visual()
	_sync_collision_to_ground_shadow()
	_play_character_idle_animation()


func _get_character_visual_root() -> Node2D:
	if _character_visual != null and is_instance_valid(_character_visual):
		return _character_visual
	if %VisualMount.get_child_count() > 0:
		return %VisualMount.get_child(0) as Node2D
	return null


func _bind_character_visual() -> void:
	var visual := _get_character_visual_root()
	if visual == null:
		return
	var colorizer := visual.get_node_or_null("Colorizer") as CanvasItem
	if colorizer != null:
		_hit_flash_target = colorizer
		_hit_flash_base_modulate = colorizer.modulate


func _play_character_idle_animation() -> void:
	var visual := _get_character_visual_root()
	if visual != null and visual.has_method(&"play_idle_animation"):
		visual.play_idle_animation()


func _play_character_walk_animation() -> void:
	var visual := _get_character_visual_root()
	if visual != null and visual.has_method(&"play_walk_animation"):
		visual.play_walk_animation()


# loadout 장비 stat_modifiers를 캐시하고 이동·무기 배율을 갱신합니다.
func refresh_stats_from_loadout(registry: ItemRegistry, loadout: PlayerLoadoutState) -> void:
	if registry == null or loadout == null:
		_stats.set_loadout_modifiers({}, false)
		_loadout_registry = null
		_loadout_state = null
	else:
		_stats.set_loadout_modifiers(registry.sum_stat_modifiers_for_loadout(loadout), true)
		_loadout_registry = registry
		_loadout_state = loadout
	_sync_health_bar_max()
	_sync_stamina_max()
	_sync_revive_charges_from_stats()
	_refresh_loadout_grant_passives()
	_refresh_weapon_combat_modifiers()


func set_weapon_run_state(state: WeaponRunState) -> void:
	_weapon_run_state = state


func get_weapon_run_level(weapon: WeaponData) -> int:
	if _weapon_run_state == null or weapon == null:
		return 1
	return _weapon_run_state.get_level(weapon)


func get_persistent_stat_modifiers() -> Dictionary:
	return _stats.get_combined_persistent_modifiers()


# 런 패시브·악세서리 시너지 modifier를 반영합니다.
func refresh_stats_from_passives(
	run_state: PassiveRunState,
	accessory_ids: Array[String] = []
) -> void:
	if run_state == null:
		_stats.clear_passive_modifiers()
	else:
		_stats.set_passive_modifiers(PassiveStatMerge.merge_owned(run_state, accessory_ids))
	_sync_health_bar_max()
	_sync_stamina_max()
	_sync_revive_charges_from_stats()
	_refresh_loadout_grant_passives()
	_refresh_weapon_combat_modifiers()


# use_inventory_loadout off 시 장비 source만 제거합니다(런 패시브는 유지).
func clear_loadout_stats() -> void:
	if not _stats.is_loadout_active():
		return
	_stats.clear_loadout_modifiers()
	_loadout_registry = null
	_loadout_state = null
	_sync_health_bar_max()
	_sync_stamina_max()
	_sync_revive_charges_from_stats()
	_refresh_loadout_grant_passives()
	_refresh_weapon_combat_modifiers()


func is_loadout_stats_active() -> bool:
	return _stats.is_loadout_active()


func get_max_health() -> float:
	return _stats.get_max_health(level)


func get_health_regen_per_sec() -> float:
	return _stats.get_health_regen_per_sec(level)


func get_max_stamina() -> float:
	return _stats.get_max_stamina()


func get_stamina_regen_delay() -> float:
	return BASE_STAMINA_REGEN_DELAY


func get_stamina_regen_rate() -> float:
	return BASE_STAMINA_REGEN_RATE * _stats.get_stamina_regen_mult()


func get_dash_stamina_cost() -> float:
	return DASH_STAMINA_COST


func get_effective_dash_duration() -> float:
	return BASE_DASH_DURATION * _stats.get_dash_duration_mult()


# 대시 중·장비 무적(대시 후·피격 후)·부활 무적 여부.
func is_damage_immune() -> bool:
	return (
		_dash_time_remaining > 0.0
		or _gear_invincibility_remaining > 0.0
		or _revive_invincible_remaining > 0.0
	)


# 장비 invincibility_after_* 초를 남은 무적 시간에 max로 합칩니다.
func _add_gear_invincibility(seconds: float) -> void:
	if seconds > 0.0:
		_gear_invincibility_remaining = maxf(_gear_invincibility_remaining, seconds)


# 스태미나 소모 — 성공 시 회복 대기 타이머를 리셋합니다.
func spend_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if _stamina_current < amount:
		return false
	_stamina_current -= amount
	_regen_idle_time = 0.0
	return true


func _refill_stamina_to_max() -> void:
	_stamina_current = get_max_stamina()
	_regen_idle_time = 0.0


# 장비·패시브 변경 후 스태미나 상한에 맞춥니다.
func _sync_stamina_max() -> void:
	_stamina_current = minf(_stamina_current, get_max_stamina())


# 전투 중·unpaused일 때만 회복 대기·회복 tick.
func _tick_stamina(delta: float) -> void:
	if not %HurtBox.monitoring or get_tree().paused:
		return
	if _debuff_controller.blocks_stamina_regen():
		return
	_regen_idle_time += delta
	var max_stamina := get_max_stamina()
	if _stamina_current >= max_stamina:
		return
	if _regen_idle_time < get_stamina_regen_delay():
		return
	_stamina_current = minf(_stamina_current + get_stamina_regen_rate() * delta, max_stamina)


# 직업 기본 체력 회복을 초당 tick합니다.
func _tick_health_regen(delta: float) -> void:
	if get_tree().paused or _health_depleted_emitted or health <= 0.0:
		return
	var rate := get_health_regen_per_sec()
	if rate <= 0.0:
		return
	heal_health(rate * delta)


func get_revive_charges_max() -> int:
	return _stats.get_revive_charges_max()


func get_revive_charges_remaining() -> int:
	return _revive_remaining


# 장비·패시브 revive 상한 증가분만 런 차지에 반영합니다.
func _sync_revive_charges_from_stats() -> void:
	var new_max := get_revive_charges_max()
	if new_max > _revive_cap_granted:
		_revive_remaining += new_max - _revive_cap_granted
		_revive_cap_granted = new_max


# 장비 heart_* 반영 후 체력바 상한을 맞춥니다.
func _sync_health_bar_max() -> void:
	var previous_max: float = _cached_max_health
	var new_max: float = get_max_health()
	if new_max > previous_max:
		health += new_max - previous_max
	health = minf(health, new_max)
	_cached_max_health = new_max
	_update_health_hud()


# loadout 방어구·방패가 있으면 피해를 줄입니다.
func _resolve_incoming_damage(raw_amount: int) -> int:
	if is_damage_immune():
		return 0
	return _stats.mitigate_incoming_damage(raw_amount)


# 피해 적용 후 체력 0 클램프·사망/부활 판정(접촉 누적 플로팅은 선택).
func _apply_damage_taken(taken: int, add_to_contact_float: bool = false) -> void:
	if taken <= 0:
		return
	health = maxf(health - float(taken), 0.0)
	_update_health_hud()
	if add_to_contact_float:
		_damage_float_accumulator += taken
	_try_emit_health_depleted()
	if taken > 0:
		_add_gear_invincibility(_stats.get_invincibility_after_damage_sec())


func get_move_speed() -> float:
	return _stats.get_move_speed(_base_move_speed) * _debuff_controller.get_move_speed_mult()


func get_base_move_speed() -> float:
	return _base_move_speed


# 기본 이동속도(장비·버프 배율 적용 전)를 설정합니다.
func set_base_move_speed(speed: float) -> void:
	_base_move_speed = maxf(speed, 50.0)


func get_last_move_direction() -> Vector2:
	return _last_move_direction


# grant_on_dash: haste — 대시 후 버프 시스템으로 잠시 이동 속도 상승.
func apply_loadout_dash_haste() -> void:
	BuffTriggerRouter.apply_loadout_dash_haste(self)


# grant_on_kill — 장비·런 패시브 grant 태그를 처치 시 반영합니다.
func apply_loadout_on_kill() -> void:
	var grant_modifiers := _stats.get_combined_persistent_modifiers()
	PassiveResolver.on_kill(self, _loadout_registry, grant_modifiers)


# grant_on_wave_start — 장비·런 패시브 grant 태그를 웨이브 시작 시 반영합니다.
func apply_loadout_on_wave_start(wave_number: int = 0) -> void:
	var grant_modifiers := _stats.get_combined_persistent_modifiers()
	PassiveResolver.on_wave_start(self, _loadout_registry, grant_modifiers, wave_number)


# grant_on_kill: magnet_pulse — 필드의 경험치·골드를 플레이어에게 끌어옵니다.
func magnetize_field_pickups() -> void:
	for orb in get_tree().get_nodes_in_group("exp_orbs"):
		if is_instance_valid(orb) and orb.has_method(&"start_magnet"):
			orb.start_magnet(self)
	for coin in get_tree().get_nodes_in_group("gold_coins"):
		if is_instance_valid(coin) and coin.has_method(&"start_magnet"):
			coin.start_magnet(self)


# grant_on_hit — 무기 적중 시 장비·런 패시브 상태이상 부여를 반영합니다.
func apply_loadout_on_hit(target_mob: Node, source_weapon: WeaponData) -> void:
	var grant_modifiers := _stats.get_combined_persistent_modifiers()
	PassiveResolver.on_hit(self, _loadout_registry, grant_modifiers, target_mob, source_weapon)


# 외부 트리거가 플레이어에게 런타임 버프를 부여합니다.
func apply_buff(buff_data: BuffData, source_id: String = "", stacks: int = 1) -> void:
	_buff_controller.add_buff(buff_data, source_id, stacks)


func on_wave_completed_for_buffs() -> void:
	_buff_controller.on_wave_completed()


func get_active_buff_summaries() -> Array[Dictionary]:
	return _buff_controller.get_active_buff_summaries()


func _refresh_loadout_grant_passives() -> void:
	var grant_modifiers := _stats.get_combined_persistent_modifiers()
	LoadoutGrantPassive.refresh_orbitals(
		self, _loadout_registry, grant_modifiers, _grant_orbital_nodes
	)
	if _stats.is_loadout_active() and _loadout_registry != null and _loadout_state != null:
		LoadoutGrantPassive.refresh_offhand_visual(self, _loadout_registry, _loadout_state)
	else:
		var pivot := get_node_or_null("%OffhandPivot") as Node2D
		if pivot:
			pivot.visible = false


func _clear_loadout_grant_passives() -> void:
	LoadoutGrantPassive.clear_orbitals(_grant_orbital_nodes)
	var pivot := get_node_or_null("%OffhandPivot") as Node2D
	if pivot:
		pivot.visible = false


func _apply_loadout_on_dash() -> void:
	var grant_modifiers := _stats.get_combined_persistent_modifiers()
	PassiveResolver.on_dash(self, _loadout_registry, grant_modifiers)


# 장비·버프·무기 강화 배율을 반영한 무기 피해 롤.
func roll_weapon_damage(weapon: WeaponData) -> int:
	return _stats.roll_weapon_damage(weapon, level, get_weapon_run_level(weapon))


# 장비·버프 배율을 반영한 무기 APS.
func get_effective_attacks_per_second(weapon: WeaponData) -> float:
	return _stats.get_effective_attacks_per_second(weapon)


# 장비·버프의 power를 반영한 범위/반경 배율입니다.
func get_power_radius_mult() -> float:
	return _stats.get_power_radius_mult()


func _refresh_weapon_combat_modifiers() -> void:
	for gun in %Weapons.get_children():
		if gun.has_method(&"refresh_loadout_combat_modifiers"):
			gun.call("refresh_loadout_combat_modifiers")
	refresh_primary_weapon_range_ring()


func _on_buffs_changed() -> void:
	_stats.set_buff_modifiers(_buff_controller.get_stat_modifiers())
	_refresh_weapon_combat_modifiers()


func add_weapon(weapon_data: WeaponData) -> void:
	weapon_data = DevWeaponTuning.build_tuned_weapon(weapon_data)
	if weapon_data == null:
		return
	if has_weapon(weapon_data):
		return

	_owned_weapons.append(weapon_data)
	if _weapon_run_state != null:
		_weapon_run_state.ensure_registered(weapon_data)

	var gun: Area2D = GUN_SCENE.instantiate()
	%Weapons.add_child(gun)
	gun.equip_weapon(weapon_data)
	if gun.has_method("refresh_auto_attack"):
		gun.refresh_auto_attack()
	_rearrange_weapons()
	refresh_primary_weapon_range_ring()


func _rearrange_weapons() -> void:
	var guns := %Weapons.get_children()
	for i in guns.size():
		var gun := guns[i]
		if gun.has_method("arrange_slot"):
			gun.arrange_slot(i, guns.size())


func get_exp_to_level() -> int:
	return base_exp_to_level * level


# 사망 시그널 중복 방지 상태를 초기화합니다(테스트 아레나 리스폰 등).
func reset_health_depleted_state() -> void:
	_health_depleted_emitted = false


func _play_hit_flash() -> void:
	if _hit_flash_target:
		HitFlash.play(_hit_flash_target, _hit_flash_base_modulate)


# 몹 원거리 투사체 1발 피해. 성공 시 "" 반환, 스킵 시 사유 문자열(디버그 로그용).
func apply_mob_projectile_damage(amount: int) -> String:
	if amount <= 0:
		return "damage_amount<=0 (value=%d)" % amount
	if _health_depleted_emitted:
		return "player_health_depleted (health=%.1f)" % health
	var taken := _resolve_incoming_damage(amount)
	if taken <= 0:
		return ""
	_play_hit_flash()
	_apply_damage_taken(taken)
	FloatingDamageText.spawn_player_damage(global_position, taken)
	return ""


# 체력 회복 아이템 등에서 호출합니다.
func heal_health(amount: float) -> void:
	if _debuff_controller.blocks_healing():
		return
	var max_hp: float = get_max_health()
	health = minf(health + amount, max_hp)
	_update_health_hud()
	if health > 0.0:
		_health_depleted_emitted = false


func gain_experience(amount: int) -> void:
	experience += amount
	while experience >= get_exp_to_level():
		experience -= get_exp_to_level()
		level += 1
		_sync_health_bar_max()
		leveled_up.emit(level)
	_update_experience_hud()


func gain_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	_update_gold_hud()


func can_spend_gold(amount: int) -> bool:
	return amount >= 0 and gold >= amount


# 상자 구매 등 런 한정 비용을 지불합니다.
func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	_update_gold_hud()
	return true


func refund_gold(amount: int) -> void:
	gain_gold(amount)


func _update_health_hud() -> void:
	var panel: Node = _get_player_status_panel()
	if panel == null:
		return
	panel.set_health(health, get_max_health())


func _update_burn_hud() -> void:
	var panel: Node = _get_player_status_panel()
	if panel == null:
		return
	var burn_id: StringName = EliteBlazingConstantsScript.PLAYER_DEBUFF_ID
	var burning: bool = _debuff_controller.has_debuff(burn_id)
	var remaining_sec: float = 0.0
	if burning:
		remaining_sec = _debuff_controller.get_debuff_remaining_seconds(burn_id)
	panel.set_burn_active(burning, remaining_sec)


func _update_experience_hud() -> void:
	var panel: Node = _get_player_status_panel()
	if panel == null:
		return
	panel.set_experience(experience, get_exp_to_level(), level)


func _get_player_status_panel() -> Node:
	var hud := get_node_or_null("/root/Game/HUD")
	if hud == null:
		return null
	return hud.get_node_or_null("HUDRoot/PlayerStatusPanel")


func _update_gold_hud() -> void:
	var hud := get_node_or_null("/root/Game/HUD")
	if not hud:
		return
	var label: Label = hud.get_node_or_null("HUDRoot/GoldLabel") as Label
	if not label:
		return
	label.text = "골드: %d" % gold


func refresh_locale() -> void:
	_update_auto_target_hud()
	_update_auto_attack_hud()


func _update_auto_target_hud() -> void:
	var label := get_node_or_null("%AutoTargetLabel") as Label
	if not label:
		return
	var action_label := ActionManager.get_action_label(ActionManager.ACTION_TOGGLE_AUTO_TARGET, "-")
	if auto_target_enabled:
		label.text = UiLocale.t(&"hud.auto_target_on") % action_label
		label.add_theme_color_override("font_color", Color(0.1, 0.45, 0.15))
	else:
		label.text = UiLocale.t(&"hud.auto_target_off") % action_label
		label.add_theme_color_override("font_color", Color(0.55, 0.12, 0.12))


func _update_auto_attack_hud() -> void:
	var label := get_node_or_null("%AutoAttackLabel") as Label
	if not label:
		return
	var action_label := ActionManager.get_action_label(ActionManager.ACTION_TOGGLE_AUTO_ATTACK, "-")
	if auto_attack_enabled:
		label.text = UiLocale.t(&"hud.auto_attack_on") % action_label
		label.add_theme_color_override("font_color", Color(0.1, 0.45, 0.15))
	else:
		label.text = UiLocale.t(&"hud.auto_attack_off") % action_label
		label.add_theme_color_override("font_color", Color(0.55, 0.12, 0.12))


func _get_move_direction() -> Vector2:
	return ActionManager.get_move_vector()


func _get_game_root() -> Node:
	var game := get_node_or_null("/root/Game")
	if game != null:
		return game
	return get_tree().current_scene


func _is_combat_input_blocked() -> bool:
	var game := _get_game_root()
	if game == null:
		return false
	if game.has_method("is_weapon_select_open") and game.call("is_weapon_select_open"):
		return true
	if game.has_method("is_pause_menu_open") and game.call("is_pause_menu_open"):
		return true
	if game.has_method("is_inventory_open") and game.call("is_inventory_open"):
		return true
	if game.has_method("is_chest_purchase_open") and game.call("is_chest_purchase_open"):
		return true
	if game.has_method("is_game_over") and game.call("is_game_over"):
		return true
	if is_elite_debuff_frozen():
		return true
	return false


# 일시정지·전투 UI(무기 선택·인벤·상자 등)·동결 중 새 대시 시작 불가.
func _is_dash_input_blocked() -> bool:
	return get_tree().paused or _is_combat_input_blocked() or is_elite_debuff_frozen()


func _unhandled_input(event: InputEvent) -> void:
	if _is_combat_input_blocked():
		return
	if ActionManager.event_is_pressed(event, ActionManager.ACTION_TOGGLE_AUTO_TARGET):
		toggle_auto_target()
		get_viewport().set_input_as_handled()
	elif ActionManager.event_is_pressed(event, ActionManager.ACTION_TOGGLE_AUTO_ATTACK):
		toggle_auto_attack()
		get_viewport().set_input_as_handled()


# 스태미나 잔량·회복 시작 대기 진행을 발밑 게이지로 표시합니다.
func _update_stamina_gauge() -> void:
	var stamina_bar := %DashCooldownBar
	var wait_bar := %StaminaRegenWaitBar
	var max_stamina := get_max_stamina()
	var regen_delay := get_stamina_regen_delay()
	var at_max := _stamina_current >= max_stamina - 0.001
	var in_regen_wait := not at_max and _regen_idle_time < regen_delay - 0.001

	if at_max:
		stamina_bar.visible = false
		wait_bar.visible = false
		return

	stamina_bar.visible = true
	stamina_bar.max_value = max_stamina
	stamina_bar.value = _stamina_current

	wait_bar.visible = in_regen_wait
	if in_regen_wait:
		wait_bar.max_value = regen_delay
		wait_bar.value = _regen_idle_time


# 대시 종료 시 장비 대시 후 무적을 적용합니다.
func _apply_post_dash_invincibility() -> void:
	_add_gear_invincibility(_stats.get_invincibility_after_dash_sec())


func _on_pickup_range_area_entered(area: Area2D) -> void:
	if area.has_method("collect"):
		area.collect(self)
	elif area.has_method("start_magnet"):
		area.start_magnet(self)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_tick_revive_invincibility(delta)
	_tick_gear_invincibility(delta)


func _physics_process(delta: float) -> void:
	_tick_active_buffs(delta)
	_tick_player_debuffs(delta)
	_tick_stamina(delta)
	_tick_health_regen(delta)
	if is_elite_debuff_frozen():
		velocity = Vector2.ZERO
		move_and_slide()
		if velocity.length_squared() > 0.0:
			_play_character_walk_animation()
		else:
			_play_character_idle_animation()
		_apply_contact_damage(delta)
		_damage_float_timer -= delta
		if _damage_float_accumulator > 0.0 and _damage_float_timer <= 0.0:
			_play_hit_flash()
			FloatingDamageText.spawn_player_damage(
				global_position,
				maxi(int(_damage_float_accumulator), 1)
			)
			_damage_float_accumulator = 0.0
			_damage_float_timer = DAMAGE_FLOAT_INTERVAL
		return
	var speed := get_move_speed()
	var direction := _get_move_direction()
	if direction.length_squared() > 0.01:
		_last_move_direction = direction.normalized()

	_update_stamina_gauge()

	if _dash_time_remaining > 0.0:
		_dash_time_remaining = maxf(_dash_time_remaining - delta, 0.0)
		velocity = _dash_direction * DASH_SPEED
		if _dash_time_remaining <= 0.0:
			_apply_post_dash_invincibility()
	elif ActionManager.is_just_pressed(ActionManager.ACTION_DASH) and not _is_dash_input_blocked():
		var dash_dir := direction
		if dash_dir.length_squared() < 0.01:
			dash_dir = _last_move_direction
		if dash_dir.length_squared() > 0.01 and spend_stamina(get_dash_stamina_cost()):
			_dash_direction = dash_dir.normalized()
			_dash_time_remaining = get_effective_dash_duration()
			velocity = _dash_direction * DASH_SPEED
			_apply_loadout_on_dash()
		else:
			velocity = direction * speed
	else:
		velocity = direction * speed

	move_and_slide()

	if velocity.length_squared() > 0.0:
		_play_character_walk_animation()
	else:
		_play_character_idle_animation()
	
	_apply_contact_damage(delta)

	_damage_float_timer -= delta
	if _damage_float_accumulator > 0.0 and _damage_float_timer <= 0.0:
		_play_hit_flash()
		FloatingDamageText.spawn_player_damage(
			global_position,
			maxi(int(_damage_float_accumulator), 1)
		)
		_damage_float_accumulator = 0.0
		_damage_float_timer = DAMAGE_FLOAT_INTERVAL


func _tick_active_buffs(delta: float) -> void:
	if get_tree().paused:
		return
	_buff_controller.tick_seconds(delta)


func _tick_player_debuffs(delta: float) -> void:
	if get_tree().paused:
		return
	_debuff_controller.tick(delta, self)
	RelicCombatBridgeScript.tick(delta, self)
	_update_burn_hud()


# affix 몹 debuff를 적용합니다.
func apply_elite_debuff(debuff_id: StringName, payload: Dictionary = {}) -> void:
	_debuff_controller.apply(debuff_id, payload)
	_update_burn_hud()


# 유물 on-hit 효과 — Mob.apply_weapon_damage 성공 후 호출됩니다.
func notify_relic_weapon_hit_mob(mob: Mob, weapon: WeaponData, raw_damage: int) -> void:
	RelicCombatBridgeScript.on_weapon_hit_mob(mob, weapon, raw_damage)


func is_elite_debuff_frozen() -> bool:
	return _debuff_controller.is_frozen()


# affix debuff·리스폰 시 초기화합니다.
func clear_player_debuffs() -> void:
	_debuff_controller.clear()
	_update_burn_hud()


func _tick_revive_invincibility(delta: float) -> void:
	if _revive_invincible_remaining <= 0.0:
		return
	_revive_invincible_remaining = maxf(_revive_invincible_remaining - delta, 0.0)


func _tick_gear_invincibility(delta: float) -> void:
	if _gear_invincibility_remaining <= 0.0:
		return
	_gear_invincibility_remaining = maxf(_gear_invincibility_remaining - delta, 0.0)


# 체력 0 시 부활 차지를 소비해 생존합니다.
func _try_consume_revive() -> bool:
	if _revive_remaining <= 0 or get_revive_charges_max() <= 0:
		return false
	_revive_remaining -= 1
	_revive_invincible_remaining = REVIVE_INVINCIBILITY_SEC
	var max_hp := get_max_health()
	health = maxf(max_hp * REVIVE_HP_RATIO, 1.0)
	_update_health_hud()
	FloatingInfoText.spawn_info(global_position, UiLocale.t(&"combat.revived"))
	return true


func _try_emit_health_depleted() -> void:
	if health > 0.0 or _health_depleted_emitted:
		return
	health = 0.0
	_update_health_hud()
	var frame := Engine.get_physics_frames()
	if _lethal_resolve_physics_frame == frame:
		return
	_lethal_resolve_physics_frame = frame
	if _try_consume_revive():
		return
	_health_depleted_emitted = true
	health_depleted.emit()
