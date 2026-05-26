extends CharacterBody2D
class_name Mob

signal died

@export var attack_distance := 150.0
@export var contact_attack_interval := 1.0
@export var contact_attack_damage := 1
@export var movement_enabled := true
@export var combat_enabled := true
@export var base_max_health := 200
@export var mob_kind: StringName = &"basic"
@export var speed_min := 160.0
@export var speed_max := 240.0
@export var slime_tint := Color(1.0, 1.0, 1.0, 1.0)
@export var ranged_attack_enabled := false
@export var ranged_cooldown := 1.4
@export var ranged_damage_min := 6
@export var ranged_damage_max := 10
@export var ranged_projectile_speed := 520.0
@export var ranged_max_distance := 900.0
## (레거시) 발사체 스폰은 get_footprint_global_center() — 씬 호환용으로만 유지
@export var ranged_spawn_offset := Vector2.ZERO
@export var ranged_telegraph_delay := 0.5
@export var ranged_attack_mark_offset := Vector2(0, -72)

var speed := 200.0
var max_health := base_max_health
var health := base_max_health

var _nettles_timer := 0.0
var _status_effects := StatusEffectController.new()
var _is_targeted := false
var _target_pulse := 0.0
var _is_dying := false
var _stage_clear_death := false
var _ranged_cooldown_remaining := 0.0
var _contact_attack_cooldown_remaining := 0.0
var _ranged_windup_active := false
var _pending_ranged_direction := Vector2.RIGHT
var _active_attack_mark: Node2D = null

const TARGET_INDICATOR_BASE_SCALE := Vector2(2.4, 2.4)
const EXP_ORB_SCENE := preload("res://effects/exp_orb/exp_orb.tscn")
const GOLD_COIN_SCENE := preload("res://effects/gold_coin/gold_coin.tscn")
const GOLD_DROP_OFFSET := Vector2(12.0, -8.0)
const MOB_PROJECTILE_SCENE := preload("res://entities/mob/mob_projectile.tscn")
const MOB_ATTACK_MARK_SCENE := preload("res://entities/mob/mob_attack_mark.tscn")
const POOL_STORAGE_POSITION := Vector2(-50000.0, -50000.0)
const CONTACT_STANDOFF_PADDING := 6.0
const ATTACK_RANGE_RING_TEXTURE := preload("res://art/shared/fx/circle.png")
const MELEE_ATTACK_RANGE_RING_COLOR := Color(0.95, 0.4, 0.32, 0.28)

@onready var player: Node2D = get_node("/root/Game/Player")
@onready var _target_indicator: Node2D = %TargetIndicator
@onready var _attack_range_ring: Sprite2D = get_node_or_null("AttackRangeRing")


# 스폰 직전 Game에서 호출해 밸런스 HP 배수를 반영합니다.
func initialize_spawn_health(hp_multiplier: float) -> void:
	var scaled := maxi(1, roundi(base_max_health * maxf(hp_multiplier, 0.01)))
	max_health = scaled
	health = scaled
	_sync_health_bar()
	_hide_health_bar()


func pool_reset() -> void:
	if is_in_group("mobs"):
		remove_from_group("mobs")
	_nettles_timer = 0.0
	_status_effects.clear()
	_is_dying = false
	_stage_clear_death = false
	_is_targeted = false
	_target_pulse = 0.0
	_ranged_cooldown_remaining = 0.0
	_contact_attack_cooldown_remaining = 0.0
	_cancel_ranged_telegraph()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if is_inside_tree():
		global_position = POOL_STORAGE_POSITION
	if is_node_ready():
		HitFlash.cancel(%Slime, slime_tint)
		_target_indicator.visible = false
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE
		_target_indicator.rotation = 0.0
		_set_attack_range_ring_visible(false)
		_hide_health_bar()


func pool_on_acquire() -> void:
	PhysicsLayers.apply_mob_body(self)
	speed = randf_range(speed_min, speed_max)
	add_to_group("mobs")
	%Slime.modulate = slime_tint
	if movement_enabled:
		%Slime.play_walk()
	elif %Slime.has_method(&"play_idle"):
		%Slime.play_idle()
	if ranged_attack_enabled and combat_enabled:
		_ranged_cooldown_remaining = randf_range(0.0, ranged_cooldown * 0.5)
	if combat_enabled and (ranged_attack_enabled or movement_enabled):
		if not ranged_attack_enabled:
			_contact_attack_cooldown_remaining = randf_range(
				0.0, maxf(contact_attack_interval, 0.01) * 0.5
			)
		_sync_attack_range_ring()
	else:
		_set_attack_range_ring_visible(false)
	_sync_body_collision_to_shadow()
	set_physics_process(true)


