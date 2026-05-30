extends RefCounted
class_name DevTuningApplier

## F5/F6 공통 몹 튜닝 적용 — baseline + overrides 병합 후 Mob에 반영.


static func apply_mob_scene_tuning(mob: Mob, scene: PackedScene) -> void:
	if mob == null or scene == null:
		return
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	apply_mob_tuning(mob, scene, DevTuningStore.get_mob_authoring(scene_id))


# overrides만 넘기면 mob 현재 export를 baseline으로 씁니다( F5 authoring 전용 ).
static func apply_mob_tuning(
	mob: Mob,
	scene: PackedScene,
	overrides: Dictionary,
	baseline: Dictionary = {}
) -> void:
	if mob == null or scene == null or overrides.is_empty():
		return
	var stats: Dictionary = baseline if not baseline.is_empty() else _capture_stats_from_mob(mob)
	var normalized: Dictionary = _normalize_overrides(overrides, stats)
	_apply_overrides(stats, normalized)
	_clamp_ranged_damage(stats)
	_apply_stats_to_mob(mob, stats)
	if normalized.has("chase_mode"):
		mob.chase_mode = clampi(int(normalized["chase_mode"]), 0, 1) as Mob.ChaseMode
		mob.refresh_chase_strategy()


static func build_merged_stats(
	scene: PackedScene,
	baseline: Dictionary,
	authoring: Dictionary,
	session: Dictionary = {}
) -> Dictionary:
	var stats: Dictionary = baseline.duplicate(true)
	_apply_overrides(stats, _normalize_overrides(authoring, stats))
	_apply_overrides(stats, _normalize_overrides(session, stats))
	_clamp_ranged_damage(stats)
	return stats


# F6 — baseline+authoring+session 병합 결과를 Mob에 반영합니다.
static func apply_merged_stats_to_mob(mob: Mob, stats: Dictionary) -> void:
	if mob == null:
		return
	_apply_stats_to_mob(mob, stats)
	if stats.has("chase_mode"):
		mob.chase_mode = clampi(int(stats["chase_mode"]), 0, 1) as Mob.ChaseMode
		mob.refresh_chase_strategy()


static func _apply_stats_to_mob(mob: Mob, stats: Dictionary) -> void:
	for prop in TestArenaMobSnapshot.COMBAT_PROPERTIES:
		if stats.has(prop):
			mob.set(prop, stats[prop])
	if _supports_death_burst_tuning(mob):
		for prop in TestArenaMobSnapshot.DEATH_BURST_PROPERTIES:
			if stats.has(prop):
				mob.set(prop, stats[prop])
	if _supports_charge_tuning(mob):
		mob.charge_speed_mult = float(stats.get("charge_speed_mult", mob.charge_speed_mult))
		var target_distance := _charge_travel_distance_from_stats(stats)
		var denom := mob.speed * maxf(mob.charge_speed_mult, 0.01)
		mob.charge_duration = maxf(target_distance / maxf(denom, 0.01), 0.01)


static func _supports_death_burst_tuning(mob: Mob) -> bool:
	if mob.charge_attack_enabled:
		return false
	return mob.death_burst_enabled


static func _supports_charge_tuning(mob: Mob) -> bool:
	return mob.charge_attack_enabled


static func _capture_stats_from_mob(mob: Mob) -> Dictionary:
	var stats: Dictionary = {}
	for prop in TestArenaMobSnapshot.COMBAT_PROPERTIES:
		stats[prop] = mob.get(prop)
	if mob.death_burst_enabled:
		for prop in TestArenaMobSnapshot.DEATH_BURST_PROPERTIES:
			stats[prop] = mob.get(prop)
	if mob.charge_attack_enabled:
		for prop in TestArenaMobSnapshot.CHARGE_PROPERTIES:
			stats[prop] = mob.get(prop)
		stats["speed_min"] = mob.speed_min
		stats["speed_max"] = mob.speed_max
	return stats


static func _normalize_overrides(overrides: Dictionary, baseline: Dictionary) -> Dictionary:
	var normalized: Dictionary = overrides.duplicate(true)
	if normalized.has("ranged_damage"):
		var damage := int(roundf(float(normalized["ranged_damage"])))
		normalized.erase("ranged_damage")
		normalized["ranged_damage_min"] = damage
		normalized["ranged_damage_max"] = damage
	if normalized.has("charge_travel_distance"):
		var merged: Dictionary = baseline.duplicate(true)
		_apply_overrides(merged, normalized)
		normalized.erase("charge_travel_distance")
		normalized["charge_duration"] = _charge_duration_for_distance(
			merged,
			float(overrides["charge_travel_distance"])
		)
	return normalized


static func _apply_overrides(stats: Dictionary, overrides: Dictionary) -> void:
	for key in overrides:
		stats[key] = overrides[key]


static func _clamp_ranged_damage(stats: Dictionary) -> void:
	if int(stats.get("ranged_damage_max", 0)) < int(stats.get("ranged_damage_min", 0)):
		stats["ranged_damage_max"] = stats["ranged_damage_min"]


static func _reference_speed(stats: Dictionary) -> float:
	return (float(stats.get("speed_min", 0.0)) + float(stats.get("speed_max", 0.0))) * 0.5


static func _charge_travel_distance_from_stats(stats: Dictionary) -> float:
	return (
		_reference_speed(stats)
		* maxf(float(stats.get("charge_speed_mult", 1.0)), 0.01)
		* maxf(float(stats.get("charge_duration", 0.01)), 0.01)
	)


static func _charge_duration_for_distance(stats: Dictionary, distance: float) -> float:
	var denom := _reference_speed(stats) * maxf(float(stats.get("charge_speed_mult", 1.0)), 0.01)
	return maxf(distance / maxf(denom, 0.01), 0.01)
