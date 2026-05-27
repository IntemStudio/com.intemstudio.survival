extends Node2D

## F6 테스트 아레나 — 몹 고정 스폰 위치를 월드에서 표시합니다.

const RING_RADIUS := 22.0
const RING_WIDTH := 2.5
const RING_SEGMENTS := 48
const MARK_COLOR := Color(0.95, 0.42, 0.28, 0.92)
const FILL_COLOR := Color(0.95, 0.42, 0.28, 0.14)


func _ready() -> void:
	z_index = 8
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RING_RADIUS, FILL_COLOR)
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, RING_SEGMENTS, MARK_COLOR, RING_WIDTH, true)
	var arm := RING_RADIUS * 0.62
	draw_line(Vector2(-arm, 0.0), Vector2(arm, 0.0), MARK_COLOR, RING_WIDTH, true)
	draw_line(Vector2(0.0, -arm), Vector2(0.0, arm), MARK_COLOR, RING_WIDTH, true)
