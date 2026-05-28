class_name TestArenaStatusEffectSnapshot
extends RefCounted

## 테스트 아레나 상태이상 스냅샷 — 카탈로그 기본값·세션·user:// 저장(F6 전용).

const SAVE_PATH := "user://test_arena_status_effect_snapshots.cfg"

const BASE_FIELD_DEFS := [
	{"property": "duration_seconds", "label": "지속 시간(초)", "min": 0.0, "max": 60.0, "step": 0.1},
	{"property": "max_stacks", "label": "최대 중첩", "min": 0.0, "max": 32.0, "step": 1.0, "integer": true},
	{"property": "damage_taken_mult", "label": "피해 배율", "min": 0.1, "max": 5.0, "step": 0.05},
	{"property": "move_speed_mult", "label": "이동속도 배율", "min": 0.1, "max": 2.0, "step": 0.05},
]
const DOT_FIELD_DEFS := [
	{"property": "tick_damage_min", "label": "틱 최소 피해", "min": 0.0, "max": 999.0, "step": 1.0, "integer": true},
	{"property": "tick_damage_max", "label": "틱 최대 피해", "min": 0.0, "max": 999.0, "step": 1.0, "integer": true},
	{"property": "tick_interval", "label": "틱 간격(초)", "min": 0.05, "max": 10.0, "step": 0.05},
]

var _baselines: Dictionary = {}
var _saved: Dictionary = {}
var _session: Dictionary = {}


func register_status(status_id: StringName) -> void:
	if status_id == &"" or _baselines.has(status_id):
		return
	var data := StatusEffectCatalog.get_status(status_id)
	if data == null:
		return
	_baselines[status_id] = _capture_values(data)


func register_all_catalog_statuses() -> void:
	for status_id in StatusEffectCatalog.get_all_status_ids():
		register_status(status_id)


func load_from_disk() -> void:
	_saved.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("TestArenaStatusEffectSnapshot: load failed (%s)" % error_string(err))
		return
	for section in cfg.get_sections():
		if not section.begins_with("status/"):
			continue
		var status_id := StringName(section.trim_prefix("status/"))
		var overrides: Dictionary = {}
		for key in cfg.get_section_keys(section):
			overrides[key] = cfg.get_value(section, key)
		if not overrides.is_empty():
			_saved[status_id] = overrides


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	for status_id in _saved:
		var section := "status/%s" % String(status_id)
		for key in _saved[status_id]:
			cfg.set_value(section, key, _saved[status_id][key])
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


func supports_status_tuning(status_id: StringName) -> bool:
	register_status(status_id)
	return _baselines.has(status_id)


func get_field_defs(status_id: StringName) -> Array:
	if not supports_status_tuning(status_id):
		return []
	var result: Array = BASE_FIELD_DEFS.duplicate(true)
	var baseline: Dictionary = _baselines.get(status_id, {})
	var has_dot := (
		float(baseline.get("tick_interval", 0.0)) > 0.0
		or int(baseline.get("tick_damage_max", 0)) > 0
		or int(baseline.get("tick_damage_min", 0)) > 0
	)
	if has_dot:
		result.append_array(DOT_FIELD_DEFS.duplicate(true))
	return result


func build_tuned_values(status_id: StringName) -> Dictionary:
	if not supports_status_tuning(status_id):
		return {}
	var tuned: Dictionary = _baselines[status_id].duplicate(true)
	_apply_overrides(tuned, _saved.get(status_id, {}))
	_apply_overrides(tuned, _session.get(status_id, {}))
	_clamp_tuned_values(tuned)
	return tuned


func apply_to_catalog(status_id: StringName) -> void:
	var data := StatusEffectCatalog.get_status(status_id)
	if data == null:
		return
	var tuned := build_tuned_values(status_id)
	for field_def in get_field_defs(status_id):
		var property: String = field_def["property"]
		if not tuned.has(property):
			continue
		data.set(property, tuned[property])


func apply_saved_to_catalog() -> void:
	for status_id_variant in _saved.keys():
		var status_id := StringName(status_id_variant)
		apply_to_catalog(status_id)


func get_session_overrides(status_id: StringName) -> Dictionary:
	return _session.get(status_id, {}).duplicate()


func set_session_value(status_id: StringName, property: String, value: Variant) -> void:
	if not _session.has(status_id):
		_session[status_id] = {}
	_session[status_id][property] = value


func has_saved_snapshot(status_id: StringName) -> bool:
	return _saved.has(status_id) and not _saved[status_id].is_empty()


func save_status(status_id: StringName) -> void:
	if not _session.has(status_id):
		if _saved.has(status_id):
			_saved.erase(status_id)
			save_to_disk()
		return
	if not _saved.has(status_id):
		_saved[status_id] = {}
	for key in _session[status_id]:
		_saved[status_id][key] = _session[status_id][key]
	save_to_disk()


func reset_status(status_id: StringName) -> void:
	_session.erase(status_id)
	_saved.erase(status_id)
	save_to_disk()
	apply_to_catalog(status_id)


func _capture_values(data: StatusEffectData) -> Dictionary:
	var result: Dictionary = {}
	for field_def in BASE_FIELD_DEFS:
		var property: String = field_def["property"]
		result[property] = data.get(property)
	for field_def in DOT_FIELD_DEFS:
		var property: String = field_def["property"]
		result[property] = data.get(property)
	return result


func _apply_overrides(values: Dictionary, overrides: Dictionary) -> void:
	for key in overrides:
		values[key] = overrides[key]


func _clamp_tuned_values(values: Dictionary) -> void:
	if int(values.get("max_stacks", 1)) < 0:
		values["max_stacks"] = 0
	var tick_min := int(values.get("tick_damage_min", 0))
	var tick_max := int(values.get("tick_damage_max", 0))
	if tick_max < tick_min:
		values["tick_damage_max"] = tick_min
	if float(values.get("tick_interval", 0.0)) <= 0.0 and int(values.get("tick_damage_max", 0)) > 0:
		values["tick_interval"] = 0.1
