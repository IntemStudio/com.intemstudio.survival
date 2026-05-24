extends Area2D

@export var weapon: WeaponData = preload("res://weapons/data/revolver.tres")

const BULLET_SCENE := preload("res://weapons/core/bullet_2d.tscn")
const MELEE_PROJECTILE_SCENE := preload("res://weapons/melee/melee_projectile.tscn")
const MAGIC_BOLT_SCENE := preload("res://weapons/magic/magic_bolt.tscn")
const KING_BIBLE_ORB_SCENE := preload("res://weapons/magic/king_bible_orb.tscn")
const THROWING_PROJECTILE_SCENE := preload("res://weapons/throwing/throwing_projectile.tscn")

@onready var _shoot_timer: Timer = $Timer
@onready var _weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var _shooting_point: Marker2D = $WeaponPivot/WeaponSprite/ShootingPoint
var _current_target: Node2D = null
var _burst_shots_remaining := 0
var _magic_companion: Node = null


func _ready() -> void:
	if not _shoot_timer.timeout.is_connected(_on_timer_timeout):
		_shoot_timer.timeout.connect(_on_timer_timeout)
	_shoot_timer.stop()
	_apply_weapon_data()


func equip_weapon(new_weapon: WeaponData) -> void:
	_clear_magic_companion()
	weapon = new_weapon
	_burst_shots_remaining = 0
	_apply_weapon_data()
	if weapon.is_orbit_magic():
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
		_shoot_timer.wait_time = 1.0 / weapon.attacks_per_second
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


# 플레이어 자동 공격 토글(G)에 맞춰 타이머를 켜거나 끕니다.
func refresh_auto_attack() -> void:
	if not weapon or not is_inside_tree() or weapon.is_orbit_magic():
		return
	if _is_auto_attack_enabled():
		if _shoot_timer.time_left <= 0.0 and not _is_manual_fire_pressed():
			if weapon.has_burst():
				_begin_burst()
			else:
				shoot()
				_shoot_timer.wait_time = 1.0 / weapon.attacks_per_second
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
	if weapon.is_orbit_magic():
		return weapon.get_orbit_radius()
	return weapon._get_attack_range()


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
	_handle_auto_attack()
	_handle_manual_fire_input()


# 자동 공격 ON이면 타이머로 연속 발사합니다(마우스 불필요).
func _handle_auto_attack() -> void:
	if not weapon or weapon.is_orbit_magic():
		return
	if not _is_auto_attack_enabled() or _is_manual_fire_pressed():
		return
	if _shoot_timer.time_left > 0.0:
		return
	if weapon.has_burst():
		_begin_burst()
	else:
		shoot()
		_shoot_timer.wait_time = 1.0 / weapon.attacks_per_second
		_shoot_timer.start()


# 마우스 좌클릭을 누르고 있는 동안 공격 속도에 맞춰 발사합니다.
func _handle_manual_fire_input() -> void:
	if not weapon or weapon.is_orbit_magic():
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
		_shoot_timer.wait_time = 1.0 / weapon.attacks_per_second
		_shoot_timer.start()


func _is_manual_fire_pressed() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


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
	if is_instance_valid(_current_target):
		var target_pos := _get_target_aim_position(_current_target)
		var to_target := origin.direction_to(target_pos)
		var distance := minf(origin.distance_to(target_pos), weapon.throw_range)
		return origin + to_target * distance
	return origin + _get_shoot_direction() * weapon.throw_range


func _get_spawn_transform() -> Transform2D:
	return _shooting_point.global_transform


func _get_player() -> Node2D:
	var node: Node = self
	while node:
		if node.has_method("add_weapon"):
			return node as Node2D
		node = node.get_parent()
	return null


func _get_scene_pool(game: Node) -> ScenePool:
	return game.get_node_or_null("ObjectPools") as ScenePool


func _spawn_from_pool(game: Node, scene: PackedScene) -> Node:
	var pool := _get_scene_pool(game)
	if pool:
		return pool.acquire(scene, game)
	var node := scene.instantiate()
	game.add_child(node)
	return node


