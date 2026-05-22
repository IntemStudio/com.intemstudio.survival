extends Area2D
class_name AreaDamageZone

const HIT_INTERVAL := 0.07

var _weapon: WeaponData
var _hit_mobs: Dictionary = {}
var _setup_generation := 0
var _apply_poison := false


func pool_reset() -> void:
	_setup_generation += 1
	_weapon = null
	_hit_mobs.clear()
	_apply_poison = false


func pool_on_acquire() -> void:
	pass


# 착지·투척 등 원형 영역 피해(연금 물약 등)
func setup_circle(weapon_data: WeaponData, radius: float, apply_poison: bool = false) -> void:
	_apply_poison = apply_poison
	_begin_setup(weapon_data)

	var circle := CircleShape2D.new()
	circle.radius = radius
	$CollisionShape2D.shape = circle
	$CollisionShape2D.position = Vector2.ZERO

	var visual: ColorRect = $Visual
	visual.visible = false


# 방향 사각 영역 피해(향후 광역 근접·스킬 등 — 현재 카탈로그 근접은 melee_projectile)
func setup_rectangle(weapon_data: WeaponData, direction: Vector2, reach: float, width: float = 56.0) -> void:
	_apply_poison = false
	_begin_setup(weapon_data)
	rotation = direction.angle()

	var shape := RectangleShape2D.new()
	shape.size = Vector2(reach, width)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(reach * 0.5, 0.0)

	var visual: ColorRect = $Visual
	visual.visible = true
	visual.custom_minimum_size = shape.size
	visual.position = $CollisionShape2D.position - shape.size * 0.5


func _begin_setup(weapon_data: WeaponData) -> void:
	_setup_generation += 1
	var generation := _setup_generation
	_weapon = weapon_data
	_hit_mobs.clear()

	call_deferred("_pulse_damage")
	if _weapon.hit_count > 1:
		for hit_index in range(1, _weapon.hit_count):
			get_tree().create_timer(HIT_INTERVAL * hit_index).timeout.connect(
				_on_hit_timer.bind(generation, hit_index)
			)

	var lifetime := 0.1 + HIT_INTERVAL * maxi(_weapon.hit_count - 1, 0)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired.bind(generation))


func _on_hit_timer(generation: int, _hit_index: int) -> void:
	if generation != _setup_generation:
		return
	_pulse_damage()


func _on_lifetime_expired(generation: int) -> void:
	if generation != _setup_generation:
		return
	PoolUtil.release_node(self)


func _pulse_damage() -> void:
	if not is_inside_tree() or not _weapon:
		return

	for body in _collect_hit_bodies():
		var mob_id: int = body.get_instance_id()
		var hits_done: int = _hit_mobs.get(mob_id, 0)
		if hits_done >= _weapon.hit_count:
			continue

		if _apply_poison and body.has_method("apply_poison"):
			body.apply_poison(_weapon)
		if body.has_method("apply_weapon_damage"):
			body.apply_weapon_damage(_weapon.roll_damage(), _weapon)

		_hit_mobs[mob_id] = hits_done + 1


# 풀 acquire 직후 overlap이 비어 있을 수 있어, overlap → shape 쿼리 → 거리 폴백 순으로 수집
func _collect_hit_bodies() -> Array[Node]:
	var hits: Array[Node] = []
	var seen: Dictionary = {}

	for body in get_overlapping_bodies():
		if not _is_valid_mob(body):
			continue
		var mob_id: int = body.get_instance_id()
		if seen.get(mob_id, false):
			continue
		seen[mob_id] = true
		hits.append(body)

	if not hits.is_empty():
		return hits

	var collision := $CollisionShape2D as CollisionShape2D
	if not collision or not collision.shape:
		return hits

	var space_state := get_world_2d().direct_space_state
	if space_state:
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = collision.shape
		params.transform = collision.global_transform
		params.collision_mask = collision_mask
		params.collide_with_areas = false
		params.collide_with_bodies = true

		for result in space_state.intersect_shape(params, 64):
			var collider: Object = result.get("collider")
			if not _is_valid_mob(collider):
				continue
			var query_mob_id: int = collider.get_instance_id()
			if seen.get(query_mob_id, false):
				continue
			seen[query_mob_id] = true
			hits.append(collider)

	if not hits.is_empty():
		return hits

	return _collect_hit_bodies_by_distance(collision)


func _is_valid_mob(body: Variant) -> bool:
	return body is Node and is_instance_valid(body) and (body as Node).is_in_group("mobs")


func _collect_hit_bodies_by_distance(collision: CollisionShape2D) -> Array[Node]:
	if not collision.shape is CircleShape2D:
		return []

	var circle := collision.shape as CircleShape2D
	var center := collision.global_position
	var shape_scale := collision.global_transform.get_scale()
	var radius := circle.radius * maxf(shape_scale.x, shape_scale.y)

	var hits: Array[Node] = []
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or mob is not Node2D:
			continue
		var mob_node := mob as Node2D
		var mob_center := _get_mob_hit_center(mob_node)
		var mob_radius := _get_mob_hit_radius(mob_node)
		if mob_center.distance_to(center) <= radius + mob_radius:
			hits.append(mob)
	return hits


func _get_mob_hit_center(mob: Node2D) -> Vector2:
	var mob_collision := mob.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if mob_collision:
		return mob_collision.global_position
	return mob.global_position


func _get_mob_hit_radius(mob: Node2D) -> float:
	var mob_collision := mob.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if mob_collision and mob_collision.shape is CircleShape2D:
		var mob_circle := mob_collision.shape as CircleShape2D
		var shape_scale := mob_collision.global_transform.get_scale()
		return mob_circle.radius * maxf(shape_scale.x, shape_scale.y)
	return 0.0
