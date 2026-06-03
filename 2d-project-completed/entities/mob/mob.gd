extends CharacterBody2D
class_name Mob

signal died

@export var attack_distance := 150.0
## 추격 정지 거리. 0이면 attack_distance - CHASE_DEFAULT_INSET(공격 사거리보다 조금 가깝게).
@export var chase_distance := 0.0
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
## 근접·원거리·돌진 공격 전 느낌표 예고 대기 시간(초).
@export var ranged_telegraph_delay := 0.5
@export var ranged_attack_mark_offset := Vector2(0, -72)
@export var death_burst_enabled := false
@export var death_burst_radius := 96.0
@export var death_burst_damage := 12
## 사망 후 폭발까지 대기 시간(초). 0이면 즉시 폭발합니다.
@export var death_burst_delay := 0.0
@export var charge_attack_enabled := false
@export var charge_trigger_distance := 230.0
@export var charge_speed_mult := 2.6
@export var charge_duration := 0.32
@export var charge_cooldown := 2.2
@export var charge_end_burst_radius := 76.0
@export var charge_end_burst_damage := 10
## 돌진 시작 시 직선 구간·화살표 예고 표시 시간(초).
@export var charge_lane_display_duration := 1.0
@export var jump_chase_enabled := false
@export var jump_chase_trigger_distance := 230.0
@export var jump_chase_windup_delay := 0.4
@export var jump_chase_travel_distance := 140.0
@export var jump_chase_duration := 0.28
@export var jump_chase_arc_height := 48.0
@export var jump_chase_cooldown := 1.6
## 완료 효과용 — 기술 본체(MobChaseSkillJump)와 분리된 튜닝 키.
@export var jump_chase_landing_burst_radius := 68.0
@export var jump_chase_landing_burst_damage := 10
@export var self_destruct_enabled := false
@export var self_destruct_health_ratio := 0.2

enum ChaseMode {
	STRAIGHT,
	ORBIT,
}

@export var chase_mode: ChaseMode = ChaseMode.STRAIGHT
## 포위 추격 시 standoff 바깥 목표 궤도 반경(픽셀).
@export var orbit_radius_buffer := 48.0
## 포위 추격 시 직선 접근에서 접선 이동으로 블렌드하는 거리(픽셀).
@export var orbit_approach_blend := 72.0

var speed := 200.0
var max_health := base_max_health
var health := base_max_health
## overloading affix 방어막 placeholder — PR-C에서 사용.
var elite_shield_hp := 0
var _elite_pre_affix_contact_damage := 0
var _elite_pre_affix_ranged_mid := 0

var _nettles_timer := 0.0
var _elite_affix_id: StringName = &""
var _elite_runtime: EliteAffixRuntime = null
var _elite_restore_slime_tint := Color.WHITE
var _elite_affix_label: Label = null
var _status_effects := StatusEffectController.new()
var _is_targeted := false
var _target_pulse := 0.0
var _is_dying := false
var _stage_clear_death := false
var _ranged_cooldown_remaining := 0.0
var _contact_attack_cooldown_remaining := 0.0
var _ranged_windup_active := false
var _contact_windup_active := false
var _charge_attack_mark_active := false
var _pending_ranged_direction := Vector2.RIGHT
var _active_attack_mark: Node2D = null
var _charge_active := false
var _charge_windup_remaining := 0.0
var _charge_direction := Vector2.RIGHT
var _charge_time_remaining := 0.0
var _charge_cooldown_remaining := 0.0
var _chase_skill: MobChaseSkill = null
var _chase_skill_cooldown_remaining := 0.0
var _chase_skill_completion_effects: Array[MobChaseSkillEffect] = []
var _chase_skill_invuln_pulse := 0.0
var _chase_skill_invuln_visual_active := false
var _self_destruct_armed := false
var _chase_strategy: MobChaseStrategy = MobChaseStraight.new()
var _chase_context := MobChaseContext.new()
var _orbit_clockwise := true

const TARGET_INDICATOR_BASE_SCALE := Vector2(2.4, 2.4)
const EXP_ORB_SCENE := preload("res://effects/exp_orb/exp_orb.tscn")
const GOLD_COIN_SCENE := preload("res://effects/gold_coin/gold_coin.tscn")
const EQUIPMENT_DROP_SCENE := preload("res://effects/equipment_drop/equipment_drop.tscn")
const GOLD_DROP_OFFSET := Vector2(12.0, -8.0)
const MOB_PROJECTILE_SCENE := preload("res://entities/mob/mob_projectile.tscn")
const MOB_ATTACK_MARK_SCENE := preload("res://entities/mob/mob_attack_mark.tscn")
const MOB_CHARGE_LANE_SCENE := preload("res://entities/mob/mob_charge_lane.tscn")
const POOL_STORAGE_POSITION := Vector2(-50000.0, -50000.0)
const CONTACT_STANDOFF_PADDING := 6.0
const CHASE_DEFAULT_INSET := 24.0
const ATTACK_RANGE_RING_TEXTURE := preload("res://art/shared/fx/circle.png")
const MELEE_ATTACK_RANGE_RING_COLOR := Color(0.95, 0.4, 0.32, 0.28)
const CHASE_SKILL_TRIGGER_RING_COLOR := Color(0.55, 0.82, 1.0, 0.22)
const CHASE_SKILL_LANDING_RING_COLOR := Color(0.98, 0.62, 0.28, 0.3)
const CHASE_STOP_RANGE_RING_COLOR := Color(0.42, 0.9, 0.58, 0.26)
const STATUS_ICON_DEFAULT_TEXT := "ST"
const STATUS_ICON_TEXT := {
	&"bleed": "BD",
	&"burn": "BR",
	&"scorch": "SC",
	&"zap": "ZP",
	&"poison": "PS",
	&"toxic": "TX",
	&"chill": "CH",
	&"frostbite": "FB"
}
const ELITE_AFFIX_LABEL_NODE_NAME := &"EliteAffixLabel"
const ELITE_AFFIX_LABEL_HEIGHT := 18.0
const ELITE_AFFIX_LABEL_GAP := 4.0
const HEALTH_BAR_LABEL_NODE_NAME := &"HealthLabel"

