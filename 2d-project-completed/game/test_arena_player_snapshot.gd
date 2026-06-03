class_name TestArenaPlayerSnapshot
extends RefCounted

## F6 플레이어 튜닝 스냅샷 — baseline·저장(user://)·세션(미저장).

const SAVE_PATH := "user://test_arena_player_snapshots.cfg"
const DEFAULT_BASE_MOVE_SPEED := 600.0
const DEFAULT_DEFAULT_WEAPON_ID := "katana"
const BASE_MOVE_SPEED_PROPERTY := "base_move_speed"
const DEFAULT_WEAPON_ID_PROPERTY := "default_weapon_id"
const CLASS_SECTION_PREFIX := "class/"
const VALUE_KIND_MULT_BONUS_PERCENT := "mult_bonus_percent"
const VALUE_KIND_FLAT_FLOAT := "flat_float"
const VALUE_KIND_FLAT_INT := "flat_int"

const TUNING_STATE_DEFAULT := &"default"
const TUNING_STATE_SAVED := &"saved"
const TUNING_STATE_SESSION := &"session"

const MULT_BONUS_PERCENT_MIN := -90.0
const MULT_BONUS_PERCENT_MAX := 200.0
const MULT_BONUS_PERCENT_STEP := 1.0

const CLASS_STAT_FIELD_DEFS := {
	"base_max_health": {
		"label": "최대 체력(기본)",
		"min": 1.0,
		"max": 999.0,
		"step": 1.0,
		"integer": true,
		"value_kind": VALUE_KIND_FLAT_INT,
	},
	"max_health_per_level": {
		"label": "최대 체력(레벨당)",
		"min": 0.0,
		"max": 999.0,
		"step": 1.0,
		"integer": true,
		"value_kind": VALUE_KIND_FLAT_INT,
	},
	"base_attack": {
		"label": "공격력(기본)",
		"min": 0.0,
		"max": 999.0,
		"step": 0.1,
		"integer": false,
		"value_kind": VALUE_KIND_FLAT_FLOAT,
	},
	"attack_per_level": {
		"label": "공격력(레벨당)",
		"min": 0.0,
		"max": 99.0,
		"step": 0.1,
		"integer": false,
		"value_kind": VALUE_KIND_FLAT_FLOAT,
	},
	"base_health_regen": {
		"label": "체력 회복(기본)",
		"min": 0.0,
		"max": 99.0,
		"step": 0.1,
		"integer": false,
		"value_kind": VALUE_KIND_FLAT_FLOAT,
	},
	"health_regen_per_level": {
		"label": "체력 회복(레벨당)",
		"min": 0.0,
		"max": 99.0,
		"step": 0.1,
		"integer": false,
		"value_kind": VALUE_KIND_FLAT_FLOAT,
	},
	"move_speed_mult": {
		"label": "이동 속도",
		"min": MULT_BONUS_PERCENT_MIN,
		"max": MULT_BONUS_PERCENT_MAX,
		"step": MULT_BONUS_PERCENT_STEP,
		"integer": true,
		"value_kind": VALUE_KIND_MULT_BONUS_PERCENT,
	},
	"base_defense": {
		"label": "방어력",
		"min": 0.0,
		"max": 999.0,
		"step": 1.0,
		"integer": true,
		"value_kind": VALUE_KIND_FLAT_INT,
	},
}

const BASE_MOVE_SPEED_DEF := {
	"property": BASE_MOVE_SPEED_PROPERTY,
	"label": "기본 이동속도",
	"min": 100.0,
	"max": 2000.0,
	"step": 10.0,
	"integer": true,
	"value_kind": VALUE_KIND_FLAT_INT,
}

var _saved_base_move_speed := DEFAULT_BASE_MOVE_SPEED
var _session_base_move_speed := DEFAULT_BASE_MOVE_SPEED
var _saved_default_weapon_id := DEFAULT_DEFAULT_WEAPON_ID
var _session_default_weapon_id := DEFAULT_DEFAULT_WEAPON_ID
var _saved_class_stats: Dictionary = {}
var _session_class_stats: Dictionary = {}
var _persisted_on_disk := false


