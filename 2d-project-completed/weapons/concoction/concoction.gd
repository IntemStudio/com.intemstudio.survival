extends Area2D

const ARC_HEIGHT_RATIO := 0.4
const POISON_EXPLOSION_SCENE := preload("res://weapons/concoction/poison_explosion.tscn")
const AREA_DAMAGE_ZONE_SCENE := preload("res://weapons/area/area_damage_zone.tscn")

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


func pool_reset() -> void:
	_thrower = null
	_weapon = null
	_direction = Vector2.RIGHT
	_speed = 650.0
	_max_range = 400.0
	_start_position = Vector2.ZERO
	_target_position = Vector2.ZERO
	_flight_duration = 1.0
	_flight_time = 0.0
	_last_position = Vector2.ZERO
	_has_exploded = false
	rotation = 0.0


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)


func setup_weapon(thrower: Node2D, aim_position: Vector2, weapon_data: WeaponData) -> void:
	_thrower = thrower
	_weapon = weapon_data
	_speed = weapon_data.throw_speed
	var range_mult := LoadoutStatApply.get_combat_power_radius_mult()
	_max_range = weapon_data.throw_range * range_mult

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


func _on_body_entered(body: Node2D) -> void:
	if _has_exploded:
		return
	if _is_environment_body(body):
		if _weapon:
			_explode_at(global_position)
		else:
			PoolUtil.release_node(self)


func _explode_at(impact_position: Vector2) -> void:
	if _has_exploded or not _weapon:
		return
	_has_exploded = true

	var radius := _weapon.aoe_radius * LoadoutStatApply.get_combat_power_radius_mult()
	_spawn_explosion_visual(impact_position, radius)
	_spawn_area_damage_zone(impact_position, radius)
	PoolUtil.release_node(self)


func _spawn_area_damage_zone(impact_position: Vector2, radius: float) -> void:
	if not _weapon:
		return
	var factory := AttackServices.find_factory()
	if factory:
		factory.spawn_area_circle(_weapon, impact_position, radius, true)
		return

	var game := get_node_or_null("/root/Game")
	if not game:
		return
	var zone: AreaDamageZone = AREA_DAMAGE_ZONE_SCENE.instantiate() as AreaDamageZone
	game.add_child(zone)
	zone.global_position = impact_position
	zone.setup_circle(_weapon, radius, true)


func _is_environment_body(body: Node) -> bool:
	return body is CollisionObject2D and PhysicsLayers.layer_matches(
		(body as CollisionObject2D).collision_layer,
		PhysicsLayers.ENVIRONMENT
	)


func _spawn_explosion_visual(impact_position: Vector2, radius: float) -> void:
	var game := get_node_or_null("/root/Game")
	if not game:
		return

	var visual: Node2D = POISON_EXPLOSION_SCENE.instantiate()
	game.add_child(visual)
	visual.global_position = impact_position
	visual.setup(radius)
