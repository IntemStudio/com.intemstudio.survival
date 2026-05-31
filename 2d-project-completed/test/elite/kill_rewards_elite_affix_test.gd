# GdUnit generated TestSuite
class_name KillRewardsEliteAffixTest
extends GdUnitTestSuite


func test_elite_affix_multiplies_xp_by_one_point_five() -> void:
	var phase := BalancePhase.new()
	var normal := KillRewards.compute(&"basic", phase, false)
	var elite := KillRewards.compute(&"basic", phase, true)
	assert_int(elite["xp"]).is_equal(maxi(1, roundi(float(normal["xp"]) * 1.5)))
