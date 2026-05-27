extends Node2D

## 빠른 몹 이동 시 꼬리 Line2D·먼지 파티클로 속도감을 표시합니다.

@export var trail_color := Color(0.75, 0.95, 1.0, 0.88)
@export var min_speed_to_show := 70.0
@export var min_speed_for_particles := 140.0

const TRAIL_MAX_POINTS := 7
const TRAIL_SAMPLE_DISTANCE := 10.0
const POOL_STORAGE_POSITION := Vector2(-50000.0, -50000.0)

var _trail_world_points: Array[Vector2] = []
var _trail_last_sample_global := Vector2.ZERO
var _mob: CharacterBody2D

@onready var _line: Line2D = $Line2D
@onready var _particles: CPUParticles2D = $Particles


func _ready() -> void:
	_mob = get_parent() as CharacterBody2D
	_setup_line_trail()
	_setup_particles()
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if _mob == null or not is_instance_valid(_mob):
		return
	if _is_pooled():
		_clear_trail()
		_set_particles_active(false)
		return

	var speed := _mob.velocity.length()
	if speed < min_speed_to_show:
		_clear_trail()
		_set_particles_active(false)
		return

	_trail_sample_position()
	_sync_line_trail()
	_update_particles(speed)


func _is_pooled() -> bool:
	return _mob.collision_layer == 0 \
		or _mob.global_position.distance_squared_to(POOL_STORAGE_POSITION) < 10000.0


func _setup_line_trail() -> void:
	_line.visible = false
	_line.default_color = trail_color
	_line.width = 28.0
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.antialiased = true

	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 0.12))
	width_curve.add_point(Vector2(0.55, 0.55))
	width_curve.add_point(Vector2(1.0, 1.0))
	_line.width_curve = width_curve

	var color_gradient := Gradient.new()
	var tail := Color(trail_color.r, trail_color.g, trail_color.b, 0.0)
	var mid := Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * 0.45)
	var head := Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a)
	color_gradient.colors = PackedColorArray([tail, mid, head])
	color_gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	_line.gradient = color_gradient


func _setup_particles() -> void:
	_particles.emitting = false
	_particles.amount = 14
	_particles.lifetime = 0.22
	_particles.one_shot = false
	_particles.explosiveness = 0.0
	_particles.randomness = 0.35
	_particles.local_coords = false
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 10.0
	_particles.spread = 28.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 40.0
	_particles.initial_velocity_max = 110.0
	_particles.scale_amount_min = 0.35
	_particles.scale_amount_max = 0.75
	_particles.color = trail_color

	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a),
		Color(trail_color.r, trail_color.g, trail_color.b, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	_particles.color_ramp = ramp


func _trail_sample_position() -> void:
	var pos := _mob.global_position
	if _trail_world_points.is_empty() \
			or pos.distance_squared_to(_trail_last_sample_global) >= TRAIL_SAMPLE_DISTANCE * TRAIL_SAMPLE_DISTANCE:
		_trail_world_points.append(pos)
		_trail_last_sample_global = pos
		while _trail_world_points.size() > TRAIL_MAX_POINTS:
			_trail_world_points.pop_front()


func _sync_line_trail() -> void:
	if _trail_world_points.is_empty():
		_line.clear_points()
		_line.visible = false
		return

	var local_points := PackedVector2Array()
	local_points.resize(_trail_world_points.size() + 1)
	for i in _trail_world_points.size():
		local_points[i] = to_local(_trail_world_points[i])
	local_points[_trail_world_points.size()] = Vector2.ZERO
	_line.points = local_points
	_line.visible = true


func _clear_trail() -> void:
	_trail_world_points.clear()
	_trail_last_sample_global = Vector2.ZERO
	if is_node_ready():
		_line.clear_points()
		_line.visible = false


func _set_particles_active(active: bool) -> void:
	if not is_node_ready():
		return
	_particles.emitting = active


# 이동 방향 반대로 짧은 스트릭을 뿌려 속도감을 보강합니다.
func _update_particles(speed: float) -> void:
	if speed < min_speed_for_particles:
		_set_particles_active(false)
		return

	var move_dir := _mob.velocity / speed
	_particles.direction = -move_dir
	_particles.initial_velocity_min = lerpf(35.0, 70.0, clampf(speed / 360.0, 0.0, 1.0))
	_particles.initial_velocity_max = lerpf(90.0, 150.0, clampf(speed / 360.0, 0.0, 1.0))
	_set_particles_active(true)
