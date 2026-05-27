class_name InventoryService
extends RefCounted

## 인벤 상태 변경 — UI·전투는 이 API만 호출.

const ERROR_EMPTY := &"inventory.error.empty"
const ERROR_INVALID_SLOT := &"inventory.error.invalid_slot"
const ERROR_BAG_FULL := &"inventory.error.bag_full"
const ERROR_OFFHAND_BLOCKED := &"inventory.error.offhand_blocked"
const ERROR_UNKNOWN_ITEM := &"inventory.error.unknown_item"
const ERROR_CROSS_SET := &"inventory.error.cross_set"
const ERROR_TWO_HAND_BAG_FULL := &"inventory.error.two_hand_bag_full"
const ERROR_DROP_UNAVAILABLE := &"inventory.error.drop_unavailable"

var registry: ItemRegistry
var loadout: PlayerLoadoutState

var _edit_set_index := 0


func _init(
	registry_ref: ItemRegistry = null,
	loadout_ref: PlayerLoadoutState = null
) -> void:
	registry = registry_ref if registry_ref else ItemRegistry.new()
	loadout = loadout_ref if loadout_ref else PlayerLoadoutState.create_empty()
	if registry_ref == null:
		registry.register_all_catalogs()


func get_edit_set_index() -> int:
	return _edit_set_index


func set_edit_set_index(index: int) -> void:
	_edit_set_index = clampi(index, 0, EquipSlots.SET_COUNT - 1)


func swap_equip_sets() -> void:
	loadout.toggle_active_set_index()


func set_active_combat_set(index: int) -> void:
	loadout.set_active_set_index(index)


# 슬롯 설명자가 가리키는 item_id를 조회합니다.
func get_item_id_at(source: Dictionary) -> String:
	var source_kind: StringName = source.get("kind", &"")
	if source_kind == &"bag":
		var bag_index: int = source.get("bag_index", -1)
		if bag_index < 0 or bag_index >= loadout.bag_ids.size():
			return ""
		return loadout.get_bag_item_id(bag_index)
	if source_kind == &"set":
		var set_index: int = source.get("set_index", -1)
		var slot_key: StringName = source.get("slot_key", &"")
		if set_index < 0 or set_index >= loadout.sets.size():
			return ""
		if not EquipSlots.is_valid_slot_key(slot_key):
			return ""
		return loadout.get_set_item_id(set_index, slot_key)
	return ""


# 슬롯 설명자가 가리키는 장비를 인벤 상태에서 제거합니다.
func try_discard(source: Dictionary) -> StringName:
	var source_kind: StringName = source.get("kind", &"")
	if source_kind == &"bag":
		var bag_index: int = source.get("bag_index", -1)
		if bag_index < 0 or bag_index >= loadout.bag_ids.size():
			return ERROR_INVALID_SLOT
		if loadout.get_bag_item_id(bag_index).is_empty():
			return ERROR_EMPTY
		loadout.set_bag_item_id(bag_index, "")
		return &""
	if source_kind == &"set":
		var set_index: int = source.get("set_index", -1)
		var slot_key: StringName = source.get("slot_key", &"")
		if set_index < 0 or set_index >= loadout.sets.size():
			return ERROR_INVALID_SLOT
		if not EquipSlots.is_valid_slot_key(slot_key):
			return ERROR_INVALID_SLOT
		if loadout.get_set_item_id(set_index, slot_key).is_empty():
			return ERROR_EMPTY
		loadout.set_set_item_id(set_index, slot_key, "")
		return &""
	return ERROR_INVALID_SLOT


# 실패 롤백용 — 버리기 직전 슬롯에 같은 item_id를 되돌립니다.
func try_restore_item_at(target: Dictionary, item_id: String) -> StringName:
	var key := item_id.strip_edges()
	if key.is_empty():
		return ERROR_UNKNOWN_ITEM
	var target_kind: StringName = target.get("kind", &"")
	if target_kind == &"bag":
		var bag_index: int = target.get("bag_index", -1)
		if bag_index < 0 or bag_index >= loadout.bag_ids.size():
			return ERROR_INVALID_SLOT
		if not loadout.get_bag_item_id(bag_index).is_empty():
			return ERROR_INVALID_SLOT
		loadout.set_bag_item_id(bag_index, key)
		return &""
	if target_kind == &"set":
		var set_index: int = target.get("set_index", -1)
		var slot_key: StringName = target.get("slot_key", &"")
		if set_index < 0 or set_index >= loadout.sets.size():
			return ERROR_INVALID_SLOT
		if not EquipSlots.is_valid_slot_key(slot_key):
			return ERROR_INVALID_SLOT
		if not loadout.get_set_item_id(set_index, slot_key).is_empty():
			return ERROR_INVALID_SLOT
		loadout.set_set_item_id(set_index, slot_key, key)
		return &""
	return ERROR_INVALID_SLOT


