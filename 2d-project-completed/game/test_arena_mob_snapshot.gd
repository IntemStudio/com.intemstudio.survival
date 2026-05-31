class_name TestArenaMobSnapshot
extends RefCounted

## 테스트 아레나 몹 전투 스냅샷 — 프리팹 기본값·세션·res:// authoring(.tres).

const CONTACT_FIELD_DEFS := [
	{"property": "contact_attack_damage", "label": "피해량", "min": 0.0, "max": 999.0, "step": 1.0},
	{"property": "chase_distance", "label": "추격 거리", "min": 0.0, "max": 2000.0, "step": 5.0},
	{"property": "attack_distance", "label": "공격 사거리", "min": 10.0, "max": 2000.0, "step": 5.0},
	{"property": "contact_attack_interval", "label": "공격 간격", "min": 0.1, "max": 10.0, "step": 0.05},
]

const RANGED_FIELD_DEFS := [
	{"property": "ranged_damage", "label": "피해량", "min": 0.0, "max": 999.0, "step": 1.0, "virtual": true},
	{"property": "chase_distance", "label": "추격 거리", "min": 0.0, "max": 2000.0, "step": 5.0},
	{"property": "attack_distance", "label": "발사 사거리", "min": 10.0, "max": 2000.0, "step": 5.0},
	{"property": "ranged_max_distance", "label": "탄환 사거리", "min": 50.0, "max": 2000.0, "step": 10.0},
	{"property": "ranged_cooldown", "label": "공격 간격", "min": 0.1, "max": 10.0, "step": 0.05},
]

const DEATH_BURST_FIELD_DEFS := [
	{"property": "death_burst_radius", "label": "폭발 범위", "min": 10.0, "max": 600.0, "step": 5.0},
	{"property": "death_burst_damage", "label": "폭발 피해량", "min": 0.0, "max": 999.0, "step": 1.0},
	{"property": "death_burst_delay", "label": "폭발 지연", "min": 0.0, "max": 15.0, "step": 0.1},
]

