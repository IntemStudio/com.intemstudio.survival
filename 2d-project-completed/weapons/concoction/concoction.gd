extends Area2D

const ARC_HEIGHT_RATIO := 0.4
const POISON_EXPLOSION_SCENE := preload("res://weapons/concoction/poison_explosion.tscn")

var _thrower: Node2D
var _weapon: WeaponData
var _direction := Vector2.RIGHT
var _speed := 650.0
var _max_range := 400.0

var _start_position := Vector2.ZERO
var _target_position := Vector2.ZERO
var _flight_duration := 1.0
var _flight_time := 0.0
var _last_position := Vector2.ZERO
var _has_exploded := false


func setup_weapon(thrower: Node2D, aim_position: Vector2, weapon_data: WeaponData) -> void:
	_thrower = thrower
	_weapon = weapon_data
	_speed = weapon_data.throw_speed
	_max_range = weapon_data.throw_range

	_start_position = global_position
	var to_aim := aim_position - _start_position
	var throw_distance := minf(to_aim.length(), _max_range)
	if throw_distance > 0.0:
		_direction = to_aim / throw_distance
	else:
		_direction = Vector2.RIGHT

	_target_position = _start_position + _direction * throw_distance
	_flight_duration = maxf(throw_distance / _speed, 0.25)
	_flight_time = 0.0
	_last_position = _start_position
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if _has_exploded:
		return

	_flight_time += delta
	var progress := clampf(_flight_time / _flight_duration, 0.0, 1.0)

	var flat_position := _start_position.lerp(_target_position, progress)
	var throw_distance := _start_position.distance_to(_target_position)
	var arc_height := throw_distance * ARC_HEIGHT_RATIO
	var arc_lift := 4.0 * progress * (1.0 - progress) * arc_height
	global_position = flat_position + Vector2(0.0, -arc_lift)

	var move_direction := global_position - _last_position
	if move_direction.length_squared() > 1.0:
		rotation = move_direction.angle()
	_last_position = global_position

	if progress >= 1.0:
		_explode_at(_target_position)


func _explode_at(impact_position: Vector2) -> void:
	if _has_exploded or not _weapon:
		return
	_has_exploded = true

	var radius := _weapon.aoe_radius
	_spawn_explosion_visual(impact_position, radius)

	for mob in _get_mobs_in_radius(impact_position, radius):
		if mob.has_method("apply_poison"):
			mob.apply_poison(_weapon)
		if mob.has_method("apply_weapon_damage"):
			mob.apply_weapon_damage(_weapon.roll_damage(), _weapon)

	queue_free()


func _spawn_explosion_visual(impact_position: Vector2, radius: float) -> void:
	var game := get_node_or_null("/root/Game")
	if not game:
		return

	var visual: Node2D = POISON_EXPLOSION_SCENE.instantiate()
	game.add_child(visual)
	visual.global_position = impact_position
	visual.setup(radius)


func _get_mobs_in_radius(center: Vector2, radius: float) -> Array[Node]:
	var space_state := get_world_2d().direct_space_state
	if space_state:
		var circle_shape := CircleShape2D.new()
		circle_shape.radius = radius

		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = circle_shape
		params.transform = Transform2D(0.0, center)
		params.collision_mask = 2
		params.collide_with_areas = false
		params.collide_with_bodies = true
		if is_instance_valid(_thrower) and _thrower is CollisionObject2D:
			params.exclude = [(_thrower as CollisionObject2D).get_rid()]

		var hit_mobs: Array[Node] = []
		for result in space_state.intersect_shape(params, 64):
			var collider: Object = result.collider
			if collider is Node and collider.is_in_group("mobs") and collider not in hit_mobs:
				hit_mobs.append(collider)
		return hit_mobs

	return _get_mobs_in_radius_by_overlap(center, radius)


func _get_mob_hit_center(mob: Node2D) -> Vector2:
	var collision := mob.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		return collision.global_position
	return mob.global_position


func _get_mob_hit_radius(mob: Node2D) -> float:
	var collision := mob.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CircleShape2D:
		var circle := collision.shape as CircleShape2D
		var shape_scale := collision.global_transform.get_scale()
		return circle.radius * maxf(shape_scale.x, shape_scale.y)
	return 0.0


func _get_mobs_in_radius_by_overlap(center: Vector2, radius: float) -> Array[Node]:
	var hit_mobs: Array[Node] = []
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or mob is not Node2D:
			continue
		var mob_node := mob as Node2D
		var mob_center := _get_mob_hit_center(mob_node)
		var mob_radius := _get_mob_hit_radius(mob_node)
		if mob_center.distance_to(center) <= radius + mob_radius:
			hit_mobs.append(mob)
	return hit_mobs
