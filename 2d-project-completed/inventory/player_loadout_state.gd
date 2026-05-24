class_name PlayerLoadoutState
extends RefCounted

## 플레이어 인벤 상태 — 세이브·런타임에 item_id만 보관.

var active_set_index: int = 0
var sets: Array[Dictionary] = []
var bag_ids: Array[String] = []


static func create_empty() -> PlayerLoadoutState:
	var state := PlayerLoadoutState.new()
	state.active_set_index = 0
	state.sets.clear()
	for _i in EquipSlots.SET_COUNT:
		state.sets.append(EquipSlots.create_empty_set())
	state.bag_ids.clear()
	for _i in EquipSlots.BAG_SIZE:
		state.bag_ids.append("")
	return state


func duplicate_state() -> PlayerLoadoutState:
	var copy := PlayerLoadoutState.new()
	copy.active_set_index = active_set_index
	copy.sets = sets.duplicate(true)
	copy.bag_ids = bag_ids.duplicate()
	return copy


func get_active_set() -> Dictionary:
	return get_set(active_set_index)


func get_set(set_index: int) -> Dictionary:
	if set_index < 0 or set_index >= sets.size():
		return EquipSlots.create_empty_set()
	return sets[set_index]


func get_set_item_id(set_index: int, slot_key: StringName) -> String:
	var set_dict := get_set(set_index)
	if set_dict.has(slot_key):
		return String(set_dict[slot_key])
	var slot_str := EquipSlots.slot_key_to_string(slot_key)
	return String(set_dict.get(slot_str, ""))


func set_set_item_id(set_index: int, slot_key: StringName, item_id: String) -> void:
	if set_index < 0 or set_index >= sets.size():
		return
	if not EquipSlots.is_valid_slot_key(slot_key):
		return
	sets[set_index][slot_key] = _normalize_item_id(item_id)


func get_bag_item_id(bag_index: int) -> String:
	if bag_index < 0 or bag_index >= bag_ids.size():
		return ""
	return bag_ids[bag_index]


func set_bag_item_id(bag_index: int, item_id: String) -> void:
	if bag_index < 0 or bag_index >= bag_ids.size():
		return
	bag_ids[bag_index] = _normalize_item_id(item_id)


func find_first_empty_bag_index() -> int:
	for i in bag_ids.size():
		if bag_ids[i].is_empty():
			return i
	return -1


# item_id가 가방·어느 세트 슬롯에 있는지 찾습니다. 없으면 null.
func find_item_location(item_id: String) -> Variant:
	var key := _normalize_item_id(item_id)
	if key.is_empty():
		return null
	for bag_index in bag_ids.size():
		if bag_ids[bag_index] == key:
			return {"kind": &"bag", "bag_index": bag_index}
	for set_index in sets.size():
		var set_dict: Dictionary = sets[set_index]
		for slot_key in EquipSlots.ALL:
			if String(set_dict.get(slot_key, "")) == key:
				return {"kind": &"set", "set_index": set_index, "slot_key": slot_key}
	return null


func contains_item_id(item_id: String) -> bool:
	return find_item_location(item_id) != null


func toggle_active_set_index() -> void:
	active_set_index = 1 - clampi(active_set_index, 0, 1)


func set_active_set_index(index: int) -> void:
	active_set_index = clampi(index, 0, EquipSlots.SET_COUNT - 1)


static func _normalize_item_id(item_id: String) -> String:
	return item_id.strip_edges()