@onready var player: Node2D = get_node("/root/Game/Player")
@onready var _target_indicator: Node2D = %TargetIndicator
@onready var _attack_range_ring: Sprite2D = get_node_or_null("AttackRangeRing")
var _chase_stop_ring: Sprite2D
var _chase_skill_trigger_ring: Sprite2D
var _chase_skill_landing_ring: Sprite2D
@onready var _status_effect_icons: HBoxContainer = get_node_or_null("StatusEffectIcons") as HBoxContainer

var _status_icon_signature := ""
var _health_bar_label: Label = null


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
	_chase_strategy.reset()
	_reset_status_effect_icons()
	_is_dying = false
	_stage_clear_death = false
	_is_targeted = false
	_target_pulse = 0.0
	_ranged_cooldown_remaining = 0.0
	_contact_attack_cooldown_remaining = 0.0
	_cancel_all_attack_telegraphs()
	_charge_active = false
	_charge_windup_remaining = 0.0
	_charge_direction = Vector2.RIGHT
	_charge_time_remaining = 0.0
	_charge_cooldown_remaining = 0.0
	if _chase_skill != null:
		_chase_skill.reset()
	_chase_skill_cooldown_remaining = 0.0
	_chase_skill_invuln_pulse = 0.0
	_chase_skill_invuln_visual_active = false
	_self_destruct_armed = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if is_inside_tree():
		global_position = POOL_STORAGE_POSITION
	_reset_elite_affix()
	if is_node_ready():
		HitFlash.cancel(%Slime, slime_tint)
		_target_indicator.visible = false
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE
		_target_indicator.rotation = 0.0
		_set_attack_range_ring_visible(false)
		_set_chase_stop_ring_visible(false)
		_set_chase_skill_range_rings_visible(false)
		_hide_health_bar()


func pool_on_acquire() -> void:
	PhysicsLayers.apply_mob_body(self)
	speed = randf_range(speed_min, speed_max)
	_resolve_chase_strategy()
	add_to_group("mobs")
	_elite_restore_slime_tint = slime_tint
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
		if charge_attack_enabled:
			_charge_cooldown_remaining = randf_range(0.0, maxf(charge_cooldown, 0.01) * 0.5)
		if jump_chase_enabled:
			_ensure_chase_skill()
			_chase_skill_completion_effects = _build_jump_chase_completion_effects()
			_chase_skill_cooldown_remaining = randf_range(
				0.0, maxf(jump_chase_cooldown, 0.01) * 0.5
			)
		_sync_attack_range_ring()
		_sync_chase_stop_ring()
		_sync_chase_skill_range_rings()
	else:
		_set_attack_range_ring_visible(false)
		_set_chase_stop_ring_visible(false)
		_set_chase_skill_range_rings_visible(false)
	_sync_body_collision_to_shadow()
	set_physics_process(true)


func get_elite_affix_id() -> StringName:
	return _elite_affix_id


func has_elite_affix() -> bool:
	return not _elite_affix_id.is_empty()


# affix stat 배율 적용 전 공격력 스냅샷 — glacial 사망 폭탄 등에 사용.
func store_elite_pre_affix_attack_snapshot() -> void:
	_elite_pre_affix_contact_damage = contact_attack_damage
	if ranged_attack_enabled and ranged_damage_max > 0:
		_elite_pre_affix_ranged_mid = roundi((ranged_damage_min + ranged_damage_max) * 0.5)
	else:
		_elite_pre_affix_ranged_mid = 0


func get_elite_pre_affix_attack_damage() -> int:
	if _elite_pre_affix_contact_damage > 0:
		return _elite_pre_affix_contact_damage
	return _elite_pre_affix_ranged_mid


# affix id·noop runtime을 등록합니다 — stat·비주얼은 EliteAffixApplier가 선행 적용.
func apply_elite_affix(affix_id: StringName) -> void:
	if affix_id.is_empty():
		return
	_elite_affix_id = affix_id
	elite_shield_hp = 0
	_elite_runtime = EliteAffixRuntimeRegistry.create_runtime(affix_id)
	if _elite_runtime != null:
		_elite_runtime.begin(self)
	if is_node_ready():
		_sync_elite_affix_nameplate()
	else:
		ready.connect(_sync_elite_affix_nameplate, CONNECT_ONE_SHOT)


# affix tint 적용 전 복원용 baseline을 저장합니다.
func store_elite_affix_visual_baseline() -> void:
	_elite_restore_slime_tint = slime_tint


func _elite_tick(delta: float) -> void:
	if _elite_runtime != null:
		_elite_runtime.tick(delta, self)


func _elite_on_hit_player(raw_damage: int) -> void:
	if _elite_runtime != null:
		_elite_runtime.on_hit_player(raw_damage, self)


# 무기 적중 성공 시 유물 on-hit 효과를 Player 쪽 bridge로 위임합니다.
func _notify_relic_weapon_hit(weapon: WeaponData, raw_damage: int) -> void:
	if not is_instance_valid(player):
		return
	if player.has_method(&"notify_relic_weapon_hit_mob"):
		player.call(&"notify_relic_weapon_hit_mob", self, weapon, raw_damage)


func _reset_elite_affix() -> void:
	if _elite_runtime != null:
		_elite_runtime.reset()
		_elite_runtime = null
	_elite_affix_id = &""
	elite_shield_hp = 0
	_elite_pre_affix_contact_damage = 0
	_elite_pre_affix_ranged_mid = 0
	slime_tint = _elite_restore_slime_tint
	_remove_elite_horn_child()
	_hide_elite_affix_nameplate()


func _sync_elite_affix_nameplate() -> void:
	if _elite_affix_id.is_empty():
		_hide_elite_affix_nameplate()
		return
	var data := EliteAffixCatalog.get_affix(_elite_affix_id)
	if data == null:
		_hide_elite_affix_nameplate()
		return
	var label := _ensure_elite_affix_label()
	var display_text := data.display_prefix_ko.strip_edges()
	if display_text.is_empty():
		display_text = String(_elite_affix_id)
	label.text = display_text
	label.add_theme_color_override("font_color", data.tint)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.9))
	label.add_theme_constant_override("outline_size", 2)
	_position_elite_affix_label()
	label.visible = true