func load_from_disk() -> void:
	_persisted_on_disk = false
	_saved_base_move_speed = DEFAULT_BASE_MOVE_SPEED
	_session_base_move_speed = DEFAULT_BASE_MOVE_SPEED
	_saved_default_weapon_id = DEFAULT_DEFAULT_WEAPON_ID
	_session_default_weapon_id = DEFAULT_DEFAULT_WEAPON_ID
	_saved_class_stats.clear()
	_session_class_stats.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("TestArenaPlayerSnapshot: load failed (%s)" % error_string(err))
		return
	if err != OK:
		return
	_persisted_on_disk = true
	if cfg.has_section_key("player", BASE_MOVE_SPEED_PROPERTY):
		_saved_base_move_speed = float(
			cfg.get_value("player", BASE_MOVE_SPEED_PROPERTY, DEFAULT_BASE_MOVE_SPEED)
		)
	if cfg.has_section_key("player", DEFAULT_WEAPON_ID_PROPERTY):
		_saved_default_weapon_id = str(
			cfg.get_value("player", DEFAULT_WEAPON_ID_PROPERTY, DEFAULT_DEFAULT_WEAPON_ID)
		)
	for section in cfg.get_sections():
		if not section.begins_with(CLASS_SECTION_PREFIX):
			continue
		var class_id := section.trim_prefix(CLASS_SECTION_PREFIX)
		if class_id.is_empty():
			continue
		var stats: Dictionary = {}
		for key in cfg.get_section_keys(section):
			stats[key] = cfg.get_value(section, key)
		if not stats.is_empty():
			_saved_class_stats[class_id] = stats
	_session_base_move_speed = _saved_base_move_speed
	_session_default_weapon_id = _saved_default_weapon_id


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", BASE_MOVE_SPEED_PROPERTY, _saved_base_move_speed)
	cfg.set_value("player", DEFAULT_WEAPON_ID_PROPERTY, _saved_default_weapon_id)
	for class_id in _saved_class_stats:
		var section := "%s%s" % [CLASS_SECTION_PREFIX, class_id]
		for key in _saved_class_stats[class_id]:
			cfg.set_value(section, key, _saved_class_stats[class_id][key])
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)
	_persisted_on_disk = true


func get_effective_base_move_speed() -> float:
	return _session_base_move_speed


func get_effective_default_weapon_id() -> String:
	return _session_default_weapon_id


func set_session_default_weapon_id(weapon_id: String) -> void:
	var key := weapon_id.strip_edges()
	_session_default_weapon_id = key if not key.is_empty() else DEFAULT_DEFAULT_WEAPON_ID


func get_tuned_value(property: String, class_id: String = "") -> float:
	if property == BASE_MOVE_SPEED_PROPERTY:
		return _session_base_move_speed
	if not class_id.is_empty():
		return float(get_tuned_class_stat(class_id, property))
	return 0.0


func get_spin_display_value(class_id: String, field_def: Dictionary) -> float:
	var property: String = field_def["property"]
	var tuned: Variant = get_tuned_class_stat(class_id, property)
	if field_def.get("value_kind", "") == VALUE_KIND_MULT_BONUS_PERCENT:
		return mult_to_bonus_percent(float(tuned))
	return float(tuned)


func get_baseline_value(property: String, class_id: String = "") -> float:
	if property == BASE_MOVE_SPEED_PROPERTY:
		return DEFAULT_BASE_MOVE_SPEED
	if not class_id.is_empty():
		return float(_get_catalog_stat(class_id, property))
	return 0.0


func set_session_base_move_speed(value: float) -> void:
	_session_base_move_speed = clampf(
		value,
		float(BASE_MOVE_SPEED_DEF["min"]),
		float(BASE_MOVE_SPEED_DEF["max"])
	)


