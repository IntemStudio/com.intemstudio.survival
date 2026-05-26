extends Area2D

var _weapon: WeaponData
var _damage := 0
var _travelled_distance := 0.0
var _hit_mob_ids: Dictionary = {}


func pool_reset() -> void:
	_weapon = null
	_damage = 0
	_travelled_distance = 0.0
	_hit_mob_ids.clear()


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)


func setup(weapon_data: WeaponData, spawn_transform: Transform2D) -> void:
	if not WeaponData.is_valid_projectile_pierce_count(weapon_data.projectile_pierce_count):
		push_error(
			"Bullet2D: projectile_pierce_count가 0입니다 (무기=%s)." % weapon_data.get_unique_key()
		)
		PoolUtil.release_node(self)
		return
	_weapon = weapon_data
	_damage = LoadoutStatApply.roll_combat_damage(weapon_data)
	_hit_mob_ids.clear()
	global_transform = spawn_transform
	if has_node("Sprite"):
		$Sprite.modulate = weapon_data.get_element_color()


func _physics_process(delta: float) -> void:
	const DEFAULT_SPEED := 1000.0
	var speed := DEFAULT_SPEED
	var max_range := 1200.0
	if _weapon:
		if _weapon.projectile_speed > 0.0:
			speed = _weapon.projectile_speed
		max_range = _weapon.get_projectile_range()

	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	_travelled_distance += speed * delta
	if _travelled_distance > max_range:
		PoolUtil.release_node(self)


func _on_body_entered(body: Node) -> void:
	if _is_environment_body(body):
		if _weapon and _weapon.is_explosion_ranged():
			_explode_at(global_position)
		call_deferred(&"_return_to_pool")
		return
	if not body.is_in_group("mobs"):
		return

	var mob_id: int = body.get_instance_id()
	if _hit_mob_ids.has(mob_id):
		return
	_hit_mob_ids[mob_id] = true

	if _weapon and _weapon.is_explosion_ranged():
		_explode_at(global_position)
		call_deferred(&"_return_to_pool")
		return

	_hit_mob(body)
	if _should_end_after_hit():
		call_deferred(&"_return_to_pool")


func _should_end_after_hit() -> bool:
	if not _weapon:
		return true
	if _weapon.has_unlimited_projectile_pierce():
		return false
	return _hit_mob_ids.size() >= _weapon.get_projectile_pierce_count_safe()


func _return_to_pool() -> void:
	PoolUtil.release_node(self)


func _is_environment_body(body: Node) -> bool:
	return body is CollisionObject2D and PhysicsLayers.layer_matches(
		(body as CollisionObject2D).collision_layer,
		PhysicsLayers.ENVIRONMENT
	)


func _hit_mob(body: Node) -> void:
	if _weapon and body.has_method("apply_weapon_damage"):
		body.apply_weapon_damage(_damage, _weapon)
	elif body.has_method("take_damage"):
		body.take_damage(_damage)


func _explode_at(center: Vector2) -> void:
	if not _weapon:
		return

	var radius := _weapon.explosion_radius
	if radius <= 0.0:
		radius = 90.0

	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or mob is not Node2D:
			continue
		var mob_node := mob as Node2D
		if GroundShadowFootprint.get_combat_target_center(mob_node).distance_to(center) > radius:
			continue
		var damage := LoadoutStatApply.roll_combat_damage(_weapon)
		if mob.has_method("apply_weapon_damage"):
			mob.apply_weapon_damage(damage, _weapon)
		elif mob.has_method("take_damage"):
			mob.take_damage(damage)