func _ensure_elite_affix_label() -> Label:
	if _elite_affix_label != null and is_instance_valid(_elite_affix_label):
		return _elite_affix_label
	var existing := get_node_or_null(String(ELITE_AFFIX_LABEL_NODE_NAME)) as Label
	if existing != null:
		_elite_affix_label = existing
		return existing
	var label := Label.new()
	label.name = String(ELITE_AFFIX_LABEL_NODE_NAME)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 102
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	_elite_affix_label = label
	return label


func _position_elite_affix_label() -> void:
	if _elite_affix_label == null:
		return
	var left_x := -50.0
	var width := 100.0
	var top_y := -138.0
	var bar := get_node_or_null("%HealthBar") as Control
	if bar != null:
		left_x = bar.offset_left
		width = bar.offset_right - bar.offset_left
		top_y = bar.offset_top - ELITE_AFFIX_LABEL_GAP - ELITE_AFFIX_LABEL_HEIGHT
	if _status_effect_icons != null:
		top_y = minf(
			top_y,
			_status_effect_icons.offset_top - ELITE_AFFIX_LABEL_GAP - ELITE_AFFIX_LABEL_HEIGHT
		)
	_elite_affix_label.position = Vector2(left_x, top_y)
	_elite_affix_label.size = Vector2(width, ELITE_AFFIX_LABEL_HEIGHT)


func _hide_elite_affix_nameplate() -> void:
	if _elite_affix_label != null and is_instance_valid(_elite_affix_label):
		_elite_affix_label.visible = false


func _remove_elite_horn_child() -> void:
	if not is_node_ready():
		return
	var slime := get_node_or_null("%Slime") as Node
	if slime == null:
		return
	var horn := slime.get_node_or_null(String(EliteAffixIds.HORN_NODE_NAME))
	if horn != null:
		horn.free()


func _ensure_health_bar_label() -> Label:
	if _health_bar_label != null and is_instance_valid(_health_bar_label):
		return _health_bar_label
	var existing := %HealthBar.get_node_or_null(String(HEALTH_BAR_LABEL_NODE_NAME)) as Label
	if existing != null:
		_health_bar_label = existing
		return existing
	var label := Label.new()
	label.name = String(HEALTH_BAR_LABEL_NODE_NAME)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 2)
	%HealthBar.add_child(label)
	_health_bar_label = label
	return label


func _sync_health_bar() -> void:
	if not is_node_ready():
		return
	%HealthBar.max_value = max_health
	%HealthBar.value = health
	var max_value: float = maxf(max_health, 1.0)
	var label := _ensure_health_bar_label()
	label.text = "%d / %d" % [int(round(health)), int(round(max_value))]


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


# AttackRangeRing — 공격 사거리(attack_range) 반경.
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
	var display_radius := _get_attack_range_distance()
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


# ChaseStopRing — 추격 정지 거리(_get_chase_stop_distance) 반경.
func _sync_chase_stop_ring() -> void:
	_ensure_chase_stop_ring()
	if _chase_stop_ring == null:
		return
	var tex := _chase_stop_ring.texture
	if tex == null:
		_set_chase_stop_ring_visible(false)
		return
	var tex_radius := maxf(tex.get_width(), tex.get_height()) * 0.5
	if tex_radius <= 0.0:
		return
	var display_radius := _get_chase_stop_distance()
	var ring_scale := display_radius / tex_radius
	_chase_stop_ring.scale = Vector2(ring_scale, ring_scale)
	_set_chase_stop_ring_visible(true)


func _ensure_chase_stop_ring() -> void:
	if _chase_stop_ring:
		return
	_chase_stop_ring = Sprite2D.new()
	_chase_stop_ring.name = &"ChaseStopRing"
	_chase_stop_ring.z_index = -12
	_chase_stop_ring.texture = ATTACK_RANGE_RING_TEXTURE
	_chase_stop_ring.modulate = CHASE_STOP_RANGE_RING_COLOR
	add_child(_chase_stop_ring)


# 설정·스폰 상태에 맞춰 추격 정지 링 표시를 갱신합니다.
func refresh_chase_stop_ring() -> void:
	if combat_enabled and movement_enabled:
		_sync_chase_stop_ring()
	else:
		_set_chase_stop_ring_visible(false)


func _should_show_chase_stop_ring() -> bool:
	return (
		combat_enabled
		and movement_enabled
		and GameplaySettings.is_chase_stop_range_visible()
	)


func _set_chase_stop_ring_visible(visible_state: bool) -> void:
	if _chase_stop_ring:
		_chase_stop_ring.visible = visible_state and _should_show_chase_stop_ring()


# 추격 기술 — 발동 거리·착지 burst 반경(기술 진행 중) 링.
func _sync_chase_skill_range_rings() -> void:
	if not _should_show_chase_skill_range_rings():
		_set_chase_skill_range_rings_visible(false)
		return
	_sync_chase_skill_trigger_ring()
	if (
		_chase_skill != null
		and _chase_skill.is_active()
		and _chase_skill is MobChaseSkillJump
	):
		var jump_skill := _chase_skill as MobChaseSkillJump
		_sync_chase_skill_landing_ring(
			jump_skill.get_landing_footprint_global(),
			jump_skill.get_landing_burst_radius()
		)
	else:
		_set_chase_skill_landing_ring_visible(false)


func refresh_chase_skill_range_rings() -> void:
	if jump_chase_enabled and combat_enabled and movement_enabled:
		_sync_chase_skill_range_rings()
	else:
		_set_chase_skill_range_rings_visible(false)


func _should_show_chase_skill_range_rings() -> bool:
	return (
		jump_chase_enabled
		and combat_enabled
		and movement_enabled
		and GameplaySettings.is_chase_skill_range_visible()
	)


