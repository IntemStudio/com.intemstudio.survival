class_name TestArenaWeaponSnapshot
extends RefCounted

## 테스트 아레나 무기 발사체 스냅샷 — 카탈로그 기본값·세션·user:// 저장.

const SAVE_PATH := "user://test_arena_weapon_snapshots.cfg"

const PIERCE_FIELD_DEF := {
	"property": "projectile_pierce_count",
	"label": "관통 수",
	"min": -1.0,
	"max": 32.0,
	"step": 1.0,
}

const FIELD_DEFS_BY_TYPE := {
	"Melee": [
		{"property": "melee_spread_count", "label": "탄막 수", "min": 1.0, "max": 32.0, "step": 1.0},
		{"property": "melee_spread_angle_deg", "label": "부채꼴(°)", "min": 0.0, "max": 360.0, "step": 1.0},
		{"property": "melee_projectile_speed", "label": "탄속", "min": 50.0, "max": 4000.0, "step": 25.0},
		{"property": "hit_count", "label": "타격 횟수", "min": 1.0, "max": 20.0, "step": 1.0},
		PIERCE_FIELD_DEF,
	],
	"Ranged": [
		{"property": "projectile_speed", "label": "탄속", "min": 50.0, "max": 4000.0, "step": 25.0},
		{"property": "burst_count", "label": "연사 발수", "min": 1.0, "max": 12.0, "step": 1.0},
		{"property": "burst_interval", "label": "연사 간격(초)", "min": 0.01, "max": 1.0, "step": 0.01},
		PIERCE_FIELD_DEF,
	],
	"Magic": [
		{"property": "projectile_speed", "label": "탄속", "min": 50.0, "max": 4000.0, "step": 25.0},
		{"property": "homing_strength", "label": "유도 강도", "min": 0.0, "max": 20.0, "step": 0.1},
		PIERCE_FIELD_DEF,
	],
}

const FIELD_DEFS_ORBIT := [
	{"property": "orbit_speed", "label": "궤도 회전 속도", "min": 0.5, "max": 15.0, "step": 0.1},
	{"property": "orbit_radius_extra", "label": "궤도 반경 보정", "min": 0.0, "max": 200.0, "step": 5.0},
	{"property": "attacks_per_second", "label": "타격 빈도(APS)", "min": 0.2, "max": 10.0, "step": 0.1},
]

const FIELD_DEFS_AREA_ZONE := [
	{"property": "throw_speed", "label": "투척 속도", "min": 100.0, "max": 2000.0, "step": 25.0},
	{"property": "throw_range", "label": "투척 사거리", "min": 100.0, "max": 2000.0, "step": 25.0},
	{"property": "aoe_radius", "label": "폭발 반경", "min": 20.0, "max": 400.0, "step": 5.0},
	{"property": "poison_damage_min", "label": "독 최소 피해", "min": 1.0, "max": 500.0, "step": 1.0},
	{"property": "poison_damage_max", "label": "독 최대 피해", "min": 1.0, "max": 500.0, "step": 1.0},
	{"property": "poison_duration", "label": "독 지속(초)", "min": 0.5, "max": 30.0, "step": 0.5},
	{"property": "poison_ticks_per_second", "label": "독 틱/초", "min": 0.5, "max": 10.0, "step": 0.5},
	{"property": "hit_count", "label": "존 타격 횟수", "min": 1.0, "max": 20.0, "step": 1.0},
	{"property": "attacks_per_second", "label": "투척 빈도(APS)", "min": 0.2, "max": 10.0, "step": 0.1},
]

var _baselines: Dictionary = {}
var _saved: Dictionary = {}
var _session: Dictionary = {}


func register_catalog_weapon(weapon: WeaponData) -> void:
	var weapon_id := weapon.get_unique_key()
	if _baselines.has(weapon_id):
		return
	_baselines[weapon_id] = weapon.duplicate(true)


func load_from_disk() -> void:
	_saved.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("TestArenaWeaponSnapshot: load failed (%s)" % error_string(err))
		return

	for section in cfg.get_sections():
		if not section.begins_with("weapon/"):
			continue
		var weapon_id := section.trim_prefix("weapon/")
		var overrides: Dictionary = {}
		for key in cfg.get_section_keys(section):
			overrides[key] = cfg.get_value(section, key)
		if not overrides.is_empty():
			_saved[weapon_id] = overrides


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	for weapon_id in _saved:
		var section := "weapon/%s" % weapon_id
		for key in _saved[weapon_id]:
			cfg.set_value(section, key, _saved[weapon_id][key])
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


func get_field_defs(weapon: WeaponData) -> Array:
	if weapon == null:
		return []
	if weapon.is_orbit_magic():
		return FIELD_DEFS_ORBIT.duplicate()
	if weapon.is_area_zone_attack():
		return FIELD_DEFS_AREA_ZONE.duplicate()
	return FIELD_DEFS_BY_TYPE.get(weapon.weapon_type, [])


func supports_projectile_tuning(weapon: WeaponData) -> bool:
	return not get_field_defs(weapon).is_empty()


func supports_projectile_movement_tuning(weapon: WeaponData) -> bool:
	if weapon == null:
		return false
	if weapon.is_orbit_magic() or weapon.is_area_zone_attack():
		return false
	return supports_projectile_tuning(weapon)


func build_tuned_weapon(catalog_weapon: WeaponData) -> WeaponData:
	register_catalog_weapon(catalog_weapon)
	var weapon_id := catalog_weapon.get_unique_key()
	var tuned: WeaponData = _baselines[weapon_id].duplicate(true)
	_apply_overrides(tuned, _saved.get(weapon_id, {}))
	_apply_overrides(tuned, _session.get(weapon_id, {}))
	tuned.normalize_projectile_movement_from_legacy()
	tuned.apply_projectile_movement_side_effects()
	return tuned


func get_session_overrides(weapon_id: String) -> Dictionary:
	return _session.get(weapon_id, {}).duplicate()


func set_session_value(weapon_id: String, property: String, value: Variant) -> void:
	if not _session.has(weapon_id):
		_session[weapon_id] = {}
	_session[weapon_id][property] = value


func has_saved_snapshot(weapon_id: String) -> bool:
	return _saved.has(weapon_id) and not _saved[weapon_id].is_empty()


func save_weapon(weapon_id: String) -> void:
	if not _session.has(weapon_id):
		if _saved.has(weapon_id):
			_saved.erase(weapon_id)
			save_to_disk()
		return
	if not _saved.has(weapon_id):
		_saved[weapon_id] = {}
	for key in _session[weapon_id]:
		_saved[weapon_id][key] = _session[weapon_id][key]
	save_to_disk()


func reset_weapon(weapon_id: String) -> void:
	_session.erase(weapon_id)
	_saved.erase(weapon_id)
	save_to_disk()


func _apply_overrides(weapon: WeaponData, overrides: Dictionary) -> void:
	for key in overrides:
		weapon.set(key, overrides[key])
