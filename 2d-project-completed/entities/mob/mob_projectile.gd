extends Area2D

## 플레이어 bullet_2d.tscn과 동일한 비주얼·히트박스
const SPRITE_SCALE := Vector2.ONE
const SPRITE_OFFSET := Vector2(-11.0, -1.0)
const SWEEP_STEP_PX := 8.0

var _player: CharacterBody2D
var _source_mob: Mob
var _direction := Vector2.RIGHT
var _damage := 0
var _speed := 520.0
var _max_range := 900.0
var _travelled := 0.0
var _hit := false
var _collision_shape: CollisionShape2D


func _ready() -> void:
	_collision_shape = $CollisionShape2D as CollisionShape2D


func pool_reset() -> void:
	_player = null
	_source_mob = null
	_direction = Vector2.RIGHT
	_damage = 0
	_speed = 520.0
	_max_range = 900.0
	_travelled = 0.0
	_hit = false


func pool_on_acquire() -> void:
	_ensure_collision_config()


# 몹 원거리 탄환: 방향·데미지·사거리·발사 몹(affix hook) 설정.
func setup(
	target_player: CharacterBody2D,
	direction: Vector2,
	damage: int,
	speed: float,
	max_range: float,
	tint: Color,
	source_mob: Mob = null
) -> void:
	_player = target_player
	_source_mob = source_mob
	_direction = direction.normalized()
	_damage = damage
	_speed = speed
	_max_range = max_range
	_travelled = 0.0
	_hit = false
	rotation = _direction.angle()
	_ensure_collision_config()
	if has_node("Sprite"):
		$Sprite.modulate = tint
		$Sprite.scale = SPRITE_SCALE
		$Sprite.position = SPRITE_OFFSET
	call_deferred(&"_poll_overlaps_after_spawn")


func _ensure_collision_config() -> void:
	PhysicsLayers.apply_mob_projectile(self)
	monitoring = true
	if _collision_shape == null:
		_collision_shape = $CollisionShape2D as CollisionShape2D
	if _collision_shape:
		_collision_shape.disabled = false


func _poll_overlaps_after_spawn() -> void:
	if _hit or not is_inside_tree():
		return
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		_handle_body_contact(body)


func _physics_process(delta: float) -> void:
	if _hit:
		return

	var motion := _direction * _speed * delta
	for body in _collect_bodies_along_motion(motion):
		_handle_body_contact(body)
		if _hit:
			return

	global_position += motion
	_travelled += _speed * delta

	for body in get_overlapping_bodies():
		_handle_body_contact(body)
		if _hit:
			return

	if _travelled >= _max_range:
		PoolUtil.release_node(self)


# 이동 구간을 잘라 intersect_shape — body_entered·터널링 보완.
func _collect_bodies_along_motion(motion: Vector2) -> Array[Node]:
	var found: Array[Node] = []
	if _collision_shape == null or _collision_shape.shape == null:
		return found

	var space := get_world_2d().direct_space_state
	if space == null:
		return found

	var length := motion.length()
	if length <= 0.001:
		return found

	var steps := maxi(1, ceili(length / SWEEP_STEP_PX))
	for step_index in range(steps + 1):
		var t := float(step_index) / float(steps)
		var sample_pos := global_position + motion * t
		var xf := Transform2D(rotation, sample_pos)
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = _collision_shape.shape
		params.transform = xf
		params.collision_mask = collision_mask
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.exclude = [get_rid()]
		for hit in space.intersect_shape(params, 16):
			var collider: Variant = hit.get("collider")
			if collider is Node:
				var node := collider as Node
				if node not in found:
					found.append(node)
	return found


func _on_body_entered(body: Node) -> void:
	_handle_body_contact(body)


func _handle_body_contact(body: Node) -> void:
	if _hit:
		return

	if body is StaticBody2D:
		_hit = true
		call_deferred(&"_return_to_pool")
		return

	if not _is_player_character_body(body):
		return

	_hit = true
	var skip_reason := _resolve_hit_skip_reason(body)
	_log_player_collision(body, skip_reason == "")
	if skip_reason != "":
		_log_hit_skipped(body, skip_reason)
	call_deferred(&"_return_to_pool")


func _is_player_character_body(body: Node) -> bool:
	return body is CharacterBody2D and body.name == &"Player"


func _log_player_collision(body: Node, damage_applied: bool) -> void:
	print(
		"[MobProjectile] 플레이어 충돌 | damage_applied=%s | damage=%d | projectile_pos=%s | body=%s | setup_player_ref=%s | mask=%d layer=%d | monitoring=%s"
		% [
			damage_applied,
			_damage,
			global_position,
			_node_debug_label(body),
			_node_debug_label(_player),
			collision_mask,
			collision_layer,
			monitoring,
		]
	)


func _log_hit_skipped(body: Node, skip_reason: String) -> void:
	var player := body as CharacterBody2D
	var player_layer := player.collision_layer if player else -1
	var mask_matches_player := PhysicsLayers.layer_matches(collision_mask, player_layer) if player else false
	push_warning(
		"[MobProjectile] 플레이어 충돌 후 피해 미적용 | 사유=%s | damage=%d | body_layer=%d (기대=%d) | mask_includes_body=%s | body_mask=%d | monitoring=%s | projectile_pos=%s | body=%s | setup_player_ref=%s"
		% [
			skip_reason,
			_damage,
			player_layer,
			PhysicsLayers.PLAYER,
			mask_matches_player,
			player.collision_mask if player else -1,
			monitoring,
			global_position,
			_node_debug_label(body),
			_node_debug_label(_player),
		]
	)


# 피해 적용 — 빈 문자열이면 성공.
func _resolve_hit_skip_reason(body: Node) -> String:
	if _damage <= 0:
		return "projectile_damage<=0"

	var damage_target := body as CharacterBody2D
	if damage_target == null:
		return "body_not_character_body2d"

	if not is_instance_valid(damage_target):
		return "player_body_freed"

	if _player != null and is_instance_valid(_player) and damage_target != _player:
		var game_player := _get_game_player()
		if game_player != null and damage_target == game_player:
			damage_target = game_player
		else:
			return "body_is_not_setup_player_ref (%s vs %s)" % [
				_node_debug_label(damage_target),
				_node_debug_label(_player),
			]
	elif _player == null:
		var game_player := _get_game_player()
		if game_player != null and damage_target == game_player:
			damage_target = game_player
		else:
			return "setup_player_ref_null (mob.gd setup에 Player 미전달)"

	if not damage_target.has_method(&"apply_mob_projectile_damage"):
		return "player_missing_apply_mob_projectile_damage"
	var skip_reason: String = DamageResolver.apply_mob_projectile_to_player(damage_target, _damage)
	if skip_reason.is_empty() and _source_mob != null and is_instance_valid(_source_mob):
		_source_mob._elite_on_hit_player(_damage)
	return skip_reason


func _get_game_player() -> CharacterBody2D:
	return get_tree().root.get_node_or_null("Game/Player") as CharacterBody2D


func _node_debug_label(node: Node) -> String:
	if node == null:
		return "null"
	if not is_instance_valid(node):
		return "freed(id=%d)" % node.get_instance_id()
	return "%s id=%d path=%s" % [node.name, node.get_instance_id(), node.get_path()]


func _return_to_pool() -> void:
	PoolUtil.release_node(self)
