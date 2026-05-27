class_name TestArenaMobSnapshot
extends RefCounted

## 테스트 아레나 몹 전투 스냅샷 — 프리팹 기본값·세션·user:// 저장.

const SAVE_PATH := "user://test_arena_mob_snapshots.cfg"
const SECTION_META_SCENE_PATH := "_scene_path"
const MOB_SCENE_DIR := "res://entities/mob/"
const LEGACY_SECTION_PREFIX := "entities_mob_"

const CONTACT_FIELD_DEFS := [
	{"property": "contact_attack_damage", "label": "피해량", "min": 0.0, "max": 999.0, "step": 1.0},
	{"property": "attack_distance", "label": "사거리", "min": 10.0, "max": 2000.0, "step": 5.0},
	{"property": "contact_attack_interval", "label": "공격 간격", "min": 0.1, "max": 10.0, "step": 0.05},
]

const RANGED_FIELD_DEFS := [
	{"property": "ranged_damage", "label": "피해량", "min": 0.0, "max": 999.0, "step": 1.0, "virtual": true},
	{"property": "ranged_max_distance", "label": "사거리", "min": 50.0, "max": 2000.0, "step": 10.0},
	{"property": "ranged_cooldown", "label": "공격 간격", "min": 0.1, "max": 10.0, "step": 0.05},
]

const DEATH_BURST_FIELD_DEFS := [
	{"property": "death_burst_radius", "label": "폭발 범위", "min": 10.0, "max": 600.0, "step": 5.0},
	{"property": "death_burst_damage", "label": "폭발 피해량", "min": 0.0, "max": 999.0, "step": 1.0},
	{"property": "death_burst_delay", "label": "폭발 지연", "min": 0.0, "max": 15.0, "step": 0.1},
]

const COMBAT_PROPERTIES: Array[String] = [
	"contact_attack_damage",
	"attack_distance",
	"contact_attack_interval",
	"ranged_damage_min",
	"ranged_damage_max",
	"ranged_max_distance",
	"ranged_cooldown",
]

const DEATH_BURST_PROPERTIES: Array[String] = [
	"death_burst_radius",
	"death_burst_damage",
	"death_burst_delay",
]

const CHARGE_FIELD_DEFS := [
	{"property": "charge_travel_distance", "label": "돌진 거리", "min": 20.0, "max": 900.0, "step": 10.0},
]

const CHARGE_PROPERTIES: Array[String] = [
	"charge_duration",
	"charge_speed_mult",
]

const TUNING_STATE_DEFAULT := &"default"
const TUNING_STATE_SAVED := &"saved"
const TUNING_STATE_SESSION := &"session"

var _baselines: Dictionary = {}
var _is_ranged: Dictionary = {}
var _has_death_burst: Dictionary = {}
var _has_charge_attack: Dictionary = {}
var _saved: Dictionary = {}
var _session: Dictionary = {}


static func get_scene_id(scene: PackedScene) -> String:
	return scene.resource_path if scene else ""


static func _section_for_scene_id(scene_id: String) -> String:
	return "mob/%s" % scene_id.trim_prefix("res://").replace("/", "|")


static func _scene_id_from_section(section: String) -> String:
	if not section.begins_with("mob/"):
		return ""
	var encoded := section.trim_prefix("mob/")
	var from_pipe := "res://" + encoded.replace("|", "/")
	if ResourceLoader.exists(from_pipe):
		return from_pipe
	if encoded.begins_with(LEGACY_SECTION_PREFIX):
		return MOB_SCENE_DIR + encoded.substr(LEGACY_SECTION_PREFIX.length())
	var from_legacy := "res://" + encoded.replace("_", "/")
	if ResourceLoader.exists(from_legacy):
		return from_legacy
	return ""


func register_scene(scene: PackedScene) -> void:
	var scene_id := get_scene_id(scene)
	if scene_id.is_empty() or _baselines.has(scene_id):
		return
	var mob := scene.instantiate() as Mob
	if mob == null:
		return
	_is_ranged[scene_id] = mob.ranged_attack_enabled
	_has_death_burst[scene_id] = mob.death_burst_enabled
	_has_charge_attack[scene_id] = mob.charge_attack_enabled
	_baselines[scene_id] = _capture_stats(mob)
	mob.free()


