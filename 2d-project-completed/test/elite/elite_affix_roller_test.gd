# GdUnit generated TestSuite
class_name EliteAffixRollerTest
extends GdUnitTestSuite


func test_excluded_mob_kinds_return_empty_when_roll_disabled() -> void:
	var previous_roll := EliteFeatureFlags.affix_roll_enabled
	var previous_force := EliteFeatureFlags.force_affix_id
	EliteFeatureFlags.affix_roll_enabled = false
	EliteFeatureFlags.force_affix_id = &""

	var context := EliteAffixRollContext.new()
	context.mob_kind = &"dummy"
	context.is_boss = true
	assert_str(EliteAffixRoller.roll(context)).is_empty()

	context.mob_kind = &"special_a"
	assert_str(EliteAffixRoller.roll(context)).is_empty()

	context.mob_kind = &"special_b"
	assert_str(EliteAffixRoller.roll(context)).is_empty()

	EliteFeatureFlags.affix_roll_enabled = previous_roll
	EliteFeatureFlags.force_affix_id = previous_force


func test_force_affix_id_returns_requested_id() -> void:
	var previous_force := EliteFeatureFlags.force_affix_id
	EliteFeatureFlags.force_affix_id = &""

	var context := EliteAffixRollContext.new()
	context.mob_kind = &"dummy"
	context.force_affix_id = EliteAffixIds.GLACIAL
	assert_str(EliteAffixRoller.roll(context)).is_equal(String(EliteAffixIds.GLACIAL))

	EliteFeatureFlags.force_affix_id = previous_force


func test_roll_disabled_without_force_returns_empty() -> void:
	var previous_roll := EliteFeatureFlags.affix_roll_enabled
	var previous_force := EliteFeatureFlags.force_affix_id
	EliteFeatureFlags.affix_roll_enabled = false
	EliteFeatureFlags.force_affix_id = &""

	var context := EliteAffixRollContext.new()
	context.mob_kind = &"basic"
	context.phase_minute = 12.0
	context.is_boss = true
	assert_str(EliteAffixRoller.roll(context)).is_empty()

	EliteFeatureFlags.affix_roll_enabled = previous_roll
	EliteFeatureFlags.force_affix_id = previous_force
