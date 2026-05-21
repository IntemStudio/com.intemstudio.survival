class_name WeaponDamageTracker
extends RefCounted

var _totals: Dictionary = {}
var _weapons: Dictionary = {}


# 무기 키별 누적 피해량을 기록합니다.
func register(weapon: WeaponData, amount: int) -> void:
	if amount <= 0 or weapon == null:
		return
	var key := weapon.get_unique_key()
	_totals[key] = int(_totals.get(key, 0)) + amount
	_weapons[key] = weapon


# 게임 오버 표시용 — 보유 무기 포함, 피해량 내림차순.
func build_display_rows(owned_weapons: Array[WeaponData]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var seen: Dictionary = {}

	for weapon in owned_weapons:
		if weapon == null:
			continue
		var key := weapon.get_unique_key()
		if seen.has(key):
			continue
		seen[key] = true
		rows.append({
			"weapon": weapon,
			"total": int(_totals.get(key, 0)),
		})

	for key in _totals.keys():
		if seen.has(key):
			continue
		var weapon: WeaponData = _weapons.get(key)
		if weapon == null:
			continue
		rows.append({
			"weapon": weapon,
			"total": int(_totals[key]),
		})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["total"]) > int(b["total"])
	)
	return rows