func _sync_health_bar() -> void:
	if not is_node_ready():
		return
	%HealthBar.max_value = max_health
	%HealthBar.value = health


func _hide_health_bar() -> void:
	if not is_node_ready():
		return
	%HealthBar.visible = false


# 피해를 입은 뒤에만 체력바를 표시하고 현재 HP를 반영합니다.
func _reveal_health_bar() -> void:
	if not is_node_ready():
		return
	_sync_health_bar()
	if GameplaySettings.is_mob_health_bar_visible():
		%HealthBar.visible = true


# 설정 변경 시 피해를 받은 몹의 체력바 표시를 갱신합니다.
func refresh_health_bar_visibility() -> void:
	if not is_node_ready():
		return
	if not GameplaySettings.is_mob_health_bar_visible():
		%HealthBar.visible = false
		return
	if health < max_health and health > 0:
		_sync_health_bar()
		%HealthBar.visible = true
	else:
		%HealthBar.visible = false


# AttackRangeRing — 원거리는 attack_distance, 근거리는 접촉 정지 거리(standoff) 반경.
func _sync_attack_range_ring() -> void:
	_ensure_attack_range_ring()
	if not _attack_range_ring:
		return
	var tex := _attack_range_ring.texture
	if not tex:
		_set_attack_range_ring_visible(false)
		return
	var tex_radius := maxf(tex.get_width(), tex.get_height()) * 0.5
	if tex_radius <= 0.0:
		return
	var display_radius := attack_distance
	if not ranged_attack_enabled:
		display_radius = _get_contact_standoff_distance()
	var ring_scale := display_radius / tex_radius
	_attack_range_ring.scale = Vector2(ring_scale, ring_scale)
	_set_attack_range_ring_visible(true)


# 근거리 몹은 씬에 링이 없을 수 있어 런타임에 생성합니다.
func _ensure_attack_range_ring() -> void:
	if _attack_range_ring:
		return
	_attack_range_ring = Sprite2D.new()
	_attack_range_ring.name = &"AttackRangeRing"
	_attack_range_ring.z_index = -10
	_attack_range_ring.texture = ATTACK_RANGE_RING_TEXTURE
	if ranged_attack_enabled:
		var ranged_color := slime_tint
		ranged_color.a = 0.28
		_attack_range_ring.modulate = ranged_color
	else:
		_attack_range_ring.modulate = MELEE_ATTACK_RANGE_RING_COLOR
	add_child(_attack_range_ring)


# 설정·스폰 상태에 맞춰 공격 범위 링 표시를 갱신합니다.
func refresh_attack_range_ring() -> void:
	if combat_enabled and (ranged_attack_enabled or movement_enabled):
		_sync_attack_range_ring()
	else:
		_set_attack_range_ring_visible(false)


func _is_attack_range_ring_setting_enabled() -> bool:
	if ranged_attack_enabled:
		return GameplaySettings.is_ranged_attack_range_visible()
	return GameplaySettings.is_melee_attack_range_visible()


func _set_attack_range_ring_visible(visible_state: bool) -> void:
	if _attack_range_ring:
		_attack_range_ring.visible = (
			visible_state and _is_attack_range_ring_setting_enabled()
		)


func set_targeted(active: bool) -> void:
	_is_targeted = active
	_target_indicator.visible = active
	if not active:
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE
		_target_indicator.rotation = 0.0
		_target_pulse = 0.0


func _process(delta: float) -> void:
	if not _is_targeted:
		return
	_target_pulse += delta * 8.0
	var pulse := 1.0 + sin(_target_pulse) * 0.1
	_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE * pulse
	_target_indicator.rotation = sin(_target_pulse * 0.65) * 0.12


func _physics_process(delta: float) -> void:
	if ranged_attack_enabled and combat_enabled and _ranged_cooldown_remaining > 0.0:
		_ranged_cooldown_remaining = maxf(_ranged_cooldown_remaining - delta, 0.0)

	if movement_enabled:
		var offset: Vector2 = (
			GroundShadowFootprint.get_combat_target_center(player as Node2D)
			- get_footprint_global_center()
		)
		var distance: float = offset.length()
		var stop_distance := _get_contact_standoff_distance()

		if distance > stop_distance:
			velocity = offset / distance * _get_effective_speed()
		else:
			velocity = Vector2.ZERO
			if (
				ranged_attack_enabled
				and combat_enabled
				and not _ranged_windup_active
				and _ranged_cooldown_remaining <= 0.0
				and offset.length_squared() > 0.01
			):
				_begin_ranged_telegraph(offset)
	else:
		velocity = Vector2.ZERO

	if movement_enabled:
		_apply_mob_separation()
		_clamp_velocity_away_from_player()
	_status_effects.tick(delta, self)
	_process_nettles(delta)
	move_and_slide()


