extends Area2D

var _thrower: Node2D
var _weapon: WeaponData
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _returning := false
var _hit_counts: Dictionary = {}


func pool_reset() -> void:
	_thrower = null
	_weapon = null
	_direction = Vector2.RIGHT
	_travelled = 0.0
	_returning = false
	_hit_counts.clear()


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)


func setup_weapon(thrower: Node2D, direction: Vector2, weapon_data: WeaponData) -> void:
	_thrower = thrower
	_weapon = weapon_data
	_direction = direction.normalized()
	rotation = _direction.angle()
	if $Sprite2D:
		$Sprite2D.modulate = weapon_data.get_element_color()
	ProjectileVisualUtil.apply_circle_projectile(
		self,
		weapon_data,
		Vector2(0.85, 0.85),
		Vector2.ZERO,
		14.0
	)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_thrower) or not _weapon:
		PoolUtil.release_node(self)
		return

	var speed := _weapon.throw_speed
	var max_range := _weapon.get_projectile_range() * LoadoutStatApply.get_combat_power_radius_mult()
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
			if _weapon.returns_to_owner:
				_returning = true
			else:
				PoolUtil.release_node(self)
				return

	global_position += move_dir * speed * delta
	rotation += delta * 10.0


func _on_body_entered(body: Node2D) -> void:
	if body == _thrower or not _weapon:
		return
	if _is_environment_body(body):
		call_deferred(&"_return_to_pool")
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
		call_deferred(&"_return_to_pool")


func _return_to_pool() -> void:
	PoolUtil.release_node(self)


func _is_environment_body(body: Node) -> bool:
	return body is CollisionObject2D and PhysicsLayers.layer_matches(
		(body as CollisionObject2D).collision_layer,
		PhysicsLayers.ENVIRONMENT
	)


func _deal_damage(body: Node) -> void:
	var damage := LoadoutStatApply.roll_combat_damage(_weapon)
	if _weapon.damage_element == "poison" and _weapon.status_effects.is_empty() and body.has_method("apply_poison"):
		body.apply_poison(_weapon)

	DamageResolver.apply_weapon_to_mob(body, damage, _weapon)
