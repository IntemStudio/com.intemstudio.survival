extends RefCounted
class_name MobSpawnSelector

const MOB_BASIC_SCENE: PackedScene = preload("res://entities/mob/mob.tscn")
const MOB_FAST_SCENE: PackedScene = preload("res://entities/mob/mob_fast.tscn")
const MOB_RANGED_SCENE: PackedScene = preload("res://entities/mob/mob_ranged.tscn")
const MOB_ELITE_SCENE: PackedScene = preload("res://entities/mob/mob_elite.tscn")
const MOB_BOSS_SCENE: PackedScene = preload("res://entities/mob/mob_boss.tscn")
const MOB_SPECIAL_A_SCENE: PackedScene = preload("res://entities/mob/mob_special_a.tscn")
const MOB_SPECIAL_B_SCENE: PackedScene = preload("res://entities/mob/mob_special_b.tscn")


# 밸런스 페이즈 비율로 스폰할 몹 프리팹을 고릅니다. (행동은 동일, 프리팹만 구분)
static func pick_scene(phase: BalancePhase) -> PackedScene:
	var roll := randf()
	var threshold := 0.0

	if phase.boss_spawn_enabled:
		threshold += phase.boss_spawn_ratio
		if roll < threshold:
			return MOB_BOSS_SCENE

	if phase.special_mob_count > 0:
		threshold += phase.special_spawn_ratio
		if roll < threshold:
			return _pick_special_scene(phase.special_mob_count)

	threshold += phase.fast_spawn_ratio
	if roll < threshold:
		return MOB_FAST_SCENE

	threshold += phase.ranged_spawn_ratio
	if roll < threshold:
		return MOB_RANGED_SCENE

	threshold += phase.elite_spawn_ratio
	if roll < threshold:
		return MOB_ELITE_SCENE

	return MOB_BASIC_SCENE


static func _pick_special_scene(special_mob_count: int) -> PackedScene:
	if special_mob_count >= 2 and randf() < 0.5:
		return MOB_SPECIAL_B_SCENE
	return MOB_SPECIAL_A_SCENE