# 테스트 아레나 등 — 활성 세트 무기를 교체합니다. 기존 무기는 삭제하고 새 무기를 슬롯에 둡니다.
func try_force_equip_weapon_on_active_set(item_id: String) -> StringName:
	var key := item_id.strip_edges()
	if key.is_empty() or not registry.has_item(key):
		return ERROR_UNKNOWN_ITEM
	if not registry.can_item_occupy_slot(key, EquipSlots.WEAPON):
		return ERROR_INVALID_SLOT

	var set_index := loadout.active_set_index
	var current_weapon_id := loadout.get_set_item_id(set_index, EquipSlots.WEAPON)
	if current_weapon_id == key:
		return &""

	if not current_weapon_id.is_empty():
		loadout.set_set_item_id(set_index, EquipSlots.WEAPON, "")

	if registry.is_two_handed_weapon(key):
		var offhand_id := loadout.get_set_item_id(set_index, EquipSlots.OFFHAND)
		if not offhand_id.is_empty():
			loadout.set_set_item_id(set_index, EquipSlots.OFFHAND, "")

	_remove_item_id_from_loadout(key)
	loadout.set_set_item_id(set_index, EquipSlots.WEAPON, key)
	return &""


# 획득 아이템을 규칙에 따라 장착 슬롯 또는 가방에 자동 배치합니다.
func acquire_item(item_id: String) -> StringName:
	var key := item_id.strip_edges()
	if key.is_empty() or not registry.has_item(key):
		return ERROR_UNKNOWN_ITEM
	if loadout.contains_item_id(key):
		return &""

	var slot_key := _resolve_equip_slot_for_item(key)
	if slot_key.is_empty():
		return ERROR_INVALID_SLOT
	if slot_key == EquipSlots.WEAPON:
		return _acquire_weapon_item(key)
	if slot_key == EquipSlots.OFFHAND:
		return _acquire_offhand_item(key)
	if _is_shared_armor_slot(slot_key):
		return _acquire_shared_armor_item(key, slot_key)
	return _place_item_in_bag(key)


func can_acquire_item(item_id: String) -> StringName:
	var preview := InventoryService.new(registry, loadout.duplicate_state())
	return preview.acquire_item(item_id)


# 드롭 가능 여부(UI 하이라이트용) — 상태 변경 없음.
func can_drop(source: Dictionary, target: Dictionary) -> bool:
	return try_drop(source, target, true).is_empty()


# 가방 칸 → 지정 세트·슬롯에 장착합니다. 성공 시 "".
func try_equip_from_bag(bag_index: int, set_index: int, slot_key: StringName) -> StringName:
	var item_id := loadout.get_bag_item_id(bag_index)
	if item_id.is_empty():
		return ERROR_EMPTY
	if not registry.has_item(item_id):
		return ERROR_UNKNOWN_ITEM
	if not registry.can_item_occupy_slot(item_id, slot_key):
		return ERROR_INVALID_SLOT
	if slot_key == EquipSlots.OFFHAND:
		var weapon_id := loadout.get_set_item_id(set_index, EquipSlots.WEAPON)
		if registry.is_offhand_blocked_by_weapon(weapon_id):
			return ERROR_OFFHAND_BLOCKED

	var displaced := loadout.get_set_item_id(set_index, slot_key)
	var offhand_id := ""
	if slot_key == EquipSlots.WEAPON and registry.is_two_handed_weapon(item_id):
		offhand_id = loadout.get_set_item_id(set_index, EquipSlots.OFFHAND)

	var to_bag: Array[String] = []
	if not displaced.is_empty() and displaced != item_id:
		to_bag.append(displaced)
	if not offhand_id.is_empty() and offhand_id != item_id:
		to_bag.append(offhand_id)

	var bag_targets := _collect_bag_targets(bag_index, to_bag.size())
	if bag_targets.size() < to_bag.size():
		return ERROR_BAG_FULL

	if not _dry_run:
		loadout.set_bag_item_id(bag_index, "")
		for i in to_bag.size():
			loadout.set_bag_item_id(bag_targets[i], to_bag[i])
		loadout.set_set_item_id(set_index, slot_key, item_id)
		if slot_key == EquipSlots.WEAPON and registry.is_two_handed_weapon(item_id):
			loadout.set_set_item_id(set_index, EquipSlots.OFFHAND, "")
	return &""


