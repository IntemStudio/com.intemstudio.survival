extends RefCounted
class_name DevTuningPersistence

## res:// Resource 저장 — Godot 에디터 실행(플레이 모드 포함)에서만 쓰기 허용.

const ERR_EDITOR_ONLY := "EDITOR_ONLY"

static var last_error := ""


# F6 플레이 모드 포함, Godot 에디터에서 실행 중일 때만 프로젝트 쓰기를 허용합니다.
static func can_write_project_resources() -> bool:
	return OS.has_feature("editor")


# res:// / user:// 경로를 OS 절대 경로로 변환합니다(플레이 모드 저장용).
static func _to_absolute_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


static func save_resource(resource: Resource, path: String) -> Dictionary:
	last_error = ""
	if not can_write_project_resources():
		last_error = ERR_EDITOR_ONLY
		return {"ok": false, "error": ERR_EDITOR_ONLY}
	if resource == null or path.is_empty() or not path.begins_with("res://"):
		last_error = "INVALID_ARGS"
		return {"ok": false, "error": last_error}
	var absolute_path := _to_absolute_path(path)
	var parent_dir := absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent_dir):
		var mkdir_err := DirAccess.make_dir_recursive_absolute(parent_dir)
		if mkdir_err != OK:
			last_error = error_string(mkdir_err)
			return {"ok": false, "error": last_error}
	resource.resource_path = path
	var err := ResourceSaver.save(resource, absolute_path)
	if err != OK:
		last_error = error_string(err)
		return {"ok": false, "error": last_error}
	return {"ok": true, "error": ""}


static func delete_resource(path: String) -> Dictionary:
	last_error = ""
	if not can_write_project_resources():
		last_error = ERR_EDITOR_ONLY
		return {"ok": false, "error": ERR_EDITOR_ONLY}
	if path.is_empty() or not path.begins_with("res://"):
		last_error = "INVALID_ARGS"
		return {"ok": false, "error": last_error}
	var absolute_path := _to_absolute_path(path)
	if not FileAccess.file_exists(absolute_path):
		return {"ok": true, "error": ""}
	var err := DirAccess.remove_absolute(absolute_path)
	if err != OK:
		last_error = error_string(err)
		return {"ok": false, "error": last_error}
	var uid_path := absolute_path + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)
	return {"ok": true, "error": ""}
