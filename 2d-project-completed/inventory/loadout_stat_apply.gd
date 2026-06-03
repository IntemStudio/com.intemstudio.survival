class_name LoadoutStatApply
extends RefCounted

## loadout 합산 stat_modifiers → Player·Gun에 적용할 배율·방어·체력 계산.

const BASE_MAX_HEALTH := 100.0
const BASE_MAX_STAMINA := 3.0
const FALLBACK_ATTACK_POWER := 12.0
## heart min/max 합산값 1당 최대 체력 보너스(툴팁 "+1 Heart" 체감용).
const HEART_HP_PER_POINT := 10.0
const POWER_DAMAGE_PER_POINT := 0.01
const POWER_RADIUS_PER_POINT := 0.01
const POWER_SOFTCAP_START := 50.0
const POWER_SOFTCAP_SLOPE := 0.5


static func get_mult(modifiers: Dictionary, key: String) -> float:
	return float(modifiers.get(key, 1.0))


# 장비·패시브 stamina flat 합산 → 최대 스태미나.
static func compute_max_stamina(modifiers: Dictionary) -> float:
	return BASE_MAX_STAMINA + float(modifiers.get("stamina", 0.0))


# 스태미나 회복 속도 배율(stamina_recovery_mult).
static func compute_stamina_regen_mult(modifiers: Dictionary) -> float:
	return get_mult(modifiers, "stamina_recovery_mult")


# 대시 지속 시간 배율(dash_duration_mult).
static func compute_dash_duration_mult(modifiers: Dictionary) -> float:
	return get_mult(modifiers, "dash_duration_mult")


# 대시 종료 후 추가 무적 시간(장비 max 병합 결과).
static func get_invincibility_after_dash_sec(modifiers: Dictionary) -> float:
	return float(modifiers.get("invincibility_after_dash_sec", 0.0))


# 피격(HP 실감) 후 추가 무적 시간(장비 max 병합 결과).
static func get_invincibility_after_damage_sec(modifiers: Dictionary) -> float:
	return float(modifiers.get("invincibility_after_damage_sec", 0.0))


# 이동 속도 배율(move_speed_mult).
static func compute_move_speed_mult(modifiers: Dictionary) -> float:
	return get_mult(modifiers, "move_speed_mult")


# 무기 공격 속도 배율 — attack_speed_mult × 타입별 APS mult.
static func compute_attack_speed_mult(modifiers: Dictionary, weapon: WeaponData) -> float:
	var mult := get_mult(modifiers, "attack_speed_mult")
	if weapon == null:
		return mult
	if weapon.is_melee():
		mult *= get_mult(modifiers, "melee_attack_speed_mult")
	elif weapon.is_magic():
		mult *= get_mult(modifiers, "magic_attack_speed_mult")
	elif weapon.is_ranged() or weapon.is_throwing():
		mult *= get_mult(modifiers, "ranged_attack_speed_mult")
	if weapon.is_orbit_attack():
		mult *= get_mult(modifiers, "companion_attack_speed_mult")
	return mult


# 무기 피해 배율 — weapon_damage_mult·damage_mult·타입/원소·레벨당 보정.
static func compute_damage_mult(
	modifiers: Dictionary,
	weapon: WeaponData,
	player_level: int = 1
) -> float:
	var mult := get_mult(modifiers, "weapon_damage_mult") * get_mult(modifiers, "damage_mult")
	var per_level := float(modifiers.get("damage_mult_per_level", 0.0))
	if not is_zero_approx(per_level):
		mult *= 1.0 + per_level * float(maxi(player_level, 1) - 1)

	if weapon == null:
		return mult

	if weapon.is_melee():
		mult *= get_mult(modifiers, "melee_damage_mult")
	elif weapon.is_magic():
		mult *= get_mult(modifiers, "magic_damage_mult")
	elif weapon.is_throwing():
		mult *= get_mult(modifiers, "throwing_damage_mult")
	elif weapon.is_ranged():
		mult *= get_mult(modifiers, "ranged_damage_mult")

	if weapon.is_orbit_attack():
		mult *= get_mult(modifiers, "companion_damage_mult")

	mult *= _element_damage_mult(modifiers, weapon.damage_element, weapon)
	return mult


# power 점감(soft cap) 적용 후 실효 파워 값을 계산합니다.
static func compute_effective_power(modifiers: Dictionary) -> float:
	var power := float(modifiers.get("power", 0.0))
	if power <= POWER_SOFTCAP_START:
		return power
	return POWER_SOFTCAP_START + (power - POWER_SOFTCAP_START) * POWER_SOFTCAP_SLOPE


# power 1당 무기 피해 +1%(점감 포함).
static func compute_power_damage_mult(modifiers: Dictionary) -> float:
	return 1.0 + compute_effective_power(modifiers) * POWER_DAMAGE_PER_POINT


# power 1당 범위/반경 +1%(점감 포함).
static func compute_power_radius_mult(modifiers: Dictionary) -> float:
	return 1.0 + compute_effective_power(modifiers) * POWER_RADIUS_PER_POINT