func load_from_disk() -> void:
	_saved.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("TestArenaMobSnapshot: load failed (%s)" % error_string(err))
		return

	for section in cfg.get_sections():
		var overrides: Dictionary = {}
		for key in cfg.get_section_keys(section):
			overrides[key] = cfg.get_value(section, key)
		var scene_id := str(overrides.get(SECTION_META_SCENE_PATH, ""))
		overrides.erase(SECTION_META_SCENE_PATH)
		if scene_id.is_empty():
			scene_id = _scene_id_from_section(section)
		if scene_id.is_empty() or overrides.is_empty():
			continue
		_saved[scene_id] = overrides


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	for scene_id in _saved:
		var section := _section_for_scene_id(scene_id)
		cfg.set_value(section, SECTION_META_SCENE_PATH, scene_id)
		for key in _saved[scene_id]:
			cfg.set_value(section, key, _saved[scene_id][key])
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


func get_field_defs(scene: PackedScene) -> Array:
	if is_ranged_scene(scene):
		return RANGED_FIELD_DEFS.duplicate()
	return CONTACT_FIELD_DEFS.duplicate()


func get_death_burst_field_defs(scene: PackedScene) -> Array:
	if not supports_death_burst_tuning(scene):
		return []
	return DEATH_BURST_FIELD_DEFS.duplicate()


func supports_death_burst_tuning(scene: PackedScene) -> bool:
	var scene_id := get_scene_id(scene)
	if scene_id.is_empty():
		return false
	# 돌진 몹(특수 B)은 F6에서 사망 폭발 대신 돌진 거리 튜닝을 노출합니다.
	if _has_charge_attack.get(scene_id, false):
		return false
	return _has_death_burst.get(scene_id, false)


func get_charge_field_defs(scene: PackedScene) -> Array:
	if not supports_charge_tuning(scene):
		return []
	return CHARGE_FIELD_DEFS.duplicate()


func supports_charge_tuning(scene: PackedScene) -> bool:
	var scene_id := get_scene_id(scene)
	return not scene_id.is_empty() and _has_charge_attack.get(scene_id, false)


func supports_combat_tuning(scene: PackedScene) -> bool:
	return not get_scene_id(scene).is_empty() and _baselines.has(get_scene_id(scene))


func is_ranged_scene(scene: PackedScene) -> bool:
	return _is_ranged.get(get_scene_id(scene), false)


func build_tuned_stats(scene: PackedScene) -> Dictionary:
	register_scene(scene)
	var scene_id := get_scene_id(scene)
	var tuned: Dictionary = _baselines[scene_id].duplicate()
	_apply_overrides(tuned, _saved.get(scene_id, {}))
	_apply_overrides(tuned, _session.get(scene_id, {}))
	_clamp_ranged_damage(tuned)
	return tuned


func get_tuned_value(scene: PackedScene, property: String) -> float:
	var stats := build_tuned_stats(scene)
	if property == "ranged_damage":
		return float(stats.get("ranged_damage_min", 0))
	if property == "charge_travel_distance":
		return _charge_travel_distance_from_stats(stats)
	return float(stats.get(property, 0.0))


func apply_to_mob(mob: Mob, scene: PackedScene) -> void:
	if mob == null or scene == null:
		return
	var stats := build_tuned_stats(scene)
	for prop in COMBAT_PROPERTIES:
		mob.set(prop, stats[prop])
	if supports_death_burst_tuning(scene):
		for prop in DEATH_BURST_PROPERTIES:
			mob.set(prop, stats[prop])
	if supports_charge_tuning(scene):
		mob.charge_speed_mult = float(stats.get("charge_speed_mult", mob.charge_speed_mult))
		var target_distance := _charge_travel_distance_from_stats(stats)
		var denom := mob.speed * maxf(mob.charge_speed_mult, 0.01)
		mob.charge_duration = maxf(target_distance / maxf(denom, 0.01), 0.01)


func get_session_overrides(scene_id: String) -> Dictionary:
	return _session.get(scene_id, {}).duplicate()


func get_property_tuning_state(scene: PackedScene, property: String) -> StringName:
	var scene_id := get_scene_id(scene)
	if scene_id.is_empty() or not _baselines.has(scene_id):
		return TUNING_STATE_DEFAULT
	if _has_session_override(scene_id, property):
		return TUNING_STATE_SESSION
	if _is_modified_from_baseline(scene_id, property):
		return TUNING_STATE_SAVED
	return TUNING_STATE_DEFAULT


