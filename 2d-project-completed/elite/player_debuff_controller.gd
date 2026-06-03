class_name PlayerDebuffController
extends RefCounted

## affix 몹이 거는 플레이어 debuff 목록 — apply/tick/gate 집계.

const ActivePlayerDebuffScript = preload("res://elite/active_player_debuff.gd")
const PlayerDebuffCatalogScript = preload("res://elite/player_debuff_catalog.gd")

var _active_debuffs: Array = []


func apply(debuff_id: StringName, payload: Dictionary = {}) -> void:
	if debuff_id.is_empty():
		return
	if not PlayerDebuffCatalogScript.has_debuff(debuff_id):
		push_warning("PlayerDebuffController: unknown debuff '%s'" % String(debuff_id))
		return
	var existing = _find_active(debuff_id)
	if existing != null:
		existing.refresh(payload)
		return
	var active = _create_active_debuff(debuff_id, payload)
	if active == null or not active.is_valid():
		return
	_active_debuffs.append(active)


func tick(delta: float, player_context: Node = null) -> void:
	if delta <= 0.0 or _active_debuffs.is_empty():
		return
	if _is_player_paused(player_context):
		return
	var skip_effects := _should_skip_tick_effects(player_context)
	for index in range(_active_debuffs.size() - 1, -1, -1):
		var active = _active_debuffs[index]
		if active == null or not active.is_valid():
			_active_debuffs.remove_at(index)
			continue
		var expired: bool = active.advance_time(delta)
		if not expired and not skip_effects:
			_advance_and_apply_dot(active, delta, player_context)
		if expired:
			if not skip_effects:
				_apply_expire_burst(active, player_context)
			_active_debuffs.remove_at(index)


func clear() -> void:
	_active_debuffs.clear()


func has_debuff(debuff_id: StringName) -> bool:
	return _find_active(debuff_id) != null


func get_debuff_remaining_seconds(debuff_id: StringName) -> float:
	var active = _find_active(debuff_id)
	if active == null:
		return 0.0
	return maxf(active.remaining_seconds, 0.0)


func get_move_speed_mult() -> float:
	var mult := 1.0
	for active in _active_debuffs:
		if active == null or active.data == null:
			continue
		if active.data.locks_movement:
			return 0.0
		if active.data.affects_move_speed():
			mult = minf(mult, active.data.move_speed_mult)
	return mult


func blocks_healing() -> bool:
	for active in _active_debuffs:
		if active != null and active.data != null and active.data.blocks_healing:
			return true
	return false


func blocks_stamina_regen() -> bool:
	for active in _active_debuffs:
		if active != null and active.data != null and active.data.blocks_stamina_regen:
			return true
	return false


func is_frozen() -> bool:
	for active in _active_debuffs:
		if active != null and active.data != null and active.data.locks_movement:
			return true
	return false


func _find_active(debuff_id: StringName):
	for active in _active_debuffs:
		if active != null and active.get_id() == debuff_id:
			return active
	return null


func _create_active_debuff(debuff_id: StringName, payload: Dictionary):
	var debuff_data = PlayerDebuffCatalogScript.get_debuff(debuff_id)
	if debuff_data == null:
		return null
	var active = ActivePlayerDebuffScript.new()
	active.setup(debuff_data, payload)
	return active


func _is_player_paused(player_context: Node) -> bool:
	if player_context == null:
		return false
	var tree := player_context.get_tree()
	return tree != null and tree.paused


func _should_skip_tick_effects(player_context: Node) -> bool:
	if player_context == null:
		return false
	if player_context.has_method(&"is_damage_immune"):
		return bool(player_context.call(&"is_damage_immune"))
	return false


func _advance_and_apply_dot(
	active,
	delta: float,
	player_context: Node
) -> void:
	if not active.data.provides_dot():
		return
	active.advance_dot_timer(delta)
	while active.is_dot_due() and active.remaining_seconds > 0.0:
		var tick_damage := _compute_dot_damage(active, player_context)
		if tick_damage > 0:
			_apply_dot_damage(player_context, tick_damage)
		active.consume_dot_tick()


func _compute_dot_damage(active, player_context: Node) -> int:
	var max_hp := _get_player_max_health(player_context)
	if max_hp <= 0.0:
		return 0
	return maxi(roundi(max_hp * active.data.dot_percent_max_hp / 100.0), 1)


func _apply_dot_damage(player_context: Node, tick_damage: int) -> void:
	if player_context == null or tick_damage <= 0:
		return
	if player_context.has_method(&"_apply_damage_taken"):
		player_context.call(&"_apply_damage_taken", tick_damage)


func _apply_expire_burst(active, player_context: Node) -> void:
	if not active.data.provides_expire_burst():
		return
	var snapshot_damage := int(active.payload.get("snapshot_damage", 0))
	var damage := roundi(float(snapshot_damage) * active.data.burst_damage_mult)
	if damage <= 0:
		return
	var origin := _get_player_burst_origin(player_context)
	DamageResolver.apply_burst_damage_to_player_in_radius(
		origin,
		active.data.burst_radius,
		damage
	)


func _get_player_max_health(player_context: Node) -> float:
	if player_context != null and player_context.has_method(&"get_max_health"):
		return float(player_context.call(&"get_max_health"))
	return 0.0


func _get_player_burst_origin(player_context: Node) -> Vector2:
	if player_context == null:
		return Vector2.ZERO
	if player_context is Node2D:
		if player_context.has_method(&"get_footprint_global_center"):
			return player_context.call(&"get_footprint_global_center") as Vector2
		return (player_context as Node2D).global_position
	return Vector2.ZERO
