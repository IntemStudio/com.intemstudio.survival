# GdUnit generated TestSuite
class_name EliteAffixRuntimeBlazingTest
extends GdUnitTestSuite

const MOB_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")
const BlazingRuntimeScript = preload("res://elite/affix/elite_affix_runtime_blazing.gd")
const ScenePoolScript = preload("res://game/pool/scene_pool.gd")
const EmberHazardScript = preload("res://effects/elite_ember/elite_ember_hazard.gd")


class MockPlayerDebuffTarget extends Node2D:
	var applied_debuffs: Array[StringName] = []

	func apply_elite_debuff(debuff_id: StringName, _payload: Dictionary = {}) -> void:
		applied_debuffs.append(debuff_id)


func _setup_game_player(player: Node2D, with_object_pools: bool = false) -> Node2D:
	var root := get_tree().root
	var existing_game := root.get_node_or_null("Game")
	if existing_game != null:
		existing_game.free()
	var game := Node2D.new()
	game.name = "Game"
	if with_object_pools:
		var pools := ScenePoolScript.new()
		pools.name = "ObjectPools"
		game.add_child(pools)
	player.name = "Player"
	game.add_child(player)
	root.add_child(game)
	auto_free(game)
	return game


func _count_ember_hazards(game: Node) -> int:
	var count := 0
	for child in game.get_children():
		if child.get_script() == EmberHazardScript:
			count += 1
	return count


func _spawn_blazing_mob(
	base_health: int,
	contact_damage: int,
	with_object_pools: bool = false,
	setup_game_stubs: bool = true
) -> Mob:
	if setup_game_stubs:
		var stub_player := Node2D.new()
		_setup_game_player(stub_player, with_object_pools)
	var mob: Mob = auto_free(MOB_SCENE.instantiate()) as Mob
	mob.base_max_health = base_health
	mob.contact_attack_damage = contact_damage
	mob.movement_enabled = false
	mob.combat_enabled = false
	mob.set_physics_process(false)
	add_child(mob)
	await await_idle_frame()
	mob.initialize_spawn_health(1.0)
	EliteAffixApplier.apply(mob, EliteAffixIds.BLAZING)
	return mob


func test_registry_creates_blazing_runtime() -> void:
	var runtime := EliteAffixRuntimeRegistry.create_runtime(EliteAffixIds.BLAZING)
	assert_object(runtime).is_not_null()
	assert_object(runtime.get_script()).is_same(BlazingRuntimeScript)


func test_blazing_scales_hp_and_contact_damage() -> void:
	var mob := await _spawn_blazing_mob(100, 10)
	assert_int(mob.max_health).is_equal(400)
	assert_int(mob.health).is_equal(400)
	assert_int(mob.contact_attack_damage).is_equal(20)
	assert_str(String(mob.get_elite_affix_id())).is_equal(String(EliteAffixIds.BLAZING))


func test_on_hit_player_applies_burn() -> void:
	var mob := await _spawn_blazing_mob(100, 10)
	var mock_player := MockPlayerDebuffTarget.new()
	_setup_game_player(mock_player)
	mob.player = mock_player
	var runtime := BlazingRuntimeScript.new()
	runtime.on_hit_player(10, mob)
	assert_int(mock_player.applied_debuffs.size()).is_equal(1)
	assert_str(String(mock_player.applied_debuffs[0])).is_equal("elite_burn")


func test_elite_on_hit_player_applies_burn() -> void:
	var mob := await _spawn_blazing_mob(100, 10)
	var mock_player := MockPlayerDebuffTarget.new()
	_setup_game_player(mock_player)
	mob.player = mock_player
	mob._elite_on_hit_player(15)
	assert_int(mock_player.applied_debuffs.size()).is_equal(1)
	assert_str(String(mock_player.applied_debuffs[0])).is_equal("elite_burn")


func test_pool_reset_clears_blazing_affix() -> void:
	var mob := await _spawn_blazing_mob(100, 10)
	assert_str(String(mob.get_elite_affix_id())).is_equal(String(EliteAffixIds.BLAZING))
	mob.pool_reset()
	assert_str(String(mob.get_elite_affix_id())).is_equal("")
	assert_object(EliteAffixRuntimeRegistry.create_runtime(EliteAffixIds.BLAZING).get_script()).is_same(
		BlazingRuntimeScript
	)


func test_tick_spawns_ember_after_move() -> void:
	var game := _setup_game_player(Node2D.new(), false)
	var mob := await _spawn_blazing_mob(100, 10, false, false)
	var start_pos := mob.global_position
	mob.global_position = start_pos + Vector2(80.0, 0.0)
	await await_idle_frame()
	mob._elite_tick(0.25)
	assert_that(_count_ember_hazards(game)).is_greater_equal(1)


func test_tick_does_not_spawn_ember_without_move() -> void:
	var game := _setup_game_player(Node2D.new(), false)
	var mob := await _spawn_blazing_mob(100, 10, false, false)
	for _tick_index in 5:
		mob._elite_tick(0.25)
	assert_int(_count_ember_hazards(game)).is_equal(0)
