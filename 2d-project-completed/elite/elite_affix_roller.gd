class_name EliteAffixRoller
extends RefCounted

## mob kind·phase·보스·feature flag에 따라 affix id 또는 empty를 반환합니다.

const _EXCLUDED_MOB_KINDS: Array[StringName] = [&"dummy", &"special_a", &"special_b"]


static func roll(context: EliteAffixRollContext) -> StringName:
	if context == null:
		return &""

	var forced := context.force_affix_id
	if forced.is_empty():
		forced = EliteFeatureFlags.force_affix_id
	if not forced.is_empty():
		return _resolve_forced(forced)

	if _EXCLUDED_MOB_KINDS.has(context.mob_kind):
		return &""

	if not EliteFeatureFlags.affix_roll_enabled:
		return &""

	var pool := _build_enabled_pool()
	if pool.is_empty():
		return &""

	if context.is_boss:
		return pool[randi() % pool.size()]

	var roll_chance := _get_normal_spawn_chance(context.phase_minute)
	if roll_chance <= 0.0:
		return &""
	if randf() >= roll_chance:
		return &""

	return pool[randi() % pool.size()]


static func _resolve_forced(forced_id: StringName) -> StringName:
	var data := EliteAffixCatalog.get_affix(forced_id)
	if data == null or not data.enabled:
		push_warning("EliteAffixRoller: unknown or disabled forced affix '%s'" % String(forced_id))
		return &""
	return forced_id


static func _build_enabled_pool() -> Array[StringName]:
	var include_gilded := EliteFeatureFlags.gilded_enabled
	var pool := EliteAffixCatalog.get_tier1_roll_pool(include_gilded)
	var enabled: Array[StringName] = []
	for affix_id in pool:
		var data := EliteAffixCatalog.get_affix(affix_id)
		if data != null and data.enabled:
			enabled.append(affix_id)
	return enabled


# Wiki v0.1 p_normal 테이블 — BalancePhase 연동 전 임시.
static func _get_normal_spawn_chance(phase_minute: float) -> float:
	if phase_minute < 9.0:
		return 0.0
	if phase_minute < 11.0:
		return 0.03
	if phase_minute < 25.0:
		return 0.04
	return 0.05
