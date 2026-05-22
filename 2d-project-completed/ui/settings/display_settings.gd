class_name DisplaySettings
extends RefCounted

## 창 해상도·화면 모드·VSync 저장·적용. 일시정지 설정 UI와 게임 시작 시 로드.

const SAVE_PATH := "user://display_settings.cfg"
const KEY_WIDTH := "width"
const KEY_HEIGHT := "height"
const KEY_WINDOW_MODE := "window_mode"
const KEY_VSYNC := "vsync"

enum WindowModeOption {
	WINDOWED,
	BORDERLESS_FULLSCREEN,
	EXCLUSIVE_FULLSCREEN,
}

const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]


static func get_resolution_presets() -> Array[Vector2i]:
	var screen_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var result: Array[Vector2i] = []
	for preset in RESOLUTION_PRESETS:
		if preset.x <= screen_size.x and preset.y <= screen_size.y:
			result.append(preset)
	if result.is_empty():
		result.append(screen_size)
	return result


static func resolution_label(size: Vector2i) -> String:
	return "%d × %d" % [size.x, size.y]


# 저장 파일 없음 → 적용 생략(project.godot 기본 창 크기·모드 유지).
static func load_and_apply() -> void:
	var data := _load_file()
	if data.is_empty():
		return
	apply(
		int(data.get(KEY_WIDTH, 1280)),
		int(data.get(KEY_HEIGHT, 720)),
		int(data.get(KEY_WINDOW_MODE, WindowModeOption.WINDOWED)) as WindowModeOption,
		int(data.get(KEY_VSYNC, DisplayServer.VSYNC_ENABLED)) as DisplayServer.VSyncMode
	)


static func apply(
	width: int,
	height: int,
	window_mode: WindowModeOption,
	vsync_mode: DisplayServer.VSyncMode
) -> void:
	var size := Vector2i(maxi(width, 320), maxi(height, 240))
	DisplayServer.window_set_vsync_mode(vsync_mode)
	DisplayServer.window_set_mode(_display_server_window_mode(window_mode))
	_set_resize_allowed(window_mode == WindowModeOption.WINDOWED)
	DisplayServer.window_set_size(size)
	_save(size.x, size.y, window_mode, vsync_mode)


static func read_current() -> Dictionary:
	var mode := _window_mode_from_display_server(DisplayServer.window_get_mode())
	var size := DisplayServer.window_get_size()
	if mode != WindowModeOption.WINDOWED:
		var saved := _load_file()
		if not saved.is_empty():
			size = Vector2i(
				int(saved.get(KEY_WIDTH, size.x)),
				int(saved.get(KEY_HEIGHT, size.y))
			)
	return {
		"resolution": size,
		"window_mode": mode,
		"vsync": DisplayServer.window_get_vsync_mode(),
	}


static func _display_server_window_mode(option: WindowModeOption) -> DisplayServer.WindowMode:
	match option:
		WindowModeOption.WINDOWED:
			return DisplayServer.WINDOW_MODE_WINDOWED
		WindowModeOption.BORDERLESS_FULLSCREEN:
			return DisplayServer.WINDOW_MODE_FULLSCREEN
		_:
			return DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func _window_mode_from_display_server(mode: DisplayServer.WindowMode) -> WindowModeOption:
	match mode:
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return WindowModeOption.BORDERLESS_FULLSCREEN
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return WindowModeOption.EXCLUSIVE_FULLSCREEN
		_:
			return WindowModeOption.WINDOWED


static func _set_resize_allowed(allowed: bool) -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, not allowed)


static func _save(
	width: int,
	height: int,
	window_mode: WindowModeOption,
	vsync_mode: DisplayServer.VSyncMode
) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", KEY_WIDTH, width)
	cfg.set_value("display", KEY_HEIGHT, height)
	cfg.set_value("display", KEY_WINDOW_MODE, window_mode)
	cfg.set_value("display", KEY_VSYNC, vsync_mode)
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


static func _load_file() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return {
		KEY_WIDTH: cfg.get_value("display", KEY_WIDTH, 1280),
		KEY_HEIGHT: cfg.get_value("display", KEY_HEIGHT, 720),
		KEY_WINDOW_MODE: cfg.get_value("display", KEY_WINDOW_MODE, WindowModeOption.WINDOWED),
		KEY_VSYNC: cfg.get_value("display", KEY_VSYNC, DisplayServer.VSYNC_ENABLED),
	}