# min/max 합산 → 런 차지 수(heart·revive 등). min·max 평균을 반올림합니다.
static func compute_charge_count(modifiers: Dictionary, min_key: String, max_key: String) -> int:
	var lo := float(modifiers.get(min_key, 0.0))
	var hi := float(modifiers.get(max_key, 0.0))
	if lo <= 0.0 and hi <= 0.0:
		return 0
	return maxi(0, int(round((lo + hi) * 0.5)))


# revive_* 합산 → 런 부활 가능 횟수.
static func compute_revive_charges(modifiers: Dictionary) -> int:
	return compute_charge_count(modifiers, "revive_min", "revive_max")


# heart_* 합산 → 최대 체력. min·max 평균 × HEART_HP_PER_POINT.
# class_base_max_health가 있으면 직업 기본·레벨당 체력 위에 장비 heart를 더합니다.
static func compute_max_health(modifiers: Dictionary, player_level: int = 1) -> float:
	var level := maxi(player_level, 1)
	var heart_min := float(modifiers.get("heart_min", 0.0))
	var heart_max := float(modifiers.get("heart_max", 0.0))
	var heart_points := (heart_min + heart_max) * 0.5
	var class_base := float(modifiers.get("class_base_max_health", 0.0))
	if class_base > 0.0:
		var per_level := float(modifiers.get("class_max_health_per_level", 0.0))
		var class_hp := class_base + per_level * float(level - 1)
		return class_hp + heart_points * HEART_HP_PER_POINT
	return BASE_MAX_HEALTH + heart_points * HEART_HP_PER_POINT


# 직업 기본 공격력 + 레벨당 공격력(무기 피해 계수의 기준 값).
static func compute_class_attack_bonus(modifiers: Dictionary, player_level: int = 1) -> float:
	var class_base := float(modifiers.get("class_base_attack", 0.0))
	if class_base <= 0.0 and not modifiers.has("class_base_attack"):
		return 0.0
	var level := maxi(player_level, 1)
	var per_level := float(modifiers.get("class_attack_per_level", 0.0))
	return class_base + per_level * float(level - 1)


# 직업 기본 체력 회복 + 레벨당 회복(HP/초).
static func compute_health_regen_per_sec(modifiers: Dictionary, player_level: int = 1) -> float:
	if not modifiers.has("class_base_health_regen"):
		return 0.0
	var level := maxi(player_level, 1)
	var class_base := float(modifiers.get("class_base_health_regen", 0.0))
	var per_level := float(modifiers.get("class_health_regen_per_level", 0.0))
	return class_base + per_level * float(level - 1)


# block(고정 감소) 후 armor(% 감소) 순으로 피해를 줄입니다.
static func mitigate_incoming_damage(modifiers: Dictionary, amount: int) -> int:
	if amount <= 0:
		return 0
	var dmg := float(amount)
	var block_max := int(modifiers.get("block_max", 0))
	if block_max > 0:
		var block_min := int(modifiers.get("block_min", 0))
		dmg -= float(randi_range(block_min, block_max))
	dmg = maxf(dmg, 0.0)
	var armor_max := int(modifiers.get("armor_max", 0))
	if armor_max > 0:
		var armor_min := int(modifiers.get("armor_min", 0))
		var armor_rating := randi_range(armor_min, armor_max)
		if armor_rating > 0:
			dmg = dmg * 100.0 / (100.0 + float(armor_rating))
	return maxi(0, int(round(dmg)))


# 원소 배율 — weapon_type에서 이미 적용한 키(magic 등)는 중복 곱하지 않음.
static func _element_damage_mult(
	modifiers: Dictionary,
	element: String,
	weapon: WeaponData
) -> float:
	if weapon != null and weapon.is_magic() and element == "magic":
		return 1.0
	match element:
		"physical":
			return get_mult(modifiers, "physical_damage_mult")
		"fire":
			return get_mult(modifiers, "fire_damage_mult")
		"lightning":
			return get_mult(modifiers, "lightning_damage_mult")
		"cold":
			return get_mult(modifiers, "cold_damage_mult")
		"poison":
			return get_mult(modifiers, "poison_damage_mult")
		"nature":
			return get_mult(modifiers, "nature_damage_mult")
		"magic":
			return get_mult(modifiers, "magic_damage_mult")
		"energy":
			return get_mult(modifiers, "energy_damage_mult")
		_:
			return 1.0


static func find_combat_player() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var game := tree.root.get_node_or_null("Game")
	if game == null:
		return null
	var player := game.get_node_or_null("Player")
	if player != null and player.has_method("add_weapon"):
		return player
	return null


static func roll_combat_damage(weapon: WeaponData) -> int:
	var player := find_combat_player()
	if player and player.has_method(&"roll_weapon_damage"):
		return player.roll_weapon_damage(weapon)
	if weapon:
		return weapon.compute_damage_from_attack(FALLBACK_ATTACK_POWER)
	return 1


static func get_effective_attacks_per_second(weapon: WeaponData) -> float:
	if weapon == null:
		return 1.0
	var player := find_combat_player()
	if player and player.has_method(&"get_effective_attacks_per_second"):
		return player.get_effective_attacks_per_second(weapon)
	return weapon.attacks_per_second


static func get_combat_power_radius_mult() -> float:
	var player := find_combat_player()
	if player and player.has_method(&"get_power_radius_mult"):
		return float(player.call(&"get_power_radius_mult"))
	return 1.0
