extends Area2D

@export var weapon: WeaponData = preload("res://weapons/data/revolver.tres")

const KING_BIBLE_ORB_COUNT := 2
const AIM_LINE_COLOR := Color(1.0, 0.85, 0.35, 0.55)
const AIM_LINE_WIDTH := 4.0

@onready var _shoot_timer: Timer = $Timer
@onready var _weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var _shooting_point: Marker2D = $WeaponPivot/WeaponSprite/ShootingPoint
@onready var _aim_direction_line: Line2D = %AimDirectionLine
var _current_target: Node2D = null
var _burst_shots_remaining := 0
var _magic_companions: Array[Node] = []


func _ready() -> void:
	if not _shoot_timer.timeout.is_connected(_on_timer_timeout):
		_shoot_timer.timeout.connect(_on_timer_timeout)
	_shoot_timer.stop()
	_apply_weapon_data()
	_setup_aim_direction_line()


func equip_weapon(new_weapon: WeaponData) -> void:
	_clear_magic_companion()
	weapon = new_weapon
	_burst_shots_remaining = 0
	_apply_weapon_data()
	if weapon.is_orbit_attack():
		_spawn_orbit_companion()
	call_deferred("_reset_fire_state")
	call_deferred("refresh_auto_attack")


func arrange_slot(slot_index: int, total_slots: int) -> void:
	if total_slots <= 1:
		position = Vector2(0, -40)
		return
	var angle := -PI * 0.5 + TAU * float(slot_index) / float(total_slots)
	position = Vector2.from_angle(angle) * 40.0


func _apply_weapon_data() -> void:
	if not weapon:
		return
	if not weapon.has_burst():
		_shoot_timer.wait_time = 1.0 / _get_effective_attacks_per_second()
	if weapon.texture:
		_weapon_sprite.texture = weapon.texture
		_weapon_sprite.modulate = weapon.sprite_modulate
	_match_two_handed_scale()


func _reset_fire_state() -> void:
	if not weapon or not is_inside_tree():
		return
	_shoot_timer.stop()
	_burst_shots_remaining = 0


func refresh_targeting_mode() -> void:
	_update_target_display()
	_update_aim_direction_line()


# 자동 타겟 OFF일 때 발사 지점에서 마우스 조준 방향(사거리)을 표시합니다.
func _setup_aim_direction_line() -> void:
	if not _aim_direction_line:
		return
	_aim_direction_line.width = AIM_LINE_WIDTH
	_aim_direction_line.default_color = AIM_LINE_COLOR
	_aim_direction_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_aim_direction_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_aim_direction_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_aim_direction_line.visible = false


func _update_aim_direction_line() -> void:
	if not _aim_direction_line:
		return
	if not weapon or weapon.is_orbit_attack() or _is_auto_target_enabled():
		_aim_direction_line.visible = false
		return
	var range_length := _get_attack_range()
	if range_length <= 0.0 or not is_finite(range_length):
		_aim_direction_line.visible = false
		return
	_aim_direction_line.points = PackedVector2Array([Vector2.ZERO, Vector2(range_length, 0.0)])
	_aim_direction_line.visible = true


# 플레이어 자동 공격 토글(G)에 맞춰 타이머를 켜거나 끕니다.
func refresh_auto_attack() -> void:
	if not weapon or not is_inside_tree() or weapon.is_orbit_attack():
		return
	if _is_auto_attack_enabled():
		if _shoot_timer.time_left <= 0.0 and not _is_manual_fire_pressed():
			if not _has_enemy_in_attack_range():
				return
			if weapon.has_burst():
				_begin_burst()
			else:
				shoot()
				_shoot_timer.wait_time = 1.0 / _get_effective_attacks_per_second()
				_shoot_timer.start()
	elif not _is_manual_fire_pressed():
		_shoot_timer.stop()
		_burst_shots_remaining = 0


