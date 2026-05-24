extends RefCounted
class_name KillRewards

## 몹 처치 시 XP·골드(2차) 보상을 한곳에서 계산합니다.

const GOLD_PER_XP := 0.5

const BASE_XP_BY_KIND: Dictionary = {
	&"basic": 1,
	&"fast": 1,
	&"ranged": 2,
	&"elite": 4,
	&"special_a": 5,
	&"special_b": 5,
	&"boss": 25,
	&"dummy": 0,
}


# 페이즈 loot_multiplier × mob_kind 기본 XP로 처치 보상을 반환합니다.
static func compute(mob_kind: StringName, phase: BalancePhase) -> Dictionary:
	var base_xp: int = int(BASE_XP_BY_KIND.get(mob_kind, BASE_XP_BY_KIND[&"basic"]))
	if base_xp <= 0:
		return {"xp": 0, "gold": 0}

	var loot_mult := 1.0
	if phase:
		loot_mult = maxf(phase.loot_multiplier, 0.01)

	var xp := maxi(1, roundi(float(base_xp) * loot_mult))
	var gold := maxi(0, roundi(float(xp) * GOLD_PER_XP))
	return {"xp": xp, "gold": gold}
