class_name EliteEmberSpawner
extends RefCounted

## 불타는 affix 잔불 hazard — Game/ObjectPools 경유 스폰.

const EMBER_HAZARD_SCENE := preload("res://effects/elite_ember/elite_ember_hazard.tscn")
const _Constants := preload("res://elite/elite_blazing_constants.gd")


static func spawn_at(mob: Mob, world_position: Vector2) -> void:
	if mob == null:
		return
	var game := _find_game_root(mob)
	if game == null:
		return
	var pool := game.get_node_or_null("ObjectPools") as ScenePool
	var hazard: Node = null
	if pool:
		hazard = pool.acquire(
			EMBER_HAZARD_SCENE,
			game,
			world_position
		)
	else:
		hazard = EMBER_HAZARD_SCENE.instantiate()
		game.add_child(hazard)
		if hazard is Node2D:
			(hazard as Node2D).global_position = world_position
	if hazard == null:
		return
	if hazard.has_method(&"setup"):
		hazard.call(
			&"setup",
			_Constants.EMBER_LIFETIME_SEC,
			_Constants.EMBER_RADIUS_PX
		)


static func _find_game_root(mob: Mob) -> Node:
	var from_path := mob.get_node_or_null("/root/Game")
	if from_path != null:
		return from_path
	var current := mob.get_tree().current_scene if mob.get_tree() else null
	if current != null and current.has_node("ObjectPools"):
		return current
	return null
