extends Node2D

const BASE_SCALE := Vector2(1.1, 1.1)
const STEM_SIZE := Vector2(8.0, 22.0)
const STEM_OFFSET_Y := -28.0
const DOT_CENTER_Y := 18.0
const DOT_RADIUS := 5.0
const OUTLINE_COLOR := Color(0.08, 0.04, 0.02, 0.55)
const OUTLINE_WIDTH := 2.0

var _mark_color := Color(1.0, 0.38, 0.22, 0.95)


func pool_reset() -> void:
	position = Vector2.ZERO
	scale = BASE_SCALE
	_mark_color = Color(1.0, 0.38, 0.22, 0.95)
	queue_redraw()


func pool_on_acquire() -> void:
	queue_redraw()


# 몹 머리 위 로컬 위치·색으로 공격 예고 느낌표를 표시합니다.
func setup(local_offset: Vector2, tint: Color) -> void:
	position = local_offset
	scale = BASE_SCALE
	_mark_color = Color(
		minf(tint.r * 1.15, 1.0),
		minf(tint.g * 0.45, 1.0),
		minf(tint.b * 0.35, 1.0),
		0.95
	)
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func _draw() -> void:
	var fill := _mark_color
	var stem_rect := Rect2(Vector2(-STEM_SIZE.x * 0.5, STEM_OFFSET_Y), STEM_SIZE)
	var dot_center := Vector2(0.0, DOT_CENTER_Y)
	_draw_exclamation_stem(stem_rect, fill)
	_draw_exclamation_dot(dot_center, fill)


func _draw_exclamation_stem(rect: Rect2, fill: Color) -> void:
	draw_rect(rect.grow(OUTLINE_WIDTH), OUTLINE_COLOR)
	draw_rect(rect, fill)


func _draw_exclamation_dot(center: Vector2, fill: Color) -> void:
	draw_circle(center, DOT_RADIUS + OUTLINE_WIDTH * 0.5, OUTLINE_COLOR)
	draw_circle(center, DOT_RADIUS, fill)
