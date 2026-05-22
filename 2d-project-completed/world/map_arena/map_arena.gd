extends Node2D
class_name MapArena

## 고정 직사각형 맵 경계 — 벽 충돌과 플레이 영역 내부 스폰 좌표를 제공합니다.

const SPAWN_TEST_RADIUS := 52.0
const SPAWN_CLEAR_ATTEMPTS := 12
const ENVIRONMENT_COLLISION_MASK := 1

@export var arena_rect: Rect2 = Rect2(-1055.0, -697.0, 2112.0, 1368.0):
	set(value):
		arena_rect = value
		_schedule_wall_rebuild()

@export var wall_thickness: float = 48.0:
	set(value):
		wall_thickness = maxf(value, 1.0)
		_schedule_wall_rebuild()

@export var spawn_margin: float = 96.0:
	set(value):
		spawn_margin = maxf(value, 0.0)

@export var wall_color: Color = Color(0.2, 0.22, 0.18, 1.0):
	set(value):
		wall_color = value
		_schedule_wall_rebuild()

var _walls_root: Node2D
var _spawn_test_shape: CircleShape2D


func _ready() -> void:
	_spawn_test_shape = CircleShape2D.new()
	_spawn_test_shape.radius = SPAWN_TEST_RADIUS
	_rebuild_walls()


# 플레이 영역 안쪽의 무작위 월드 좌표(장애물 겹침 시 재시도)를 반환합니다.
func get_random_spawn_position() -> Vector2:
	var inner := _get_spawn_inner_rect()
	var end := inner.position + inner.size
	var space := get_world_2d().direct_space_state
	if space == null:
		return to_global(inner.get_center())

	for _attempt in SPAWN_CLEAR_ATTEMPTS:
		var local_pos := Vector2(
			randf_range(inner.position.x, end.x),
			randf_range(inner.position.y, end.y)
		)
		var world_pos := to_global(local_pos)
		if _is_spawn_point_clear(space, world_pos):
			return world_pos

	return to_global(inner.get_center())


func _get_spawn_inner_rect() -> Rect2:
	var margin := spawn_margin
	var max_margin_x := maxf(arena_rect.size.x * 0.5 - 1.0, 0.0)
	var max_margin_y := maxf(arena_rect.size.y * 0.5 - 1.0, 0.0)
	if margin > max_margin_x or margin > max_margin_y:
		push_warning(
			"MapArena: spawn_margin %.1f exceeds playable area; clamping." % spawn_margin
		)
		margin = minf(margin, max_margin_x)
		margin = minf(margin, max_margin_y)
	return arena_rect.grow(-margin)


func _is_spawn_point_clear(space: PhysicsDirectSpaceState2D, world_pos: Vector2) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _spawn_test_shape
	params.transform = Transform2D(0.0, world_pos)
	params.collision_mask = ENVIRONMENT_COLLISION_MASK
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return space.intersect_shape(params, 1).is_empty()


func _schedule_wall_rebuild() -> void:
	if is_node_ready():
		call_deferred("_rebuild_walls")


func _rebuild_walls() -> void:
	if _walls_root != null and is_instance_valid(_walls_root):
		_walls_root.queue_free()
		_walls_root = null

	_walls_root = Node2D.new()
	_walls_root.name = "Walls"
	add_child(_walls_root)

	var corner_span_w := arena_rect.size.x + wall_thickness * 2.0
	var corner_span_h := arena_rect.size.y + wall_thickness * 2.0
	var center_x := arena_rect.position.x + arena_rect.size.x * 0.5
	var center_y := arena_rect.position.y + arena_rect.size.y * 0.5
	var top_y := arena_rect.position.y - wall_thickness * 0.5
	var bottom_y := arena_rect.position.y + arena_rect.size.y + wall_thickness * 0.5
	var left_x := arena_rect.position.x - wall_thickness * 0.5
	var right_x := arena_rect.position.x + arena_rect.size.x + wall_thickness * 0.5

	_add_wall_segment(_walls_root, "WallTop", Vector2(center_x, top_y), Vector2(corner_span_w, wall_thickness))
	_add_wall_segment(_walls_root, "WallBottom", Vector2(center_x, bottom_y), Vector2(corner_span_w, wall_thickness))
	_add_wall_segment(_walls_root, "WallLeft", Vector2(left_x, center_y), Vector2(wall_thickness, corner_span_h))
	_add_wall_segment(_walls_root, "WallRight", Vector2(right_x, center_y), Vector2(wall_thickness, corner_span_h))


func _add_wall_segment(parent: Node, segment_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = segment_name
	body.position = center
	parent.add_child(body)

	var collision := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision.shape = rect_shape
	body.add_child(collision)

	var half := size * 0.5
	var visual := Polygon2D.new()
	visual.color = wall_color
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	body.add_child(visual)
