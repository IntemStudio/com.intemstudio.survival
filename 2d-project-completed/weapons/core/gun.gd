extends Area2D

@export var weapon: WeaponData = preload("res://weapons/data/revolver.tres")

const BULLET_SCENE := preload("res://weapons/core/bullet_2d.tscn")
const MELEE_SWIPE_SCENE := preload("res://weapons/melee/melee_swipe.tscn")
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
	call_deferred("_start_shooting")


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


func _start_shooting() -> void:
	if not weapon or not is_inside_tree():
		return
	if weapon.is_orbit_magic():
		return
	_shoot_timer.stop()
	if weapon.has_burst():
		_begin_burst()
	else:
		shoot()
		_shoot_timer.start()


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
	if not weapon:
		return INF
	if weapon.is_melee():
		return weapon.get_melee_range()
	return weapon.get_projectile_range()


func _get_nearest_enemy(enemies: Array, from_position: Vector2, max_range: float = INF) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := INF
	var max_range_sq := max_range * max_range
	for body in enemies:
		if not is_instance_valid(body) or body is not Node2D:
			continue
		var enemy := body as Node2D
		var distance_sq := from_position.distance_squared_to(enemy.global_position)
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
		look_at(_current_target.global_position)


func shoot() -> void:
	if not weapon:
		return

	if weapon.is_melee():
		_melee_attack()
	elif weapon.is_magic():
		_shoot_magic()
	elif weapon.is_throwing():
		_shoot_throwing()
	else:
		_shoot_bullet()


func _refresh_current_target() -> void:
	_update_target_display()


func _get_shoot_direction() -> Vector2:
	if is_instance_valid(_current_target):
		return _shooting_point.global_position.direction_to(_current_target.global_position)
	return Vector2.RIGHT.rotated(_shooting_point.global_rotation)


func _get_throw_aim_position() -> Vector2:
	var origin := _shooting_point.global_position
	if is_instance_valid(_current_target):
		var to_target := origin.direction_to(_current_target.global_position)
		var distance := minf(origin.distance_to(_current_target.global_position), weapon.throw_range)
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


func _clear_magic_companion() -> void:
	if is_instance_valid(_magic_companion):
		_magic_companion.queue_free()
	_magic_companion = null


func _spawn_orbit_companion() -> void:
	var player := _get_player()
	var game := get_node_or_null("/root/Game")
	if not player or not game or not weapon:
		return

	var orb: Area2D = KING_BIBLE_ORB_SCENE.instantiate()
	game.add_child(orb)
	orb.setup(weapon, player)
	_magic_companion = orb


func _shoot_magic() -> void:
	if weapon.is_orbit_magic():
		return

	var game := get_node_or_null("/root/Game")
	if not game:
		return

	_refresh_current_target()
	var bolt: Area2D = MAGIC_BOLT_SCENE.instantiate()
	game.add_child(bolt)
	bolt.setup(weapon, _get_spawn_transform())


func _melee_attack() -> void:
	_refresh_current_target()
	var target := _get_current_target()
	if not is_instance_valid(target):
		return

	var game := get_node_or_null("/root/Game")
	if not game:
		return

	var direction := _shooting_point.global_position.direction_to(target.global_position)
	var swipe: Area2D = MELEE_SWIPE_SCENE.instantiate()
	game.add_child(swipe)
	swipe.global_position = _shooting_point.global_position
	swipe.setup(weapon, direction)


func _shoot_bullet() -> void:
	var game := get_node_or_null("/root/Game")
	if not game:
		return

	var new_bullet: Area2D = BULLET_SCENE.instantiate()
	game.add_child(new_bullet)
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
		projectile = weapon.projectile_scene.instantiate()
		game.add_child(projectile)
		projectile.global_position = _shooting_point.global_position
		projectile.setup_weapon(player, _get_throw_aim_position(), weapon)
	elif weapon.projectile_scene:
		projectile = weapon.projectile_scene.instantiate()
		game.add_child(projectile)
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
		projectile = THROWING_PROJECTILE_SCENE.instantiate()
		game.add_child(projectile)
		projectile.global_position = _shooting_point.global_position
		projectile.setup_weapon(player, _get_shoot_direction(), weapon)


func _exit_tree() -> void:
	_clear_magic_companion()


func _on_timer_timeout() -> void:
	if not weapon:
		return

	if weapon.is_orbit_magic():
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
