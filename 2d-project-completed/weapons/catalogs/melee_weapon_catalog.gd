extends RefCounted

const WeaponDataScript = preload("res://weapons/data/weapon_data.gd")
const TEXTURE := preload("res://art/shared/pistol.png")

static var _cache: Array[WeaponData] = []


static func get_all() -> Array[WeaponData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func _build_cache() -> void:
	var entries: Array[Dictionary] = [
		{"id": "katana", "en": "Katana", "ko": "카타나", "subtype": "Two Handed Sword", "hand": 2, "min": 55, "max": 125, "aps": 2.5, "range": "Far", "effect": "Primary attack deals slashing damage.", "status": [&"bleed"], "movement": "CurvedReturn"},
	]

	for entry in entries:
		_cache.append(_create_weapon(entry))


static func _create_weapon(entry: Dictionary) -> WeaponData:
	var weapon: WeaponData = WeaponDataScript.new()
	weapon.weapon_id = entry["id"]
	weapon.display_name = entry["en"]
	weapon.display_name_ko = entry["ko"]
	weapon.weapon_type = "Melee"
	weapon.attack_delivery = "Projectile"
	weapon.weapon_subtype = entry["subtype"]
	weapon.rarity = "Common"
	weapon.hand = "Two-Handed" if entry["hand"] == 2 else "One-Handed"
	weapon.range_type = entry["range"]
	weapon.effect = entry["effect"]
	weapon.texture = TEXTURE
	weapon.sprite_modulate = _tint_for_subtype(entry["subtype"])
	weapon.damage_coefficient = WeaponDataScript.resolve_damage_coefficient(entry)
	weapon.attacks_per_second = entry["aps"]
	for status_id in entry.get("status", []):
		weapon.status_effects.append(status_id)
	weapon.status_chance = entry.get("status_chance", 1.0)
	weapon.hit_count = entry.get("hits", 1)
	weapon.melee_spread_count = entry.get("spread", 1)
	weapon.melee_spread_angle_deg = entry.get("spread_angle", 0.0)
	weapon.melee_parallel_offset = entry.get("parallel_offset", 0.0)
	weapon.melee_projectile_speed = entry.get("speed", weapon.melee_projectile_speed)
	weapon.projectile_pierce_count = entry.get("pierce", -1)
	if entry.has("movement"):
		weapon.projectile_movement = entry["movement"]
	elif entry.get("returns", false):
		weapon.projectile_movement = "Return"
	else:
		weapon.projectile_movement = "StraightPierce"
	weapon.apply_projectile_movement_side_effects()
	return weapon


static func _tint_for_subtype(subtype: String) -> Color:
	match subtype:
		"Dagger", "One Handed Sword", "Two Handed Sword", "Cutlass", "Broadsword", "Shortsword", "Wooden Sword", "Side Sword", "Rapier", "Bastard Sword", "Broken Hero Sword":
			return Color(0.85, 0.9, 1.0)
		"Axe", "Polearm", "Twin Axes", "Hand Axe", "Poleaxe":
			return Color(1.0, 0.75, 0.55)
		"Mace", "Flail", "Club", "Crusader Mace":
			return Color(0.75, 0.75, 0.8)
		"Spear", "Draco Spear":
			return Color(0.7, 1.0, 0.85)
		"Scythe", "Sickles", "Crop Scythe":
			return Color(0.75, 1.0, 0.65)
		"Fan", "Daibo", "Throwing":
			return Color(0.95, 0.85, 1.0)
		_:
			return Color.WHITE
