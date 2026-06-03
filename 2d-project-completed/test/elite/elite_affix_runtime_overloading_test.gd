# GdUnit generated TestSuite
class_name EliteAffixRuntimeOverloadingTest
extends GdUnitTestSuite

const MOB_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")
const TEST_WEAPON: WeaponData = preload("res://weapons/data/katana.tres")


func _ensure_game_player_stub() -> void:
	var root := get_tree().root
	var existing_game := root.get_node_or_null("Game")
	if existing_game != null:
		existing_game.free()
	var game := Node2D.new()
	game.name = "Game"
	var player := Node2D.new()
	player.name = "Player"
	game.add_child(player)
	root.add_child(game)
	auto_free(game)


func _spawn_overloading_mob(base_health: int) -> Mob:
	_ensure_game_player_stub()
	var mob: Mob = auto_free(MOB_SCENE.instantiate()) as Mob
	mob.base_max_health = base_health
	mob.contact_attack_damage = 10
	mob.movement_enabled = false
	mob.combat_enabled = false
	mob.set_physics_process(false)
	add_child(mob)
	await await_idle_frame()
	mob.initialize_spawn_health(1.0)
	EliteAffixApplier.apply(mob, EliteAffixIds.OVERLOADING)
	return mob


func test_begin_sets_shield_to_half_max_health() -> void:
	var mob := await _spawn_overloading_mob(200)
	assert_int(mob.elite_shield_hp).is_equal(400)


func test_shield_absorbs_before_health() -> void:
	var mob := await _spawn_overloading_mob(100)
	var health_before := mob.health
	mob.apply_weapon_damage(50, TEST_WEAPON)
	assert_int(mob.elite_shield_hp).is_equal(150)
	assert_int(mob.health).is_equal(health_before)


func test_shield_recharges_after_delay() -> void:
	var mob := await _spawn_overloading_mob(100)
	mob.apply_weapon_damage(200, TEST_WEAPON)
	assert_int(mob.elite_shield_hp).is_equal(0)
	mob._elite_tick(7.1)
	mob._elite_tick(1.0)
	assert_int(mob.elite_shield_hp).is_equal(200)


func test_charge_end_burst_applies_bomb_debuff_on_hit() -> void:
	var root := get_tree().root
	var existing_game := root.get_node_or_null("Game")
	if existing_game != null:
		existing_game.free()
	var game := Node2D.new()
	game.name = "Game"
	var player := _ChargeBurstMockPlayer.new()
	player.name = "Player"
	game.add_child(player)
	root.add_child(game)
	auto_free(game)

	var mob: Mob = auto_free(MOB_SCENE.instantiate()) as Mob
	mob.base_max_health = 100
	mob.contact_attack_damage = 10
	mob.charge_end_burst_damage = 20
	mob.charge_end_burst_radius = 120.0
	mob.movement_enabled = false
	mob.combat_enabled = false
	mob.set_physics_process(false)
	add_child(mob)
	await await_idle_frame()
	mob.initialize_spawn_health(1.0)
	EliteAffixApplier.apply(mob, EliteAffixIds.OVERLOADING)
	mob.global_position = Vector2.ZERO
	player.global_position = Vector2.ZERO

	mob._end_charge_attack()

	assert_int(player.projectile_hits.size()).is_equal(1)
	assert_int(player.projectile_hits[0]).is_equal(20)
	assert_int(player.debuff_applied.size()).is_equal(1)
	assert_str(String(player.debuff_applied[0].get("id", ""))).is_equal("elite_bomb")
	assert_int(int(player.debuff_applied[0].get("payload", {}).get("snapshot_damage", 0))).is_equal(20)


class _ChargeBurstMockPlayer extends Node2D:
	var projectile_hits: Array[int] = []
	var debuff_applied: Array[Dictionary] = []

	func get_footprint_global_center() -> Vector2:
		return global_position

	func apply_mob_projectile_damage(amount: int) -> String:
		projectile_hits.append(amount)
		return ""

	func apply_elite_debuff(debuff_id: StringName, payload: Dictionary = {}) -> void:
		debuff_applied.append({"id": debuff_id, "payload": payload})