func _is_auto_attack_enabled() -> bool:
	var player := _get_player()
	if player and player.has_method("is_auto_attack_enabled"):
		return player.is_auto_attack_enabled()
	return true


func _is_auto_target_enabled() -> bool:
	var player := _get_player()
	if player and player.has_method("is_auto_target_enabled"):
		return player.is_auto_target_enabled()
	return true


func _begin_burst() -> void:
	_burst_shots_remaining = weapon.burst_count - 1
	shoot()
	_schedule_burst_timer()


func _schedule_burst_timer() -> void:
	if _burst_shots_remaining > 0:
		_shoot_timer.wait_time = weapon.burst_interval
	else:
		_shoot_timer.wait_time = weapon.get_burst_cooldown()
	_shoot_timer.start()


func _match_two_handed_scale() -> void:
	if weapon.hand == "Two-Handed":
		_weapon_sprite.scale = Vector2(1.15, 1.15)
	else:
		_weapon_sprite.scale = Vector2.ONE


func _get_attack_range() -> float:
	return get_display_attack_range()


# UI·사거리 링에 쓸 공격 사거리(투척·궤도 마법 포함).
func get_display_attack_range() -> float:
	if not weapon:
		return 0.0
	var range_mult := _get_power_radius_mult()
	if weapon.is_orbit_attack():
		return weapon.get_orbit_radius() * range_mult
	return weapon._get_attack_range() * range_mult


func _get_nearest_enemy(enemies: Array, from_position: Vector2, max_range: float = INF) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := INF
	var max_range_sq := max_range * max_range
	for body in enemies:
		if not is_instance_valid(body) or body is not Node2D:
			continue
		var enemy := body as Node2D
		var distance_sq := from_position.distance_squared_to(
			GroundShadowFootprint.get_combat_target_center(enemy)
		)
		if distance_sq > max_range_sq:
			continue
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = enemy
	return nearest


func _get_current_target() -> Node2D:
	return _get_nearest_enemy(
		get_overlapping_bodies(),
		_shooting_point.global_position,
		_get_attack_range()
	)


# 자동 공격은 사거리 안에 적이 있을 때만 발사합니다.
func _has_enemy_in_attack_range() -> bool:
	return is_instance_valid(_get_current_target())


func _set_targeted(enemy, active: bool) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("set_targeted"):
		enemy.set_targeted(active)


func _update_target_display() -> void:
	if not is_instance_valid(_current_target):
		_current_target = null
	if not _is_auto_target_enabled():
		if is_instance_valid(_current_target):
			_set_targeted(_current_target, false)
		_current_target = null
		return

	var new_target := _get_current_target()
	if new_target == _current_target:
		return

	if is_instance_valid(_current_target):
		_set_targeted(_current_target, false)
	_current_target = new_target
	if is_instance_valid(_current_target):
		_set_targeted(_current_target, true)


func _process(_delta: float) -> void:
	_update_target_display()
	if is_instance_valid(_current_target):
		look_at(_get_target_aim_position(_current_target))
	else:
		look_at(get_global_mouse_position())
	_update_aim_direction_line()
	_handle_auto_attack()
	_handle_manual_fire_input()


# 자동 공격 ON이면 타이머로 연속 발사합니다(마우스 불필요).
func _handle_auto_attack() -> void:
	if not weapon or weapon.is_orbit_attack():
		return
	if not _is_auto_attack_enabled() or _is_manual_fire_pressed():
		return
	if not _has_enemy_in_attack_range():
		return
	if _shoot_timer.time_left > 0.0:
		return
	if weapon.has_burst():
		_begin_burst()
	else:
		shoot()
		_shoot_timer.wait_time = 1.0 / _get_effective_attacks_per_second()
		_shoot_timer.start()


