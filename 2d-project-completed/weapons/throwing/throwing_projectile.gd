extends Area2D

var _thrower: Node2D
var _weapon: WeaponData
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _returning := false
var _hit_counts: Dictionary = {}


func setup_weapon(thrower: Node2D, direction: Vector2, weapon_data: WeaponData) -> void:
	_thrower = thrower
	_weapon = weapon_data
	_direction = direction.normalized()
	rotation = _direction.angle()
	if $Sprite2D:
		$Sprite2D.modulate = weapon_data.get_element_color()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_thrower) or not _weapon:
		queue_free()
		return

	var speed := _weapon.throw_speed
	var max_range := _weapon.get_projectile_range()
	var move_dir: Vector2

	if _returning:
		move_dir = global_position.direction_to(_thrower.global_position)
		if global_position.distance_to(_thrower.global_position) < 36.0:
			queue_free()
			return
	else:
		move_dir = _direction
		_travelled += speed * delta
		if _travelled >= max_range:
			if _weapon.returns_to_owner:
				_returning = true
			else:
				queue_free()
				return

	global_position += move_dir * speed * delta
	rotation += delta * 10.0


func _on_body_entered(body: Node2D) -> void:
	if body == _thrower or not _weapon:
		return
	if not body.is_in_group("mobs"):
		return

	var mob_id: int = body.get_instance_id()
	var hits_done: int = _hit_counts.get(mob_id, 0)
	if hits_done >= _weapon.hit_count:
		return

	_deal_damage(body)
	_hit_counts[mob_id] = hits_done + 1

	if _weapon.hit_count <= 1 and not _weapon.returns_to_owner:
		call_deferred("queue_free")


func _deal_damage(body: Node) -> void:
	var damage := _weapon.roll_damage()
	if _weapon.damage_element == "poison" and body.has_method("apply_poison"):
		body.apply_poison(_weapon)

	if body.has_method("apply_weapon_damage"):
		body.apply_weapon_damage(damage, _weapon)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