func set_session_class_stat(class_id: String, property: String, value: Variant) -> void:
	if class_id.is_empty() or property.is_empty():
		return
	if not _session_class_stats.has(class_id):
		_session_class_stats[class_id] = {}
	if str(property).ends_with("_mult"):
		_session_class_stats[class_id][property] = _clamp_mult(float(value))
	elif _is_integer_class_field(property):
		_session_class_stats[class_id][property] = int(roundf(float(value)))
	else:
		_session_class_stats[class_id][property] = float(value)


func set_session_class_mult(class_id: String, property: String, mult_value: float) -> void:
	set_session_class_stat(class_id, property, mult_value)


func spin_value_to_stored(field_def: Dictionary, spin_value: float) -> Variant:
	if field_def.get("value_kind", "") == VALUE_KIND_MULT_BONUS_PERCENT:
		return bonus_percent_to_mult(spin_value)
	if field_def.get("value_kind", "") == VALUE_KIND_FLAT_FLOAT:
		return float(spin_value)
	return int(roundf(spin_value))


func get_class_stat_field_defs(_player_class: PlayerClassData) -> Array:
	var defs: Array = []
	for property in CLASS_STAT_FIELD_DEFS:
		var field_def: Dictionary = CLASS_STAT_FIELD_DEFS[property].duplicate(true)
		field_def["property"] = property
		defs.append(field_def)
	return defs


func get_class_mult_field_defs(player_class: PlayerClassData) -> Array:
	return get_class_stat_field_defs(player_class)


func build_class_stat_modifiers(class_id: String) -> Dictionary:
	var player_class := PlayerClassCatalog.get_by_id(StringName(class_id))
	if player_class == null:
		return {}
	var fields := _get_effective_class_fields(class_id, player_class)
	return _modifiers_from_class_fields(fields)


func get_tuned_class_stat(class_id: String, property: String) -> Variant:
	var baseline: Variant = _get_catalog_stat(class_id, property)
	var saved_stats: Dictionary = _saved_class_stats.get(class_id, {})
	if saved_stats.has(property):
		baseline = saved_stats[property]
	var session_stats: Dictionary = _session_class_stats.get(class_id, {})
	if session_stats.has(property):
		return session_stats[property]
	return baseline


func get_tuned_class_mult(class_id: String, property: String) -> float:
	return float(get_tuned_class_stat(class_id, property))


func mult_to_bonus_percent(mult: float) -> float:
	return (mult - 1.0) * 100.0


func bonus_percent_to_mult(percent: float) -> float:
	return _clamp_mult(1.0 + percent / 100.0)


func has_saved_snapshot() -> bool:
	return _persisted_on_disk


func has_unsaved_session_changes() -> bool:
	if not is_equal_approx(_session_base_move_speed, _saved_base_move_speed):
		return true
	if _session_default_weapon_id != _saved_default_weapon_id:
		return true
	for class_id in _session_class_stats:
		var session_stats: Dictionary = _session_class_stats[class_id]
		var saved_stats: Dictionary = _saved_class_stats.get(class_id, {})
		for property in session_stats:
			var saved_value: Variant = (
				saved_stats[property]
				if saved_stats.has(property)
				else _get_catalog_stat(class_id, property)
			)
			if not _stat_values_equal(session_stats[property], saved_value, String(property)):
				return true
	return false


func get_property_tuning_state(property: String, class_id: String = "") -> StringName:
	if property == BASE_MOVE_SPEED_PROPERTY:
		if not is_equal_approx(_session_base_move_speed, _saved_base_move_speed):
			return TUNING_STATE_SESSION
		if _persisted_on_disk:
			return TUNING_STATE_SAVED
		return TUNING_STATE_DEFAULT
	if class_id.is_empty():
		return TUNING_STATE_DEFAULT
	if _session_class_stats.get(class_id, {}).has(property):
		var saved_value: Variant = _get_saved_or_catalog_stat(class_id, property)
		if not _stat_values_equal(_session_class_stats[class_id][property], saved_value, property):
			return TUNING_STATE_SESSION
	if _saved_class_stats.get(class_id, {}).has(property):
		if not _stat_values_equal(
			_saved_class_stats[class_id][property],
			_get_catalog_stat(class_id, property),
			property
		):
			return TUNING_STATE_SAVED
	return TUNING_STATE_DEFAULT


