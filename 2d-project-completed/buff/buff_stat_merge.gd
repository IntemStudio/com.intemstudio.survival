class_name BuffStatMerge
extends RefCounted

## 활성 버프 stat_modifiers를 장비와 같은 합산 규칙으로 병합합니다.


static func merge_active_buffs(active_buffs: Array[ActiveBuff]) -> Dictionary:
	var totals: Dictionary = {}
	for buff in active_buffs:
		if buff == null or buff.data == null:
			continue
		for _i in buff.stacks:
			GearStatMerge.merge_into(totals, buff.data.stat_modifiers)
	return totals
