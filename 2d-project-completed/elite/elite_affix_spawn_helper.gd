class_name EliteAffixSpawnHelper
extends RefCounted

## Game·TestArena 공통 affix 롤·적용 진입점 — health init·튜닝 직후 호출.


static func apply_after_mob_ready(mob: Mob, context: EliteAffixRollContext) -> void:
	if mob == null or context == null:
		return
	var affix_id := EliteAffixRoller.roll(context)
	if affix_id.is_empty():
		return
	EliteAffixApplier.apply(mob, affix_id)
