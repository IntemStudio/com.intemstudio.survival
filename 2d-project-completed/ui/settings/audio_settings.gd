class_name AudioSettings
extends RefCounted

## Master·BGM·SFX 버스 볼륨 저장·적용. AudioStreamPlayer는 bus를 "BGM"/"SFX"로 지정.

const SAVE_PATH := "user://audio_settings.cfg"
const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"

const KEY_MASTER := "master"
const KEY_BGM := "bgm"
const KEY_SFX := "sfx"

const DEFAULT_LINEAR := 1.0
const MUTE_DB := -80.0


# 저장 파일 없음 → 기본 볼륨(1.0)으로 apply.
static func load_and_apply() -> void:
	var data := _load_file()
	apply(
		float(data.get(KEY_MASTER, DEFAULT_LINEAR)),
		float(data.get(KEY_BGM, DEFAULT_LINEAR)),
		float(data.get(KEY_SFX, DEFAULT_LINEAR))
	)


static func apply(master: float, bgm: float, sfx: float) -> void:
	var m := _clamp_linear(master)
	var b := _clamp_linear(bgm)
	var s := _clamp_linear(sfx)
	_set_bus_linear(BUS_MASTER, m)
	_set_bus_linear(BUS_BGM, b)
	_set_bus_linear(BUS_SFX, s)
	_save(m, b, s)


static func read_current() -> Dictionary:
	return {
		KEY_MASTER: _get_bus_linear(BUS_MASTER),
		KEY_BGM: _get_bus_linear(BUS_BGM),
		KEY_SFX: _get_bus_linear(BUS_SFX),
	}


static func percent_label(linear: float) -> String:
	return "%d%%" % int(round(_clamp_linear(linear) * 100.0))


static func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var clamped := _clamp_linear(linear)
	if clamped <= 0.0001:
		AudioServer.set_bus_volume_db(idx, MUTE_DB)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))


static func _get_bus_linear(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return DEFAULT_LINEAR
	return _clamp_linear(db_to_linear(AudioServer.get_bus_volume_db(idx)))


static func _clamp_linear(value: float) -> float:
	return clampf(value, 0.0, 1.0)


static func _save(master: float, bgm: float, sfx: float) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", KEY_MASTER, master)
	cfg.set_value("audio", KEY_BGM, bgm)
	cfg.set_value("audio", KEY_SFX, sfx)
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


static func _load_file() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return {
		KEY_MASTER: cfg.get_value("audio", KEY_MASTER, DEFAULT_LINEAR),
		KEY_BGM: cfg.get_value("audio", KEY_BGM, DEFAULT_LINEAR),
		KEY_SFX: cfg.get_value("audio", KEY_SFX, DEFAULT_LINEAR),
	}