# 세션 변경을 user:// 저장값에 merge합니다.
func save_player() -> void:
	commit_session_to_saved()
	save_to_disk()


# session만 제거하고 저장된 스냅샷(baseline+saved)으로 되돌립니다.
func reset_player() -> void:
	_session_base_move_speed = _saved_base_move_speed
	_session_default_weapon_id = _saved_default_weapon_id
	_session_class_stats.clear()


func commit_session_to_saved() -> void:
	_saved_base_move_speed = _session_base_move_speed
	_saved_default_weapon_id = _session_default_weapon_id
	for class_id in _session_class_stats:
		if not _saved_class_stats.has(class_id):
			_saved_class_stats[class_id] = {}
		for property in _session_class_stats[class_id]:
			_saved_class_stats[class_id][property] = _session_class_stats[class_id][property]


static func _clamp_mult(mult: float) -> float:
	return clampf(mult, 0.1, 3.0)


static func _stat_values_equal(a: Variant, b: Variant, property: String) -> bool:
	if str(property).ends_with("_mult"):
		return is_equal_approx(float(a), float(b))
	if _is_integer_class_field(property):
		return int(a) == int(b)
	return is_equal_approx(float(a), float(b))


static func _is_integer_class_field(property: String) -> bool:
	var field_def: Dictionary = CLASS_STAT_FIELD_DEFS.get(property, {})
	return field_def.get("value_kind", "") == VALUE_KIND_FLAT_INT


func _get_catalog_stat(class_id: String, property: String) -> Variant:
	var player_class := PlayerClassCatalog.get_by_id(StringName(class_id))
	if player_class == null:
		if str(property).ends_with("_mult"):
			return 1.0
		return 0
	return _read_class_field(player_class, property)


func _get_saved_or_catalog_stat(class_id: String, property: String) -> Variant:
	var saved_stats: Dictionary = _saved_class_stats.get(class_id, {})
	if saved_stats.has(property):
		return saved_stats[property]
	return _get_catalog_stat(class_id, property)


func _get_effective_class_fields(class_id: String, player_class: PlayerClassData) -> Dictionary:
	var fields := _class_fields_from_data(player_class)
	for property in CLASS_STAT_FIELD_DEFS:
		fields[property] = get_tuned_class_stat(class_id, property)
	return fields


static func _class_fields_from_data(player_class: PlayerClassData) -> Dictionary:
	return {
		"base_max_health": player_class.base_max_health,
		"max_health_per_level": player_class.max_health_per_level,
		"base_attack": player_class.base_attack,
		"attack_per_level": player_class.attack_per_level,
		"base_health_regen": player_class.base_health_regen,
		"health_regen_per_level": player_class.health_regen_per_level,
		"move_speed_mult": player_class.move_speed_mult,
		"base_defense": player_class.base_defense,
	}


static func _read_class_field(player_class: PlayerClassData, property: String) -> Variant:
	var fields := _class_fields_from_data(player_class)
	if fields.has(property):
		return fields[property]
	if str(property).ends_with("_mult"):
		return 1.0
	return 0


static func _modifiers_from_class_fields(fields: Dictionary) -> Dictionary:
	var data := PlayerClassData.new()
	data.base_max_health = float(fields.get("base_max_health", 110.0))
	data.max_health_per_level = float(fields.get("max_health_per_level", 33.0))
	data.base_attack = float(fields.get("base_attack", 12.0))
	data.attack_per_level = float(fields.get("attack_per_level", 2.4))
	data.base_health_regen = float(fields.get("base_health_regen", 1.0))
	data.health_regen_per_level = float(fields.get("health_regen_per_level", 0.2))
	data.move_speed_mult = float(fields.get("move_speed_mult", 1.0))
	data.base_defense = int(fields.get("base_defense", 0))
	return data.build_stat_modifiers()
