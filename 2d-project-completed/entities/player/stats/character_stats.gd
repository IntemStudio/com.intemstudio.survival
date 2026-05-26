class_name CharacterStats
extends RefCounted

## 캐릭터의 장비·버프 modifier를 모아 최종 전투 수치를 계산합니다.

var _loadout_active := false
var _loadout_modifiers: Dictionary = {}
var _buff_modifiers: Dictionary = {}


# 장착 장비 modifier를 현재 능력치 source로 저장합니다.
func set_loadout_modifiers(modifiers: Dictionary, active: bool = true) -> void:
	_loadout_active = active
	_loadout_modifiers = modifiers.duplicate(true) if active else {}


# 런타임 버프 modifier를 현재 능력치 source로 저장합니다.
func set_buff_modifiers(modifiers: Dictionary) -> void:
	_buff_modifiers = modifiers.duplicate(true)


# 장착 장비 source를 제거해 기본 능력치로 되돌립니다.
func clear_loadout_modifiers() -> void:
	_loadout_active = false
	_loadout_modifiers = {}


func is_loadout_active() -> bool:
	return _loadout_active


func get_loadout_modifiers() -> Dictionary:
	return _loadout_modifiers.duplicate(true)


func get_max_health() -> float:
	if not _loadout_active:
		return LoadoutStatApply.BASE_MAX_HEALTH
	return LoadoutStatApply.compute_max_health(_loadout_modifiers)


# 방패·방어구 장비 source만 피격 피해 경감에 사용합니다.
func mitigate_incoming_damage(raw_amount: int) -> int:
	if raw_amount <= 0:
		return 0
	if not _loadout_active:
		return raw_amount
	return LoadoutStatApply.mitigate_incoming_damage(_loadout_modifiers, raw_amount)


func get_move_speed(base_speed: float) -> float:
	var speed := base_speed
	if _loadout_active:
		speed *= LoadoutStatApply.compute_move_speed_mult(_loadout_modifiers)
	speed *= LoadoutStatApply.compute_move_speed_mult(_buff_modifiers)
	return speed


# 무기 기본 피해 롤에 장비·버프 배율을 곱합니다.
func roll_weapon_damage(weapon: WeaponData, player_level: int = 1) -> int:
	if weapon == null:
		return 1
	var rolled := weapon.roll_damage()
	var mult := 1.0
	if _loadout_active:
		mult *= LoadoutStatApply.compute_damage_mult(_loadout_modifiers, weapon, player_level)
	mult *= LoadoutStatApply.compute_damage_mult(_buff_modifiers, weapon, player_level)
	return maxi(1, roundi(float(rolled) * mult))


# 무기 기본 APS에 장비·버프 공격 속도 배율을 곱합니다.
func get_effective_attacks_per_second(weapon: WeaponData) -> float:
	if weapon == null:
		return 1.0
	var mult := LoadoutStatApply.compute_attack_speed_mult(_buff_modifiers, weapon)
	if _loadout_active:
		mult *= LoadoutStatApply.compute_attack_speed_mult(_loadout_modifiers, weapon)
	return weapon.attacks_per_second * mult