# 마우스 좌클릭을 누르고 있는 동안 공격 속도에 맞춰 발사합니다.
func _handle_manual_fire_input() -> void:
	if not weapon or weapon.is_orbit_attack():
		return
	if not _is_manual_fire_pressed():
		# 자동 공격 타이머는 유지 — OFF일 때만 정지
		if not _is_auto_attack_enabled() and not weapon.has_burst():
			_shoot_timer.stop()
		return
	if _shoot_timer.time_left > 0.0:
		return
	if weapon.has_burst():
		_begin_burst()
	else:
		shoot()
		_shoot_timer.wait_time = 1.0 / _get_effective_attacks_per_second()
		_shoot_timer.start()


func _is_manual_fire_pressed() -> bool:
	return ActionManager.is_pressed(ActionManager.ACTION_ATTACK)


func shoot() -> void:
	if not weapon:
		return

	if weapon.is_melee():
		_shoot_melee_projectile()
	elif weapon.is_magic():
		_shoot_magic()
	elif weapon.is_throwing():
		_shoot_throwing()
	else:
		_shoot_bullet()


func _refresh_current_target() -> void:
	_update_target_display()


func _get_target_aim_position(target: Node2D) -> Vector2:
	return GroundShadowFootprint.get_combat_target_center(target)


func _get_shoot_direction() -> Vector2:
	if is_instance_valid(_current_target):
		return _shooting_point.global_position.direction_to(
			_get_target_aim_position(_current_target)
		)
	return Vector2.RIGHT.rotated(_shooting_point.global_rotation)


func _get_throw_aim_position() -> Vector2:
	var origin := _shooting_point.global_position
	var throw_range := weapon.throw_range * _get_power_radius_mult()
	if is_instance_valid(_current_target):
		var target_pos := _get_target_aim_position(_current_target)
		var to_target := origin.direction_to(target_pos)
		var distance := minf(origin.distance_to(target_pos), throw_range)
		return origin + to_target * distance
	return origin + _get_shoot_direction() * throw_range


func _get_spawn_transform() -> Transform2D:
	return _shooting_point.global_transform


func _get_player() -> Node2D:
	var node: Node = self
	while node:
		if node.has_method("add_weapon"):
			return node as Node2D
		node = node.get_parent()
	var found := LoadoutStatApply.find_combat_player()
	return found as Node2D if found != null else null


func refresh_loadout_combat_modifiers() -> void:
	if not weapon or not is_inside_tree():
		return
	if weapon.has_burst():
		return
	var aps := _get_effective_attacks_per_second()
	if aps > 0.0:
		_shoot_timer.wait_time = 1.0 / aps


func _get_effective_attacks_per_second() -> float:
	var player := _get_player()
	if player and player.has_method("get_effective_attacks_per_second"):
		return player.get_effective_attacks_per_second(weapon)
	if weapon:
		return weapon.attacks_per_second
	return 1.0


func _get_power_radius_mult() -> float:
	var player := _get_player()
	if player and player.has_method(&"get_power_radius_mult"):
		return float(player.call(&"get_power_radius_mult"))
	return 1.0


func _roll_combat_damage() -> int:
	var player := _get_player()
	if player and player.has_method("roll_weapon_damage"):
		return player.roll_weapon_damage(weapon)
	if weapon:
		return weapon.roll_damage()
	return 1


func _get_attack_factory() -> AttackFactory:
	var game := get_node_or_null("/root/Game")
	if game == null:
		AttackServices.warn_missing_factory()
		return null
	return AttackServices.find_factory(game)


func _build_attack_context(pre_rolled_damage: int = -1) -> AttackContext:
	var target: Node2D = _current_target if is_instance_valid(_current_target) else null
	return AttackContext.from_gun(
		weapon,
		_get_spawn_transform(),
		_get_shoot_direction(),
		_get_player(),
		target,
		pre_rolled_damage
	)


func _clear_magic_companion() -> void:
	for companion in _magic_companions:
		if is_instance_valid(companion):
			PoolUtil.release_node(companion)
	_magic_companions.clear()


