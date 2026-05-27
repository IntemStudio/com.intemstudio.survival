class_name AccessorySynergy
extends RefCounted

## 활성 악세서리 + 보유 RunPassive 조합 보너스.

const RULES: Array[Dictionary] = [
	{
		"accessory_id": "hunter_charm",
		"passive_id": "hunter_instinct",
		"stats": {"damage_mult": 1.05},
	},
	{
		"accessory_id": "scout_medallion",
		"passive_id": "hunter_instinct",
		"stats": {"attack_speed_mult": 1.05},
	},
	{
		"accessory_id": "bamboo_bracelet",
		"passive_id": "steady_aim",
		"stats": {"ranged_damage_mult": 1.05},
	},
	{
		"accessory_id": "battle_crest",
		"passive_id": "wave_rider",
		"stats": {"heart_min": 1, "heart_max": 1},
	},
]


static func merge_synergy_bonus(
	accessory_ids: Array[String],
	run_state: PassiveRunState
) -> Dictionary:
	var totals: Dictionary = {}
	if run_state == null or accessory_ids.is_empty():
		return totals
	for rule in RULES:
		if not accessory_ids.has(rule["accessory_id"]):
			continue
		if run_state.get_level(String(rule["passive_id"])) <= 0:
			continue
		GearStatMerge.merge_into(totals, rule["stats"])
	return totals
