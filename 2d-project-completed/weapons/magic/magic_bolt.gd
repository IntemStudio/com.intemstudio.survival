extends Area2D

var _weapon: WeaponData
var _damage := 0
var _travelled_distance := 0.0
var _homing_strength := 0.0


func setup(weapon_data: WeaponData, spawn_transform: Transform2D) -> void:
	_weapon = weapon_data
	_damage = weapon_data.roll_damage()
	_homing_strength = weapon_data.homing_strength
	global_transform = spawn_transform

	if $Sprite:
		$Sprite.modulate = weapon_data.get_element_color()
		$Sprite.scale = Vector2(0.55, 0.55)


func _physics_process(delta: float) -> void:
	if not _weapon:
		queue_free()
		return

	if _homing_strength > 0.0:
		_apply_homing(delta)

	var speed := _weapon.projectile_speed
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	_travelled_distance += speed * delta
	if _travelled_distance >= _weapon.get_projectile_range():
		queue_free()


func _apply_homing(delta: float) -> void:
	var target := _find_nearest_mob()
	if not target:
		return
	var desired_angle := global_position.angle_to_point(target.global_position)
	rotation = lerp_angle(rotation, desired_angle, _homing_strength * delta)


func _find_nearest_mob() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := INF
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or mob is not Node2D:
			continue
		var mob_node := mob as Node2D
		var distance_sq := global_position.distance_squared_to(mob_node.global_position)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = mob_node
	return nearest


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("mobs"):
		return
	_apply_hit(body)
	call_deferred("queue_free")


func _apply_hit(body: Node) -> void:
	if _weapon.magic_attack_style == "Explosion":
		_spawn_explosion(global_position)
		return

	if body.has_method("apply_weapon_damage"):
		body.apply_weapon_damage(_damage, _weapon)
	elif body.has_method("take_damage"):
		body.take_damage(_damage)


func _spawn_explosion(center: Vector2) -> void:
	var game := get_node_or_null("/root/Game")
	if not game or not _weapon:
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
