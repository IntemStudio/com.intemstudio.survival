extends Node2D
class_name MapArena

## 고정 직사각형 맵 경계 — 벽 충돌, Poisson 소나무, 플레이 영역 내부 스폰 좌표를 제공합니다.

const SPAWN_TEST_RADIUS := 52.0
const SPAWN_CLEAR_ATTEMPTS := 12
const ENVIRONMENT_COLLISION_MASK := 1
## Poisson 간격 기본값 — 슬라이더·인스펙터는 tree_spacing_dense/sparse export 사용.
const TREE_SPACING_DENSE_DEFAULT := 50.0
const TREE_SPACING_SPARSE_DEFAULT := 960.0
const TREE_DENSITY_DEFAULT := 0.5
const TREE_MIN_SPACING_DEFAULT := lerpf(
	TREE_SPACING_SPARSE_DEFAULT,
	TREE_SPACING_DENSE_DEFAULT,
	TREE_DENSITY_DEFAULT
)
## 테스트(F6)·스크립트 기본 플레이 영역 — 메인은 survivors_game.tscn에서 3× 오버라이드
const ARENA_RECT_1X := Rect2(-1055, -697, 2112, 1368)
const SPAWN_MARGIN_1X := 96.0

const _PINE_TREE_SCENE := preload("res://world/trees/pine_tree.tscn")

@export var arena_rect: Rect2 = ARENA_RECT_1X:
	set(value):
		arena_rect = value
		_schedule_wall_rebuild()
		_schedule_tree_rebuild()

@export var wall_thickness: float = 48.0:
	set(value):
		wall_thickness = maxf(value, 1.0)
		_schedule_wall_rebuild()

@export var spawn_margin: float = SPAWN_MARGIN_1X:
	set(value):
		spawn_margin = maxf(value, 0.0)

@export var wall_color: Color = Color(0.2, 0.22, 0.18, 1.0):
	set(value):
		wall_color = value
		_schedule_wall_rebuild()

@export_group("Trees")
@export var spawn_trees: bool = true:
	set(value):
		spawn_trees = value
		_schedule_tree_rebuild()

@export var tree_scene: PackedScene = _PINE_TREE_SCENE:
	set(value):
		tree_scene = value if value != null else _PINE_TREE_SCENE
		_schedule_tree_rebuild()

@export_range(45.0, 300.0, 1.0, "or_greater") var tree_spacing_dense: float = TREE_SPACING_DENSE_DEFAULT:
	set(value):
		tree_spacing_dense = maxf(value, 45.0)
		_clamp_tree_min_spacing_to_limits()
		_schedule_tree_rebuild()

@export_range(200.0, 2400.0, 10.0, "or_greater") var tree_spacing_sparse: float = TREE_SPACING_SPARSE_DEFAULT:
	set(value):
		tree_spacing_sparse = maxf(value, tree_spacing_dense + 10.0)
		_clamp_tree_min_spacing_to_limits()
		_schedule_tree_rebuild()

@export var tree_min_spacing: float = TREE_MIN_SPACING_DEFAULT:
	set(value):
		var clamped := clampf(value, tree_spacing_dense, tree_spacing_sparse)
		if is_equal_approx(clamped, tree_min_spacing):
			return
		tree_min_spacing = clamped
		_schedule_tree_rebuild()

@export var wall_padding: float = 288.0:
	set(value):
		wall_padding = maxf(value, 0.0)
		_schedule_tree_rebuild()

@export var player_clear_radius: float = 280.0:
	set(value):
		player_clear_radius = maxf(value, 0.0)
		_schedule_tree_rebuild()

## 몹 스폰 시 플레이어 추가 이격 — 접촉 정지 거리(attack_distance)만큼 더 띄웁니다.
@export var mob_spawn_player_clear_extra: float = 130.0:
	set(value):
		mob_spawn_player_clear_extra = maxf(value, 0.0)

@export var rejection_samples: int = 30:
	set(value):
		rejection_samples = maxi(value, 1)
		_schedule_tree_rebuild()

@export var tree_spawn_seed: int = 0:
	set(value):
		tree_spawn_seed = value
		_schedule_tree_rebuild()

@export var tree_scale_min: float = 0.9:
	set(value):
		tree_scale_min = value
		_schedule_tree_rebuild()

@export var tree_scale_max: float = 1.1:
	set(value):
		tree_scale_max = value
		_schedule_tree_rebuild()

@export var tree_rotation_max_deg: float = 15.0:
	set(value):
		tree_rotation_max_deg = maxf(value, 0.0)
		_schedule_tree_rebuild()

var _walls_root: Node2D
var _obstacles_root: Node2D
var _spawn_test_shape: CircleShape2D
var _tree_rng: RandomNumberGenerator


func _ready() -> void:
	_spawn_test_shape = CircleShape2D.new()
	_spawn_test_shape.radius = SPAWN_TEST_RADIUS
	_tree_rng = RandomNumberGenerator.new()
	_rebuild_walls()
	_rebuild_trees()


# tree_min_spacing을 0~1 밀도(1=밀집)로 변환합니다.
func get_tree_density_normalized() -> float:
	return inverse_lerp(tree_spacing_sparse, tree_spacing_dense, tree_min_spacing)


