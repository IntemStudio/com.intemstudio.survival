class_name ScenePool
extends Node

const BULLET_SCENE := preload("res://weapons/core/bullet_2d.tscn")
const MELEE_SWIPE_SCENE := preload("res://weapons/melee/melee_swipe.tscn")
const MAGIC_BOLT_SCENE := preload("res://weapons/magic/magic_bolt.tscn")
const THROWING_PROJECTILE_SCENE := preload("res://weapons/throwing/throwing_projectile.tscn")
const BOOMERANG_SCENE := preload("res://weapons/boomerang/boomerang.tscn")
const KING_BIBLE_ORB_SCENE := preload("res://weapons/magic/king_bible_orb.tscn")
const EXP_ORB_SCENE := preload("res://effects/exp_orb/exp_orb.tscn")
const MOB_PROJECTILE_SCENE := preload("res://entities/mob/mob_projectile.tscn")
const MOB_ATTACK_MARK_SCENE := preload("res://entities/mob/mob_attack_mark.tscn")

@export_range(1, 1000, 1) var default_max_per_scene: int = 200
@export_range(0, 200, 1) var prewarm_bullets: int = 40
@export_range(0, 200, 1) var prewarm_magic_bolts: int = 24
@export_range(0, 200, 1) var prewarm_melee_swipes: int = 16
@export_range(0, 200, 1) var prewarm_throwing: int = 24
@export_range(0, 200, 1) var prewarm_boomerangs: int = 12
@export_range(0, 20, 1) var prewarm_king_bible_orbs: int = 2
@export_range(0, 500, 1) var prewarm_exp_orbs: int = 80
@export_range(0, 100, 1) var prewarm_mobs_per_type: int = 14
@export_range(0, 200, 1) var prewarm_mob_projectiles: int = 32
@export_range(0, 100, 1) var prewarm_mob_attack_marks: int = 20

var _inactive: Dictionary = {}
var _source_scenes: Dictionary = {}


func _ready() -> void:
	_prewarm_scene(BULLET_SCENE, prewarm_bullets)
	_prewarm_scene(MAGIC_BOLT_SCENE, prewarm_magic_bolts)
	_prewarm_scene(MELEE_SWIPE_SCENE, prewarm_melee_swipes)
	_prewarm_scene(THROWING_PROJECTILE_SCENE, prewarm_throwing)
	_prewarm_scene(BOOMERANG_SCENE, prewarm_boomerangs)
	_prewarm_scene(KING_BIBLE_ORB_SCENE, prewarm_king_bible_orbs)
	_prewarm_scene(EXP_ORB_SCENE, prewarm_exp_orbs)
	_prewarm_scene(MOB_PROJECTILE_SCENE, prewarm_mob_projectiles)
	_prewarm_scene(MOB_ATTACK_MARK_SCENE, prewarm_mob_attack_marks)
	# MobSpawnSelector 상수는 몹 씬→mob.gd를 끌어오므로, ScenePool 등록 후 _ready에서만 prewarm합니다.
	for mob_scene in [
		MobSpawnSelector.MOB_BASIC_SCENE,
		MobSpawnSelector.MOB_FAST_SCENE,
		MobSpawnSelector.MOB_RANGED_SCENE,
		MobSpawnSelector.MOB_ELITE_SCENE,
		MobSpawnSelector.MOB_BOSS_SCENE,
		MobSpawnSelector.MOB_SPECIAL_A_SCENE,
		MobSpawnSelector.MOB_SPECIAL_B_SCENE,
	]:
		_prewarm_scene(mob_scene, prewarm_mobs_per_type)


func prewarm(scene: PackedScene, count: int) -> void:
	_prewarm_scene(scene, count)


