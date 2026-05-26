extends Area2D

var damage := 0
var speed := 700.0
var max_range := 600.0

var _thrower: Node2D
var _weapon: WeaponData
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _returning := false


func pool_reset() -> void:
	_thrower = null
	_weapon = null
	_direction = Vector2.RIGHT
	_travelled = 0.0
	_returning = false
	damage = 0
	speed = 700.0
	max_range = 600.0


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)


func setup(thrower: Node2D, direction: Vector2, dmg: int, range_dist: float, move_speed: float) -> void:
	_thrower = thrower
	_direction = direction.normalized()
	damage = dmg
	max_range = range_dist
	speed = move_speed
	rotation = _direction.angle()


func setup_weapon(thrower: Node2D, direction: Vector2, weapon_data: WeaponData) -> void:
	_weapon = weapon_data
	setup(
		thrower,
		direction,
		0,
		weapon_data.get_projectile_range(),
		weapon_data.throw_speed
	)
	if has_node("Sprite2D"):
		$Sprite2D.modulate = weapon_data.get_element_color()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_thrower):
		PoolUtil.release_node(self)
		return

	var move_dir: Vector2
	if _returning:
		move_dir = global_position.direction_to(_thrower.global_position)
		if global_position.distance_to(_thrower.global_position) < 36.0:
			PoolUtil.release_node(self)
			return
	else:
		move_dir = _direction
		_travelled += speed * delta
		if _travelled >= max_range:
			_returning = true

	global_position += move_dir * speed * delta
	rotation += delta * 12.0


func _on_body_entered(body: Node2D) -> void:
	if body == _thrower:
		return
	if _is_environment_body(body):
		PoolUtil.release_node(self)
		return
	if not body.is_in_group("mobs"):
		return
	var hit_damage := _roll_weapon_damage()
	if _weapon and body.has_method("apply_weapon_damage"):
		body.apply_weapon_damage(hit_damage, _weapon)
	elif body.has_method("take_damage"):
		body.take_damage(hit_damage)


func _is_environment_body(body: Node) -> bool:
	return body is CollisionObject2D and PhysicsLayers.layer_matches(
		(body as CollisionObject2D).collision_layer,
		PhysicsLayers.ENVIRONMENT
	)


func _roll_weapon_damage() -> int:
	if _weapon == null:
		return maxi(damage, 1)
	if is_instance_valid(_thrower) and _thrower.has_method("roll_weapon_damage"):
		return _thrower.roll_weapon_damage(_weapon)
	return _weapon.roll_damage()
