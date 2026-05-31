# GdUnit generated TestSuite
class_name PlayerDebuffControllerTest
extends GdUnitTestSuite

const PlayerDebuffControllerScript = preload("res://elite/player_debuff_controller.gd")


class MockPlayerContext extends Node2D:
	var max_health := 100.0
	var damage_taken: Array[int] = []
	var projectile_damage_taken: Array[int] = []
	var damage_immune := false

	func get_max_health() -> float:
		return max_health

	func _apply_damage_taken(tick_damage: int, _add_to_contact_float: bool = false) -> void:
		damage_taken.append(tick_damage)

	func apply_mob_projectile_damage(amount: int) -> String:
		projectile_damage_taken.append(amount)
		return ""

	func is_damage_immune() -> bool:
		return damage_immune

	func add_weapon(_weapon: WeaponData) -> void:
		pass


func _make_controller() -> PlayerDebuffController:
	return PlayerDebuffControllerScript.new()


func _make_mock_player() -> MockPlayerContext:
	var root := get_tree().root
	var existing_game := root.get_node_or_null("Game")
	if existing_game != null:
		existing_game.free()
	var game := Node2D.new()
	game.name = "Game"
	var player := MockPlayerContext.new()
	player.name = "Player"
	game.add_child(player)
	root.add_child(game)
	auto_free(game)
	return player


func test_chill_move_speed_mult_and_expires() -> void:
	var controller := _make_controller()
	var player := _make_mock_player()
	controller.apply(&"elite_chill")
	assert_float(controller.get_move_speed_mult()).is_equal(0.2)
	controller.tick(1.6, player)
	assert_float(controller.get_move_speed_mult()).is_equal(1.0)
	assert_bool(controller.has_debuff(&"elite_chill")).is_false()


func test_burn_blocks_healing_and_stamina_regen() -> void:
	var controller := _make_controller()
	controller.apply(&"elite_burn")
	assert_bool(controller.blocks_healing()).is_true()
	assert_bool(controller.blocks_stamina_regen()).is_true()
	controller.tick(4.1)
	assert_bool(controller.blocks_healing()).is_false()
	assert_bool(controller.blocks_stamina_regen()).is_false()


func test_burn_applies_dot_damage() -> void:
	var controller := _make_controller()
	var player := _make_mock_player()
	player.max_health = 100.0
	controller.apply(&"elite_burn")
	controller.tick(0.49, player)
	assert_int(player.damage_taken.size()).is_equal(1)
	assert_int(player.damage_taken[0]).is_equal(5)


func test_bomb_expire_burst_applies_snapshot_damage() -> void:
	var controller := _make_controller()
	var player := _make_mock_player()
	player.global_position = Vector2(200.0, 200.0)
	controller.apply(&"elite_bomb", {"snapshot_damage": 40})
	controller.tick(1.6, player)
	assert_int(player.projectile_damage_taken.size()).is_equal(1)
	assert_int(player.projectile_damage_taken[0]).is_equal(20)


func test_refresh_resets_duration_and_updates_bomb_snapshot() -> void:
	var controller := _make_controller()
	var player := _make_mock_player()
	player.global_position = Vector2.ZERO
	controller.apply(&"elite_bomb", {"snapshot_damage": 10})
	controller.tick(1.0, player)
	assert_bool(controller.has_debuff(&"elite_bomb")).is_true()
	controller.apply(&"elite_bomb", {"snapshot_damage": 50})
	controller.tick(1.0, player)
	assert_bool(controller.has_debuff(&"elite_bomb")).is_true()
	controller.tick(0.6, player)
	assert_int(player.projectile_damage_taken.size()).is_equal(1)
	assert_int(player.projectile_damage_taken[0]).is_equal(25)


func test_dash_skips_dot_but_duration_still_decays() -> void:
	var controller := _make_controller()
	var player := _make_mock_player()
	player.max_health = 100.0
	player.damage_immune = true
	controller.apply(&"elite_burn")
	controller.tick(0.6, player)
	assert_int(player.damage_taken.size()).is_equal(0)
	assert_bool(controller.has_debuff(&"elite_burn")).is_true()
	player.damage_immune = false
	controller.tick(0.49, player)
	assert_int(player.damage_taken.size()).is_equal(1)


func test_freeze_locks_movement_gate() -> void:
	var controller := _make_controller()
	controller.apply(&"elite_freeze")
	assert_bool(controller.is_frozen()).is_true()
	assert_float(controller.get_move_speed_mult()).is_equal(0.0)
	controller.tick(1.6)
	assert_bool(controller.is_frozen()).is_false()
