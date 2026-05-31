class_name EliteAffixApplier
extends RefCounted

## affix id를 Mob에 stat·tint·horn·runtime으로 적용합니다.

const ELITE_HORN_NODE_NAME := EliteAffixIds.HORN_NODE_NAME
const TINT_BLEND_WEIGHT := 0.5


static func apply(mob: Mob, affix_id: StringName) -> void:
	if mob == null or affix_id.is_empty():
		return
	var data := EliteAffixCatalog.get_affix(affix_id)
	if data == null or not data.enabled:
		push_warning("EliteAffixApplier: unknown or disabled affix '%s'" % String(affix_id))
		return

	mob.store_elite_pre_affix_attack_snapshot()
	_apply_stat_scaling(mob, data)
	_apply_visual(mob, data)
	mob.apply_elite_affix(affix_id)


static func _apply_stat_scaling(mob: Mob, data: EliteAffixData) -> void:
	var hp_mult := maxf(data.hp_mult, 1.0)
	var damage_mult := maxf(data.damage_mult, 1.0)

	var scaled_max := maxi(1, roundi(mob.max_health * hp_mult))
	mob.max_health = scaled_max
	mob.health = scaled_max
	mob._sync_health_bar()

	if mob.contact_attack_damage > 0:
		mob.contact_attack_damage = maxi(1, roundi(mob.contact_attack_damage * damage_mult))
	if mob.ranged_attack_enabled:
		if mob.ranged_damage_min > 0:
			mob.ranged_damage_min = maxi(1, roundi(mob.ranged_damage_min * damage_mult))
		if mob.ranged_damage_max > 0:
			mob.ranged_damage_max = maxi(
				mob.ranged_damage_min,
				roundi(mob.ranged_damage_max * damage_mult)
			)


static func _apply_visual(mob: Mob, data: EliteAffixData) -> void:
	mob.store_elite_affix_visual_baseline()
	var blended := mob.slime_tint.lerp(data.tint, TINT_BLEND_WEIGHT)
	mob.slime_tint = blended
	if mob.is_node_ready():
		var slime: CanvasItem = mob.get_node_or_null("%Slime") as CanvasItem
		if slime != null:
			slime.modulate = blended
	_spawn_horn_if_present(mob, data)


static func _spawn_horn_if_present(mob: Mob, data: EliteAffixData) -> void:
	if data.horn_scene == null or not mob.is_node_ready():
		return
	var slime := mob.get_node_or_null("%Slime") as Node2D
	if slime == null:
		return
	_remove_existing_horn(slime)
	var horn := data.horn_scene.instantiate() as Node2D
	if horn == null:
		return
	horn.name = String(ELITE_HORN_NODE_NAME)
	slime.add_child(horn)


static func _remove_existing_horn(slime: Node) -> void:
	var existing := slime.get_node_or_null(String(ELITE_HORN_NODE_NAME))
	if existing != null:
		existing.free()