func _clear_magic_companion() -> void:
	if is_instance_valid(_magic_companion):
		PoolUtil.release_node(_magic_companion)
	_magic_companion = null


func _spawn_orbit_companion() -> void:
	var player := _get_player()
	var game := get_node_or_null("/root/Game")
	if not player or not game or not weapon:
		return

	var orb: Area2D = _spawn_from_pool(game, KING_BIBLE_ORB_SCENE) as Area2D
	orb.setup(weapon, player)
	_magic_companion = orb


func _shoot_magic() -> void:
	if weapon.is_orbit_magic():
		return

	var game := get_node_or_null("/root/Game")
	if not game:
		return

	_refresh_current_target()
	var bolt: Area2D = _spawn_from_pool(game, MAGIC_BOLT_SCENE) as Area2D
	bolt.setup(weapon, _get_spawn_transform())


func _shoot_melee_projectile() -> void:
	var game := get_node_or_null("/root/Game")
	if not game:
		return

	_refresh_current_target()
	var owner := _get_player()
	var base_transform := _get_spawn_transform()
	var spread_count := weapon.get_melee_spread_count()
	if spread_count <= 1:
		_spawn_melee_projectile(game, weapon, base_transform, owner)
		return

	var origin := base_transform.origin
	var base_angle := base_transform.get_rotation()
	var half_spread := deg_to_rad(weapon.melee_spread_angle_deg) * 0.5
	var last_index := spread_count - 1
	for index in spread_count:
		var t := float(index) / float(last_index)
		var angle := base_angle - half_spread + t * half_spread * 2.0
		var spread_transform := Transform2D(angle, origin)
		_spawn_melee_projectile(game, weapon, spread_transform, owner)


func _spawn_melee_projectile(
	game: Node,
	weapon_data: WeaponData,
	spawn_transform: Transform2D,
	owner: Node2D
) -> void:
	var projectile: Area2D = _spawn_from_pool(game, MELEE_PROJECTILE_SCENE) as Area2D
	projectile.setup(weapon_data, spawn_transform, owner)


func _shoot_bullet() -> void:
	var game := get_node_or_null("/root/Game")
	if not game:
		return

	var new_bullet: Area2D = _spawn_from_pool(game, BULLET_SCENE) as Area2D
	if new_bullet.has_method("setup"):
		new_bullet.setup(weapon, _get_spawn_transform())
	else:
		new_bullet.global_transform = _get_spawn_transform()
		new_bullet.set("damage", weapon.roll_damage())


func _shoot_throwing() -> void:
	var player := _get_player()
	var game := get_node_or_null("/root/Game")
	if not player or not game:
		return

	_refresh_current_target()

	var projectile: Node
	if weapon.uses_arc_throw and weapon.projectile_scene:
		projectile = _spawn_from_pool(game, weapon.projectile_scene)
		projectile.global_position = _shooting_point.global_position
		projectile.setup_weapon(player, _get_throw_aim_position(), weapon)
	elif weapon.projectile_scene:
		projectile = _spawn_from_pool(game, weapon.projectile_scene)
		projectile.global_position = _shooting_point.global_position
		if projectile.has_method("setup_weapon"):
			projectile.setup_weapon(player, _get_shoot_direction(), weapon)
		else:
			projectile.setup(
				player,
				_get_shoot_direction(),
				weapon.roll_damage(),
				weapon.get_projectile_range(),
				weapon.throw_speed
			)
	else:
		projectile = _spawn_from_pool(game, THROWING_PROJECTILE_SCENE)
		projectile.global_position = _shooting_point.global_position
		projectile.setup_weapon(player, _get_shoot_direction(), weapon)


func _exit_tree() -> void:
	_clear_magic_companion()


func _on_timer_timeout() -> void:
	if not weapon:
		return

	if weapon.is_orbit_magic():
		return

	var auto_attack := _is_auto_attack_enabled()
	var manual := _is_manual_fire_pressed()
	if not auto_attack and not manual:
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
		_shoot_timer.wait_time = 1.0 / weapon.attacks_per_second
		_shoot_timer.start()
