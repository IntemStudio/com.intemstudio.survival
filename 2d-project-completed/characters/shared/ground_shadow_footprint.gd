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


static func footprint_center_global(visual_root: Node) -> Vector2:
	var shadow := find_shadow_sprite(visual_root)
	if shadow != null:
		return shadow.global_position
	if visual_root is Node2D:
		return (visual_root as Node2D).global_position
	return Vector2.ZERO


# 플레이어·몹 등 전투 판정·조준에 쓸 발밑 중심(그림자 우선).
static func get_combat_target_center(target: Node2D) -> Vector2:
	if target != null and target.has_method(&"get_footprint_global_center"):
		return target.call(&"get_footprint_global_center") as Vector2
	if target != null:
		return target.global_position
	return Vector2.ZERO


static func apply_rectangle_collision(shape_node: CollisionShape2D, footprint: Vector2) -> void:
	if footprint == Vector2.ZERO:
		return
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		shape_node.shape = rect
	rect.size = footprint
	shape_node.position = Vector2.ZERO


# 발밑 그림자 중심·크기에 맞춰 충돌 박스 위치·크기를 맞춥니다.
static func sync_collision_shape_to_shadow(
	body: Node2D,
	shape_node: CollisionShape2D,
	visual_root: Node
) -> void:
	var footprint := footprint_size_from_visual(visual_root)
	if footprint == Vector2.ZERO:
		return
	apply_rectangle_collision(shape_node, footprint)
	var shadow := find_shadow_sprite(visual_root)
	if shadow != null:
		shape_node.position = body.to_local(shadow.global_position)


# 두 발밑 AABB(중심 정렬)가 겹치지 않는 보수적 중심 간 최소 거리
static func min_center_distance_no_overlap(half_a: Vector2, half_b: Vector2, padding: float = 0.0) -> float:
	return half_a.length() + half_b.length() + padding