func set_session_value(scene_id: String, property: String, value: Variant) -> void:
	if not _session.has(scene_id):
		_session[scene_id] = {}
	if property == "ranged_damage":
		var damage := int(roundf(float(value)))
		_session[scene_id]["ranged_damage_min"] = damage
		_session[scene_id]["ranged_damage_max"] = damage
		return
	if property == "charge_travel_distance":
		var stats: Dictionary = _baselines[scene_id].duplicate()
		_apply_overrides(stats, _saved.get(scene_id, {}))
		_apply_overrides(stats, _session.get(scene_id, {}))
		_session[scene_id]["charge_duration"] = _charge_duration_for_distance(stats, float(value))
		return
	if property in ["contact_attack_damage", "death_burst_damage"]:
		_session[scene_id][property] = int(roundf(float(value)))
		return
	_session[scene_id][property] = value


func has_saved_snapshot(scene_id: String) -> bool:
	return _saved.has(scene_id) and not _saved[scene_id].is_empty()


func save_mob(scene_id: String) -> void:
	if not _session.has(scene_id):
		if _saved.has(scene_id):
			_saved.erase(scene_id)
			save_to_disk()
		return
	if not _saved.has(scene_id):
		_saved[scene_id] = {}
	for key in _session[scene_id]:
		_saved[scene_id][key] = _session[scene_id][key]
	_session.erase(scene_id)
	save_to_disk()


func reset_mob(scene_id: String) -> void:
	_session.erase(scene_id)
	_saved.erase(scene_id)
	save_to_disk()


func _capture_stats(mob: Mob) -> Dictionary:
	var stats: Dictionary = {}
	for prop in COMBAT_PROPERTIES:
		stats[prop] = mob.get(prop)
	if mob.death_burst_enabled:
		for prop in DEATH_BURST_PROPERTIES:
			stats[prop] = mob.get(prop)
	if mob.charge_attack_enabled:
		for prop in CHARGE_PROPERTIES:
			stats[prop] = mob.get(prop)
		stats["speed_min"] = mob.speed_min
		stats["speed_max"] = mob.speed_max
	return stats


func _apply_overrides(stats: Dictionary, overrides: Dictionary) -> void:
	for key in overrides:
		stats[key] = overrides[key]


func _clamp_ranged_damage(stats: Dictionary) -> void:
	if int(stats.get("ranged_damage_max", 0)) < int(stats.get("ranged_damage_min", 0)):
		stats["ranged_damage_max"] = stats["ranged_damage_min"]


static func _reference_speed(stats: Dictionary) -> float:
	return (float(stats.get("speed_min", 0.0)) + float(stats.get("speed_max", 0.0))) * 0.5


static func _charge_travel_distance_from_stats(stats: Dictionary) -> float:
	return (
		_reference_speed(stats)
		* maxf(float(stats.get("charge_speed_mult", 1.0)), 0.01)
		* maxf(float(stats.get("charge_duration", 0.01)), 0.01)
	)


static func _charge_duration_for_distance(stats: Dictionary, distance: float) -> float:
	var denom := _reference_speed(stats) * maxf(float(stats.get("charge_speed_mult", 1.0)), 0.01)
	return maxf(distance / maxf(denom, 0.01), 0.01)


func _has_session_override(scene_id: String, property: String) -> bool:
	var session: Dictionary = _session.get(scene_id, {})
	if property == "ranged_damage":
		return session.has("ranged_damage_min") or session.has("ranged_damage_max")
	if property == "charge_travel_distance":
		return session.has("charge_duration")
	return session.has(property)


func _is_modified_from_baseline(scene_id: String, property: String) -> bool:
	var baseline: Dictionary = _baselines[scene_id]
	var saved_stats: Dictionary = baseline.duplicate()
	_apply_overrides(saved_stats, _saved.get(scene_id, {}))
	return not _property_values_equal(baseline, saved_stats, property)


static func _property_values_equal(
	baseline: Dictionary,
	tuned: Dictionary,
	property: String
) -> bool:
	if property == "ranged_damage":
		return (
			int(tuned.get("ranged_damage_min", 0))
			== int(baseline.get("ranged_damage_min", 0))
			and int(tuned.get("ranged_damage_max", 0))
			== int(baseline.get("ranged_damage_max", 0))
		)
	if property == "charge_travel_distance":
		return abs(
			_charge_travel_distance_from_stats(tuned)
			- _charge_travel_distance_from_stats(baseline)
		) < 0.5
	return _float_eq(tuned.get(property), baseline.get(property))


static func _float_eq(a: Variant, b: Variant) -> bool:
	return abs(float(a) - float(b)) < 0.0001
