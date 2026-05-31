class_name PlayerDebuffCatalog
extends RefCounted

## v0.1 플레이어 debuff id·수치 등록.

const PlayerDebuffDataScript = preload("res://elite/player_debuff_data.gd")

static var _cache: Dictionary = {}


static func get_debuff(debuff_id: StringName):
	_ensure_cache()
	return _cache.get(debuff_id)


static func has_debuff(debuff_id: StringName) -> bool:
	_ensure_cache()
	return _cache.has(debuff_id)


static func get_display_name(debuff_id: StringName) -> String:
	var data = get_debuff(debuff_id)
	return data.display_name_ko if data != null else String(debuff_id)


static func get_all_debuff_ids() -> Array[StringName]:
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
		&"elite_burn",
		"화상",
		{
			"duration_sec": 4.0,
			"has_dot": true,
			"dot_tick_interval": 0.5,
			"dot_percent_max_hp": 5.0,
			"blocks_healing": true,
			"blocks_stamina_regen": true,
		}
	)
	_register(
		&"elite_bomb",
		"부착 폭탄",
		{
			"duration_sec": 1.5,
			"has_expire_burst": true,
			"burst_radius": 160.0,
			"burst_damage_mult": 0.5,
		}
	)
	_register(
		&"elite_chill",
		"냉기",
		{
			"duration_sec": 1.5,
			"move_speed_mult": 0.2,
		}
	)
	_register(
		&"elite_freeze",
		"동결",
		{
			"duration_sec": 1.5,
			"locks_movement": true,
		}
	)


static func _register(debuff_id: StringName, display_name_ko: String, config: Dictionary = {}) -> void:
	var data: PlayerDebuffData = PlayerDebuffDataScript.new()
	data.debuff_id = debuff_id
	data.display_name_ko = display_name_ko
	data.duration_sec = float(config.get("duration_sec", 0.0))
	data.move_speed_mult = float(config.get("move_speed_mult", 1.0))
	data.blocks_healing = bool(config.get("blocks_healing", false))
	data.blocks_stamina_regen = bool(config.get("blocks_stamina_regen", false))
	data.locks_movement = bool(config.get("locks_movement", false))
	data.has_dot = bool(config.get("has_dot", false))
	data.dot_tick_interval = float(config.get("dot_tick_interval", 0.0))
	data.dot_percent_max_hp = float(config.get("dot_percent_max_hp", 0.0))
	data.has_expire_burst = bool(config.get("has_expire_burst", false))
	data.burst_radius = float(config.get("burst_radius", 0.0))
	data.burst_damage_mult = float(config.get("burst_damage_mult", 0.0))
	_cache[debuff_id] = data