func _sync_chase_skill_trigger_ring() -> void:
	_ensure_chase_skill_trigger_ring()
	var tex := _chase_skill_trigger_ring.texture
	if tex == null:
		_set_chase_skill_trigger_ring_visible(false)
		return
	var tex_radius := maxf(tex.get_width(), tex.get_height()) * 0.5
	if tex_radius <= 0.0:
		return
	var ring_scale := maxf(jump_chase_trigger_distance, 0.0) / tex_radius
	_chase_skill_trigger_ring.scale = Vector2(ring_scale, ring_scale)
	_set_chase_skill_trigger_ring_visible(true)


func _sync_chase_skill_landing_ring(global_center: Vector2, radius: float) -> void:
	if radius <= 0.0:
		_set_chase_skill_landing_ring_visible(false)
		return
	_ensure_chase_skill_landing_ring()
	var tex := _chase_skill_landing_ring.texture
	if tex == null:
		_set_chase_skill_landing_ring_visible(false)
		return
	var tex_radius := maxf(tex.get_width(), tex.get_height()) * 0.5
	if tex_radius <= 0.0:
		return
	var foot_offset := global_center - get_footprint_global_center()
	_chase_skill_landing_ring.position = foot_offset
	var ring_scale := radius / tex_radius
	_chase_skill_landing_ring.scale = Vector2(ring_scale, ring_scale)
	_set_chase_skill_landing_ring_visible(true)


func _ensure_chase_skill_trigger_ring() -> void:
	if _chase_skill_trigger_ring:
		return
	_chase_skill_trigger_ring = Sprite2D.new()
	_chase_skill_trigger_ring.name = &"ChaseSkillTriggerRing"
	_chase_skill_trigger_ring.z_index = -11
	_chase_skill_trigger_ring.texture = ATTACK_RANGE_RING_TEXTURE
	_chase_skill_trigger_ring.modulate = CHASE_SKILL_TRIGGER_RING_COLOR
	add_child(_chase_skill_trigger_ring)


func _ensure_chase_skill_landing_ring() -> void:
	if _chase_skill_landing_ring:
		return
	_chase_skill_landing_ring = Sprite2D.new()
	_chase_skill_landing_ring.name = &"ChaseSkillLandingRing"
	_chase_skill_landing_ring.z_index = -9
	_chase_skill_landing_ring.texture = ATTACK_RANGE_RING_TEXTURE
	_chase_skill_landing_ring.modulate = CHASE_SKILL_LANDING_RING_COLOR
	add_child(_chase_skill_landing_ring)


func _set_chase_skill_range_rings_visible(visible_state: bool) -> void:
	_set_chase_skill_trigger_ring_visible(visible_state)
	_set_chase_skill_landing_ring_visible(false)


func _set_chase_skill_trigger_ring_visible(visible_state: bool) -> void:
	if _chase_skill_trigger_ring:
		_chase_skill_trigger_ring.visible = (
			visible_state and _should_show_chase_skill_range_rings()
		)


func _set_chase_skill_landing_ring_visible(visible_state: bool) -> void:
	if _chase_skill_landing_ring:
		_chase_skill_landing_ring.visible = (
			visible_state and _should_show_chase_skill_range_rings()
		)


func set_targeted(active: bool) -> void:
	_is_targeted = active
	_target_indicator.visible = active
	if not active:
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE
		_target_indicator.rotation = 0.0
		_target_pulse = 0.0


func _process(delta: float) -> void:
	_update_chase_skill_invuln_visual(delta)
	if not _is_targeted:
		return
	_target_pulse += delta * 8.0
	var pulse := 1.0 + sin(_target_pulse) * 0.1
	_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE * pulse
	_target_indicator.rotation = sin(_target_pulse * 0.65) * 0.12


# 점프 추격 무적 구간 — 슬라임을 밝은 시안 톤·투명도로 맥동시켜 공격 무시를 표시합니다.
func _update_chase_skill_invuln_visual(delta: float) -> void:
	if not is_node_ready():
		return
	var slime := %Slime as CanvasItem
	if slime == null:
		return
	if _is_chase_skill_attack_immune():
		if not _chase_skill_invuln_visual_active:
			HitFlash.cancel(slime, slime_tint)
		_chase_skill_invuln_visual_active = true
		_chase_skill_invuln_pulse += delta * 10.0
		var wave := sin(_chase_skill_invuln_pulse) * 0.5 + 0.5
		var alpha := lerpf(0.38, 0.92, wave)
		var base := slime_tint
		slime.modulate = Color(
			lerpf(base.r, minf(base.r * 1.3 + 0.2, 1.0), wave),
			lerpf(base.g, minf(base.g * 1.3 + 0.25, 1.0), wave),
			lerpf(base.b, minf(base.b * 1.35 + 0.35, 1.0), wave),
			base.a * alpha
		)
		return
	if _chase_skill_invuln_visual_active:
		_chase_skill_invuln_visual_active = false
		_chase_skill_invuln_pulse = 0.0
		HitFlash.cancel(slime, slime_tint)
		slime.modulate = slime_tint


