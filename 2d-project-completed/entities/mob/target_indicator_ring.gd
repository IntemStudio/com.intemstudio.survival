extends Node2D
class_name TargetIndicatorRing

@export var ring_radius := 26.0
@export var ring_width := 3.5
@export var ring_segments := 64
@export var show_corner_brackets := true
@export var bracket_arm := 9.0
@export var bracket_offset := 22.0
@export var ring_color := Color(1, 1, 1, 1)


func _ready() -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func _draw() -> void:
	var color := ring_color * modulate
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, ring_segments, color, ring_width, true)

	if not show_corner_brackets:
		return

	var corner_dirs := [
		Vector2(1, -1).normalized(),
		Vector2(1, 1).normalized(),
		Vector2(-1, 1).normalized(),
		Vector2(-1, -1).normalized(),
	]
	for corner_dir in corner_dirs:
		_draw_corner_bracket(corner_dir, color)


# 코너 L자 브래킷 — 조준 고정 느낌
func _draw_corner_bracket(corner_dir: Vector2, color: Color) -> void:
	var anchor := corner_dir * bracket_offset
	var inward := -corner_dir
	var tangent := Vector2(-corner_dir.y, corner_dir.x)
	draw_line(anchor, anchor + inward * bracket_arm, color, ring_width, true)
	draw_line(anchor, anchor + tangent * bracket_arm, color, ring_width, true)
