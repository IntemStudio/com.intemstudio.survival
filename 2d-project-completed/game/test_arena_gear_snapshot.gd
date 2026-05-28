class_name TestArenaGearSnapshot
extends RefCounted

## 테스트 아레나 장비 stat_modifiers 스냅샷 — 카탈로그 기본값·세션·user:// 저장(F6 전용).

const SAVE_PATH := "user://test_arena_gear_snapshots.cfg"

const BLOCK_MIN_DEF := {
	"property": "block_min",
	"label": "막기 최소",
	"min": 0.0,
	"max": 999.0,
	"step": 1.0,
	"integer": true,
}
const BLOCK_MAX_DEF := {
	"property": "block_max",
	"label": "막기 최대",
	"min": 0.0,
	"max": 999.0,
	"step": 1.0,
	"integer": true,
}
const ARMOR_MIN_DEF := {
	"property": "armor_min",
	"label": "방어 최소",
	"min": 0.0,
	"max": 999.0,
	"step": 1.0,
	"integer": true,
}
const ARMOR_MAX_DEF := {
	"property": "armor_max",
	"label": "방어 최대",
	"min": 0.0,
	"max": 999.0,
	"step": 1.0,
	"integer": true,
}
const WEAPON_DAMAGE_MULT_DEF := {
	"property": "weapon_damage_mult",
	"label": "무기 피해 배율",
	"min": 0.05,
	"max": 10.0,
	"step": 0.05,
}
const POWER_DEF := {
	"property": "power",
	"label": "파워",
	"min": 0.0,
	"max": 999.0,
	"step": 1.0,
	"integer": true,
}
const REVIVE_MIN_DEF := {
	"property": "revive_min",
	"label": "부활 최소",
	"min": 0.0,
	"max": 99.0,
	"step": 1.0,
	"integer": true,
}
const REVIVE_MAX_DEF := {
	"property": "revive_max",
	"label": "부활 최대",
	"min": 0.0,
	"max": 99.0,
	"step": 1.0,
	"integer": true,
}
const STAMINA_DEF := {
	"property": "stamina",
	"label": "스태미나",
	"min": 0.0,
	"max": 999.0,
	"step": 1.0,
	"integer": true,
}
const STAMINA_RECOVERY_MULT_DEF := {
	"property": "stamina_recovery_mult",
	"label": "스태미나 회복 배율",
	"min": 0.05,
	"max": 10.0,
	"step": 0.05,
}
const INVINCIBILITY_AFTER_DAMAGE_DEF := {
	"property": "invincibility_after_damage_sec",
	"label": "피격 후 무적(초)",
	"min": 0.0,
	"max": 30.0,
	"step": 0.05,
}

var _baselines: Dictionary = {}
var _saved: Dictionary = {}
var _session: Dictionary = {}


func register_catalog_gear(gear: GearData) -> void:
	if gear == null:
		return
	var gear_id := gear.get_unique_key()
	if _baselines.has(gear_id):
		return
	_baselines[gear_id] = GearStatMerge.normalize_modifiers(gear.stat_modifiers).duplicate(true)


func load_from_disk() -> void:
	_saved.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("TestArenaGearSnapshot: load failed (%s)" % error_string(err))
		return

	for section in cfg.get_sections():
		if not section.begins_with("gear/"):
			continue
		var gear_id := section.trim_prefix("gear/")
		var overrides: Dictionary = {}
		for key in cfg.get_section_keys(section):
			overrides[key] = cfg.get_value(section, key)
		if not overrides.is_empty():
			_saved[gear_id] = overrides


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	for gear_id in _saved:
		var section := "gear/%s" % gear_id
		for key in _saved[gear_id]:
			cfg.set_value(section, key, _saved[gear_id][key])
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


func get_field_defs(gear: GearData) -> Array:
	if gear == null:
		return []
	var stats := GearStatMerge.normalize_modifiers(gear.stat_modifiers)
	var result: Array = []
	if stats.has("block_min") or stats.has("block_max"):
		result.append(BLOCK_MIN_DEF.duplicate(true))
		result.append(BLOCK_MAX_DEF.duplicate(true))
	if stats.has("armor_min") or stats.has("armor_max"):
		result.append(ARMOR_MIN_DEF.duplicate(true))
		result.append(ARMOR_MAX_DEF.duplicate(true))
	if stats.has("weapon_damage_mult"):
		result.append(WEAPON_DAMAGE_MULT_DEF.duplicate(true))
	if stats.has("power"):
		result.append(POWER_DEF.duplicate(true))
	if stats.has("revive_min") or stats.has("revive_max"):
		result.append(REVIVE_MIN_DEF.duplicate(true))
		result.append(REVIVE_MAX_DEF.duplicate(true))
	if stats.has("stamina"):
		result.append(STAMINA_DEF.duplicate(true))
	if stats.has("stamina_recovery_mult"):
		result.append(STAMINA_RECOVERY_MULT_DEF.duplicate(true))
	if stats.has("invincibility_after_damage_sec"):
		result.append(INVINCIBILITY_AFTER_DAMAGE_DEF.duplicate(true))
	return result


func supports_gear_tuning(gear: GearData) -> bool:
	return gear != null and not get_field_defs(gear).is_empty()


func build_tuned_stat_modifiers(gear_id: String) -> Dictionary:
	if not _baselines.has(gear_id):
		return {}
	var tuned: Dictionary = _baselines[gear_id].duplicate(true)
	_apply_overrides(tuned, _saved.get(gear_id, {}))
	_apply_overrides(tuned, _session.get(gear_id, {}))
	return tuned


func build_tuned_gear(catalog_gear: GearData) -> GearData:
	register_catalog_gear(catalog_gear)
	var gear_id := catalog_gear.get_unique_key()
	var tuned: GearData = catalog_gear.duplicate(true)
	tuned.stat_modifiers = build_tuned_stat_modifiers(gear_id)
	return tuned


# ItemRegistry gear_modifier_resolver — F6 튜닝된 stat_modifiers를 반환합니다.
func resolve_modifiers(item_id: String, base_modifiers: Dictionary) -> Dictionary:
	var key := item_id.strip_edges()
	if key.is_empty():
		return base_modifiers
	if not _baselines.has(key):
		return base_modifiers
	return build_tuned_stat_modifiers(key)


func get_tuning_spin_display_value(tuned_modifiers: Dictionary, property: String) -> float:
	return float(tuned_modifiers.get(property, 0.0))


func get_session_overrides(gear_id: String) -> Dictionary:
	return _session.get(gear_id, {}).duplicate()


func set_session_value(gear_id: String, property: String, value: Variant) -> void:
	if not _session.has(gear_id):
		_session[gear_id] = {}
	_session[gear_id][property] = value


func has_saved_snapshot(gear_id: String) -> bool:
	return _saved.has(gear_id) and not _saved[gear_id].is_empty()


func save_gear(gear_id: String) -> void:
	if not _session.has(gear_id):
		if _saved.has(gear_id):
			_saved.erase(gear_id)
			save_to_disk()
		return
	if not _saved.has(gear_id):
		_saved[gear_id] = {}
	for key in _session[gear_id]:
		_saved[gear_id][key] = _session[gear_id][key]
	save_to_disk()


func reset_gear(gear_id: String) -> void:
	_session.erase(gear_id)
	_saved.erase(gear_id)
	save_to_disk()


func _apply_overrides(modifiers: Dictionary, overrides: Dictionary) -> void:
	for key in overrides:
		modifiers[key] = overrides[key]
