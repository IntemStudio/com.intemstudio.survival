class_name AttackDelivery
extends RefCounted

## 공격 전달 방식 — AttackFactory 분기용

const BULLET := 0
const MELEE_PROJECTILE := 1
const MAGIC_BOLT := 2
const THROWING := 3
const ORBIT := 4
const AREA_ZONE := 5
const CUSTOM_PROJECTILE_SCENE := 6


static func resolve_for_weapon(weapon: WeaponData) -> int:
	if weapon == null:
		return BULLET
	if weapon.is_orbit_attack():
		return ORBIT
	if weapon.is_area_zone_attack():
		return AREA_ZONE
	if weapon.is_melee():
		return MELEE_PROJECTILE
	if weapon.is_magic():
		return MAGIC_BOLT
	if weapon.is_throwing():
		if weapon.projectile_scene:
			return CUSTOM_PROJECTILE_SCENE
		return THROWING
	return BULLET
