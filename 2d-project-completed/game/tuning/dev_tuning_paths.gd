extends RefCounted
class_name DevTuningPaths

## res:// authoring 경로·씬 ID 인코딩( TestArenaMobSnapshot 섹션 규칙과 동일 ).

const MOBS_DIR := "res://game/tuning/mobs/"
const WEAPONS_DIR := "res://game/tuning/weapons/"
const GEAR_DIR := "res://game/tuning/gear/"
const STATUS_EFFECTS_DIR := "res://game/tuning/status_effects/"


# res://entities/mob/mob_elite.tscn → entities__mob__mob_elite (Windows 금지 문자 | 제외)
static func encode_scene_id(scene_path: String) -> String:
	var relative := scene_path.trim_prefix("res://")
	if relative.ends_with(".tscn"):
		relative = relative.trim_suffix(".tscn")
	return relative.replace("/", "__")


static func mob_tuning_path(scene_path: String) -> String:
	return MOBS_DIR + encode_scene_id(scene_path) + ".tres"