# 장비 슬롯 → 가방 빈 칸.
func try_unequip(set_index: int, slot_key: StringName) -> StringName:
	var item_id := loadout.get_set_item_id(set_index, slot_key)
	if item_id.is_empty():
		return &""
	var bag_index := loadout.find_first_empty_bag_index()
	if bag_index < 0:
		return ERROR_BAG_FULL
	if not _dry_run:
		loadout.set_bag_item_id(bag_index, item_id)
		loadout.set_set_item_id(set_index, slot_key, "")
	return &""


# 가방 칸끼리 교환.
func try_swap_bag(bag_a: int, bag_b: int) -> void:
	if bag_a == bag_b or _dry_run:
		return
	var id_a := loadout.get_bag_item_id(bag_a)
	var id_b := loadout.get_bag_item_id(bag_b)
	loadout.set_bag_item_id(bag_a, id_b)
	loadout.set_bag_item_id(bag_b, id_a)


# 드래그 드롭 — 소스·대상 슬롯 규칙에 맞게 위임.
func try_drop(
	source: Dictionary,
	target: Dictionary,
	dry_run: bool = false
) -> StringName:
	var prev_dry := _dry_run
	_dry_run = dry_run
	var result := _try_drop_impl(source, target)
	_dry_run = prev_dry
	return result


var _dry_run := false


func _try_drop_impl(source: Dictionary, target: Dictionary) -> StringName:
	var source_kind: StringName = source.get("kind", &"")
	var target_kind: StringName = target.get("kind", &"")
	if source_kind == &"bag" and target_kind == &"bag":
		try_swap_bag(source["bag_index"], target["bag_index"])
		return &""
	if source_kind == &"bag" and target_kind == &"set":
		return try_equip_from_bag(
			source["bag_index"],
			target["set_index"],
			target["slot_key"]
		)
	if source_kind == &"set" and target_kind == &"bag":
		var set_index: int = source["set_index"]
		var slot_key: StringName = source["slot_key"]
		var bag_index: int = target["bag_index"]
		if not loadout.get_bag_item_id(bag_index).is_empty():
			return try_swap_set_and_bag(set_index, slot_key, bag_index)
		return try_unequip_to_bag_index(set_index, slot_key, bag_index)
	if source_kind == &"set" and target_kind == &"set":
		return try_swap_set_slots(
			source["set_index"],
			source["slot_key"],
			target["set_index"],
			target["slot_key"]
		)
	return ERROR_INVALID_SLOT


func try_unequip_to_bag_index(set_index: int, slot_key: StringName, bag_index: int) -> StringName:
	var item_id := loadout.get_set_item_id(set_index, slot_key)
	if item_id.is_empty():
		return &""
	if not loadout.get_bag_item_id(bag_index).is_empty():
		return ERROR_BAG_FULL
	if not _dry_run:
		loadout.set_bag_item_id(bag_index, item_id)
		loadout.set_set_item_id(set_index, slot_key, "")
	return &""


func try_swap_set_and_bag(set_index: int, slot_key: StringName, bag_index: int) -> StringName:
	var set_item := loadout.get_set_item_id(set_index, slot_key)
	var bag_item := loadout.get_bag_item_id(bag_index)
	if set_item.is_empty() and bag_item.is_empty():
		return &""
	if set_item.is_empty():
		return try_equip_from_bag(bag_index, set_index, slot_key)
	if bag_item.is_empty():
		return try_unequip_to_bag_index(set_index, slot_key, bag_index)
	return try_equip_from_bag(bag_index, set_index, slot_key)