func _apply_mob_separation() -> void:
	const SEPARATION_RADIUS := 70.0
	const SEPARATION_FORCE := 4.0

	for mob in get_tree().get_nodes_in_group("mobs"):
		if mob == self:
			continue

		var push: Vector2 = global_position - mob.global_position
		var dist: float = push.length()
		if dist > 0.0 and dist < SEPARATION_RADIUS:
			velocity += push.normalized() * (SEPARATION_RADIUS - dist) * SEPARATION_FORCE

	var effective_speed := _get_effective_speed()
	if velocity.length() > effective_speed:
		velocity = velocity.normalized() * effective_speed


func _get_effective_speed() -> float:
	return speed * _status_effects.get_move_speed_mult()


# 접촉 공격 판정·범위 링에 쓰는 중심 간 거리(플레이어 global_position 기준).
func get_contact_attack_distance() -> float:
	if not is_node_ready():
		return attack_distance
	return _get_contact_standoff_distance()


# 근접 접촉·범위 DPS — 원거리 몹은 발사체만 피해.
func is_contact_damage_active() -> bool:
	return not _is_dying and is_in_group("mobs") and not ranged_attack_enabled


func is_player_in_contact_attack_range(player_global_position: Vector2) -> bool:
	if not is_contact_damage_active():
		return false
	var attack_dist := get_contact_attack_distance()
	return (
		global_position.distance_squared_to(player_global_position)
		<= attack_dist * attack_dist
	)


# 공격 범위 안에서 contact_attack_interval마다 contact_attack_damage를 반환합니다.
func tick_contact_attack(delta: float) -> int:
	if not is_contact_damage_active() or contact_attack_damage <= 0:
		return 0
	var interval := maxf(contact_attack_interval, 0.01)
	_contact_attack_cooldown_remaining -= delta
	if _contact_attack_cooldown_remaining > 0.0:
		return 0
	_contact_attack_cooldown_remaining = interval
	return contact_attack_damage


# 발밑 그림자 충돌 박스·플레이어 HurtBox가 겹치지 않는 중심 간 최소 거리
func _get_contact_standoff_distance() -> float:
	var mob_half := GroundShadowFootprint.footprint_half_extents_from_visual(%Slime)
	var player_half := Vector2.ZERO
	if player.has_method(&"get_contact_hurtbox_half_extents"):
		player_half = player.call(&"get_contact_hurtbox_half_extents") as Vector2
	var shape_clear := GroundShadowFootprint.min_center_distance_no_overlap(
		mob_half,
		player_half,
		CONTACT_STANDOFF_PADDING
	)
	return maxf(attack_distance, shape_clear)


# Slime 자식 GroundShadow 글로벌 스케일에 맞춰 몹 이동 충돌체를 맞춥니다.
func _sync_body_collision_to_shadow() -> void:
	GroundShadowFootprint.sync_collision_shape_to_shadow(self, $CollisionShape2D, %Slime)


# 조준·발사체·접촉 거리에 쓰는 발밑 그림자 중심.
func get_footprint_global_center() -> Vector2:
	return GroundShadowFootprint.footprint_center_global(%Slime)


# 몹 분리력이 플레이어 접촉 거리 안으로 밀어넣지 않도록 접근 속도를 제거합니다.
func _clamp_velocity_away_from_player() -> void:
	var to_player := (
		GroundShadowFootprint.get_combat_target_center(player as Node2D)
		- get_footprint_global_center()
	)
	var distance := to_player.length()
	var stop_distance := _get_contact_standoff_distance()
	if distance >= stop_distance or distance < 0.01:
		return
	var toward := to_player / distance
	var toward_speed := velocity.dot(toward)
	if toward_speed > 0.0:
		velocity -= toward * toward_speed


# 사거리 안에서 공격 마크를 띄운 뒤 ranged_telegraph_delay 후 탄환을 쏩니다.
func _begin_ranged_telegraph(offset: Vector2) -> void:
	if _ranged_windup_active:
		return

	_ranged_windup_active = true
	_pending_ranged_direction = offset.normalized()
	_spawn_attack_mark()

	var tree := get_tree()
	if not tree:
		_complete_ranged_telegraph()
		return

	var timer := tree.create_timer(ranged_telegraph_delay)
	timer.timeout.connect(_on_ranged_telegraph_timeout, CONNECT_ONE_SHOT)


