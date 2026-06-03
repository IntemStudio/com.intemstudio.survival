extends RefCounted

const WeaponDataScript = preload("res://weapons/data/weapon_data.gd")
const SHOTGUN_PATH := "res://weapons/data/shotgun.tres"

static var _cache: Array[WeaponData] = []


static func get_all() -> Array[WeaponData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func _build_cache() -> void:
	var shotgun_variant: Resource = load(SHOTGUN_PATH)
	if shotgun_variant is WeaponData:
		_cache.append(shotgun_variant)
	else:
		push_error("RangedWeaponCatalog: failed to load WeaponData at %s" % SHOTGUN_PATH)
	var entries: Array[Dictionary] = []

	for entry in entries:
		_cache.append(_create_weapon(entry))


static func _create_weapon(entry: Dictionary) -> WeaponData:
	var weapon: WeaponData = WeaponDataScript.new()
	weapon.weapon_id = entry["id"]
	weapon.display_name = entry["en"]
	weapon.display_name_ko = entry["ko"]
	weapon.weapon_type = "Ranged"
	weapon.weapon_subtype = entry["subtype"]
	weapon.rarity = "Common"
	weapon.hand = "Two-Handed" if entry["hand"] == 2 else "One-Handed"
	weapon.range_type = entry["range"]
	weapon.effect = entry["effect"]
	return weapon
