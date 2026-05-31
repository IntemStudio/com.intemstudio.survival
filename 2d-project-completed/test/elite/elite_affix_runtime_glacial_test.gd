# GdUnit generated TestSuite
class_name EliteAffixRuntimeGlacialTest
extends GdUnitTestSuite

const MOB_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")
const GlacialRuntimeScript = preload("res://elite/affix/elite_affix_runtime_glacial.gd")


class MockPlayerDebuffTarget extends Node2D:
	var applied_debuffs: Array[StringName] = []
	var projectile_damage: Array[int] = []

	func apply_elite_debuff(debuff_id: StringName, _payload: Dictionary = {}) -> void:
		applied_debuffs.append(debuff_id)

	func apply_mob_projectile_damage(amount: int) -> String:
		projectile_damage.append(amount)
		return ""

	func get_footprint_global_center() -> Vector2:
		return global_position


func _setup_game_player(player: Node2D) -> void:
	var root := get_tree().root
	var existing_game := root.get_node_or_null("Game")
	if existing_game != null:
		existing_game.free()
	var game := Node2D.new()
	game.name = "Game"
	player.name = "Player"
	game.add_child(player)
	root.add_child(game)
	auto_free(game)


func _spawn_test_mob(base_health: int, contact_damage: int) -> Mob:
	var stub_player := Node2D.new()
	_setup_game_player(stub_player)
	var mob: Mob = auto_free(MOB_SCENE.instantiate()) as Mob
	mob.base_max_health = base_health
	mob.contact_attack_damage = contact_damage
	mob.movement_enabled = false
	mob.combat_enabled = false
	mob.set_physics_process(false)
	add_child(mob)
	await await_idle_frame()
	mob.initialize_spawn_health(1.0)
	return mob


func test_pre_affix_snapshot_survives_glacial_scaling() -> void:
	var mob := await _spawn_test_mob(100, 10)
	EliteAffixApplier.apply(mob, EliteAffixIds.GLACIAL)
	assert_int(mob.get_elite_pre_affix_attack_damage()).is_equal(10)
	assert_int(mob.contact_attack_damage).is_equal(20)


func test_pool_reset_clears_pre_affix_snapshot() -> void:
	var mob := await _spawn_test_mob(100, 10)
	EliteAffixApplier.apply(mob, EliteAffixIds.GLACIAL)
	assert_int(mob.get_elite_pre_affix_attack_damage()).is_equal(10)
	mob.pool_reset()
	assert_int(mob.get_elite_pre_affix_attack_damage()).is_equal(0)


func test_registry_creates_glacial_runtime() -> void:
	var runtime := EliteAffixRuntimeRegistry.create_runtime(EliteAffixIds.GLACIAL)
	assert_object(runtime).is_not_null()
	assert_object(runtime.get_script()).is_same(GlacialRuntimeScript)


func test_on_hit_player_applies_chill() -> void:
	var mob := await _spawn_test_mob(100, 10)
	var mock_player := MockPlayerDebuffTarget.new()
	_setup_game_player(mock_player)
	mob.player = mock_player
	var runtime := GlacialRuntimeScript.new()
	runtime.on_hit_player(10, mob)
	assert_int(mock_player.applied_debuffs.size()).is_equal(1)
	assert_str(String(mock_player.applied_debuffs[0])).is_equal("elite_chill")


func test_on_death_schedules_neutral_burst_with_pre_affix_damage() -> void:
	var mob := await _spawn_test_mob(100, 10)
	EliteAffixApplier.apply(mob, EliteAffixIds.GLACIAL)
	var mock_player := MockPlayerDebuffTarget.new()
	_setup_game_player(mock_player)
	mock_player.global_position = mob.get_footprint_global_center()
	mob.player = mock_player
	var runtime := EliteAffixRuntimeRegistry.create_runtime(EliteAffixIds.GLACIAL)
	runtime.on_death(mob)
	await get_tree().create_timer(2.05).timeout
	assert_int(mock_player.projectile_damage.size()).is_equal(1)
	assert_int(mock_player.projectile_damage[0]).is_equal(15)
	assert_int(mock_player.applied_debuffs.size()).is_equal(1)
	assert_str(String(mock_player.applied_debuffs[0])).is_equal("elite_freeze")


func test_neutral_burst_damages_mob_in_radius() -> void:
	var mob := await _spawn_test_mob(100, 10)
	mob.add_to_group("mobs")
	mob.health = 100
	mob.max_health = 100
	var origin := mob.get_footprint_global_center()
	DamageResolver.apply_neutral_burst_in_radius(origin, 160.0, 15)
	assert_int(mob.health).is_equal(85)