func _spawn_orbit_companion() -> void:
	var player := _get_player()
	var factory := _get_attack_factory()
	if not player or not factory or not weapon:
		return

	var count := _get_orbit_companion_count()
	var base_angle := randf() * TAU
	for index in count:
		var angle := base_angle + TAU * float(index) / float(count)
		var orb := factory.spawn_orbit_orb(weapon, player, angle)
		if orb:
			_magic_companions.append(orb)


func _get_orbit_companion_count() -> int:
	if weapon and weapon.get_unique_key() == "king_bible":
		return KING_BIBLE_ORB_COUNT
	return 1


func _shoot_magic() -> void:
	if weapon.is_orbit_attack():
		return

	var factory := _get_attack_factory()
	if factory == null:
		return

	_refresh_current_target()
	factory.spawn_magic_bolt(_build_attack_context())


func _shoot_melee_projectile() -> void:
	var factory := _get_attack_factory()
	if factory == null:
		return

	_refresh_current_target()
	var projectile_owner := _get_player()
	var base_transform := _get_spawn_transform()
	var context := _build_attack_context()
	var spread_count := weapon.get_melee_spread_count()
	if spread_count <= 1:
		factory.spawn_melee_projectile(context, base_transform, projectile_owner)
		return
	if weapon.has_melee_parallel_spawn():
		_shoot_parallel_melee_projectiles(factory, context, projectile_owner, base_transform, spread_count)
		return

	var origin := base_transform.origin
	var base_angle := base_transform.get_rotation()
	var half_spread := deg_to_rad(weapon.melee_spread_angle_deg) * 0.5
	var last_index := spread_count - 1
	for index in spread_count:
		var t := float(index) / float(last_index)
		var angle := base_angle - half_spread + t * half_spread * 2.0
		var spread_transform := Transform2D(angle, origin)
		factory.spawn_melee_projectile(context, spread_transform, projectile_owner)


func _shoot_parallel_melee_projectiles(
	factory: AttackFactory,
	context: AttackContext,
	projectile_owner: Node2D,
	base_transform: Transform2D,
	spread_count: int
) -> void:
	var origin := base_transform.origin
	var angle := base_transform.get_rotation()
	var perpendicular := Vector2.RIGHT.rotated(angle).orthogonal()
	var center_index := float(spread_count - 1) * 0.5
	for index in spread_count:
		var lane_offset := (float(index) - center_index) * weapon.melee_parallel_offset * 2.0
		var parallel_transform := Transform2D(angle, origin + perpendicular * lane_offset)
		factory.spawn_melee_projectile(context, parallel_transform, projectile_owner)


func _shoot_bullet() -> void:
	var factory := _get_attack_factory()
	if factory == null:
		return
	factory.spawn_bullet(_build_attack_context(_roll_combat_damage()))


func _shoot_throwing() -> void:
	var player := _get_player()
	var factory := _get_attack_factory()
	if not player or factory == null:
		return

	_refresh_current_target()
	factory.spawn_throwing_from_gun(
		player,
		weapon,
		_shooting_point.global_position,
		_get_throw_aim_position(),
		_get_shoot_direction(),
		_roll_combat_damage()
	)


func _exit_tree() -> void:
	_clear_magic_companion()


func _on_timer_timeout() -> void:
	if not weapon:
		return

	if weapon.is_orbit_attack():
		return

	var auto_attack := _is_auto_attack_enabled()
	var manual := _is_manual_fire_pressed()
	if not auto_attack and not manual:
		_shoot_timer.stop()
		_burst_shots_remaining = 0
		return

	if auto_attack and not manual and not _has_enemy_in_attack_range():
		_shoot_timer.stop()
		_burst_shots_remaining = 0
		return

	if weapon.has_burst():
		if _burst_shots_remaining > 0:
			shoot()
			_burst_shots_remaining -= 1
			_schedule_burst_timer()
		else:
			_begin_burst()
	else:
		shoot()
		_shoot_timer.wait_time = 1.0 / _get_effective_attacks_per_second()
		_shoot_timer.start()
