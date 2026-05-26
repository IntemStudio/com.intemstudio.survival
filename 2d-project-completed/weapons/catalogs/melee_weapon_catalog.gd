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
		{"id": "dagger", "en": "Dagger", "ko": "단검", "subtype": "Dagger", "hand": 1, "min": 90, "max": 185, "aps": 2.0, "range": "Short", "effect": "Primary attack deals thrusting damage.", "movement": "Return"},
		{"id": "spiky_flail", "en": "Spiky Flail", "ko": "가시 철퇴", "subtype": "Flail", "hand": 1, "min": 55, "max": 100, "aps": 1.0, "range": "Medium", "effect": "Primary attack spins a flail that deals striking damage.", "movement": "Orbit"},
		{"id": "katana", "en": "Katana", "ko": "카타나", "subtype": "Two Handed Sword", "hand": 2, "min": 55, "max": 125, "aps": 2.5, "range": "Far", "effect": "Primary attack deals slashing damage.", "movement": "CurvedReturn"},
		{"id": "broken_hero_sword", "en": "Broken Hero Sword", "ko": "부서진 영웅의 검", "subtype": "One Handed Sword", "hand": 1, "min": 80, "max": 155, "aps": 2.0, "range": "Very Short", "effect": "Primary attack deals slashing damage."},
		{"id": "hand_axe", "en": "Hand Axe", "ko": "손도끼", "subtype": "Axe", "hand": 1, "min": 100, "max": 200, "aps": 2.0, "range": "Medium", "effect": "Primary attack deals slashing damage."},
		{"id": "sickles", "en": "Sickles", "ko": "낫", "subtype": "Sickles", "hand": 2, "min": 30, "max": 65, "aps": 3.0, "range": "Medium", "effect": "Primary attacks deal slashing damage and can hit multiple times.", "hits": 3, "spread": 2, "parallel_offset": 18.0, "movement": "Decelerate", "speed": 900.0},
		{"id": "club", "en": "Club", "ko": "곤봉", "subtype": "Mace", "hand": 1, "min": 105, "max": 215, "aps": 2.0, "range": "Short", "effect": "Primary attack deals striking damage."},
		{"id": "crop_scythe", "en": "Crop Scythe", "ko": "작물 낫", "subtype": "Scythe", "hand": 2, "min": 65, "max": 150, "aps": 2.0, "range": "Medium", "effect": "Primary attack deals slashing damage.", "spread": 1, "spread_angle": 0.0, "movement": "CurvedReturn"},
		{"id": "spear", "en": "Spear", "ko": "창", "subtype": "Spear", "hand": 2, "min": 100, "max": 210, "aps": 2.0, "range": "Medium", "effect": "Primary attack deals thrusting damage.", "movement": "Return"},
		{"id": "broadsword", "en": "Broadsword", "ko": "브로드소드", "subtype": "One Handed Sword", "hand": 1, "min": 80, "max": 165, "aps": 2.5, "range": "Short", "effect": "Primary attack deals slashing damage."},
		{"id": "shortsword", "en": "Shortsword", "ko": "숏소드", "subtype": "One Handed Sword", "hand": 1, "min": 80, "max": 165, "aps": 2.5, "range": "Short", "effect": "Primary attack deals slashing damage."},
		{"id": "wooden_sword", "en": "Wooden Sword", "ko": "나무 검", "subtype": "One Handed Sword", "hand": 1, "min": 65, "max": 140, "aps": 2.5, "range": "Short", "effect": "Primary attack deals slashing damage."},
		{"id": "twin_axes", "en": "Twin Axes", "ko": "쌍도끼", "subtype": "Axe", "hand": 2, "min": 85, "max": 155, "aps": 2.0, "range": "Medium", "effect": "Primary attacks deal slashing damage."},
		{"id": "poleaxe", "en": "Poleaxe", "ko": "폴액스", "subtype": "Polearm", "hand": 2, "min": 95, "max": 200, "aps": 2.0, "range": "Far", "effect": "Primary attack deals slashing damage.", "movement": "CurvedReturn"},
		{"id": "circus_knives", "en": "Circus Knives", "ko": "서커스 나이프", "subtype": "Dagger", "hand": 2, "min": 110, "max": 205, "aps": 2.0, "range": "Very Short", "effect": "Primary attack deals thrusting damage.", "movement": "Return"},
		{"id": "wooden_bo", "en": "Wooden Bo", "ko": "나무 봉", "subtype": "Daibo", "hand": 2, "min": 115, "max": 220, "aps": 2.0, "range": "Short", "effect": "Primary attack deals striking damage."},
		{"id": "rusty_fans", "en": "Rusty Fans", "ko": "녹슨 부채", "subtype": "Fan", "hand": 2, "min": 55, "max": 105, "aps": 3.0, "range": "Medium", "effect": "Primary attacks deal slashing damage and can hit multiple times.", "hits": 3, "spread": 2, "parallel_offset": 18.0, "movement": "Decelerate", "speed": 900.0},
		{"id": "crusader_mace", "en": "Crusader Mace", "ko": "크루세이더 철퇴", "subtype": "Mace", "hand": 1, "min": 105, "max": 245, "aps": 2.0, "range": "Short", "effect": "Primary attack deals striking damage."},
		{"id": "side_sword", "en": "Side Sword", "ko": "사이드 소드", "subtype": "One Handed Sword", "hand": 1, "min": 75, "max": 170, "aps": 2.5, "range": "Medium", "effect": "Primary attack deals thrusting damage.", "movement": "Return"},
		{"id": "rapier", "en": "Rapier", "ko": "레이피어", "subtype": "One Handed Sword", "hand": 1, "min": 115, "max": 240, "aps": 2.0, "range": "Medium", "effect": "On combat start, grants En Garde.", "movement": "Return"},
		{"id": "bastard_sword", "en": "Bastard Sword", "ko": "바스타드 소드", "subtype": "Two Handed Sword", "hand": 2, "min": 95, "max": 200, "aps": 2.0, "range": "Far", "effect": "Primary attack deals slashing damage.", "spread": 3, "spread_angle": 50.0, "movement": "CurvedReturn"},
		{"id": "cutlass", "en": "Cutlass", "ko": "커틀러스", "subtype": "One Handed Sword", "hand": 1, "min": 60, "max": 125, "aps": 2.5, "range": "Medium", "effect": "Primary attack deals slashing damage."},
		{"id": "draco_spear", "en": "Draco Spear", "ko": "드라코 스피어", "subtype": "Spear", "hand": 2, "min": 80, "max": 180, "aps": 2.0, "range": "Medium", "effect": "Primary attack deals thrusting damage.", "movement": "Return"},
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
	weapon.min_damage = entry["min"]
	weapon.max_damage = entry["max"]
	weapon.attacks_per_second = entry["aps"]
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
