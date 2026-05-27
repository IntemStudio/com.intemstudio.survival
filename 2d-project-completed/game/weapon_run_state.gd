class_name WeaponRunState
extends RefCounted

## 한 런 동안 보유 무기 id → 강화 레벨(1부터).

const MAX_LEVEL := 8
const DAMAGE_MULT_PER_LEVEL := 0.10


var _levels: Dictionary = {}


func clear() -> void:
	_levels.clear()


func ensure_registered(weapon: WeaponData) -> void:
	if weapon == null:
		return
	var key := _weapon_key(weapon)
	if not _levels.has(key):
		_levels[key] = 1


func get_level(weapon: WeaponData) -> int:
	if weapon == null:
		return 1
	return int(_levels.get(_weapon_key(weapon), 1))


func can_upgrade(weapon: WeaponData) -> bool:
	return get_level(weapon) < MAX_LEVEL


func add_level(weapon: WeaponData, bonus_levels: int = 0) -> int:
	if weapon == null:
		return 0
	ensure_registered(weapon)
	var key := _weapon_key(weapon)
	var current := int(_levels[key])
	if current >= MAX_LEVEL:
		return 0
	var added := 1 + maxi(bonus_levels, 0)
	var new_level := mini(current + added, MAX_LEVEL)
	_levels[key] = new_level
	return new_level


static func compute_damage_mult(level: int) -> float:
	var safe_level := maxi(level, 1)
	return 1.0 + float(safe_level - 1) * DAMAGE_MULT_PER_LEVEL


static func _weapon_key(weapon: WeaponData) -> String:
	return weapon.get_unique_key()
