class_name EquipSlots
extends RefCounted

## 착용 슬롯 키·가방·장비 세트 크기 — UI·세이브·PlayerLoadoutState 공통.

const WEAPON := &"weapon"
const HELMET := &"helmet"
const ARMOR := &"armor"
const GLOVES := &"gloves"
const BOOTS := &"boots"
const OFFHAND := &"offhand"
const ACCESSORY := &"accessory"

const BAG_SIZE := 8
const SET_COUNT := 2
## 방어구·악세는 항상 sets[0] — UI·스탯 합산 공통.
const SHARED_ARMOR_SET_INDEX := 0

const ARMOR_STAT_SLOTS: Array[StringName] = [
	HELMET,
	ARMOR,
	GLOVES,
	BOOTS,
	ACCESSORY,
]

const ALL: Array[StringName] = [
	WEAPON,
	HELMET,
	ARMOR,
	GLOVES,
	BOOTS,
	OFFHAND,
	ACCESSORY,
]


# 빈 장비 세트(슬롯 키 → item_id, 비어 있으면 "").
static func create_empty_set() -> Dictionary:
	var set_dict: Dictionary = {}
	for slot_key in ALL:
		set_dict[slot_key] = ""
	return set_dict


static func is_valid_slot_key(slot_key: StringName) -> bool:
	return slot_key in ALL


static func slot_key_to_string(slot_key: StringName) -> String:
	return String(slot_key)
