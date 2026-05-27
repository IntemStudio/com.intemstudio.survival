class_name PassiveStatMerge
extends RefCounted

## PassiveRunState → GearStatMerge 규칙으로 합산 modifier.


static func merge_owned(
	run_state: PassiveRunState,
	accessory_ids: Array[String] = []
) -> Dictionary:
	var totals: Dictionary = {}
	if run_state == null:
		return totals
	for passive_id in run_state.get_owned_ids():
		var passive := PassiveCatalog.get_passive(passive_id)
		if passive == null:
			continue
		var level := run_state.get_level(passive_id)
		GearStatMerge.merge_into(totals, passive.get_cumulative_stat_modifiers(level))
		GearStatMerge.merge_into(totals, passive.get_cumulative_grant_modifiers(level))
	GearStatMerge.merge_into(totals, AccessorySynergy.merge_synergy_bonus(accessory_ids, run_state))
	return totals
