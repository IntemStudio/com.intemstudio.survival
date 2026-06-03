# GdUnit generated TestSuite
class_name RelicCombatBridgeTest
extends GdUnitTestSuite

const MOB_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")
const TEST_WEAPON: WeaponData = preload("res://weapons/data/katana.tres")
const RelicCombatBridgeScript = preload("res://inventory/relic_combat_bridge.gd")
const StatusEffectCatalogScript = preload("res://status/status_effect_catalog.gd")


class MockHealPlayer extends Node2D:
	var max_health := 200.0
	var health := 100.0
	var heal_calls: Array[float] = []

	func get_max_health() -> float:
		return max_health

	func heal_health(amount: float) -> void:
		heal_calls.append(amount)
		health = minf(health + amount, max_health)


func _ensure_game_player_stub() -> void:
	var root := get_tree().root
	if root.get_node_or_null("Game") != null:
		return
	var game := Node2D.new()
	game.name = "Game"
	var player := Node2D.new()
	player.name = "Player"
	game.add_child(player)
	root.add_child(game)
	auto_free(game)


func _spawn_mob() -> Mob:
	_ensure_game_player_stub()
	var mob: Mob = auto_free(MOB_SCENE.instantiate()) as Mob
	mob.base_max_health = 200
	mob.movement_enabled = false
	mob.combat_enabled = false
	mob.set_physics_process(false)
	add_child(mob)
	await await_idle_frame()
	mob.initialize_spawn_health(1.0)
	return mob


func after() -> void:
	RelicCombatBridgeScript.clear()


func test_blazing_relic_applies_relic_burn_on_hit() -> void:
	var loadout := PlayerLoadoutState.create_empty()
	loadout.set_bag_item_id(0, "relic_blazing")
	RelicCombatBridgeScript.refresh_from_bag(loadout)
	var mob := await _spawn_mob()
	RelicCombatBridgeScript.on_weapon_hit_mob(mob, TEST_WEAPON, 20)
	assert_bool(mob._status_effects.has_status(&"relic_burn")).is_true()
	var burn_data := StatusEffectCatalogScript.get_status(&"relic_burn")
	assert_float(burn_data.tick_percent_max_hp).is_equal(2.5)


func test_mending_relic_heals_every_three_seconds() -> void:
	var player := MockHealPlayer.new()
	add_child(player)
	var loadout := PlayerLoadoutState.create_empty()
	loadout.set_bag_item_id(0, "relic_mending")
	RelicCombatBridgeScript.refresh_from_bag(loadout)
	RelicCombatBridgeScript.tick(3.0, player)
	assert_int(player.heal_calls.size()).is_equal(1)
	assert_float(player.heal_calls[0]).is_equal(2.0)
