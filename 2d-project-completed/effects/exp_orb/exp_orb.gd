extends Area2D

@export var experience_value := 1
@export var collect_distance := 24.0

const MAGNET_SPEED_BASE := 380.0
const MAGNET_RAMP_DURATION := 0.28
const MAGNET_RAMP_MAX_MULTIPLIER := 4.5
const MAGNET_SNAP_DISTANCE := 88.0
const MAGNET_SNAP_MAX_MULTIPLIER := 4.0
const MAGNET_MAX_SPEED := 1600.0
const TRAIL_MAX_POINTS := 8
const TRAIL_SAMPLE_DISTANCE := 4.0

var _magnet_target: Node2D = null
var _magnet_time := 0.0
var _trail_world_points: Array[Vector2] = []
var _trail_last_sample_global := Vector2.ZERO

@onready var _magnet_trail: Line2D = $MagnetTrail


func _ready() -> void:
	_setup_magnet_trail()


func pool_reset() -> void:
	if is_in_group("exp_orbs"):
		remove_from_group("exp_orbs")
	_magnet_target = null
	_magnet_time = 0.0
	_clear_magnet_trail()


func pool_on_acquire() -> void:
	add_to_group("exp_orbs")
	call_deferred(&"_try_auto_magnet")


func _try_auto_magnet() -> void:
	if not is_inside_tree() or not get_meta(&"_pooled_active", false):
		return
	var player := get_node_or_null("/root/Game/Player")
	if player and global_position.distance_to(player.global_position) <= player.pickup_range:
		start_magnet(player)


func start_magnet(target: Node2D) -> void:
	if _magnet_target:
		return
	_magnet_target = target
	_magnet_time = 0.0
	_clear_magnet_trail()
	if is_node_ready():
		_magnet_trail.visible = true
	_trail_last_sample_global = global_position
	_trail_sample_position()


# 꼬리(0)는 가늘고 알파 0, 오브 쪽(1)은 굵고 진하게
func _setup_magnet_trail() -> void:
	_magnet_trail.visible = false
	_magnet_trail.default_color = Color(1.0, 1.0, 1.0, 1.0)
	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 0.08))
	width_curve.add_point(Vector2(1.0, 1.0))
	_magnet_trail.width_curve = width_curve
	var color_gradient := Gradient.new()
	color_gradient.colors = PackedColorArray([
		Color(0.35, 0.85, 1.0, 0.0),
		Color(0.35, 0.85, 1.0, 0.35),
		Color(0.35, 0.85, 1.0, 0.88),
	])
	color_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	_magnet_trail.gradient = color_gradient


func _clear_magnet_trail() -> void:
	_trail_world_points.clear()
	if not is_node_ready():
		return
	_magnet_trail.clear_points()
	_magnet_trail.visible = false


func _trail_sample_position() -> void:
	if _trail_world_points.is_empty() \
			or global_position.distance_to(_trail_last_sample_global) >= TRAIL_SAMPLE_DISTANCE:
		_trail_world_points.append(global_position)
		_trail_last_sample_global = global_position
		while _trail_world_points.size() > TRAIL_MAX_POINTS:
			_trail_world_points.pop_front()


func _sync_magnet_trail() -> void:
	if not is_node_ready():
		return
	if _trail_world_points.is_empty():
		_magnet_trail.clear_points()
		return
	var local_points := PackedVector2Array()
	local_points.resize(_trail_world_points.size() + 1)
	for i in _trail_world_points.size():
		local_points[i] = to_local(_trail_world_points[i])
	local_points[_trail_world_points.size()] = Vector2.ZERO
	_magnet_trail.points = local_points


# 시간·거리 이중 가속 — 멀리서는 서서히, 가까울수록 확 끌림
func _get_magnet_speed_multiplier(distance_to_target: float) -> float:
	var ramp_t := clampf(_magnet_time / MAGNET_RAMP_DURATION, 0.0, 1.0)
	var time_mult := lerpf(1.0, MAGNET_RAMP_MAX_MULTIPLIER, ramp_t * ramp_t)
	var snap_t := 1.0 - clampf(distance_to_target / MAGNET_SNAP_DISTANCE, 0.0, 1.0)
	var snap_mult := lerpf(1.0, MAGNET_SNAP_MAX_MULTIPLIER, snap_t * snap_t)
	return time_mult * snap_mult


func _physics_process(delta: float) -> void:
	if not _magnet_target:
		return

	_magnet_time += delta
	var distance := global_position.distance_to(_magnet_target.global_position)
	var speed := minf(
		MAGNET_SPEED_BASE * _get_magnet_speed_multiplier(distance),
		MAGNET_MAX_SPEED
	)
	var direction := global_position.direction_to(_magnet_target.global_position)
	var step := speed * delta
	if step >= distance:
		global_position = _magnet_target.global_position
	else:
		global_position += direction * step
	_trail_sample_position()
	_sync_magnet_trail()

	if global_position.distance_to(_magnet_target.global_position) < collect_distance:
		if _magnet_target.has_method("gain_experience"):
			_magnet_target.gain_experience(experience_value)
		PoolUtil.release_node(self)
