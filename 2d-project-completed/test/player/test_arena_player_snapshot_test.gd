# GdUnit generated TestSuite
class_name TestArenaPlayerSnapshotTest
extends GdUnitTestSuite


func test_build_class_stat_modifiers_applies_session_mult() -> void:
	var snapshot := TestArenaPlayerSnapshot.new()
	snapshot.set_session_class_mult("rogue", "move_speed_mult", 1.25)
	var modifiers := snapshot.build_class_stat_modifiers("rogue")
	assert_float(float(modifiers["move_speed_mult"])).is_equal(1.25)


func test_bonus_percent_round_trip() -> void:
	var snapshot := TestArenaPlayerSnapshot.new()
	var mult := snapshot.bonus_percent_to_mult(12.0)
	assert_bool(is_equal_approx(snapshot.mult_to_bonus_percent(mult), 12.0)).is_true()


func test_reset_player_clears_session_mult() -> void:
	var snapshot := TestArenaPlayerSnapshot.new()
	snapshot.set_session_class_stat("knight", "move_speed_mult", 1.5)
	snapshot.reset_player()
	var modifiers := snapshot.build_class_stat_modifiers("knight")
	assert_float(float(modifiers["move_speed_mult"])).is_equal(1.0)


func test_default_weapon_id_session_and_reset() -> void:
	var snapshot := TestArenaPlayerSnapshot.new()
	snapshot.set_session_default_weapon_id("res://weapons/data/sword_1handed.tres")
	assert_str(snapshot.get_effective_default_weapon_id()).is_equal(
		"res://weapons/data/sword_1handed.tres"
	)
	snapshot.commit_session_to_saved()
	snapshot.set_session_default_weapon_id("res://weapons/data/bow.tres")
	assert_str(snapshot.get_effective_default_weapon_id()).is_equal("res://weapons/data/bow.tres")
	snapshot.reset_player()
	assert_str(snapshot.get_effective_default_weapon_id()).is_equal(
		"res://weapons/data/sword_1handed.tres"
	)


func test_build_class_stat_modifiers_applies_session_flat_stat() -> void:
	var snapshot := TestArenaPlayerSnapshot.new()
	snapshot.set_session_class_stat("knight", "base_defense", 30)
	var modifiers := snapshot.build_class_stat_modifiers("knight")
	assert_int(int(modifiers["armor_min"])).is_equal(30)
	assert_int(int(modifiers["armor_max"])).is_equal(30)