func _physics_process(delta: float) -> void:
	if ranged_attack_enabled and combat_enabled and _ranged_cooldown_remaining > 0.0:
		_ranged_cooldown_remaining = maxf(_ranged_cooldown_remaining - delta, 0.0)
	if charge_attack_enabled and _charge_cooldown_remaining > 0.0:
		_charge_cooldown_remaining = maxf(_charge_cooldown_remaining - delta, 0.0)
	if jump_chase_enabled and _chase_skill_cooldown_remaining > 0.0:
		_chase_skill_cooldown_remaining = maxf(_chase_skill_cooldown_remaining - delta, 0.0)
	_process_self_destruct()
	if _is_dying:
		return

	if _charge_windup_remaining > 0.0:
		_process_charge_windup(delta)
		_status_effects.tick(delta, self)
		_refresh_status_effect_icons()
		_process_nettles(delta)
		move_and_slide()
		_elite_tick(delta)
		_finalize_chase_skill_range_rings()
		return

	if _charge_active:
		_process_charge_attack(delta)
		_status_effects.tick(delta, self)
		_refresh_status_effect_icons()
		_process_nettles(delta)
		move_and_slide()
		_elite_tick(delta)
		_finalize_chase_skill_range_rings()
		return

	if movement_enabled:
		var offset: Vector2 = (
			GroundShadowFootprint.get_combat_target_center(player as Node2D)
			- get_footprint_global_center()
		)

		if _process_chase_skill(delta, offset):
			_status_effects.tick(delta, self)
			_refresh_status_effect_icons()
			_process_nettles(delta)
			move_and_slide()
			_elite_tick(delta)
			_finalize_chase_skill_range_rings()
			return

		var can_start_charge := (
			charge_attack_enabled
			and combat_enabled
			and _charge_cooldown_remaining <= 0.0
			and _charge_windup_remaining <= 0.0
			and not _charge_active
			and offset.length_squared() <= charge_trigger_distance * charge_trigger_distance
		)

		if can_start_charge:
			_begin_charge_attack(offset)
			_status_effects.tick(delta, self)
			_refresh_status_effect_icons()
			_process_nettles(delta)
			move_and_slide()
			_elite_tick(delta)
			_finalize_chase_skill_range_rings()
			return

		var chase_context := _build_chase_context(offset)
		velocity = _chase_strategy.compute_desired_velocity(chase_context)
		var attack_range := _get_attack_range_distance()
		var in_attack_range := (
			offset.length_squared() <= attack_range * attack_range
		)
		if in_attack_range:
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
	_refresh_status_effect_icons()
	_process_nettles(delta)
	move_and_slide()
	_elite_tick(delta)
	_finalize_chase_skill_range_rings()


func _finalize_chase_skill_range_rings() -> void:
	if jump_chase_enabled:
		_sync_chase_skill_range_rings()


## 돌진 시작 — 경로 예고 후 짧게 가속 이동, 도착 시 범위 피해.
func _begin_charge_attack(offset: Vector2) -> void:
	if _charge_active or _charge_windup_remaining > 0.0 or offset.length_squared() <= 0.01:
		return
	_cancel_contact_telegraph()
	_cancel_ranged_telegraph()
	_charge_attack_mark_active = true
	_spawn_attack_mark()
	_charge_direction = offset.normalized()
	_spawn_charge_lane_preview(_charge_direction)
	velocity = Vector2.ZERO
	_charge_windup_remaining = maxf(charge_lane_display_duration, 0.05)


## 돌진 경로 예고 대기 — 표시 시간이 끝나면 실제 돌진을 시작합니다.
func _process_charge_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_windup_remaining -= delta
	if _charge_windup_remaining > 0.0:
		return
	_charge_windup_remaining = 0.0
	_start_charge_movement()


func _start_charge_movement() -> void:
	_charge_active = true
	_charge_time_remaining = maxf(charge_duration, 0.01)


func _get_charge_travel_distance() -> float:
	return _get_effective_speed() * maxf(charge_speed_mult, 1.0) * maxf(charge_duration, 0.01)


# 돌진 직선 구간을 1초간 월드에 고정 표시합니다(몹 이동과 무관).
func _spawn_charge_lane_preview(direction: Vector2) -> void:
	if not charge_attack_enabled:
		return
	var travel_dir := direction.normalized()
	if travel_dir.length_squared() <= 0.01:
		return

	var half_extents := GroundShadowFootprint.footprint_half_extents_from_visual(%Slime)
	var half_width := maxf(maxf(half_extents.x, half_extents.y), 20.0)
	var length := _get_charge_travel_distance()
	var start := get_footprint_global_center()

	var spawn_parent: Node = get_parent()
	if spawn_parent == null:
		return

	var lane: Node2D
	var game := get_node_or_null("/root/Game")
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	if pool and pool.has_method(&"acquire"):
		lane = pool.acquire(MOB_CHARGE_LANE_SCENE, spawn_parent) as Node2D
	else:
		lane = MOB_CHARGE_LANE_SCENE.instantiate() as Node2D
		spawn_parent.add_child(lane)

	if lane == null or not lane.has_method(&"setup_world"):
		return
	lane.setup_world(
		start,
		travel_dir,
		length,
		half_width,
		slime_tint,
		maxf(charge_lane_display_duration, 0.05)
	)


## 돌진 진행 — 종료 시 플레이어 반경 피해를 1회 적용합니다.
func _process_charge_attack(delta: float) -> void:
	var effective_speed := _get_effective_speed() * maxf(charge_speed_mult, 1.0)
	velocity = _charge_direction * effective_speed
	_charge_time_remaining -= delta
	if _charge_time_remaining > 0.0:
		return
	_end_charge_attack()


func _end_charge_attack() -> void:
	_charge_active = false
	_charge_time_remaining = 0.0
	_charge_cooldown_remaining = maxf(charge_cooldown, 0.01)
	_charge_attack_mark_active = false
	_try_release_attack_mark()
	velocity = Vector2.ZERO
	if charge_end_burst_damage > 0 and charge_end_burst_radius > 0.0:
		var burst_origin := get_footprint_global_center()
		if _try_apply_charge_end_burst_to_player(burst_origin):
			_elite_on_hit_player(charge_end_burst_damage)


# 돌진 종료 burst — 반경 내 플레이어 피격 성공 시 true(affix debuff snapshot용).
func _try_apply_charge_end_burst_to_player(origin: Vector2) -> bool:
	if not is_instance_valid(player):
		return false
	var player_center := GroundShadowFootprint.get_combat_target_center(player as Node2D)
	if origin.distance_to(player_center) > charge_end_burst_radius:
		return false
	if not player.has_method(&"apply_mob_projectile_damage"):
		return false
	var skip_reason: String = DamageResolver.apply_mob_projectile_to_player(
		player,
		charge_end_burst_damage
	)
	return skip_reason.is_empty()


# jump_chase_enabled일 때 추격 기술 인스턴스를 만들고 export 수치를 동기화합니다.
func _ensure_chase_skill() -> void:
	if _chase_skill == null:
		_chase_skill = MobChaseSkillJump.new()
	_sync_chase_skill_from_exports()


