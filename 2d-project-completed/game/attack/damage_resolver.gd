class_name DamageResolver
extends RefCounted

## 피해 해결 단일 관문 — AttackEntity·발사체는 HP를 직접 수정하지 않습니다.


static func apply_weapon_to_mob(mob: Node, amount: int, weapon: WeaponData) -> void:
	if amount <= 0 or weapon == null or mob == null:
		return
	if mob.has_method(&"apply_weapon_damage"):
		mob.apply_weapon_damage(amount, weapon)
	elif mob.has_method(&"take_damage"):
		mob.take_damage(amount)


static func apply_weapon_to_mob_from_context(mob: Node, context: AttackContext) -> void:
	if context == null or context.weapon == null:
		return
	apply_weapon_to_mob(mob, context.rolled_damage, context.weapon)


static func apply_mob_projectile_to_player(player: Node, amount: int) -> String:
	if player == null:
		return "player_null"
	if not player.has_method(&"apply_mob_projectile_damage"):
		return "player_missing_apply_mob_projectile_damage"
	return player.call(&"apply_mob_projectile_damage", amount) as String


# 몹 사망 폭발 등 — origin 기준 radius 안의 플레이어에게 1회 피해
static func apply_burst_damage_to_player_in_radius(
	origin: Vector2,
	radius: float,
	damage: int,
	on_hit: Callable = Callable()
) -> void:
	if damage <= 0 or radius <= 0.0:
		return
	var player := _find_player_for_combat_damage()
	if player == null or not player is Node2D:
		return
	var player_center := (player as Node2D).global_position
	if player.has_method(&"get_footprint_global_center"):
		player_center = player.call(&"get_footprint_global_center") as Vector2
	if origin.distance_to(player_center) > radius:
		return
	apply_mob_projectile_to_player(player, damage)
	if on_hit.is_valid():
		on_hit.call()


# glacial 사망 폭발 등 — radius 안 몹·플레이어 모두 중립 피해(무기 귀속 없음)
static func apply_neutral_burst_in_radius(
	origin: Vector2,
	radius: float,
	damage: int,
	on_player_hit: Callable = Callable()
) -> void:
	if damage <= 0 or radius <= 0.0:
		return
	_apply_neutral_burst_to_mobs(origin, radius, damage)
	apply_burst_damage_to_player_in_radius(origin, radius, damage, on_player_hit)


static func _apply_neutral_burst_to_mobs(origin: Vector2, radius: float, damage: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("mobs"):
		if not is_instance_valid(node) or node is not Mob:
			continue
		var mob := node as Mob
		if not mob.has_method(&"take_neutral_burst_damage"):
			continue
		var mob_center := GroundShadowFootprint.get_combat_target_center(mob)
		var slime := mob.get_node_or_null("%Slime")
		var mob_half := GroundShadowFootprint.footprint_half_extents_from_visual(slime)
		var mob_radius := maxf(mob_half.x, mob_half.y)
		if origin.distance_to(mob_center) <= radius + mob_radius:
			mob.take_neutral_burst_damage(damage)


static func _find_player_for_combat_damage() -> Node:
	var player := LoadoutStatApply.find_combat_player()
	if player != null:
		return player
	return Engine.get_main_loop().root.get_node_or_null("Game/Player")