# 0~1 밀도로 tree_min_spacing을 설정하고 나무를 재배치합니다.
func set_tree_density_normalized(density: float) -> void:
	tree_min_spacing = lerpf(
		tree_spacing_sparse,
		tree_spacing_dense,
		clampf(density, 0.0, 1.0)
	)


func _clamp_tree_min_spacing_to_limits() -> void:
	var clamped := clampf(tree_min_spacing, tree_spacing_dense, tree_spacing_sparse)
	if is_equal_approx(clamped, tree_min_spacing):
		return
	tree_min_spacing = clamped


# 플레이 영역 안쪽의 무작위 월드 좌표(장애물·exclude_near_world 겹침 시 재시도)를 반환합니다.
func get_random_spawn_position(exclude_near_world: Vector2 = Vector2(INF, INF)) -> Vector2:
	var inner := _get_spawn_inner_rect()
	var end := inner.position + inner.size
	var space := get_world_2d().direct_space_state
	var use_player_exclusion := is_finite(exclude_near_world.x) and is_finite(exclude_near_world.y)
	var mob_spawn_clear := player_clear_radius + mob_spawn_player_clear_extra
	var clear_r_sq := mob_spawn_clear * mob_spawn_clear
	if space == null:
		return _pick_spawn_fallback(inner, exclude_near_world, use_player_exclusion, clear_r_sq)

	for _attempt in SPAWN_CLEAR_ATTEMPTS:
		var local_pos := Vector2(
			randf_range(inner.position.x, end.x),
			randf_range(inner.position.y, end.y)
		)
		var world_pos := to_global(local_pos)
		if _is_spawn_point_valid(space, world_pos, exclude_near_world, use_player_exclusion, clear_r_sq):
			return world_pos

	return _pick_spawn_fallback(inner, exclude_near_world, use_player_exclusion, clear_r_sq)


func _is_spawn_point_valid(
	space: PhysicsDirectSpaceState2D,
	world_pos: Vector2,
	exclude_near_world: Vector2,
	use_player_exclusion: bool,
	clear_r_sq: float
) -> bool:
	if not _is_spawn_point_clear(space, world_pos):
		return false
	if use_player_exclusion and world_pos.distance_squared_to(exclude_near_world) <= clear_r_sq:
		return false
	return true


func _pick_spawn_fallback(
	inner: Rect2,
	exclude_near_world: Vector2,
	use_player_exclusion: bool,
	clear_r_sq: float
) -> Vector2:
	var fallback := to_global(inner.get_center())
	if not use_player_exclusion or fallback.distance_squared_to(exclude_near_world) > clear_r_sq:
		return fallback
	var away := fallback - exclude_near_world
	if away.length_squared() < 1.0:
		away = Vector2.RIGHT
	var offset := away.normalized() * (sqrt(clear_r_sq) + SPAWN_TEST_RADIUS + 8.0)
	return exclude_near_world + offset


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


func _get_tree_sample_rect() -> Rect2:
	var max_pad_x := maxf(arena_rect.size.x * 0.5 - 1.0, 0.0)
	var max_pad_y := maxf(arena_rect.size.y * 0.5 - 1.0, 0.0)
	var pad := minf(wall_padding, max_pad_x)
	pad = minf(pad, max_pad_y)
	return arena_rect.grow(-pad)


func _is_tree_point_allowed(local_point: Vector2) -> bool:
	if player_clear_radius > 0.0 and local_point.length_squared() <= player_clear_radius * player_clear_radius:
		return false
	return true


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


func _schedule_tree_rebuild() -> void:
	if is_node_ready():
		call_deferred("_rebuild_trees")


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


# Poisson 샘플로 소나무를 Obstacles 자식에 생성합니다.
func _rebuild_trees() -> void:
	if _obstacles_root == null or not is_instance_valid(_obstacles_root):
		_obstacles_root = Node2D.new()
		_obstacles_root.name = "Obstacles"
		add_child(_obstacles_root)
	else:
		for child in _obstacles_root.get_children():
			child.queue_free()

	if not spawn_trees or tree_scene == null:
		return

	var sample_rect := _get_tree_sample_rect()
	if sample_rect.size.x <= 0.0 or sample_rect.size.y <= 0.0:
		push_warning("MapArena: tree sample_rect is empty; skipping tree spawn.")
		return

	_configure_tree_rng()
	var is_allowed := Callable(self, "_is_tree_point_allowed")
	var points := PoissonSampler.sample(
		sample_rect,
		tree_min_spacing,
		is_allowed,
		rejection_samples,
		_tree_rng
	)

	var scale_min := minf(tree_scale_min, tree_scale_max)
	var scale_max := maxf(tree_scale_min, tree_scale_max)
	var rotation_rad_max := deg_to_rad(tree_rotation_max_deg)

	for point in points:
		var tree := tree_scene.instantiate()
		tree.position = point
		if scale_max > 0.0:
			var scale_factor := _tree_rng.randf_range(scale_min, scale_max)
			tree.scale = Vector2(scale_factor, scale_factor)
		if rotation_rad_max > 0.0:
			tree.rotation = _tree_rng.randf_range(-rotation_rad_max, rotation_rad_max)
		_obstacles_root.add_child(tree)


func _configure_tree_rng() -> void:
	if tree_spawn_seed != 0:
		_tree_rng.seed = tree_spawn_seed
	else:
		_tree_rng.randomize()


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