func try_swap_set_slots(
	set_a: int,
	slot_a: StringName,
	set_b: int,
	slot_b: StringName
) -> StringName:
	if set_a != set_b:
		return ERROR_CROSS_SET
	var id_a := loadout.get_set_item_id(set_a, slot_a)
	var id_b := loadout.get_set_item_id(set_b, slot_b)
	if not id_a.is_empty() and not registry.can_item_occupy_slot(id_a, slot_b):
		return ERROR_INVALID_SLOT
	if not id_b.is_empty() and not registry.can_item_occupy_slot(id_b, slot_a):
		return ERROR_INVALID_SLOT

	var weapon_after := _weapon_id_after_swap(set_a, slot_a, slot_b, id_a, id_b)
	if registry.is_offhand_blocked_by_weapon(weapon_after):
		if slot_a == EquipSlots.OFFHAND or slot_b == EquipSlots.OFFHAND:
			return ERROR_OFFHAND_BLOCKED
	var err := _validate_two_handed_offhand_clear(set_a, weapon_after)
	if not err.is_empty():
		return err

	if _dry_run:
		return &""

	loadout.set_set_item_id(set_a, slot_a, id_b)
	loadout.set_set_item_id(set_b, slot_b, id_a)
	if registry.is_two_handed_weapon(weapon_after):
		var offhand_id := loadout.get_set_item_id(set_a, EquipSlots.OFFHAND)
		if not offhand_id.is_empty():
			var bag_index := loadout.find_first_empty_bag_index()
			loadout.set_bag_item_id(bag_index, offhand_id)
			loadout.set_set_item_id(set_a, EquipSlots.OFFHAND, "")
	return &""


# 가방 → try_equip_from_bag_smart 위임(무기·보조=active_set, 방어구=SHARED 0).
func try_auto_equip_from_bag(bag_index: int) -> StringName:
	return try_equip_from_bag_smart(bag_index, 0)


# 가방 → 적합 슬롯 자동 장착(교체). 무기·보조는 combat_set, 방어구는 armor_set_index.
func try_equip_from_bag_smart(bag_index: int, armor_set_index: int) -> StringName:
	var item_id := loadout.get_bag_item_id(bag_index)
	if item_id.is_empty():
		return ERROR_EMPTY
	if not registry.has_item(item_id):
		return ERROR_UNKNOWN_ITEM

	var slot_key := _resolve_equip_slot_for_item(item_id)
	if slot_key.is_empty():
		return ERROR_INVALID_SLOT

	var set_index := loadout.active_set_index
	if _is_shared_armor_slot(slot_key):
		set_index = armor_set_index

	var source := {"kind": &"bag", "bag_index": bag_index, "item_id": item_id}
	var target := {
		"kind": &"set",
		"set_index": set_index,
		"slot_key": slot_key,
	}
	var dry_err := try_drop(source, target, true)
	if not dry_err.is_empty():
		if (
			dry_err == ERROR_BAG_FULL
			and slot_key == EquipSlots.WEAPON
			and registry.is_two_handed_weapon(item_id)
			and _combat_weapon_and_offhand_occupied(set_index)
		):
			return ERROR_TWO_HAND_BAG_FULL
		return dry_err

	return try_equip_from_bag(bag_index, set_index, slot_key)


func _resolve_equip_slot_for_item(item_id: String) -> StringName:
	# 다중 슬롯 아이템은 GearData.gear_slot 지정 권장(미지정 시 EquipSlots.ALL 첫 매칭).
	var gear := registry.resolve_gear(item_id)
	if gear and registry.can_item_occupy_slot(item_id, gear.gear_slot):
		return gear.gear_slot
	for slot_key in EquipSlots.ALL:
		if registry.can_item_occupy_slot(item_id, slot_key):
			return slot_key
	return &""


static func _is_shared_armor_slot(slot_key: StringName) -> bool:
	return (
		slot_key == EquipSlots.HELMET
		or slot_key == EquipSlots.ARMOR
		or slot_key == EquipSlots.GLOVES
		or slot_key == EquipSlots.BOOTS
		or slot_key == EquipSlots.ACCESSORY
	)


func _combat_weapon_and_offhand_occupied(set_index: int) -> bool:
	return (
		not loadout.get_set_item_id(set_index, EquipSlots.WEAPON).is_empty()
		and not loadout.get_set_item_id(set_index, EquipSlots.OFFHAND).is_empty()
	)


func _acquire_weapon_item(item_id: String) -> StringName:
	if not registry.can_item_occupy_slot(item_id, EquipSlots.WEAPON):
		return ERROR_INVALID_SLOT
	for set_index in _ordered_combat_set_indices():
		if not loadout.get_set_item_id(set_index, EquipSlots.WEAPON).is_empty():
			continue
		var err := _equip_acquired_weapon_to_empty_set(item_id, set_index)
		if err.is_empty():
			return &""
	return _place_item_in_bag(item_id)


