class_name PoissonSampler
extends RefCounted

## Bridson Poisson Disk Sampling — 샘플 간 최소 거리를 보장하는 2D 점 분포.

const SQRT2 := 1.4142135623730951
const FIRST_POINT_ATTEMPTS := 64
const NEIGHBOR_CELL_RADIUS := 2


static func sample(
	bounds: Rect2,
	radius: float,
	is_allowed: Callable,
	k: int = 30,
	rng: RandomNumberGenerator = null
) -> PackedVector2Array:
	if radius <= 0.0 or bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return PackedVector2Array()

	var local_rng := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		local_rng.randomize()

	var cell_size := radius / SQRT2
	var grid: Dictionary = {}
	var active: Array[Vector2] = []
	var result: PackedVector2Array = []

	var first_point := _pick_first_point(bounds, is_allowed, local_rng)
	if first_point == Vector2.INF:
		return result

	_register_point(first_point, grid, active, result, bounds.position, cell_size)

	while not active.is_empty():
		var active_index := local_rng.randi_range(0, active.size() - 1)
		var point: Vector2 = active[active_index]
		var found := false

		for _attempt in k:
			var candidate := _random_annulus_point(point, radius, local_rng)
			if not bounds.has_point(candidate):
				continue
			if not is_allowed.call(candidate):
				continue
			if not _is_far_enough(candidate, grid, bounds.position, cell_size, radius):
				continue
			_register_point(candidate, grid, active, result, bounds.position, cell_size)
			found = true
			break

		if not found:
			active.remove_at(active_index)

	return result


static func _pick_first_point(
	bounds: Rect2,
	is_allowed: Callable,
	rng: RandomNumberGenerator
) -> Vector2:
	var end := bounds.position + bounds.size
	for _i in FIRST_POINT_ATTEMPTS:
		var p := Vector2(
			rng.randf_range(bounds.position.x, end.x),
			rng.randf_range(bounds.position.y, end.y)
		)
		if is_allowed.call(p):
			return p
	return Vector2.INF


static func _random_annulus_point(center: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector2:
	var angle := rng.randf() * TAU
	var dist := radius + rng.randf() * radius
	return center + Vector2.from_angle(angle) * dist


static func _register_point(
	point: Vector2,
	grid: Dictionary,
	active: Array[Vector2],
	result: PackedVector2Array,
	origin: Vector2,
	cell_size: float
) -> void:
	var cell := _grid_coord(point, origin, cell_size)
	grid[cell] = point
	active.append(point)
	result.append(point)


static func _grid_coord(point: Vector2, origin: Vector2, cell_size: float) -> Vector2i:
	return Vector2i(
		int(floor((point.x - origin.x) / cell_size)),
		int(floor((point.y - origin.y) / cell_size))
	)


static func _is_far_enough(
	candidate: Vector2,
	grid: Dictionary,
	origin: Vector2,
	cell_size: float,
	radius: float
) -> bool:
	var cell := _grid_coord(candidate, origin, cell_size)
	var min_dist_sq := radius * radius
	for dx in range(-NEIGHBOR_CELL_RADIUS, NEIGHBOR_CELL_RADIUS + 1):
		for dy in range(-NEIGHBOR_CELL_RADIUS, NEIGHBOR_CELL_RADIUS + 1):
			var neighbor_cell := cell + Vector2i(dx, dy)
			if not grid.has(neighbor_cell):
				continue
			var other: Vector2 = grid[neighbor_cell]
			if candidate.distance_squared_to(other) < min_dist_sq:
				return false
	return true