func _on_ranged_telegraph_timeout() -> void:
	if not _ranged_windup_active or _is_dying or not is_inside_tree():
		_cancel_ranged_telegraph()
		return
	_complete_ranged_telegraph()


func _complete_ranged_telegraph() -> void:
	_release_attack_mark()
	_ranged_windup_active = false
	var from_center := get_footprint_global_center()
	var to_center := GroundShadowFootprint.get_combat_target_center(player as Node2D)
	var aim := to_center - from_center
	if aim.length_squared() > 0.01:
		_fire_ranged_projectile(aim.normalized())
	elif _pending_ranged_direction.length_squared() > 0.01:
		_fire_ranged_projectile(_pending_ranged_direction)


func _cancel_ranged_telegraph() -> void:
	_ranged_windup_active = false
	_release_attack_mark()


func _spawn_attack_mark() -> void:
	_release_attack_mark()

	var game := get_node_or_null("/root/Game")
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	if pool and pool.has_method(&"acquire"):
		_active_attack_mark = pool.acquire(MOB_ATTACK_MARK_SCENE, self) as Node2D
	else:
		_active_attack_mark = MOB_ATTACK_MARK_SCENE.instantiate()
		add_child(_active_attack_mark)

	if _active_attack_mark.has_method(&"setup"):
		_active_attack_mark.setup(ranged_attack_mark_offset, slime_tint)


func _release_attack_mark() -> void:
	if is_instance_valid(_active_attack_mark):
		PoolUtil.release_node(_active_attack_mark)
	_active_attack_mark = null


# 풀링 탄환을 발사합니다(예고 종료 후 호출). 스폰·방향은 발밑 그림자 중심 기준.
func _fire_ranged_projectile(direction: Vector2) -> void:
	var aim_dir := direction.normalized()
	var damage := randi_range(ranged_damage_min, ranged_damage_max)
	var spawn_pos := get_footprint_global_center()

	var game := get_node_or_null("/root/Game")
	var spawn_parent := get_parent()
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	var projectile: Node2D
	if pool and pool.has_method(&"acquire"):
		projectile = pool.acquire(MOB_PROJECTILE_SCENE, spawn_parent) as Node2D
	else:
		projectile = MOB_PROJECTILE_SCENE.instantiate()
		spawn_parent.add_child(projectile)

	projectile.global_position = spawn_pos
	if projectile.has_method(&"setup"):
		projectile.setup(
			player as CharacterBody2D,
			aim_dir,
			damage,
			ranged_projectile_speed,
			ranged_max_distance,
			slime_tint
		)

	_ranged_cooldown_remaining = ranged_cooldown


func apply_nettles(duration: float) -> void:
	_nettles_timer = maxf(_nettles_timer, duration)


func has_nettles() -> bool:
	return _nettles_timer > 0.0


func _process_nettles(delta: float) -> void:
	if _nettles_timer > 0.0:
		_nettles_timer = maxf(_nettles_timer - delta, 0.0)


func apply_poison(weapon: WeaponData) -> void:
	apply_status(&"poison", weapon)


func _play_hit_flash() -> void:
	if not is_node_ready():
		return
	HitFlash.play(%Slime, slime_tint)


func apply_status(status_id: StringName, weapon: WeaponData = null) -> void:
	var active := _status_effects.apply_status(status_id, weapon)
	if active != null and active.data != null:
		FloatingStatusEffectText.spawn_status_applied(global_position, active.data)


func apply_status_tick_damage(
	amount: int,
	damage_element: StringName,
	weapon: WeaponData = null,
	color: Color = Color.WHITE
) -> void:
	if _is_dying or amount <= 0:
		return

	var final_amount := _apply_damage_taken_mult(amount, String(damage_element))
	if has_nettles() and damage_element == &"poison":
		final_amount = int(final_amount * 1.5)
	if final_amount <= 0:
		return

	_play_hit_flash()
	_register_weapon_damage(weapon, final_amount)
	health -= final_amount
	_reveal_health_bar()
	FloatingDamageText.spawn_weapon_damage(global_position, final_amount, color)

	if health <= 0:
		_request_die()


func take_damage(amount: int) -> void:
	if _is_dying or amount <= 0:
		return

	_play_hit_flash()
	%Slime.play_hurt()
	health -= amount
	_reveal_health_bar()
	FloatingDamageText.spawn_enemy_damage(global_position, amount)

	if health <= 0:
		_request_die()


