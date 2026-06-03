extends Area2D
class_name EliteEmberHazard

## 불타는 affix 잔불 — 짧은 지면 hazard, 플레이어 접촉 시 elite_burn refresh.

const _Constants := preload("res://elite/elite_blazing_constants.gd")

var _setup_generation := 0
var _radius := 32.0
var _contact_timer := 0.0
var _player: Node = null


func pool_reset() -> void:
	_setup_generation += 1
	_radius = _Constants.EMBER_RADIUS_PX
	_contact_timer = 0.0
	_player = null


func pool_on_acquire() -> void:
	PhysicsLayers.apply_elite_ember_hazard(self)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_player = get_tree().root.get_node_or_null("Game/Player")


# lifetime·반경을 설정하고 수명 종료 후 풀 반환을 예약합니다.
func setup(lifetime_sec: float, radius: float) -> void:
	_setup_generation += 1
	var generation := _setup_generation
	_radius = maxf(radius, 8.0)
	_contact_timer = 0.0
	_apply_collision_radius(_radius)
	var safe_lifetime := maxf(lifetime_sec, 0.05)
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(safe_lifetime).timeout.connect(
		_on_lifetime_expired.bind(generation),
		CONNECT_ONE_SHOT
	)


func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return
	if get_tree().paused:
		return
	_contact_timer += delta
	if _contact_timer < _Constants.EMBER_CONTACT_DEBUFF_INTERVAL_SEC:
		return
	var player := _resolve_player()
	if player == null:
		return
	if not _is_player_overlapping(player):
		return
	_contact_timer = 0.0
	_try_apply_burn(player)


func _on_body_entered(body: Node2D) -> void:
	if get_tree().paused:
		return
	if not _is_player_body(body):
		return
	_contact_timer = _Constants.EMBER_CONTACT_DEBUFF_INTERVAL_SEC
	_try_apply_burn(body)


func _on_lifetime_expired(generation: int) -> void:
	if generation != _setup_generation:
		return
	PoolUtil.release_node(self)


func _try_apply_burn(player_node: Node) -> void:
	if player_node == null:
		return
	if player_node.has_method(&"is_damage_immune") and bool(player_node.call(&"is_damage_immune")):
		return
	if player_node.has_method(&"apply_elite_debuff"):
		player_node.call(
			&"apply_elite_debuff",
			_Constants.PLAYER_DEBUFF_ID,
			{}
		)


func _resolve_player() -> Node:
	if is_instance_valid(_player):
		return _player
	_player = get_tree().root.get_node_or_null("Game/Player")
	return _player


func _is_player_body(body: Node) -> bool:
	return body != null and body.has_method(&"apply_elite_debuff")


func _is_player_overlapping(player_node: Node) -> bool:
	if player_node is not Node2D:
		return false
	var player_center: Vector2 = (player_node as Node2D).global_position
	if player_node.has_method(&"get_footprint_global_center"):
		player_center = player_node.call(&"get_footprint_global_center") as Vector2
	var reach := _radius
	if player_node.has_method(&"get_footprint_half_extents"):
		var half := player_node.call(&"get_footprint_half_extents") as Vector2
		reach += maxf(half.x, half.y)
	return global_position.distance_to(player_center) <= reach


func _apply_collision_radius(radius: float) -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var circle := shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		shape_node.shape = circle
	circle.radius = radius
	var visual := get_node_or_null("Visual") as ColorRect
	if visual != null:
		var diameter := radius * 2.0
		visual.size = Vector2(diameter, diameter)
		visual.position = Vector2(-radius, -radius)
