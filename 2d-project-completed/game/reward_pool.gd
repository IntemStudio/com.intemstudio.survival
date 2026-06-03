class_name RewardPool
extends RefCounted

## 레벨업·웨이브 보상 — 무기·강화·패시브 3택1 후보를 롤합니다.

const CHOICE_COUNT := 3
const PASSIVE_SLOT_CHANCE := 0.38
const WEAPON_UPGRADE_SLOT_CHANCE := 0.28


static func roll_choices(
	owned_weapons: Array[WeaponData],
	upgrade_weapons: Array[WeaponData],
	passive_state: PassiveRunState,
	weapon_state: WeaponRunState,
	player_level: int,
	wave_number: int,
	rng: RandomNumberGenerator,
	upgrade_bonus: int = 0,
	use_explicit_upgrade_pool: bool = false
) -> Array:
	var choices: Array = []
	var used_weapon_keys: Dictionary = {}
	var used_passive_ids: Dictionary = {}
	var upgrade_pool := _resolve_upgrade_pool(owned_weapons, upgrade_weapons, use_explicit_upgrade_pool)
	var can_weapons_new := not _build_weapon_pool(owned_weapons, used_weapon_keys).is_empty()
	var can_weapons_upgrade := _has_upgradeable_weapons(upgrade_pool, weapon_state)
	var can_passives := (
		passive_state != null
		and passive_state.has_upgradeable(_get_reward_passives(wave_number))
	)

	for _i in CHOICE_COUNT:
		var picked := false
		if can_passives and (can_weapons_new or can_weapons_upgrade):
			if rng.randf() < _passive_slot_weight(player_level, wave_number):
				var passive_choice := _pick_passive_choice(
					passive_state, used_passive_ids, wave_number, rng
				)
				if passive_choice != null:
					choices.append(passive_choice)
					used_passive_ids[passive_choice.passive.passive_id] = true
					picked = true
		if not picked and can_weapons_upgrade and can_weapons_new:
			if rng.randf() < WEAPON_UPGRADE_SLOT_CHANCE:
				var upgrade_choice := _pick_weapon_upgrade_choice(
					upgrade_pool, weapon_state, used_weapon_keys, rng, upgrade_bonus
				)
				if upgrade_choice != null:
					choices.append(upgrade_choice)
					used_weapon_keys[upgrade_choice.weapon.get_unique_key()] = true
					picked = true
		if not picked and can_weapons_new:
			var weapon_choice := _pick_weapon_choice(owned_weapons, used_weapon_keys, rng)
			if weapon_choice != null:
				choices.append(weapon_choice)
				used_weapon_keys[weapon_choice.weapon.get_unique_key()] = true
				picked = true
		if not picked and can_weapons_upgrade:
			var upgrade_fallback := _pick_weapon_upgrade_choice(
				upgrade_pool, weapon_state, used_weapon_keys, rng, upgrade_bonus
			)
			if upgrade_fallback != null:
				choices.append(upgrade_fallback)
				used_weapon_keys[upgrade_fallback.weapon.get_unique_key()] = true
				picked = true
		if not picked and can_passives:
			var passive_fallback := _pick_passive_choice(
				passive_state, used_passive_ids, wave_number, rng
			)
			if passive_fallback != null:
				choices.append(passive_fallback)
				used_passive_ids[passive_fallback.passive.passive_id] = true
	return choices


static func _passive_slot_weight(player_level: int, wave_number: int) -> float:
	var weight := PASSIVE_SLOT_CHANCE
	if player_level >= 5:
		weight += 0.05
	if wave_number >= 3:
		weight += 0.07
	return clampf(weight, 0.0, 0.65)


static func _get_reward_passives(wave_number: int) -> Array[PassiveData]:
	var pool: Array[PassiveData] = []
	for passive in PassiveCatalog.get_all():
		if _is_passive_allowed_in_context(passive, wave_number):
			pool.append(passive)
	return pool


static func _is_passive_allowed_in_context(passive: PassiveData, wave_number: int) -> bool:
	if passive == null:
		return false
	if passive.is_evolved_only():
		return false
	if wave_number > 0:
		return true
	if passive.passive_id == "wave_rider":
		return false
	return true


static func _resolve_upgrade_pool(
	owned_weapons: Array[WeaponData],
	upgrade_weapons: Array[WeaponData],
	use_explicit_upgrade_pool: bool = false
) -> Array[WeaponData]:
	if use_explicit_upgrade_pool:
		return upgrade_weapons
	if not upgrade_weapons.is_empty():
		return upgrade_weapons
	return owned_weapons


static func _has_upgradeable_weapons(
	owned_weapons: Array[WeaponData],
	weapon_state: WeaponRunState
) -> bool:
	if weapon_state == null:
		return false
	for weapon in owned_weapons:
		weapon_state.ensure_registered(weapon)
		if weapon_state.can_upgrade(weapon):
			return true
	return false


static func _pick_weapon_choice(
	owned_weapons: Array[WeaponData],
	used_keys: Dictionary,
	rng: RandomNumberGenerator
) -> RewardChoice:
	var pool := _build_weapon_pool(owned_weapons, used_keys)
	if pool.is_empty():
		return null
	return RewardChoice.from_weapon(pool[rng.randi_range(0, pool.size() - 1)])


static func _pick_weapon_upgrade_choice(
	upgrade_weapons: Array[WeaponData],
	weapon_state: WeaponRunState,
	used_keys: Dictionary,
	rng: RandomNumberGenerator,
	upgrade_bonus: int = 0
) -> RewardChoice:
	if weapon_state == null:
		return null
	var pool: Array[WeaponData] = []
	for weapon in upgrade_weapons:
		if used_keys.has(weapon.get_unique_key()):
			continue
		weapon_state.ensure_registered(weapon)
		if weapon_state.can_upgrade(weapon):
			pool.append(weapon)
	if pool.is_empty():
		return null
	var picked := pool[rng.randi_range(0, pool.size() - 1)]
	var current := weapon_state.get_level(picked)
	var delta := 1 + maxi(upgrade_bonus, 0)
	var target_level := mini(current + delta, WeaponRunState.MAX_LEVEL)
	return RewardChoice.from_weapon_upgrade(picked, current, target_level)


static func _pick_passive_choice(
	passive_state: PassiveRunState,
	used_ids: Dictionary,
	wave_number: int,
	rng: RandomNumberGenerator
) -> RewardChoice:
	var pool: Array[PassiveData] = []
	for passive in _get_reward_passives(wave_number):
		if used_ids.has(passive.passive_id):
			continue
		if not passive_state.can_accept(passive):
			continue
		pool.append(passive)
	if pool.is_empty():
		return null
	var picked := pool[rng.randi_range(0, pool.size() - 1)]
	var target_level := passive_state.get_level(picked.passive_id) + 1
	return RewardChoice.from_passive(picked, target_level)


static func _build_weapon_pool(
	owned_weapons: Array[WeaponData],
	extra_used_keys: Dictionary
) -> Array[WeaponData]:
	const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
	const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
	const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
	var pool: Array[WeaponData] = []
	var owned_keys: Dictionary = extra_used_keys.duplicate()
	for weapon in owned_weapons:
		owned_keys[weapon.get_unique_key()] = true
	for weapon in (
		RangedWeaponCatalog.get_all()
		+ MeleeWeaponCatalog.get_all()
		+ MagicWeaponCatalog.get_all()
	):
		if weapon.is_locked:
			continue
		if owned_keys.has(weapon.get_unique_key()):
			continue
		pool.append(weapon)
	return pool