func _sync_chase_skill_from_exports() -> void:
	if _chase_skill is MobChaseSkillJump:
		var jump_skill := _chase_skill as MobChaseSkillJump
		jump_skill.windup_delay = jump_chase_windup_delay
		jump_skill.travel_distance = jump_chase_travel_distance
		jump_skill.duration = jump_chase_duration
		jump_skill.arc_height = jump_chase_arc_height
		jump_skill.cooldown = jump_chase_cooldown
		jump_skill.landing_burst_radius = jump_chase_landing_burst_radius
		jump_skill.landing_burst_damage = jump_chase_landing_burst_damage


# 1차: 착지 burst만 하드코딩 — 2차 후보는 Resource 배열(completion_effects).
func _build_jump_chase_completion_effects() -> Array[MobChaseSkillEffect]:
	return [MobChaseSkillEffectLandingBurst.new()]


func _is_chase_skill_active() -> bool:
	return _chase_skill != null and _chase_skill.is_active()


# 점프 추격 windup·이동 중 직접 공격(발사체·무기) 피해를 무시합니다. DoT tick은 별도 경로.
func _is_chase_skill_attack_immune() -> bool:
	return jump_chase_enabled and _is_chase_skill_active()


func _can_start_chase_skill(target_offset: Vector2) -> bool:
	if (
		not jump_chase_enabled
		or not combat_enabled
		or not movement_enabled
		or _chase_skill == null
		or _chase_skill.is_active()
		or _chase_skill_cooldown_remaining > 0.0
	):
		return false
	if target_offset.length_squared() <= 0.01:
		return false
	if (
		target_offset.length_squared()
		> jump_chase_trigger_distance * jump_chase_trigger_distance
	):
		return false
	if target_offset.length() <= _get_chase_stop_distance():
		return false
	if (
		_ranged_windup_active
		or _contact_windup_active
		or _charge_active
		or _charge_windup_remaining > 0.0
	):
		return false
	return true


## 추격 기술 진행·시작 — 돌진 다음, 일반 추격 전에 처리합니다(separation·clamp 스킵).
func _process_chase_skill(delta: float, target_offset: Vector2) -> bool:
	if not jump_chase_enabled:
		return false
	_ensure_chase_skill()
	if _chase_skill == null:
		return false
	if _chase_skill.is_active():
		var context: MobChaseSkillContext = _chase_skill.tick(self, delta)
		if context != null:
			_on_chase_skill_completed(context)
		return true
	if _can_start_chase_skill(target_offset):
		_cancel_contact_telegraph()
		_cancel_ranged_telegraph()
		_chase_skill.begin(self, target_offset)
		return true
	return false


## 기술 완료 — burst 등 completion effect만 적용하고 쿨다운을 시작합니다.
func _on_chase_skill_completed(context: MobChaseSkillContext) -> void:
	if context == null:
		return
	for effect in _chase_skill_completion_effects:
		effect.apply(context)
	_chase_skill_cooldown_remaining = maxf(jump_chase_cooldown, 0.01)
	velocity = Vector2.ZERO


## 자폭 조건 — 체력 임계치에 도달하면 일반 사망 경로를 요청합니다.
func _process_self_destruct() -> void:
	if (
		not self_destruct_enabled
		or _self_destruct_armed
		or _is_dying
		or max_health <= 0
	):
		return
	if health > int(roundi(float(max_health) * clampf(self_destruct_health_ratio, 0.01, 1.0))):
		return
	_self_destruct_armed = true
	_request_die()


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


# ChaseStrategy에 넘길 physics tick 컨텍스트 — 필드 재사용으로 GC 할당을 줄입니다.
func _build_chase_context(target_offset: Vector2) -> MobChaseContext:
	_chase_context.target_offset = target_offset
	_chase_context.stop_distance = _get_chase_stop_distance()
	_chase_context.effective_speed = _get_effective_speed()
	_chase_context.orbit_clockwise = _orbit_clockwise
	_chase_context.orbit_radius_buffer = orbit_radius_buffer
	_chase_context.orbit_approach_blend = orbit_approach_blend
	return _chase_context


# chase_mode 변경 후 런타임에 추격 전략 객체를 다시 맞춥니다.
func refresh_chase_strategy() -> void:
	_resolve_chase_strategy()


# 변종 export에 맞는 추격 전략을 고르고, 포위 방향 등 스폰별 상태를 초기화합니다.
func _resolve_chase_strategy() -> void:
	match chase_mode:
		ChaseMode.ORBIT:
			if not (_chase_strategy is MobChaseOrbit):
				_chase_strategy = MobChaseOrbit.new()
			_orbit_clockwise = randi() % 2 == 0
		_:
			if not (_chase_strategy is MobChaseStraight):
				_chase_strategy = MobChaseStraight.new()
	_chase_strategy.reset()


# 접촉 공격 판정에 쓰는 중심 간 거리(플레이어 global_position 기준).
func get_contact_attack_distance() -> float:
	if not is_node_ready():
		return attack_distance
	return _get_attack_range_distance()


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


# 공격 범위 안에서 예고 후 contact_attack_interval마다 피해를 적용합니다.
func tick_contact_attack(delta: float) -> int:
	if not is_contact_damage_active() or contact_attack_damage <= 0 or not combat_enabled:
		return 0
	if _contact_windup_active:
		return 0
	_contact_attack_cooldown_remaining -= delta
	if _contact_attack_cooldown_remaining > 0.0:
		return 0
	_begin_contact_telegraph()
	return 0


# 발밑 그림자·플레이어 HurtBox가 겹치지 않는 중심 간 최소 거리.
func _get_shape_clear_distance() -> float:
	var mob_half := GroundShadowFootprint.footprint_half_extents_from_visual(%Slime)
	var player_half := Vector2.ZERO
	if player.has_method(&"get_contact_hurtbox_half_extents"):
		player_half = player.call(&"get_contact_hurtbox_half_extents") as Vector2
	return GroundShadowFootprint.min_center_distance_no_overlap(
		mob_half,
		player_half,
		CONTACT_STANDOFF_PADDING
	)


