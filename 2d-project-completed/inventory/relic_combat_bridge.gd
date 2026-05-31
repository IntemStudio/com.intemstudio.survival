class_name RelicCombatBridge
extends RefCounted

## 가방 유물 보유 효과 — on-hit·지연 burst tick.

const _RelicCatalog := preload("res://inventory/relic_catalog.gd")
const RelicDataScript := preload("res://inventory/relic_data.gd")

static var _held_relic_ids: Array[StringName] = []
static var _pending_bursts: Array[Dictionary] = []


static func clear() -> void:
	_held_relic_ids.clear()
	_pending_bursts.clear()


static func refresh_from_bag(loadout: PlayerLoadoutState) -> void:
	_held_relic_ids.clear()
	if loadout == null:
		return
	var seen: Dictionary = {}
	for bag_id in loadout.bag_ids:
		var key: StringName = StringName(String(bag_id).strip_edges())
		if key.is_empty() or seen.has(key):
			continue
		if not _RelicCatalog.has_relic(key):
			continue
		seen[key] = true
		_held_relic_ids.append(key)


static func on_weapon_hit_mob(mob: Mob, weapon: WeaponData, raw_damage: int) -> void:
	if mob == null or weapon == null or raw_damage <= 0:
		return
	for relic_id in _held_relic_ids:
		var relic := _RelicCatalog.get_relic(relic_id)
		if relic == null:
			continue
		match relic.held_effect_kind:
			RelicDataScript.HeldEffectKind.ON_HIT_MOB_STATUS:
				if not relic.effect_status_id.is_empty():
					mob.apply_status(relic.effect_status_id, weapon)
			RelicDataScript.HeldEffectKind.ON_HIT_DELAYED_BURST:
				_schedule_delayed_burst(mob, weapon, raw_damage, relic)


static func tick(delta: float) -> void:
	if delta <= 0.0 or _pending_bursts.is_empty():
		return
	for index in range(_pending_bursts.size() - 1, -1, -1):
		var pending: Dictionary = _pending_bursts[index]
		var elapsed: float = float(pending.get("elapsed", 0.0)) + delta
		pending["elapsed"] = elapsed
		var delay: float = float(pending.get("delay", 0.0))
		if elapsed < delay:
			continue
		_trigger_pending_burst(pending)
		_pending_bursts.remove_at(index)


static func get_held_relic_count(relic_id: StringName) -> bool:
	return _held_relic_ids.has(relic_id)


static func _schedule_delayed_burst(
	mob: Mob,
	weapon: WeaponData,
	raw_damage: int,
	relic: RelicDataScript
) -> void:
	var burst_position := mob.global_position
	if mob.has_method(&"get_footprint_global_center"):
		burst_position = mob.call(&"get_footprint_global_center") as Vector2
	var damage := maxi(roundi(float(raw_damage) * relic.burst_damage_ratio), 1)
	_pending_bursts.append({
		"position": burst_position,
		"damage": damage,
		"weapon": weapon,
		"radius": relic.burst_radius,
		"delay": relic.burst_delay_sec,
		"elapsed": 0.0,
	})


static func _trigger_pending_burst(pending: Dictionary) -> void:
	var weapon: WeaponData = pending.get("weapon") as WeaponData
	var damage: int = int(pending.get("damage", 0))
	var radius: float = float(pending.get("radius", 0.0))
	var origin: Vector2 = pending.get("position", Vector2.ZERO)
	if damage <= 0 or radius <= 0.0 or weapon == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("mobs"):
		if not is_instance_valid(node) or node is not Mob:
			continue
		var mob := node as Mob
		var mob_center := GroundShadowFootprint.get_combat_target_center(mob)
		if origin.distance_to(mob_center) > radius:
			continue
		DamageResolver.apply_weapon_to_mob(mob, damage, weapon)
