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
		{
			"id": "apprentice_wand",
			"en": "Apprentice Wand",
			"ko": "견습생 지팡이",
			"subtype": "Wand",
			"hand": 1,
			"min": 55,
			"max": 115,
			"aps": 3.0,
			"range": "Medium",
			"element": "cold",
			"style": "Projectile",
			"effect": "Primary attack deals cold damage.",
			"status": [&"chill", &"frostbite"],
		},
		{
			"id": "magic_missile_wand",
			"en": "Magic Missile Wand",
			"ko": "매직 미사일 지팡이",
			"subtype": "Wand",
			"hand": 1,
			"min": 55,
			"max": 110,
			"aps": 2.0,
			"range": "Very Far",
			"element": "lightning",
			"style": "Projectile",
			"homing": 6.0,
			"effect": "Primary attack deals lightning damage.",
			"status": [&"zap"],
		},
		{
			"id": "oak_staff",
			"en": "Oak Staff",
			"ko": "참나무 지팡이",
			"subtype": "Stave",
			"hand": 2,
			"min": 55,
			"max": 215,
			"aps": 2.0,
			"range": "Medium",
			"element": "magic",
			"style": "Projectile",
			"effect": "Primary attack deals magical damage.",
		},
		{
			"id": "sticky_orbital",
			"en": "Sticky Orbital",
			"ko": "끈적 궤도",
			"subtype": "Orb",
			"hand": 1,
			"min": 65,
			"max": 135,
			"aps": 1.2,
			"range": "Short",
			"element": "striking",
			"style": "Orbit",
			"effect": "Orbital striking damage (loadout grant).",
		},
		{
			"id": "pyromancy_orbital",
			"en": "Pyromancy Orbital",
			"ko": "화염술 궤도",
			"subtype": "Orb",
			"hand": 1,
			"min": 80,
			"max": 120,
			"aps": 1.1,
			"range": "Short",
			"element": "fire",
			"style": "Orbit",
			"effect": "Orbital fire damage (loadout grant).",
			"status": [&"scorch"],
		},
		{
			"id": "king_bible",
			"en": "King Bible",
			"ko": "왕의 성경",
			"subtype": "Bible",
			"hand": 1,
			"min": 105,
			"max": 215,
			"aps": 1.0,
			"range": "Short",
			"element": "striking",
			"style": "Orbit",
			"effect": "Primary attack deals striking damage.",
		},
		{
			"id": "fireball_wand",
			"en": "Fireball Wand",
			"ko": "파이어볼 지팡이",
			"subtype": "Wand",
			"hand": 1,
			"min": 50,
			"max": 185,
			"aps": 1.5,
			"range": "Far",
			"element": "fire",
			"style": "Explosion",
			"explosion": 95.0,
			"effect": "Primary attack deals fire damage.",
			"status": [&"burn"],
		},
		{
			"id": "fey_lute",
			"en": "Fey Lute",
			"ko": "요정의 리트",
			"subtype": "Instrument",
			"hand": 2,
			"min": 80,
			"max": 150,
			"aps": 2.0,
			"range": "Far",
			"element": "sound",
			"style": "Projectile",
			"effect": "Primary attack deals sound damage.",
		},
		{
			"id": "priest_scepter",
			"en": "Priest Scepter",
			"ko": "사제의 홀",
			"subtype": "Scepter",
			"hand": 1,
			"min": 50,
			"max": 85,
			"aps": 5.0,
			"range": "Medium",
			"element": "radiant",
			"style": "Projectile",
			"effect": "Primary attack deals radiant damage.",
		},
		{
			"id": "ivy_scroll",
			"en": "Ivy Scroll",
			"ko": "담쟁이 두루마리",
			"subtype": "Scroll",
			"hand": 1,
			"min": 145,
			"max": 300,
			"aps": 1.25,
			"range": "Very Far",
			"element": "nature",
			"style": "Projectile",
			"nettles": true,
			"effect": "Primary attack deals nature damage and inflicts Nettles.",
		},
	]

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
	weapon.texture = TEXTURE
	weapon.sprite_modulate = _tint_for_element(entry["element"])
	weapon.min_damage = entry["min"]
	weapon.max_damage = entry["max"]
	weapon.attacks_per_second = entry["aps"]
	weapon.damage_element = entry["element"]
	for status_id in entry.get("status", []):
		weapon.status_effects.append(status_id)
	weapon.status_chance = entry.get("status_chance", 1.0)
	weapon.magic_attack_style = entry["style"]
	weapon.projectile_speed = entry.get("speed", 950.0)
	weapon.homing_strength = entry.get("homing", 0.0)
	weapon.explosion_radius = entry.get("explosion", 0.0)
	weapon.applies_nettles = entry.get("nettles", false)
	weapon.nettles_duration = 8.0
	return weapon


static func _tint_for_element(element: String) -> Color:
	var weapon: Resource = WeaponDataScript.new()
	weapon.damage_element = element
	return weapon.get_element_color()
