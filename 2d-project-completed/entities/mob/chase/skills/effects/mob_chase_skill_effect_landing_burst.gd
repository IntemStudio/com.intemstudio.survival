class_name MobChaseSkillEffectLandingBurst
extends MobChaseSkillEffect

## 점프 추격 착지 시 반경 1회 피해 — 기술 본체와 분리된 해결 계층.


func apply(context: MobChaseSkillContext) -> void:
	if context == null:
		return
	DamageResolver.apply_burst_damage_to_player_in_radius(
		context.landing_position,
		context.landing_burst_radius,
		context.landing_burst_damage
	)
