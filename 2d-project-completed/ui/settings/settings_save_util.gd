class_name SettingsSaveUtil
extends RefCounted

## user:// 설정 파일 저장 — 실패 시 경고.


static func save_config(cfg: ConfigFile, path: String) -> void:
	var err := cfg.save(path)
	if err != OK:
		push_warning("설정 저장 실패 (%s): %s" % [path, error_string(err)])
