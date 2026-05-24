class_name InventoryLoadoutSeed
extends RefCounted

## 테스트·디버그용 기본 로드아웃 — 메인 게임(F5)에는 적용하지 않음.


static func is_loadout_empty(state: PlayerLoadoutState) -> bool:
	for id in state.bag_ids:
		if not id.is_empty():
			return false
	for set_index in EquipSlots.SET_COUNT:
		for slot_key in EquipSlots.ALL:
			if not state.get_set_item_id(set_index, slot_key).is_empty():
				return false
	return true


static func apply_demo(state: PlayerLoadoutState) -> void:
	state.set_set_item_id(0, EquipSlots.WEAPON, "broken_hero_sword")
	state.set_set_item_id(0, EquipSlots.OFFHAND, "wooden_shield")
	state.set_bag_item_id(0, "bastard_sword")
	state.set_bag_item_id(1, "leather_tunic")
	state.set_bag_item_id(2, "traveler_boots")
