class_name CharacterStats
extends RefCounted

## 캐릭터의 장비·패시브·버프 modifier를 모아 최종 전투 수치를 계산합니다.

var _loadout_active := false
var _class_modifiers: Dictionary = {}
var _loadout_modifiers: Dictionary = {}
var _passive_modifiers: Dictionary = {}
var _buff_modifiers: Dictionary = {}


# 런 시작 직업 modifier를 저장합니다.
func set_class_modifiers(modifiers: Dictionary) -> void:
	_class_modifiers = modifiers.duplicate(true)


# 장착 장비 modifier를 현재 능력치 source로 저장합니다.
func set_loadout_modifiers(modifiers: Dictionary, active: bool = true) -> void:
	_loadout_active = active
	_loadout_modifiers = modifiers.duplicate(true) if active else {}


# 런 패시브 modifier를 저장합니다.
func set_passive_modifiers(modifiers: Dictionary) -> void:
	_passive_modifiers = modifiers.duplicate(true)


# 런타임 버프 modifier를 현재 능력치 source로 저장합니다.
func set_buff_modifiers(modifiers: Dictionary) -> void:
	_buff_modifiers = modifiers.duplicate(true)


# 장착 장비 source를 제거해 기본 능력치로 되돌립니다.
func clear_loadout_modifiers() -> void:
	_loadout_active = false
	_loadout_modifiers = {}


func clear_passive_modifiers() -> void:
	_passive_modifiers = {}


func is_loadout_active() -> bool:
	return _loadout_active


func get_loadout_modifiers() -> Dictionary:
	return _loadout_modifiers.duplicate(true)


func get_passive_modifiers() -> Dictionary:
	return _passive_modifiers.duplicate(true)


func get_class_modifiers() -> Dictionary:
	return _class_modifiers.duplicate(true)


func get_combined_persistent_modifiers() -> Dictionary:
	var totals: Dictionary = {}
	GearStatMerge.merge_into(totals, _class_modifiers)
	if _loadout_active:
		GearStatMerge.merge_into(totals, _loadout_modifiers)
	GearStatMerge.merge_into(totals, _passive_modifiers)
	return totals


func get_max_health(player_level: int = 1) -> float:
	var mods := get_combined_persistent_modifiers()
	if mods.is_empty():
		return LoadoutStatApply.BASE_MAX_HEALTH
	return LoadoutStatApply.compute_max_health(mods, player_level)


# 직업·장비 source의 초당 체력 회복량.
func get_health_regen_per_sec(player_level: int = 1) -> float:
	return LoadoutStatApply.compute_health_regen_per_sec(
		get_combined_persistent_modifiers(),
		player_level
	)


# 장비·패시브 stamina → 최대 스태미나.
func get_max_stamina() -> float:
	return LoadoutStatApply.compute_max_stamina(get_combined_persistent_modifiers())


func get_stamina_regen_mult() -> float:
	return LoadoutStatApply.compute_stamina_regen_mult(_get_all_source_modifiers())


func get_dash_duration_mult() -> float:
	return LoadoutStatApply.compute_dash_duration_mult(_get_all_source_modifiers())


func get_invincibility_after_dash_sec() -> float:
	return LoadoutStatApply.get_invincibility_after_dash_sec(get_combined_persistent_modifiers())


func get_invincibility_after_damage_sec() -> float:
	return LoadoutStatApply.get_invincibility_after_damage_sec(get_combined_persistent_modifiers())


# revive_* 합산 → 런 부활 최대 횟수.
func get_revive_charges_max() -> int:
	return LoadoutStatApply.compute_revive_charges(get_combined_persistent_modifiers())


# 방패·방어구·패시브 source로 피격 피해 경감.
func mitigate_incoming_damage(raw_amount: int) -> int:
	if raw_amount <= 0:
		return 0
	var mods := get_combined_persistent_modifiers()
	if mods.is_empty():
		return raw_amount
	return LoadoutStatApply.mitigate_incoming_damage(mods, raw_amount)


func get_move_speed(base_speed: float) -> float:
	var speed := base_speed
	var persistent := get_combined_persistent_modifiers()
	if not persistent.is_empty():
		speed *= LoadoutStatApply.compute_move_speed_mult(persistent)
	speed *= LoadoutStatApply.compute_move_speed_mult(_buff_modifiers)
	return speed


# 무기 피해 계수에 장비·패시브·버프·무기 강화 배율을 곱합니다.
func roll_weapon_damage(
	weapon: WeaponData,
	player_level: int = 1,
	weapon_run_level: int = 1
) -> int:
	if weapon == null:
		return 1
	var persistent := get_combined_persistent_modifiers()
	var attack := LoadoutStatApply.compute_class_attack_bonus(persistent, player_level)
	var base_damage := float(attack) * weapon.damage_coefficient
	var mult := 1.0
	if weapon_run_level > 1:
		mult *= WeaponRunState.compute_damage_mult(weapon_run_level)
	if not persistent.is_empty():
		mult *= LoadoutStatApply.compute_damage_mult(persistent, weapon, player_level)
	mult *= LoadoutStatApply.compute_damage_mult(_buff_modifiers, weapon, player_level)
	# power는 전체 소스 합산 후 1회만 점감 적용합니다.
	mult *= LoadoutStatApply.compute_power_damage_mult(_get_all_source_modifiers())
	return maxi(1, roundi(base_damage * mult))


# 무기 기본 APS에 장비·패시브·버프 공격 속도 배율을 곱합니다.
func get_effective_attacks_per_second(weapon: WeaponData) -> float:
	if weapon == null:
		return 1.0
	var mult := LoadoutStatApply.compute_attack_speed_mult(_buff_modifiers, weapon)
	var persistent := get_combined_persistent_modifiers()
	if not persistent.is_empty():
		mult *= LoadoutStatApply.compute_attack_speed_mult(persistent, weapon)
	return weapon.attacks_per_second * mult


# power(장비/패시브/버프) 기반 범위·반경 배율입니다.
func get_power_radius_mult() -> float:
	return LoadoutStatApply.compute_power_radius_mult(_get_all_source_modifiers())


func _get_all_source_modifiers() -> Dictionary:
	var totals := get_combined_persistent_modifiers()
	GearStatMerge.merge_into(totals, _buff_modifiers)
	return totals
