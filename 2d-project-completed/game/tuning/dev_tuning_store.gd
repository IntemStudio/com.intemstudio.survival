extends RefCounted
class_name DevTuningStore

## 몹 authoring 로드·캐시·저장. ( 무기/장비/상태이상 API는 후속 PR )

static var _mob_authoring: Dictionary = {}


static func reload_mob_authoring() -> void:
	_mob_authoring.clear()
	if not DirAccess.dir_exists_absolute(DevTuningPaths.MOBS_DIR):
		return
	for file_name in DirAccess.get_files_at(DevTuningPaths.MOBS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var full_path := DevTuningPaths.MOBS_DIR + file_name
		var tuning := load(full_path) as MobSceneTuning
		if tuning == null:
			push_warning("DevTuningStore: invalid mob tuning (%s)" % full_path)
			continue
		var scene_path := tuning.scene_path
		if scene_path.is_empty():
			continue
		_mob_authoring[scene_path] = tuning.overrides.duplicate(true)


static func get_mob_authoring(scene_path: String) -> Dictionary:
	if scene_path.is_empty():
		return {}
	return _mob_authoring.get(scene_path, {}).duplicate(true)


static func has_mob_authoring(scene_path: String) -> bool:
	return not scene_path.is_empty() and _mob_authoring.has(scene_path)


# 세션/저장 UI에서 merge한 overrides를 .tres에 반영합니다.
static func save_mob_authoring(scene_path: String, overrides: Dictionary) -> bool:
	if scene_path.is_empty():
		return false
	var path := DevTuningPaths.mob_tuning_path(scene_path)
	var resource: MobSceneTuning
	if ResourceLoader.exists(path):
		resource = load(path) as MobSceneTuning
	if resource == null:
		resource = MobSceneTuning.new()
	resource.scene_path = scene_path
	for key in overrides:
		resource.overrides[key] = overrides[key]
	var result: Dictionary = DevTuningPersistence.save_resource(resource, path)
	if result.get("ok", false):
		_mob_authoring[scene_path] = resource.overrides.duplicate(true)
	return bool(result.get("ok", false))


# 초기화( reset ) 시 해당 씬 authoring 파일을 제거합니다.
static func delete_mob_authoring(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	var path := DevTuningPaths.mob_tuning_path(scene_path)
	var result: Dictionary = DevTuningPersistence.delete_resource(path)
	if result.get("ok", false):
		_mob_authoring.erase(scene_path)
	return bool(result.get("ok", false))


static func get_last_persistence_error() -> String:
	return DevTuningPersistence.last_error


static func get_last_save_error_key() -> String:
	return DevTuningPersistence.ERR_EDITOR_ONLY


# --- 후속 PR: weapons / gear / status_effects ---
# static func reload_weapon_authoring() -> void: pass
# static func reload_gear_authoring() -> void: pass
# static func reload_status_effect_authoring() -> void: pass