func _remove_item_id_from_loadout(item_id: String) -> void:
	var location: Variant = loadout.find_item_location(item_id)
	if location == null:
		return
	var source: Dictionary = location
	var source_kind: StringName = source.get("kind", &"")
	if source_kind == &"bag":
		var bag_index: int = source.get("bag_index", -1)
		if bag_index >= 0:
			loadout.set_bag_item_id(bag_index, "")
	elif source_kind == &"set":
		var set_index: int = source.get("set_index", -1)
		var slot_key: StringName = source.get("slot_key", &"")
		loadout.set_set_item_id(set_index, slot_key, "")


func _equip_acquired_weapon_to_empty_set(item_id: String, set_index: int) -> StringName:
	if registry.is_two_handed_weapon(item_id):
		var offhand_id := loadout.get_set_item_id(set_index, EquipSlots.OFFHAND)
		if not offhand_id.is_empty():
			var bag_index := loadout.find_first_empty_bag_index()
			if bag_index < 0:
				return ERROR_BAG_FULL
			loadout.set_bag_item_id(bag_index, offhand_id)
			loadout.set_set_item_id(set_index, EquipSlots.OFFHAND, "")
	loadout.set_set_item_id(set_index, EquipSlots.WEAPON, item_id)
	return &""


func _acquire_offhand_item(item_id: String) -> StringName:
	if not registry.can_item_occupy_slot(item_id, EquipSlots.OFFHAND):
		return ERROR_INVALID_SLOT
	for set_index in _ordered_combat_set_indices():
		if not loadout.get_set_item_id(set_index, EquipSlots.OFFHAND).is_empty():
			continue
		var weapon_id := loadout.get_set_item_id(set_index, EquipSlots.WEAPON)
		if registry.is_offhand_blocked_by_weapon(weapon_id):
			continue
		loadout.set_set_item_id(set_index, EquipSlots.OFFHAND, item_id)
		return &""
	return _place_item_in_bag(item_id)


func _acquire_shared_armor_item(item_id: String, slot_key: StringName) -> StringName:
	if not registry.can_item_occupy_slot(item_id, slot_key):
		return ERROR_INVALID_SLOT
	var set_index := EquipSlots.SHARED_ARMOR_SET_INDEX
	if loadout.get_set_item_id(set_index, slot_key).is_empty():
		loadout.set_set_item_id(set_index, slot_key, item_id)
		return &""
	return _place_item_in_bag(item_id)


func _place_item_in_bag(item_id: String) -> StringName:
	var bag_index := loadout.find_first_empty_bag_index()
	if bag_index < 0:
		return ERROR_BAG_FULL
	loadout.set_bag_item_id(bag_index, item_id)
	return &""


func _ordered_combat_set_indices() -> Array[int]:
	var active := clampi(loadout.active_set_index, 0, EquipSlots.SET_COUNT - 1)
	var indices: Array[int] = [active]
	for set_index in EquipSlots.SET_COUNT:
		if set_index != active:
			indices.append(set_index)
	return indices


func _weapon_id_after_swap(
	set_index: int,
	slot_a: StringName,
	slot_b: StringName,
	id_a: String,
	id_b: String
) -> String:
	if slot_a == EquipSlots.WEAPON:
		return id_b
	if slot_b == EquipSlots.WEAPON:
		return id_a
	return loadout.get_set_item_id(set_index, EquipSlots.WEAPON)


# 양손 무기 장착 후 offhand 비울 가방 자리가 있는지 검사합니다.
func _validate_two_handed_offhand_clear(set_index: int, weapon_id: String) -> StringName:
	if not registry.is_two_handed_weapon(weapon_id):
		return &""
	var offhand_id := loadout.get_set_item_id(set_index, EquipSlots.OFFHAND)
	if offhand_id.is_empty():
		return &""
	if loadout.find_first_empty_bag_index() < 0:
		return ERROR_BAG_FULL
	return &""


func _collect_bag_targets(primary_index: int, extra_needed: int) -> Array[int]:
	var targets: Array[int] = [primary_index]
	for i in loadout.bag_ids.size():
		if i == primary_index:
			continue
		if loadout.get_bag_item_id(i).is_empty():
			targets.append(i)
			if targets.size() >= extra_needed + 1:
				break
	return targets