func acquire(scene: PackedScene, parent: Node) -> Node:
	var key := _scene_key(scene)
	var node: Node = _pop_inactive(key)

	if node == null:
		node = scene.instantiate()
		_register_node(node, key)

	if node.has_method("pool_reset"):
		node.pool_reset()
	if node.has_meta(&"_pool_return_pending"):
		node.remove_meta(&"_pool_return_pending")

	if parent and node.get_parent() != parent:
		if node.get_parent():
			node.get_parent().remove_child(node)
		parent.add_child(node)

	_activate(node)
	node.set_meta(&"_pooled_active", true)

	# 호출자 setup/위치 설정 전 마지막 훅 — 트리·process·Area2D 활성 이후 실행
	if node.has_method("pool_on_acquire"):
		node.pool_on_acquire()

	return node


func release(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.get_meta(&"_pool_return_pending", false):
		return
	node.set_meta(&"_pool_return_pending", true)

	if not node.get_meta(&"_pooled_active", false):
		# 이미 풀 대기 중이면 중복 반환(예: hit deferred + 사거리 release) 무시
		if node.get_parent() == self:
			if node.has_meta(&"_pool_return_pending"):
				node.remove_meta(&"_pool_return_pending")
			return
		var parent_name := str(node.get_parent().name) if node.get_parent() else "null"
		push_warning(
			"ScenePool.release: inactive node outside pool storage (parent=%s, path=%s)"
			% [parent_name, node.get_path()]
		)
		_remove_from_inactive(node)
		_discard_registered_node(node)
		node.queue_free()
		return

	var id := node.get_instance_id()
	if not _source_scenes.has(id):
		_remove_from_inactive(node)
		node.queue_free()
		return

	node.set_meta(&"_pooled_active", false)

	if node.has_method("pool_reset"):
		node.pool_reset()

	_deactivate(node)

	var key: String = _source_scenes[id]
	var arr: Array = _inactive.get(key, [])
	if arr.size() >= default_max_per_scene:
		_discard_registered_node(node)
		node.queue_free()
		return

	_attach_to_pool_storage(node)
	arr.append(node)
	_inactive[key] = arr


func _prewarm_scene(scene: PackedScene, count: int) -> void:
	if count <= 0:
		return
	var key := _scene_key(scene)
	for _i in count:
		var node := scene.instantiate()
		_register_node(node, key)
		if node.has_method("pool_reset"):
			node.pool_reset()
		_attach_to_pool_storage(node)
		_deactivate(node)
		_push_inactive(key, node)


func _pop_inactive(key: String) -> Node:
	var arr: Array = _inactive.get(key, [])
	while arr.size() > 0:
		var node = arr.pop_back()
		_inactive[key] = arr
		if is_instance_valid(node):
			return node as Node
	return null


func _push_inactive(key: String, node: Node) -> void:
	var arr: Array = _inactive.get(key, [])
	arr.append(node)
	_inactive[key] = arr


func _register_node(node: Node, key: String) -> void:
	_source_scenes[node.get_instance_id()] = key
	node.set_meta(&"_scene_pool", self)
	node.set_meta(&"_pool_scene_path", key)


func _discard_registered_node(node: Node) -> void:
	if is_instance_valid(node):
		_source_scenes.erase(node.get_instance_id())


func _remove_from_inactive(node: Node) -> void:
	var key := ""
	if is_instance_valid(node):
		var id := node.get_instance_id()
		if _source_scenes.has(id):
			key = _source_scenes[id]
	if key.is_empty() and node.has_meta(&"_pool_scene_path"):
		key = str(node.get_meta(&"_pool_scene_path"))
	if key.is_empty():
		return
	var arr: Array = _inactive.get(key, [])
	for i in range(arr.size() - 1, -1, -1):
		var entry = arr[i]
		if not is_instance_valid(entry) or entry == node:
			arr.remove_at(i)
	_inactive[key] = arr


func _scene_key(scene: PackedScene) -> String:
	return scene.resource_path


func _attach_to_pool_storage(node: Node) -> void:
	if node.get_parent() == self:
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)


func _activate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is CanvasItem:
		node.visible = true
	if node is Area2D:
		var area := node as Area2D
		area.set_deferred(&"monitoring", true)
		area.set_deferred(&"monitorable", true)


func _deactivate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		node.visible = false
	if node is Area2D:
		var area := node as Area2D
		area.monitoring = false
		area.monitorable = false
