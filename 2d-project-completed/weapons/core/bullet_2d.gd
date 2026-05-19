extends Area2D

var _weapon: WeaponData
var _damage := 0
var _travelled_distance := 0.0


func setup(weapon_data: WeaponData, spawn_transform: Transform2D) -> void:
	_weapon = weapon_data
	_damage = weapon_data.roll_damage()
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
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("mobs"):
		return

	if _weapon and _weapon.is_explosion_ranged():
		_explode_at(global_position)
	else:
		_hit_mob(body)

	call_deferred("queue_free")


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
		if mob_node.global_position.distance_to(center) > radius:
			continue
		var damage := _weapon.roll_damage()
		if mob.has_method("apply_weapon_damage"):
			mob.apply_weapon_damage(damage, _weapon)
		elif mob.has_method("take_damage"):
			mob.take_damage(damage)
