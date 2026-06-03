class_name EliteAffixRuntimeBlazing
extends EliteAffixRuntime

## blazing affix — 피격·이동 잔불 시 플레이어 elite_burn.

const _Constants := preload("res://elite/elite_blazing_constants.gd")
const _EmberSpawner := preload("res://elite/elite_ember_spawner.gd")

var _last_ember_spawn_pos: Vector2 = Vector2.INF
var _ember_spawn_cooldown := 0.0


func begin(mob: Node2D) -> void:
	reset()
	if mob == null or not mob is Mob:
		return
	_last_ember_spawn_pos = (mob as Mob).get_footprint_global_center()


func reset() -> void:
	_last_ember_spawn_pos = Vector2.INF
	_ember_spawn_cooldown = 0.0


func tick(delta: float, mob: Node2D) -> void:
	if delta <= 0.0 or mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	var tree := mob_node.get_tree()
	if tree != null and tree.paused:
		return
	_ember_spawn_cooldown = maxf(_ember_spawn_cooldown - delta, 0.0)
	var center := mob_node.get_footprint_global_center()
	if _last_ember_spawn_pos == Vector2.INF:
		_last_ember_spawn_pos = center
		return
	if _last_ember_spawn_pos.distance_to(center) < _Constants.EMBER_MIN_MOVE_PX:
		return
	if _ember_spawn_cooldown > 0.0:
		return
	_EmberSpawner.spawn_at(mob_node, center)
	_last_ember_spawn_pos = center
	_ember_spawn_cooldown = _Constants.EMBER_SPAWN_INTERVAL_SEC


func on_hit_player(_raw_damage: int, mob: Node2D) -> void:
	if mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	if not is_instance_valid(mob_node.player):
		return
	if mob_node.player.has_method(&"apply_elite_debuff"):
		mob_node.player.call(&"apply_elite_debuff", _Constants.PLAYER_DEBUFF_ID, {})