const COMBAT_PROPERTIES: Array[String] = [
	"contact_attack_damage",
	"chase_distance",
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

const CHASE_SKILL_JUMP_FIELD_DEFS := [
	{"property": "jump_chase_enabled", "label": "활성", "min": 0.0, "max": 1.0, "step": 1.0},
	{"property": "jump_chase_trigger_distance", "label": "발동 거리", "min": 0.0, "max": 2000.0, "step": 5.0},
	{"property": "jump_chase_windup_delay", "label": "예고(초)", "min": 0.0, "max": 5.0, "step": 0.05},
	{"property": "jump_chase_travel_distance", "label": "점프 거리", "min": 20.0, "max": 900.0, "step": 10.0},
	{"property": "jump_chase_arc_height", "label": "점프 높이", "min": 0.0, "max": 240.0, "step": 4.0},
	{"property": "jump_chase_cooldown", "label": "쿨다운", "min": 0.1, "max": 30.0, "step": 0.1},
	{"property": "jump_chase_landing_burst_radius", "label": "착지 범위", "min": 0.0, "max": 600.0, "step": 5.0},
	{"property": "jump_chase_landing_burst_damage", "label": "착지 피해", "min": 0.0, "max": 999.0, "step": 1.0},
]

const CHASE_SKILL_JUMP_PROPERTIES: Array[String] = [
	"jump_chase_enabled",
	"jump_chase_trigger_distance",
	"jump_chase_windup_delay",
	"jump_chase_travel_distance",
	"jump_chase_duration",
	"jump_chase_arc_height",
	"jump_chase_cooldown",
	"jump_chase_landing_burst_radius",
	"jump_chase_landing_burst_damage",
]

const TUNING_STATE_DEFAULT := &"default"
const TUNING_STATE_SAVED := &"saved"
const TUNING_STATE_SESSION := &"session"

var _baselines: Dictionary = {}
var _is_ranged: Dictionary = {}
var _has_death_burst: Dictionary = {}
var _has_charge_attack: Dictionary = {}
var _session: Dictionary = {}


static func get_scene_id(scene: PackedScene) -> String:
	return scene.resource_path if scene else ""


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


func get_chase_skill_field_defs(scene: PackedScene) -> Array:
	if not supports_chase_skill_tuning(scene):
		return []
	return CHASE_SKILL_JUMP_FIELD_DEFS.duplicate()


func supports_chase_skill_tuning(scene: PackedScene) -> bool:
	return supports_combat_tuning(scene)


func supports_combat_tuning(scene: PackedScene) -> bool:
	return not get_scene_id(scene).is_empty() and _baselines.has(get_scene_id(scene))


func is_ranged_scene(scene: PackedScene) -> bool:
	return _is_ranged.get(get_scene_id(scene), false)


func build_tuned_stats(scene: PackedScene) -> Dictionary:
	register_scene(scene)
	var scene_id := get_scene_id(scene)
	return DevTuningApplier.build_merged_stats(
		scene,
		_baselines[scene_id],
		DevTuningStore.get_mob_authoring(scene_id),
		_session.get(scene_id, {})
	)


func get_tuned_value(scene: PackedScene, property: String) -> float:
	var stats := build_tuned_stats(scene)
	if property == "ranged_damage":
		return float(stats.get("ranged_damage_min", 0))
	if property == "charge_travel_distance":
		return _charge_travel_distance_from_stats(stats)
	if property == "jump_chase_travel_distance":
		return float(stats.get("jump_chase_travel_distance", 0.0))
	if property == "jump_chase_enabled":
		return 1.0 if bool(stats.get("jump_chase_enabled", false)) else 0.0
	if property == "chase_mode":
		return float(stats.get("chase_mode", 0))
	return float(stats.get(property, 0.0))


func apply_to_mob(mob: Mob, scene: PackedScene) -> void:
	if mob == null or scene == null:
		return
	var stats := build_tuned_stats(scene)
	DevTuningApplier.apply_merged_stats_to_mob(mob, stats)


func get_session_overrides(scene_id: String) -> Dictionary:
	return _session.get(scene_id, {}).duplicate()


func get_property_tuning_state(scene: PackedScene, property: String) -> StringName:
	var scene_id := get_scene_id(scene)
	if scene_id.is_empty() or not _baselines.has(scene_id):
		return TUNING_STATE_DEFAULT
	if _has_session_override(scene_id, property):
		return TUNING_STATE_SESSION
	if _is_authoring_modified_from_baseline(scene_id, property):
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
		_apply_overrides(stats, DevTuningStore.get_mob_authoring(scene_id))
		_apply_overrides(stats, _session.get(scene_id, {}))
		_session[scene_id]["charge_duration"] = _charge_duration_for_distance(stats, float(value))
		return
	if property == "jump_chase_travel_distance":
		var stats: Dictionary = _baselines[scene_id].duplicate()
		_apply_overrides(stats, DevTuningStore.get_mob_authoring(scene_id))
		_apply_overrides(stats, _session.get(scene_id, {}))
		var travel_distance := float(value)
		_session[scene_id]["jump_chase_travel_distance"] = travel_distance
		_session[scene_id]["jump_chase_duration"] = _jump_chase_duration_for_distance(
			stats,
			travel_distance
		)
		return
	if property == "jump_chase_enabled":
		_session[scene_id]["jump_chase_enabled"] = int(roundf(float(value))) != 0
		return
	if property == "chase_mode":
		_session[scene_id]["chase_mode"] = int(value)
		return
	if property in ["contact_attack_damage", "death_burst_damage", "jump_chase_landing_burst_damage"]:
		_session[scene_id][property] = int(roundf(float(value)))
		return
	_session[scene_id][property] = value


func has_saved_snapshot(scene_id: String) -> bool:
	return DevTuningStore.has_mob_authoring(scene_id)


func has_unsaved_session_changes(scene_id: String) -> bool:
	return not get_session_overrides(scene_id).is_empty()


# 세션 변경을 authoring .tres에 merge 저장합니다.
func save_mob(scene_id: String) -> bool:
	if not _session.has(scene_id) or _session[scene_id].is_empty():
		return true
	var merged: Dictionary = DevTuningStore.get_mob_authoring(scene_id)
	for key in _session[scene_id]:
		merged[key] = _session[scene_id][key]
	var ok := DevTuningStore.save_mob_authoring(scene_id, merged)
	if ok:
		_session.erase(scene_id)
	DevTuningStore.reload_mob_authoring()
	return ok


# session·UI 미적용 변경을 버리고 baseline+authoring(저장값)으로 되돌립니다.
func reset_mob(scene_id: String) -> bool:
	_session.erase(scene_id)
	return true


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
	for prop in CHASE_SKILL_JUMP_PROPERTIES:
		stats[prop] = mob.get(prop)
	stats["chase_mode"] = int(mob.chase_mode)
	return stats


func _apply_overrides(stats: Dictionary, overrides: Dictionary) -> void:
	for key in overrides:
		stats[key] = overrides[key]


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


static func _jump_chase_travel_speed(stats: Dictionary) -> float:
	var distance := maxf(float(stats.get("jump_chase_travel_distance", 1.0)), 0.01)
	var duration := maxf(float(stats.get("jump_chase_duration", 0.01)), 0.01)
	return distance / duration


static func _jump_chase_duration_for_distance(stats: Dictionary, distance: float) -> float:
	return maxf(float(distance) / maxf(_jump_chase_travel_speed(stats), 0.01), 0.01)


func _has_session_override(scene_id: String, property: String) -> bool:
	var session: Dictionary = _session.get(scene_id, {})
	if property == "ranged_damage":
		return session.has("ranged_damage_min") or session.has("ranged_damage_max")
	if property == "charge_travel_distance":
		return session.has("charge_duration")
	if property == "jump_chase_travel_distance":
		return session.has("jump_chase_duration") or session.has("jump_chase_travel_distance")
	if property == "jump_chase_enabled":
		return session.has("jump_chase_enabled")
	if property == "chase_mode":
		return session.has("chase_mode")
	return session.has(property)


func _authoring_has_property(authoring: Dictionary, property: String) -> bool:
	if property == "ranged_damage":
		return (
			authoring.has("ranged_damage")
			or authoring.has("ranged_damage_min")
			or authoring.has("ranged_damage_max")
		)
	if property == "charge_travel_distance":
		return authoring.has("charge_travel_distance") or authoring.has("charge_duration")
	if property == "jump_chase_travel_distance":
		return (
			authoring.has("jump_chase_travel_distance")
			or authoring.has("jump_chase_duration")
		)
	if property == "jump_chase_enabled":
		return authoring.has("jump_chase_enabled")
	return authoring.has(property)


func _is_authoring_modified_from_baseline(scene_id: String, property: String) -> bool:
	var authoring: Dictionary = DevTuningStore.get_mob_authoring(scene_id)
	if not _authoring_has_property(authoring, property):
		return false
	var baseline: Dictionary = _baselines[scene_id]
	var tuned: Dictionary = DevTuningApplier.build_merged_stats(
		null,
		baseline,
		authoring,
		{}
	)
	return not _property_values_equal(baseline, tuned, property)


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
	if property == "jump_chase_travel_distance":
		return abs(
			float(tuned.get("jump_chase_travel_distance", 0.0))
			- float(baseline.get("jump_chase_travel_distance", 0.0))
		) < 0.5
	if property == "jump_chase_enabled":
		return bool(tuned.get("jump_chase_enabled", false)) == bool(baseline.get("jump_chase_enabled", false))
	if property == "chase_mode":
		return int(tuned.get("chase_mode", 0)) == int(baseline.get("chase_mode", 0))
	return _float_eq(tuned.get(property), baseline.get(property))


static func _float_eq(a: Variant, b: Variant) -> bool:
	return abs(float(a) - float(b)) < 0.0001
