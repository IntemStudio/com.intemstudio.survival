# GdUnit generated TestSuite
class_name EliteAffixApplierTest
extends GdUnitTestSuite

const MOB_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")


func _spawn_test_mob(base_health: int, contact_damage: int) -> Mob:
	var stub_player := Node2D.new()
	var root := get_tree().root
	var existing_game := root.get_node_or_null("Game")
	if existing_game != null:
		existing_game.free()
	var game := Node2D.new()
	game.name = "Game"
	stub_player.name = "Player"
	game.add_child(stub_player)
	root.add_child(game)
	auto_free(game)
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


func test_glacial_scales_hp_and_contact_damage() -> void:
	var mob := await _spawn_test_mob(100, 10)
	EliteAffixApplier.apply(mob, EliteAffixIds.GLACIAL)
	assert_int(mob.max_health).is_equal(400)
	assert_int(mob.health).is_equal(400)
	assert_int(mob.contact_attack_damage).is_equal(20)
	assert_int(mob.get_elite_pre_affix_attack_damage()).is_equal(10)
	assert_str(String(mob.get_elite_affix_id())).is_equal(String(EliteAffixIds.GLACIAL))


func test_pool_reset_clears_elite_affix() -> void:
	var mob := await _spawn_test_mob(100, 10)
	EliteAffixApplier.apply(mob, EliteAffixIds.GLACIAL)
	assert_bool(mob.has_elite_affix()).is_true()
	mob.pool_reset()
	assert_str(String(mob.get_elite_affix_id())).is_empty()
	assert_bool(mob.has_elite_affix()).is_false()
