extends RefCounted

## 장비 카탈로그 — GearData .tres·코드 엔트리를 등록할 때 사용.

const _GearCatalogEntries: GDScript = preload("res://inventory/gear_catalog_entries.gd")

const TEXTURE := preload("res://art/shared/pistol.png")

static var _cache: Array[GearData] = []


static func get_all() -> Array[GearData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func _build_cache() -> void:
	_cache = []
	_GearCatalogEntries.append_all(_cache, Callable(_create_gear))


static func _create_gear(
	id: String,
	name_en: String,
	name_ko: String,
	slot: StringName,
	stats: Dictionary,
	effect_en: String = "",
	effect_ko: String = "",
	attunement: int = 1
) -> GearData:
	var gear := GearData.new()
	gear.item_id = id
	gear.display_name = name_en
	gear.display_name_ko = name_ko
	gear.gear_slot = slot
	gear.equip_slots = PackedStringArray([EquipSlots.slot_key_to_string(slot)])
	gear.stat_modifiers = stats
	gear.effect = effect_en
	gear.effect_ko = effect_ko
	gear.attunement = attunement
	gear.texture = TEXTURE
	gear.rarity = "Common"
	return gear
