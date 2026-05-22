class_name GroundShadowFootprint
## ground_shadow.png 발밑 그림자 스프라이트 크기 → 충돌 박스·접촉 거리 산출

const TEXTURE_SIZE := Vector2(84.0, 52.0)


static func find_shadow_sprite(root: Node) -> Sprite2D:
	if root == null:
		return null
	return root.find_child("GroundShadow", true, false) as Sprite2D


static func footprint_size_from_visual(root: Node) -> Vector2:
	var shadow := find_shadow_sprite(root)
	if shadow == null or shadow.texture == null:
		return Vector2.ZERO
	var tex_size := shadow.texture.get_size()
	return tex_size * shadow.global_scale


static func footprint_half_extents_from_visual(root: Node) -> Vector2:
	return footprint_size_from_visual(root) * 0.5


static func apply_rectangle_collision(shape_node: CollisionShape2D, footprint: Vector2) -> void:
	if footprint == Vector2.ZERO:
		return
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		shape_node.shape = rect
	rect.size = footprint
	shape_node.position = Vector2.ZERO


# 두 발밑 AABB(중심 정렬)가 겹치지 않는 보수적 중심 간 최소 거리
static func min_center_distance_no_overlap(half_a: Vector2, half_b: Vector2, padding: float = 0.0) -> float:
	return half_a.length() + half_b.length() + padding
