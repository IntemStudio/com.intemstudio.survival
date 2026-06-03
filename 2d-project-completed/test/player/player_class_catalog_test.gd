# GdUnit generated TestSuite
class_name PlayerClassCatalogTest
extends GdUnitTestSuite


func test_catalog_has_three_classes() -> void:
	assert_int(PlayerClassCatalog.get_all().size()).is_equal(3)


func test_default_class_is_knight() -> void:
	assert_str(String(PlayerClassCatalog.get_default_class_id())).is_equal("knight")


func test_all_classes_share_base_max_health_at_level_one() -> void:
	for class_id in [&"knight", &"rogue", &"elementalist"]:
		var player_class := PlayerClassCatalog.get_by_id(class_id)
		assert_object(player_class).is_not_null()
		var stats := CharacterStats.new()
		stats.set_class_modifiers(player_class.build_stat_modifiers())
		assert_float(stats.get_max_health(1)).is_equal(110.0)


func test_knight_has_defense() -> void:
	var knight := PlayerClassCatalog.get_by_id(&"knight")
	assert_object(knight).is_not_null()
	assert_object(knight.visual_scene).is_not_null()
	assert_int(knight.base_defense).is_equal(20)
	var stats := CharacterStats.new()
	stats.set_class_modifiers(knight.build_stat_modifiers())
	var reduced := stats.mitigate_incoming_damage(100)
	assert_int(reduced).is_less(100)


func test_rogue_and_elementalist_have_no_defense() -> void:
	for class_id in [&"rogue", &"elementalist"]:
		var player_class := PlayerClassCatalog.get_by_id(class_id)
		assert_object(player_class).is_not_null()
		assert_int(player_class.base_defense).is_equal(0)


func test_max_health_scales_with_level() -> void:
	var knight := PlayerClassCatalog.get_by_id(&"knight")
	var stats := CharacterStats.new()
	stats.set_class_modifiers(knight.build_stat_modifiers())
	assert_float(stats.get_max_health(2)).is_equal(143.0)


func test_health_regen_scales_with_level() -> void:
	var rogue := PlayerClassCatalog.get_by_id(&"rogue")
	var stats := CharacterStats.new()
	stats.set_class_modifiers(rogue.build_stat_modifiers())
	assert_float(stats.get_health_regen_per_sec(1)).is_equal(1.0)
	assert_float(stats.get_health_regen_per_sec(2)).is_equal(1.2)


func test_run_config_rejects_unknown_class() -> void:
	RunConfig.set_player_class_id(&"unknown")
	assert_str(String(RunConfig.get_player_class_id())).is_equal("knight")
