extends RefCounted

const WeaponDataScript = preload("res://weapons/data/weapon_data.gd")
const TEXTURE := preload("res://art/shared/pistol.png")
const BOOMERANG_SCENE := preload("res://weapons/boomerang/boomerang.tscn")
const CONCOCTION_SCENE := preload("res://weapons/concoction/concoction.tscn")

static var _cache: Array[WeaponData] = []


static func get_all() -> Array[WeaponData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func _build_cache() -> void:
	var entries: Array[Dictionary] = [
		{"id": "shortbow", "en": "Shortbow", "ko": "숏보우", "subtype": "Bow", "hand": 2, "min": 90, "max": 195, "aps": 2.0, "range": "Far", "element": "thrusting", "effect": "Primary attack deals thrusting damage."},
		{"id": "chakrams", "en": "Chakrams", "ko": "차크람", "subtype": "Throwing", "hand": 1, "min": 70, "max": 145, "aps": 3.0, "range": "Far", "element": "slashing", "effect": "Primary attack deals slashing damage."},
		{"id": "crude_bow", "en": "Crude Bow", "ko": "조잡한 활", "subtype": "Bow", "hand": 2, "min": 100, "max": 200, "aps": 2.0, "range": "Far", "element": "thrusting", "effect": "Primary attack deals thrusting damage."},
		{"id": "longbow", "en": "Longbow", "ko": "장궁", "subtype": "Bow", "hand": 2, "min": 115, "max": 240, "aps": 1.75, "range": "Very Far", "element": "thrusting", "effect": "Primary attack deals thrusting damage."},
		{"id": "crossbow", "en": "Crossbow", "ko": "석궁", "subtype": "Crossbow", "hand": 2, "min": 135, "max": 280, "aps": 1.5, "range": "Far", "element": "thrusting", "effect": "Primary attack deals thrusting damage."},
		{"id": "wooden_boomerang", "en": "Wooden Boomerang", "ko": "나무 부메랑", "subtype": "Throwing", "hand": 1, "min": 50, "max": 115, "aps": 2.0, "range": "Far", "element": "striking", "projectile": "boomerang", "returns": true, "effect": "Primary attack deals striking damage."},
		{"id": "revolver", "en": "Revolver", "ko": "리볼버", "subtype": "Gun", "hand": 1, "min": 85, "max": 175, "aps": 2.0, "range": "Far", "element": "thrusting", "effect": "Primary attack deals thrusting damage."},
		{"id": "shuriken", "en": "Shuriken", "ko": "수리검", "subtype": "Throwing", "hand": 1, "min": 60, "max": 120, "aps": 3.0, "range": "Far", "element": "slashing", "effect": "Primary attack deals slashing damage."},
		{"id": "throwing_javelins", "en": "Throwing Javelins", "ko": "투척 자벨린", "subtype": "Throwing", "hand": 1, "min": 115, "max": 235, "aps": 1.5, "range": "Very Far", "element": "thrusting", "effect": "Primary attack deals thrusting damage."},
		{"id": "throwing_knives", "en": "Throwing Knives", "ko": "투척 나이프", "subtype": "Throwing", "hand": 1, "min": 100, "max": 100, "aps": 2.0, "range": "Medium", "element": "slashing", "effect": "Primary attack deals slashing damage."},
		{"id": "hand_cannon", "en": "Hand Cannon", "ko": "핸드 캐논", "subtype": "Cannon", "hand": 2, "min": 75, "max": 205, "aps": 2.0, "range": "Far", "element": "explosion", "style": "Explosion", "explosion": 95.0, "effect": "Primary attack deals explosion damage."},
		{"id": "dual_crossbows", "en": "Dual Crossbows", "ko": "쌍섭석궁", "subtype": "Crossbow", "hand": 2, "min": 45, "max": 105, "aps": 3.0, "range": "Far", "element": "thrusting", "burst": 3, "effect": "Primary attack deals thrusting damage."},
		{"id": "tommy_guns", "en": "Tommy Guns", "ko": "토미 건즈", "subtype": "Gun", "hand": 2, "min": 35, "max": 75, "aps": 2.0, "range": "Far", "element": "thrusting", "burst": 3, "effect": "Primary attack deals thrusting damage."},
		{"id": "fidget_glaive", "en": "Fidget Glaive", "ko": "피젯 글레이브", "subtype": "Throwing", "hand": 1, "min": 30, "max": 60, "aps": 3.0, "range": "Medium", "element": "slashing", "hits": 3, "effect": "Primary attack deals slashing damage and can hit multiple times."},
		{"id": "ornamental_chakrams", "en": "Ornamental Chakrams", "ko": "장식 차크람", "subtype": "Throwing", "hand": 1, "min": 70, "max": 125, "aps": 2.0, "range": "Far", "element": "slashing", "effect": "Primary attack deals slashing damage."},
		{
			"id": "alchemical_concoction",
			"en": "Alchemical Concoction",
			"ko": "연금술 물약",
			"subtype": "Throwing",
			"hand": 1,
			"min": 135,
			"max": 150,
			"aps": 1.5,
			"range": "Medium",
			"element": "poison",
			"projectile": "concoction",
			"arc": true,
			"effect": "Primary attack deals poison damage.",
			"poison_min": 10,
			"poison_max": 20,
		},
	]

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
	weapon.texture = TEXTURE
	weapon.sprite_modulate = _tint_for_element(entry["element"])
	weapon.min_damage = entry["min"]
	weapon.max_damage = entry["max"]
	weapon.attacks_per_second = entry["aps"]
	weapon.damage_element = entry["element"]
	weapon.ranged_attack_style = entry.get("style", "Bullet")
	weapon.projectile_speed = entry.get("speed", 1000.0)
	weapon.throw_speed = entry.get("throw_speed", 720.0)
	weapon.explosion_radius = entry.get("explosion", 0.0)
	weapon.hit_count = entry.get("hits", 1)
	weapon.burst_count = entry.get("burst", 1)
	weapon.burst_interval = 0.08
	weapon.returns_to_owner = entry.get("returns", false)
	weapon.uses_arc_throw = entry.get("arc", false)
	weapon.throw_range = weapon.get_projectile_range()

	if entry.has("poison_min"):
		weapon.poison_damage_min = entry["poison_min"]
		weapon.poison_damage_max = entry["poison_max"]
		weapon.poison_duration = 4.0
		weapon.poison_ticks_per_second = 2.0
		weapon.aoe_radius = 110.0

	match entry.get("projectile", ""):
		"boomerang":
			weapon.projectile_scene = BOOMERANG_SCENE
		"concoction":
			weapon.projectile_scene = CONCOCTION_SCENE
			weapon.throw_speed = 650.0
			weapon.attack_delivery = "AreaZone"

	return weapon


static func _tint_for_element(element: String) -> Color:
	var temp: Resource = WeaponDataScript.new()
	temp.damage_element = element
	return temp.get_element_color()
