class_name ItemRegistry
extends RefCounted

## item_id → WeaponData / GearData 해석·착용 슬롯 검증.

const _RangedWeaponCatalog := preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const _MeleeWeaponCatalog := preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const _MagicWeaponCatalog := preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const _GearCatalog := preload("res://inventory/gear_catalog.gd")

var _weapons: Dictionary = {}
var _gear: Dictionary = {}


func clear() -> void:
	_weapons.clear()
	_gear.clear()


func register_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return
	var key := weapon.get_unique_key()
	if key.is_empty():
		push_warning("ItemRegistry: weapon without id skipped")
		return
	_weapons[key] = weapon


func register_gear(gear: GearData) -> void:
	if gear == null:
		return
	var key := gear.get_unique_key()
	if key.is_empty():
		push_warning("ItemRegistry: gear without id skipped")
		return
	_gear[key] = gear


func register_weapons_from_catalogs() -> void:
	for weapon in _RangedWeaponCatalog.get_all():
		register_weapon(weapon)
	for weapon in _MeleeWeaponCatalog.get_all():
		register_weapon(weapon)
	for weapon in _MagicWeaponCatalog.get_all():
		register_weapon(weapon)


func register_gear_from_catalog() -> void:
	for gear in _GearCatalog.get_all():
		register_gear(gear)


func register_all_catalogs() -> void:
	register_weapons_from_catalogs()
	register_gear_from_catalog()


func has_item(item_id: String) -> bool:
	var key := item_id.strip_edges()
	return _weapons.has(key) or _gear.has(key)


func resolve_weapon(item_id: String) -> WeaponData:
	return _weapons.get(item_id.strip_edges(), null)


func resolve_gear(item_id: String) -> GearData:
	return _gear.get(item_id.strip_edges(), null)


func resolve_gear_or_weapon(item_id: String) -> Resource:
	var key := item_id.strip_edges()
	if _weapons.has(key):
		return _weapons[key]
	if _gear.has(key):
		return _gear[key]
	return null


func is_two_handed_weapon(item_id: String) -> bool:
	var weapon := resolve_weapon(item_id)
	return weapon != null and weapon.hand == "Two-Handed"


# 아이템이 해당 착용 슬롯 규칙에 맞는지(양손·슬롯 타입) 검사합니다.
func can_item_occupy_slot(item_id: String, slot_key: StringName) -> bool:
	var key := item_id.strip_edges()
	if key.is_empty() or not has_item(key):
		return false
	if not EquipSlots.is_valid_slot_key(slot_key):
		return false

	var weapon := resolve_weapon(key)
	if weapon:
		if slot_key == EquipSlots.WEAPON:
			return true
		if slot_key == EquipSlots.OFFHAND:
			return weapon.hand == "One-Handed"
		return false

	var gear := resolve_gear(key)
	if gear:
		return gear.fits_slot(slot_key)
	return false


# 세트 내 양손 무기 때문에 offhand가 막혀 있는지 확인합니다.
func is_offhand_blocked_by_weapon(set_weapon_id: String) -> bool:
	return is_two_handed_weapon(set_weapon_id)


# 활성 세트 기준 스탯 보정 합산(방어구·악세·offhand 방패 등).
func sum_stat_modifiers_for_set(set_dict: Dictionary) -> Dictionary:
	var totals: Dictionary = {}
	for slot_key in EquipSlots.ALL:
		if slot_key == EquipSlots.WEAPON:
			continue
		var item_id := String(set_dict.get(slot_key, ""))
		if item_id.is_empty():
			continue
		var gear := resolve_gear(item_id)
		if gear == null:
			continue
		for stat_key in gear.stat_modifiers:
			var value: Variant = gear.stat_modifiers[stat_key]
			if totals.has(stat_key):
				if value is int or value is float:
					totals[stat_key] = totals[stat_key] + value
				else:
					totals[stat_key] = value
			else:
				totals[stat_key] = value
	return totals
