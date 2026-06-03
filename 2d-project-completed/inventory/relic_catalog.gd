class_name RelicCatalog
extends RefCounted

## 엘리트 유물 정의 — EliteAffixCatalog와 동일한 코드 등록 패턴.

const RelicDataScript = preload("res://inventory/relic_data.gd")

static var _cache: Dictionary = {}


static func get_relic(relic_id: StringName) -> RelicDataScript:
	_ensure_cache()
	return _cache.get(relic_id)


static func has_relic(relic_id: StringName) -> bool:
	_ensure_cache()
	return _cache.has(relic_id)


static func get_all_relic_ids() -> Array[StringName]:
	_ensure_cache()
	var ids: Array[StringName] = []
	for key in _cache.keys():
		ids.append(key)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


static func _ensure_cache() -> void:
	if not _cache.is_empty():
		return
	_register(
		&"relic_glacial",
		"빙하의 유물",
		RelicDataScript.HeldEffectKind.ON_HIT_MOB_STATUS,
		&"relic_chill",
		Color(0.65, 0.95, 1.0)
	)
	_register(
		&"relic_overloading",
		"과전하 유물",
		RelicDataScript.HeldEffectKind.ON_HIT_DELAYED_BURST,
		&"",
		Color(0.35, 0.55, 1.0),
		0.75,
		80.0,
		0.25
	)
	_register(
		&"relic_blazing",
		"불타는 유물",
		RelicDataScript.HeldEffectKind.ON_HIT_MOB_STATUS,
		&"relic_burn",
		Color(1.0, 0.42, 0.18)
	)
	_register(
		&"relic_mending",
		"수리 유물",
		RelicDataScript.HeldEffectKind.PERIODIC_SELF_HEAL,
		&"",
		Color(0.72, 0.58, 0.38),
		0.75,
		80.0,
		0.25,
		3.0,
		1.0
	)


static func _register(
	relic_id: StringName,
	display_name_ko: String,
	held_effect_kind: RelicDataScript.HeldEffectKind,
	effect_status_id: StringName = &"",
	tint: Color = Color.WHITE,
	burst_delay_sec: float = 0.75,
	burst_radius: float = 80.0,
	burst_damage_ratio: float = 0.25,
	heal_interval_sec: float = 3.0,
	heal_percent_max_hp: float = 1.0
) -> void:
	var data: RelicDataScript = RelicDataScript.new()
	data.item_id = String(relic_id)
	data.display_name_ko = display_name_ko
	data.rarity = "Legendary"
	data.held_effect_kind = held_effect_kind
	data.effect_status_id = effect_status_id
	data.tint = tint
	data.burst_delay_sec = burst_delay_sec
	data.burst_radius = burst_radius
	data.burst_damage_ratio = burst_damage_ratio
	data.heal_interval_sec = heal_interval_sec
	data.heal_percent_max_hp = heal_percent_max_hp
	_cache[relic_id] = data


static func register_all_to_registry(registry: ItemRegistry) -> void:
	if registry == null:
		return
	_ensure_cache()
	for relic_id in _cache.keys():
		var data: RelicDataScript = _cache[relic_id]
		if data != null:
			registry.register_relic(data)