# chase_distance 미설정(0) 시 attack보다 CHASE_DEFAULT_INSET만큼 가깝게 추격합니다.
func _get_effective_chase_distance() -> float:
	if chase_distance > 0.0:
		return chase_distance
	return maxf(attack_distance - CHASE_DEFAULT_INSET, 0.0)


# 공격(접촉·원거리 windup) 판정 거리.
func _get_attack_range_distance() -> float:
	return maxf(attack_distance, _get_shape_clear_distance())


# 추격 정지 거리 — attack_range를 넘지 않아 멀리서 공격 대기하지 않습니다.
func _get_chase_stop_distance() -> float:
	var attack_range := _get_attack_range_distance()
	var desired := maxf(_get_effective_chase_distance(), _get_shape_clear_distance())
	return minf(desired, attack_range)


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
	var stop_distance := _get_chase_stop_distance()
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
	_cancel_contact_telegraph()

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
	_ranged_windup_active = false
	_try_release_attack_mark()
	var from_center := get_footprint_global_center()
	var to_center := GroundShadowFootprint.get_combat_target_center(player as Node2D)
	var aim := to_center - from_center
	if aim.length_squared() > 0.01:
		_fire_ranged_projectile(aim.normalized())
	elif _pending_ranged_direction.length_squared() > 0.01:
		_fire_ranged_projectile(_pending_ranged_direction)


func _cancel_ranged_telegraph() -> void:
	_ranged_windup_active = false
	_try_release_attack_mark()


func _begin_contact_telegraph() -> void:
	if (
		_contact_windup_active
		or _charge_active
		or _charge_windup_remaining > 0.0
		or _is_chase_skill_active()
	):
		return
	_cancel_ranged_telegraph()
	_contact_windup_active = true
	_spawn_attack_mark()

	var tree := get_tree()
	if not tree:
		_complete_contact_telegraph()
		return

	var timer := tree.create_timer(maxf(ranged_telegraph_delay, 0.01))
	timer.timeout.connect(_on_contact_telegraph_timeout, CONNECT_ONE_SHOT)


func _on_contact_telegraph_timeout() -> void:
	if not _contact_windup_active or _is_dying or not is_inside_tree():
		_cancel_contact_telegraph()
		return
	_complete_contact_telegraph()


func _complete_contact_telegraph() -> void:
	_contact_windup_active = false
	_try_release_attack_mark()
	var interval := maxf(contact_attack_interval, 0.01)
	_contact_attack_cooldown_remaining = interval
	if not is_contact_damage_active() or _is_dying:
		return
	var player_center := GroundShadowFootprint.get_combat_target_center(player as Node2D)
	if not is_player_in_contact_attack_range(player_center):
		return
	if player.has_method(&"apply_mob_projectile_damage"):
		var skip_reason: String = player.call(&"apply_mob_projectile_damage", contact_attack_damage) as String
		if skip_reason.is_empty():
			_elite_on_hit_player(contact_attack_damage)


func _cancel_contact_telegraph() -> void:
	_contact_windup_active = false
	_try_release_attack_mark()


func _cancel_all_attack_telegraphs() -> void:
	_ranged_windup_active = false
	_contact_windup_active = false
	_charge_active = false
	_charge_windup_remaining = 0.0
	_charge_time_remaining = 0.0
	_charge_attack_mark_active = false
	if _chase_skill != null:
		_chase_skill.reset()
	_release_attack_mark()


func _try_release_attack_mark() -> void:
	if _ranged_windup_active or _contact_windup_active or _charge_attack_mark_active:
		return
	_release_attack_mark()


func _spawn_attack_mark() -> void:
	if is_instance_valid(_active_attack_mark):
		if _active_attack_mark.has_method(&"setup"):
			_active_attack_mark.setup(ranged_attack_mark_offset, slime_tint)
		return

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
			slime_tint,
			self
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
	var apply_result: Dictionary = _status_effects.apply_status_with_result(status_id, weapon)
	var is_new := false
	if apply_result.has("is_new"):
		is_new = bool(apply_result["is_new"])
	var active: ActiveStatusEffect = null
	if apply_result.has("active"):
		active = apply_result["active"] as ActiveStatusEffect
	if is_new and active != null and active.data != null:
		FloatingStatusEffectText.spawn_status_applied(global_position, active.data)
	_refresh_status_effect_icons()


# 활성 상태이상 틱 프로필을 최신 카탈로그 값으로 다시 계산합니다.
func refresh_status_effect_profiles(status_id: StringName = &"", reset_duration: bool = false) -> void:
	_status_effects.refresh_active_status_profiles(status_id, reset_duration)


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
	if _is_dying or amount <= 0 or _is_chase_skill_attack_immune():
		return

	_play_hit_flash()
	%Slime.play_hurt()
	health -= amount
	_reveal_health_bar()
	FloatingDamageText.spawn_enemy_damage(global_position, amount)

	if health <= 0:
		_request_die()


func apply_weapon_damage(amount: int, weapon: WeaponData) -> void:
	if _is_dying or amount <= 0 or not weapon or _is_chase_skill_attack_immune():
		return

	var final_amount := _apply_damage_taken_mult(amount, weapon.damage_element)
	if final_amount <= 0:
		return

	if elite_shield_hp > 0:
		var absorbed := mini(elite_shield_hp, final_amount)
		elite_shield_hp -= absorbed
		final_amount -= absorbed
		if _elite_runtime != null:
			_elite_runtime.on_took_damage(absorbed + final_amount, self)
		if final_amount <= 0:
			_play_hit_flash()
			%Slime.play_hurt()
			_reveal_health_bar()
			_notify_relic_weapon_hit(weapon, amount)
			return
	elif _elite_runtime != null:
		_elite_runtime.on_took_damage(final_amount, self)

	_register_weapon_damage(weapon, final_amount)
	_play_hit_flash()
	%Slime.play_hurt()
	health -= final_amount
	_reveal_health_bar()
	FloatingDamageText.spawn_weapon_damage(global_position, final_amount, weapon.get_element_color())

	if weapon.applies_nettles:
		apply_nettles(weapon.nettles_duration)
	_apply_weapon_status_effects(weapon)
	if is_instance_valid(player) and player.has_method(&"apply_loadout_on_hit"):
		player.call(&"apply_loadout_on_hit", self, weapon)
	_notify_relic_weapon_hit(weapon, amount)

	if health <= 0:
		_request_die()


