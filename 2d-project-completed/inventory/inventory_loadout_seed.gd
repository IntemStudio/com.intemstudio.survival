class_name InventoryLoadoutSeed
extends RefCounted

## 빈 세이브(첫 실행) 시 슬롯별 무작위 장비·무기 시드.

const _GearCatalog := preload("res://inventory/gear_catalog.gd")
const _RangedWeaponCatalog := preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const _MeleeWeaponCatalog := preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const _MagicWeaponCatalog := preload("res://weapons/catalogs/magic_weapon_catalog.gd")

const _ARMOR_SLOT_KEYS: Array[StringName] = [
	EquipSlots.HELMET,
	EquipSlots.ARMOR,
	EquipSlots.GLOVES,
	EquipSlots.BOOTS,
	EquipSlots.ACCESSORY,
]


static func is_loadout_empty(state: PlayerLoadoutState) -> bool:
	for id in state.bag_ids:
		if not id.is_empty():
			return false
	for set_index in EquipSlots.SET_COUNT:
		for slot_key in EquipSlots.ALL:
			if not state.get_set_item_id(set_index, slot_key).is_empty():
				return false
	return true


# 첫 실행(빈 세이브) 시 모든 착용 부위에 카탈로그에서 무작위 1개씩 장착합니다.
static func apply_random_starter(state: PlayerLoadoutState, registry: ItemRegistry) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for slot_key in _ARMOR_SLOT_KEYS:
		var gear_id := _pick_random_gear(registry, slot_key, rng)
		if not gear_id.is_empty():
			state.set_set_item_id(0, slot_key, gear_id)

	for set_index in EquipSlots.SET_COUNT:
		_seed_combat_set_weapons(state, registry, set_index, rng)


static func apply_demo(state: PlayerLoadoutState) -> void:
	state.set_set_item_id(0, EquipSlots.WEAPON, "broken_hero_sword")
	state.set_set_item_id(0, EquipSlots.OFFHAND, "wooden_shield")
	state.set_bag_item_id(0, "bastard_sword")
	state.set_bag_item_id(1, "leather_tunic")
	state.set_bag_item_id(2, "traveler_boots")
	state.set_bag_item_id(3, "buckler")
	state.set_bag_item_id(4, "slime_orb")
	state.set_bag_item_id(5, "quiver")
	state.set_bag_item_id(6, "knight_helmet")
	state.set_bag_item_id(7, "chain_armor")


static func _seed_combat_set_weapons(
	state: PlayerLoadoutState,
	registry: ItemRegistry,
	set_index: int,
	rng: RandomNumberGenerator
) -> void:
	var weapon_id := _pick_random_weapon(registry, rng)
	if weapon_id.is_empty():
		state.set_set_item_id(set_index, EquipSlots.WEAPON, "")
		state.set_set_item_id(set_index, EquipSlots.OFFHAND, "")
		return

	state.set_set_item_id(set_index, EquipSlots.WEAPON, weapon_id)
	if registry.is_two_handed_weapon(weapon_id):
		state.set_set_item_id(set_index, EquipSlots.OFFHAND, "")
		return

	var offhand_id := _pick_random_offhand(registry, rng)
	state.set_set_item_id(set_index, EquipSlots.OFFHAND, offhand_id)


static func _pick_random_gear(
	registry: ItemRegistry,
	slot_key: StringName,
	rng: RandomNumberGenerator
) -> String:
	var pool := _collect_gear_ids(registry, slot_key)
	return _pick_from_pool(pool, rng)


static func _pick_random_weapon(registry: ItemRegistry, rng: RandomNumberGenerator) -> String:
	return _pick_from_pool(_collect_weapon_ids(registry), rng)


static func _pick_random_offhand(registry: ItemRegistry, rng: RandomNumberGenerator) -> String:
	return _pick_from_pool(_collect_offhand_ids(registry), rng)


static func _collect_gear_ids(registry: ItemRegistry, slot_key: StringName) -> Array[String]:
	var pool: Array[String] = []
	for gear in _GearCatalog.get_all():
		if not gear.fits_slot(slot_key):
			continue
		var item_id := gear.get_unique_key()
		if item_id.is_empty() or not registry.can_item_occupy_slot(item_id, slot_key):
			continue
		pool.append(item_id)
	return pool


static func _collect_weapon_ids(registry: ItemRegistry) -> Array[String]:
	var pool: Array[String] = []
	_append_weapon_ids_for_slot(pool, registry, _RangedWeaponCatalog.get_all(), EquipSlots.WEAPON)
	_append_weapon_ids_for_slot(pool, registry, _MeleeWeaponCatalog.get_all(), EquipSlots.WEAPON)
	_append_weapon_ids_for_slot(pool, registry, _MagicWeaponCatalog.get_all(), EquipSlots.WEAPON)
	return pool


static func _collect_offhand_ids(registry: ItemRegistry) -> Array[String]:
	var pool: Array[String] = []
	for gear in _GearCatalog.get_all():
		if not gear.fits_slot(EquipSlots.OFFHAND):
			continue
		var item_id := gear.get_unique_key()
		if item_id.is_empty() or not registry.can_item_occupy_slot(item_id, EquipSlots.OFFHAND):
			continue
		pool.append(item_id)
	_append_weapon_ids_for_slot(pool, registry, _RangedWeaponCatalog.get_all(), EquipSlots.OFFHAND)
	_append_weapon_ids_for_slot(pool, registry, _MeleeWeaponCatalog.get_all(), EquipSlots.OFFHAND)
	_append_weapon_ids_for_slot(pool, registry, _MagicWeaponCatalog.get_all(), EquipSlots.OFFHAND)
	return pool


static func _append_weapon_ids_for_slot(
	pool: Array[String],
	registry: ItemRegistry,
	weapons: Array,
	slot_key: StringName
) -> void:
	for weapon in weapons:
		if weapon is not WeaponData:
			continue
		var item_id: String = weapon.get_unique_key()
		if item_id.is_empty():
			continue
		if registry.can_item_occupy_slot(item_id, slot_key):
			pool.append(item_id)


static func _pick_from_pool(pool: Array[String], rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]
