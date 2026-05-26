class_name ItemRewardPicker
extends RefCounted

## 상자 보상 후보를 슬롯·등급·중복 조건으로 고릅니다.

const SLOT_ALL := &"all"
const ERROR_NO_CANDIDATE := &"chest.error.no_candidate"
const RARITY_ORDER: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]


static func pick_item(
	registry: ItemRegistry,
	loadout: PlayerLoadoutState,
	slot_filter: StringName,
	target_rarity: String,
	rng: RandomNumberGenerator
) -> Dictionary:
	if registry == null or loadout == null:
		return {"error": ERROR_NO_CANDIDATE, "item_id": "", "rarity": ""}
	var rarity_chain := _build_rarity_fallback_chain(target_rarity)
	for rarity in rarity_chain:
		var candidates := collect_candidates(registry, loadout, slot_filter, rarity)
		if candidates.is_empty():
			continue
		var index := rng.randi_range(0, candidates.size() - 1) if rng != null else randi_range(0, candidates.size() - 1)
		return {"error": &"", "item_id": candidates[index], "rarity": rarity}
	return {"error": ERROR_NO_CANDIDATE, "item_id": "", "rarity": ""}


static func has_candidate(
	registry: ItemRegistry,
	loadout: PlayerLoadoutState,
	slot_filter: StringName,
	target_rarity: String
) -> bool:
	if registry == null or loadout == null:
		return false
	for rarity in _build_rarity_fallback_chain(target_rarity):
		if not collect_candidates(registry, loadout, slot_filter, rarity).is_empty():
			return true
	return false


static func collect_candidates(
	registry: ItemRegistry,
	loadout: PlayerLoadoutState,
	slot_filter: StringName,
	rarity: String
) -> Array[String]:
	var candidates: Array[String] = []
	var ids := registry.get_all_item_ids()
	for item_id in ids:
		if loadout.contains_item_id(item_id):
			continue
		if not _matches_slot(registry, item_id, slot_filter):
			continue
		if registry.get_item_rarity(item_id) != _normalize_rarity(rarity):
			continue
		candidates.append(item_id)
	return candidates


static func get_rarity_fallback_chain(target_rarity: String) -> Array[String]:
	return _build_rarity_fallback_chain(target_rarity)


static func _matches_slot(registry: ItemRegistry, item_id: String, slot_filter: StringName) -> bool:
	if slot_filter == SLOT_ALL or String(slot_filter).is_empty():
		return true
	if not EquipSlots.is_valid_slot_key(slot_filter):
		return false
	return registry.get_item_reward_slot(item_id) == slot_filter


static func _build_rarity_fallback_chain(target_rarity: String) -> Array[String]:
	var target := _normalize_rarity(target_rarity)
	var index := RARITY_ORDER.find(target)
	if index < 0:
		var unknown_chain: Array[String] = [target]
		if target != "Common":
			unknown_chain.append("Common")
		return unknown_chain
	var chain: Array[String] = []
	for i in range(index, -1, -1):
		chain.append(RARITY_ORDER[i])
	return chain


static func _normalize_rarity(rarity: String) -> String:
	var value := rarity.strip_edges()
	return value if not value.is_empty() else "Common"
