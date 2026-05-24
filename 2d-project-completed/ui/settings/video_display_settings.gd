extends VBoxContainer

## 일시정지 설정 — 해상도·화면 모드·VSync.

@onready var _resolution_option: OptionButton = $ResolutionRow/ResolutionOption
@onready var _window_mode_option: OptionButton = $WindowModeRow/WindowModeOption
@onready var _vsync_option: OptionButton = $VSyncRow/VSyncOption
@onready var _video_title: Label = get_node_or_null("../VideoDisplayTitle") as Label
@onready var _resolution_label: Label = (
	get_node_or_null("ResolutionRow/ResolutionLabel") as Label
)
@onready var _window_mode_label: Label = (
	get_node_or_null("WindowModeRow/WindowModeLabel") as Label
)
@onready var _vsync_label: Label = get_node_or_null("VSyncRow/VSyncLabel") as Label

var _resolution_presets: Array[Vector2i] = []
var _syncing := false


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_resolution_option.item_selected.connect(_on_display_option_changed)
	_window_mode_option.item_selected.connect(_on_display_option_changed)
	_vsync_option.item_selected.connect(_on_display_option_changed)
	refresh_locale()
	sync_from_display()


func refresh_locale() -> void:
	if _video_title:
		_video_title.text = UiLocale.t(&"settings.video")
	if _resolution_label:
		_resolution_label.text = UiLocale.t(&"settings.resolution")
	if _window_mode_label:
		_window_mode_label.text = UiLocale.t(&"settings.window_mode")
	if _vsync_label:
		_vsync_label.text = UiLocale.t(&"settings.vsync")
	_rebuild_window_mode_options()
	_rebuild_vsync_options()
	var selected_mode := _window_mode_option.selected
	var selected_vsync := _vsync_option.selected
	_syncing = true
	if selected_mode >= 0 and selected_mode < _window_mode_option.item_count:
		_window_mode_option.select(selected_mode)
	if selected_vsync >= 0 and selected_vsync < _vsync_option.item_count:
		_vsync_option.select(selected_vsync)
	_syncing = false


# 현재 디스플레이·저장값으로 옵션 UI를 맞춥니다.
func sync_from_display() -> void:
	_syncing = true
	_build_resolution_options()
	if _window_mode_option.item_count == 0:
		_rebuild_window_mode_options()
	if _vsync_option.item_count == 0:
		_rebuild_vsync_options()
	var state := DisplaySettings.read_current()
	_select_resolution(state["resolution"] as Vector2i)
	var mode_index := int(state["window_mode"])
	if mode_index >= 0 and mode_index < _window_mode_option.item_count:
		_window_mode_option.select(mode_index)
	var vsync_index := 0 if state["vsync"] == DisplayServer.VSYNC_DISABLED else 1
	if vsync_index >= 0 and vsync_index < _vsync_option.item_count:
		_vsync_option.select(vsync_index)
	_syncing = false


func _build_resolution_options() -> void:
	_resolution_option.clear()
	_resolution_presets = DisplaySettings.get_resolution_presets()
	for preset in _resolution_presets:
		_resolution_option.add_item(DisplaySettings.resolution_label(preset))


func _rebuild_window_mode_options() -> void:
	var selected := _window_mode_option.selected
	_window_mode_option.clear()
	_window_mode_option.add_item(UiLocale.t(&"window.windowed"))
	_window_mode_option.add_item(UiLocale.t(&"window.borderless"))
	_window_mode_option.add_item(UiLocale.t(&"window.fullscreen"))
	if selected >= 0 and selected < _window_mode_option.item_count:
		_window_mode_option.select(selected)


func _rebuild_vsync_options() -> void:
	var selected := _vsync_option.selected
	_vsync_option.clear()
	_vsync_option.add_item(UiLocale.t(&"vsync.off"))
	_vsync_option.add_item(UiLocale.t(&"vsync.on"))
	if selected >= 0 and selected < _vsync_option.item_count:
		_vsync_option.select(selected)


func _select_resolution(size: Vector2i) -> void:
	if _resolution_presets.is_empty():
		return
	var best_index := 0
	var best_dist := INF
	for i in _resolution_presets.size():
		var preset := _resolution_presets[i]
		var dist := absf(float(preset.x - size.x)) + absf(float(preset.y - size.y))
		if dist < best_dist:
			best_dist = dist
			best_index = i
	_resolution_option.select(best_index)


func _on_display_option_changed(_index: int) -> void:
	if _syncing:
		return
	var resolution := _resolution_presets[_resolution_option.selected]
	var window_mode := _window_mode_option.selected as DisplaySettings.WindowModeOption
	var vsync := (
		DisplayServer.VSYNC_DISABLED
		if _vsync_option.selected == 0
		else DisplayServer.VSYNC_ENABLED
	)
	DisplaySettings.apply(resolution.x, resolution.y, window_mode, vsync)