# 중립 AoE 피해 — 무기 귀속 없이 체력만 감소(glacial 사망 폭탄 연쇄 등).
func take_neutral_burst_damage(amount: int) -> void:
	if _is_dying or amount <= 0 or _is_chase_skill_attack_immune():
		return
	_play_hit_flash()
	%Slime.play_hurt()
	health -= amount
	_reveal_health_bar()
	FloatingDamageText.spawn_enemy_damage(global_position, amount)
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
	_cancel_all_attack_telegraphs()
	_is_dying = true
	set_targeted(false)
	_hide_health_bar()
	_reset_status_effect_icons()
	set_physics_process(false)
	call_deferred("_die")


# 상태이상 목록을 체력바 상단 아이콘으로 동기화합니다.
func _refresh_status_effect_icons() -> void:
	if not is_node_ready():
		return
	if _status_effect_icons == null:
		return
	var active_statuses: Array[ActiveStatusEffect] = _status_effects.get_active_statuses()
	var next_signature := _build_status_icon_signature(active_statuses)
	if next_signature == _status_icon_signature:
		return
	_status_icon_signature = next_signature
	_clear_status_effect_icon_nodes()
	if active_statuses.is_empty():
		_status_effect_icons.visible = false
		return
	_status_effect_icons.visible = true
	for active in active_statuses:
		_status_effect_icons.add_child(_create_status_effect_icon(active))


func _reset_status_effect_icons() -> void:
	_status_icon_signature = ""
	if not is_node_ready():
		return
	if _status_effect_icons == null:
		return
	_clear_status_effect_icon_nodes()
	_status_effect_icons.visible = false


func _clear_status_effect_icon_nodes() -> void:
	if _status_effect_icons == null:
		return
	for child in _status_effect_icons.get_children():
		child.queue_free()


func _build_status_icon_signature(active_statuses: Array[ActiveStatusEffect]) -> String:
	if active_statuses.is_empty():
		return ""
	var parts: PackedStringArray = []
	for active in active_statuses:
		if active == null:
			continue
		parts.append("%s:%d" % [String(active.get_key()), active.stacks])
	return "|".join(parts)


func _create_status_effect_icon(active: ActiveStatusEffect) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(18.0, 18.0)
	var style := StyleBoxFlat.new()
	var icon_color := active.data.effect_color if active != null and active.data != null else Color.DIM_GRAY
	style.bg_color = icon_color.darkened(0.22)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 10)
	label.text = _get_status_icon_text(active)
	label.modulate = Color.WHITE
	panel.add_child(label)

	if active != null and active.data != null:
		var stack_suffix := ""
		if active.stacks > 1:
			stack_suffix = " x%d" % active.stacks
		panel.tooltip_text = "%s%s" % [active.data.get_display_name_localized(), stack_suffix]
	return panel


func _get_status_icon_text(active: ActiveStatusEffect) -> String:
	if active == null:
		return STATUS_ICON_DEFAULT_TEXT
	var key := active.get_key()
	var text: String = String(STATUS_ICON_TEXT.get(key, STATUS_ICON_DEFAULT_TEXT))
	if active.stacks > 1:
		return "%s%d" % [text, mini(active.stacks, 9)]
	return text


# 일반 사망 시 플레이어 범위 피해(특수몹 등 export 활성 변종)
func _trigger_death_burst() -> void:
	if not death_burst_enabled or death_burst_damage <= 0 or death_burst_radius <= 0.0:
		return
	var burst_position := get_footprint_global_center()
	var factory := AttackServices.find_factory(null, false)
	if factory:
		factory.schedule_mob_death_burst(
			burst_position,
			death_burst_radius,
			death_burst_damage,
			death_burst_delay
		)
	elif death_burst_delay <= 0.0:
		DamageResolver.apply_burst_damage_to_player_in_radius(
			burst_position,
			death_burst_radius,
			death_burst_damage
		)
	else:
		var tree := get_tree()
		if tree:
			tree.create_timer(death_burst_delay).timeout.connect(
				func() -> void:
					DamageResolver.apply_burst_damage_to_player_in_radius(
						burst_position,
						death_burst_radius,
						death_burst_damage
					),
				CONNECT_ONE_SHOT
			)


func _die() -> void:
	if not is_inside_tree():
		return

	died.emit()

	if _stage_clear_death:
		PoolUtil.release_node(self)
		return

	if _elite_runtime != null:
		_elite_runtime.on_death(self)

	_try_drop_elite_relic()

	_trigger_death_burst()

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
		return game.get_kill_rewards_for_mob(mob_kind, get_elite_affix_id())
	return KillRewards.compute(mob_kind, BalancePhase.new(), has_elite_affix())


# affix 몹 처치 시 유물 드랍을 시도합니다.
func _try_drop_elite_relic() -> void:
	if not has_elite_affix():
		return
	var affix_data := EliteAffixCatalog.get_affix(_elite_affix_id)
	if affix_data == null or not affix_data.drops_relic:
		return
	var relic_id := String(affix_data.relic_item_id).strip_edges()
	if relic_id.is_empty():
		return
	var drop_rate := _query_relic_drop_rate()
	if drop_rate <= 0.0 or randf() >= drop_rate:
		return
	var drop := EQUIPMENT_DROP_SCENE.instantiate() as EquipmentDrop
	if drop == null:
		return
	get_parent().add_child(drop)
	drop.global_position = global_position
	drop.setup(relic_id)


func _query_relic_drop_rate() -> float:
	const DEFAULT_RELIC_DROP_RATE := 0.00025
	var game := get_node_or_null("/root/Game")
	if game and game.has_method(&"get_relic_drop_rate"):
		return float(game.call(&"get_relic_drop_rate"))
	return DEFAULT_RELIC_DROP_RATE
