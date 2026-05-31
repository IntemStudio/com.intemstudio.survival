# GdUnit generated TestSuite
class_name MobChaseSkillEffectLandingBurstTest
extends GdUnitTestSuite


func test_apply_null_context_does_not_crash() -> void:
	var effect := MobChaseSkillEffectLandingBurst.new()
	effect.apply(null)


func test_apply_zero_damage_skips_resolution() -> void:
	var effect := MobChaseSkillEffectLandingBurst.new()
	var context := MobChaseSkillContext.new()
	context.landing_position = Vector2(100.0, 100.0)
	context.landing_burst_radius = 68.0
	context.landing_burst_damage = 0
	effect.apply(context)


func test_apply_zero_radius_skips_resolution() -> void:
	var effect := MobChaseSkillEffectLandingBurst.new()
	var context := MobChaseSkillContext.new()
	context.landing_position = Vector2(100.0, 100.0)
	context.landing_burst_radius = 0.0
	context.landing_burst_damage = 10
	effect.apply(context)
