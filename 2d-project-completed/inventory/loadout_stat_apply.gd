class_name LoadoutStatApply
extends RefCounted

## loadout 합산 stat_modifiers → Player·Gun에 적용할 배율·방어·체력 계산.

const BASE_MAX_HEALTH := 100.0
## heart min/max 합산값 1당 최대 체력 보너스(툴팁 "+1 Heart" 체감용).
const HEART_HP_PER_POINT := 10.0


static func get_mult(modifiers: Dictionary, key: String) -> float:
	return float(modifiers.get(key, 1.0))


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


# heart_* 합산 → 최대 체력. min·max 평균 × HEART_HP_PER_POINT.
static func compute_max_health(modifiers: Dictionary) -> float:
	var heart_min := float(modifiers.get("heart_min", 0.0))
	var heart_max := float(modifiers.get("heart_max", 0.0))
	var heart_points := (heart_min + heart_max) * 0.5
	return BASE_MAX_HEALTH + heart_points * HEART_HP_PER_POINT


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
		return weapon.roll_damage()
	return 1


static func get_effective_attacks_per_second(weapon: WeaponData) -> float:
	if weapon == null:
		return 1.0
	var player := find_combat_player()
	if player and player.has_method(&"get_effective_attacks_per_second"):
		return player.get_effective_attacks_per_second(weapon)
	return weapon.attacks_per_second