func apply_weapon_damage(amount: int, weapon: WeaponData) -> void:
	if _is_dying or amount <= 0 or not weapon:
		return

	var final_amount := _apply_damage_taken_mult(amount, weapon.damage_element)
	if final_amount <= 0:
		return

	_register_weapon_damage(weapon, final_amount)
	_play_hit_flash()
	%Slime.play_hurt()
	health -= final_amount
	_reveal_health_bar()
	FloatingDamageText.spawn_weapon_damage(global_position, final_amount, weapon.get_element_color())

	if weapon.applies_nettles:
		apply_nettles(weapon.nettles_duration)
	_apply_weapon_status_effects(weapon)

	if health <= 0:
		_request_die()


func take_magic_damage(amount: int, weapon: WeaponData) -> void:
	apply_weapon_damage(amount, weapon)


func _register_weapon_damage(weapon: WeaponData, amount: int) -> void:
	if amount <= 0 or weapon == null:
		return
	var game := get_node_or_null("/root/Game")
	if game and game.has_method(&"register_weapon_damage"):
		game.register_weapon_damage(weapon, amount)


func _apply_weapon_status_effects(weapon: WeaponData) -> void:
	if weapon == null or weapon.status_effects.is_empty():
		return
	for status_id in weapon.status_effects:
		if randf() > weapon.status_chance:
			continue
		apply_status(status_id, weapon)


func _apply_damage_taken_mult(amount: int, damage_element: String) -> int:
	if damage_element.is_empty():
		return amount
	var mult := _status_effects.get_damage_taken_mult(damage_element)
	return maxi(0, roundi(float(amount) * mult))


# 30분 클리어 시 전장 정리용 — 드랍·처치 집계 없이 사망 처리합니다.
func die_from_stage_clear() -> void:
	if _is_dying:
		return
	_stage_clear_death = true
	health = 0
	_request_die()


func _request_die() -> void:
	if _is_dying:
		return
	_cancel_ranged_telegraph()
	_is_dying = true
	set_targeted(false)
	_hide_health_bar()
	set_physics_process(false)
	call_deferred("_die")


func _die() -> void:
	if not is_inside_tree():
		return

	died.emit()

	if _stage_clear_death:
		PoolUtil.release_node(self)
		return

	var smoke_scene = preload("res://effects/smoke_explosion/smoke_explosion.tscn")
	var smoke = smoke_scene.instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = global_position

	var game := get_node_or_null("/root/Game")
	if game and game.has_method("register_kill"):
		game.register_kill()

	var spawn_parent := get_parent()
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	var rewards: Dictionary = _compute_kill_rewards(game)
	if int(rewards.get(&"xp", 0)) > 0:
		var exp_orb: Node2D
		if pool and pool.has_method(&"acquire"):
			exp_orb = pool.acquire(EXP_ORB_SCENE, spawn_parent) as Node2D
		else:
			exp_orb = EXP_ORB_SCENE.instantiate()
			spawn_parent.add_child(exp_orb)
		exp_orb.global_position = global_position
		exp_orb.experience_value = int(rewards[&"xp"])

	if int(rewards.get(&"gold", 0)) > 0:
		var gold_coin: Node2D
		if pool and pool.has_method(&"acquire"):
			gold_coin = pool.acquire(GOLD_COIN_SCENE, spawn_parent) as Node2D
		else:
			gold_coin = GOLD_COIN_SCENE.instantiate()
			spawn_parent.add_child(gold_coin)
		gold_coin.global_position = global_position + GOLD_DROP_OFFSET
		gold_coin.gold_value = int(rewards[&"gold"])

	const MAGNET_DROP_CHANCE := 0.01
	if randf() < MAGNET_DROP_CHANCE:
		var magnet_scene = preload("res://effects/magnet_pickup/magnet_pickup.tscn")
		var magnet = magnet_scene.instantiate()
		get_parent().add_child(magnet)
		magnet.global_position = global_position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))

	const HEALTH_DROP_CHANCE := 0.01
	if randf() < HEALTH_DROP_CHANCE:
		var health_scene = preload("res://effects/health_pickup/health_pickup.tscn")
		var health_pickup = health_scene.instantiate()
		get_parent().add_child(health_pickup)
		health_pickup.global_position = global_position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))

	PoolUtil.release_node(self)


# 처치 보상 — Game 밸런스 시계가 있으면 현재 페이즈, 없으면 loot 1.0.
func _compute_kill_rewards(game: Node) -> Dictionary:
	if game and game.has_method(&"get_kill_rewards_for_mob"):
		return game.get_kill_rewards_for_mob(mob_kind)
	return KillRewards.compute(mob_kind, BalancePhase.new())
