extends Node2D

const POOL_STORAGE_POSITION := Vector2(-50000.0, -50000.0)

var _length := 120.0
var _half_width := 28.0
var _fill_color := Color(0.35, 0.82, 0.98, 0.28)
var _outline_color := Color(0.5, 0.92, 1.0, 0.72)
var _arrow_color := Color(0.85, 0.98, 1.0, 0.9)


func pool_reset() -> void:
	_length = 120.0
	_half_width = 28.0
	global_position = POOL_STORAGE_POSITION
	rotation = 0.0
	modulate = Color.WHITE
	set_process(false)


func pool_on_acquire() -> void:
	queue_redraw()


# 돌진 직선 구간(일자 네모)과 화살표를 월드에 고정 표시합니다.
func setup_world(
	start_global: Vector2,
	direction: Vector2,
	length: float,
	half_width: float,
	tint: Color,
	display_duration: float = 1.0
) -> void:
	var travel := direction.normalized()
	if travel.length_squared() <= 0.01:
		travel = Vector2.RIGHT
	_length = maxf(length, 8.0)
	_half_width = maxf(half_width, 12.0)
	global_position = start_global + travel * (_length * 0.5)
	rotation = travel.angle()
	_fill_color = Color(tint.r, tint.g, tint.b, 0.3)
	_outline_color = Color(
		minf(tint.r * 1.2, 1.0),
		minf(tint.g * 1.1, 1.0),
		minf(tint.b * 1.05, 1.0),
		0.78
	)
	_arrow_color = Color(
		minf(tint.r * 1.35, 1.0),
		minf(tint.g * 1.25, 1.0),
		minf(tint.b * 1.15, 1.0),
		0.92
	)
	queue_redraw()

	var tree := get_tree()
	if not tree:
		return
	var wait := maxf(display_duration, 0.05)
	tree.create_timer(wait).timeout.connect(_on_display_finished, CONNECT_ONE_SHOT)


func _on_display_finished() -> void:
	PoolUtil.release_node(self)


func _draw() -> void:
	var half_length := _length * 0.5
	var lane_rect := Rect2(Vector2(-half_length, -_half_width), Vector2(_length, _half_width * 2.0))
	draw_rect(lane_rect.grow(2.5), _outline_color)
	draw_rect(lane_rect, _fill_color)
	_draw_lane_arrows(half_length)


func _draw_lane_arrows(half_length: float) -> void:
	var arrow_count := maxi(1, int(roundf(_length / 72.0)))
	var step := _length / float(arrow_count)
	var chevron_half_width := clampf(_half_width * 0.42, 10.0, _half_width - 2.0)
	var chevron_depth := clampf(step * 0.32, 14.0, 28.0)
	var line_width := 3.0

	for i in arrow_count:
		var center_x := -half_length + (float(i) + 0.5) * step
		_draw_chevron(Vector2(center_x, 0.0), chevron_half_width, chevron_depth, line_width)


func _draw_chevron(center: Vector2, half_width: float, depth: float, line_width: float) -> void:
	var tip := center + Vector2(depth * 0.5, 0.0)
	var back_top := center + Vector2(-depth * 0.5, -half_width)
	var back_bottom := center + Vector2(-depth * 0.5, half_width)
	draw_line(back_top, tip, _arrow_color, line_width, true)
	draw_line(back_bottom, tip, _arrow_color, line_width, true)
	draw_line(back_top, back_bottom, _arrow_color, line_width * 0.65, true)
