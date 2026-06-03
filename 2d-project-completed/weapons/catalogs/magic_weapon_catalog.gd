extends RefCounted

const WeaponDataScript = preload("res://weapons/data/weapon_data.gd")

static var _cache: Array[WeaponData] = []


static func get_all() -> Array[WeaponData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func _build_cache() -> void:
	var entries: Array[Dictionary] = []

	for entry in entries:
		_cache.append(_create_weapon(entry))


static func _create_weapon(entry: Dictionary) -> WeaponData:
	var weapon: WeaponData = WeaponDataScript.new()
	weapon.weapon_id = entry["id"]
	weapon.display_name = entry["en"]
	weapon.display_name_ko = entry["ko"]
	weapon.weapon_type = "Magic"
	weapon.weapon_subtype = entry["subtype"]
	weapon.rarity = "Common"
	weapon.hand = "Two-Handed" if entry["hand"] == 2 else "One-Handed"
	weapon.range_type = entry["range"]
	weapon.effect = entry["effect"]
	return weapon
