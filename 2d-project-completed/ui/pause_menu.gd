extends CanvasLayer

const WEAPON_TYPE_FONT_COLORS := {
	"Melee": Color(0.95, 0.72, 0.68, 1),
	"Ranged": Color(0.68, 0.95, 0.78, 1),
	"Magic": Color(0.78, 0.82, 0.98, 1),
}
const SETTINGS_SCROLL_MIN_SIZE := Vector2(560, 620)

@onready var _owned_weapons_list: VBoxContainer = %PauseOwnedWeaponsList
@onready var _main_content: VBoxContainer = %PauseMainContent
@onready var _settings_panel: Control = %SettingsPanel
@onready var _pause_title: Label = %PauseTitleLabel
@onready var _owned_weapons_title: Label = (
	%PauseMainContent.get_node("OwnedWeaponsPanel/OwnedWeaponsTitle") as Label
)
@onready var _continue_button: Button = %PauseMainContent.get_node("Buttons/ContinueButton") as Button
@onready var _settings_button: Button = %PauseMainContent.get_node("Buttons/SettingsButton") as Button
@onready var _restart_button: Button = %PauseMainContent.get_node("Buttons/RestartButton") as Button
@onready var _quit_button: Button = %PauseMainContent.get_node("Buttons/QuitButton") as Button
@onready var _settings_title: Label = %SettingsTitle
@onready var _settings_back_button: Button = (
	%SettingsPanel.get_node("SettingsCenter/SettingsVBox/SettingsBackButton") as Button
)
@onready var _locale_settings: VBoxContainer = %LocaleSettingsUi
@onready var _video_display_settings: VBoxContainer = %VideoDisplaySettings
@onready var _audio_settings: VBoxContainer = %AudioSettingsUi
@onready var _gameplay_settings: VBoxContainer = %GameplaySettingsUi
@onready var _input_binding_settings: VBoxContainer = %InputBindingSettingsUi
@onready var _tree_density_settings: VBoxContainer = %TreeDensitySettings


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	visibility_changed.connect(_on_visibility_changed)
	_ensure_settings_scroll_layout()
	hide()
	_close_settings_view()
	refresh_locale()


func refresh_locale() -> void:
	if not is_node_ready():
		return
	_pause_title.text = UiLocale.t(&"pause.title")
	_owned_weapons_title.text = UiLocale.t(&"pause.owned_weapons")
	_continue_button.text = UiLocale.t(&"pause.continue")
	_settings_button.text = UiLocale.t(&"pause.settings")
	_restart_button.text = UiLocale.t(&"pause.restart")
	_quit_button.text = UiLocale.t(&"pause.quit")
	_settings_title.text = UiLocale.t(&"settings.title")
	_settings_back_button.text = UiLocale.t(&"pause.back")


func _on_visibility_changed() -> void:
	if not visible:
		_close_settings_view()


func _unhandled_input(event: InputEvent) -> void:
	if not ActionManager.event_is_pressed(event, ActionManager.ACTION_PAUSE):
		return

	var game := _get_game()
	if game == null:
		_toggle_standalone_pause()
		get_viewport().set_input_as_handled()
		return

	if game.has_method("is_game_over") and game.is_game_over():
		return
	if game.has_method("is_weapon_select_open") and game.is_weapon_select_open():
		return
	if game.has_method("is_inventory_open") and game.is_inventory_open():
		return

	if visible:
		if _settings_panel.visible:
			_close_settings_view()
		else:
			game.resume_game()
	else:
		game.show_pause_menu()

	get_viewport().set_input_as_handled()


# F5 Game 또는 테스트 아레나 오케스트레이터를 찾습니다(프리팹 단독 실행 시 parent는 Window).
func _get_game() -> Node:
	var parent := get_parent()
	if parent != null and parent.has_method("show_pause_menu"):
		return parent
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("show_pause_menu"):
		return scene
	return null


# pause_menu_overlay.tscn만 단독 실행할 때 Esc로 표시/숨김.
func _toggle_standalone_pause() -> void:
	if visible:
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true


func _on_settings_button_pressed() -> void:
	_main_content.hide()
	_settings_panel.show()
	if _locale_settings.has_method("sync_from_locale"):
		_locale_settings.sync_from_locale()
	if _video_display_settings.has_method("sync_from_display"):
		_video_display_settings.sync_from_display()
	if _audio_settings.has_method("sync_from_audio"):
		_audio_settings.sync_from_audio()
	if _gameplay_settings.has_method("sync_from_gameplay"):
		_gameplay_settings.sync_from_gameplay()
	if _input_binding_settings.has_method("sync_from_input_bindings"):
		_input_binding_settings.sync_from_input_bindings()
	if _tree_density_settings.has_method("sync_from_arena"):
		_tree_density_settings.sync_from_arena()


func _on_settings_back_pressed() -> void:
	_close_settings_view()


# 설정 화면을 닫고 일시정지 메인 목록을 다시 표시합니다.
func _close_settings_view() -> void:
	if _input_binding_settings.has_method("cancel_input_capture"):
		_input_binding_settings.cancel_input_capture()
	_settings_panel.hide()
	_main_content.show()


# 설정 항목이 길어져도 제목·뒤로가기 버튼은 고정하고 가운데 목록만 스크롤합니다.
func _ensure_settings_scroll_layout() -> void:
	var settings_vbox := _settings_back_button.get_parent() as VBoxContainer
	if settings_vbox == null or settings_vbox.has_node("SettingsScroll"):
		return

	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.custom_minimum_size = SETTINGS_SCROLL_MIN_SIZE
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var content := VBoxContainer.new()
	content.name = "SettingsContentVBox"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	scroll.add_child(content)

	settings_vbox.add_child(scroll)
	settings_vbox.move_child(scroll, 1)

	for settings_ui in [
		_locale_settings,
		_video_display_settings,
		_audio_settings,
		_gameplay_settings,
		_input_binding_settings,
		_tree_density_settings,
	]:
		var panel := settings_ui.get_parent() as Control
		if panel == null:
			continue
		panel.get_parent().remove_child(panel)
		content.add_child(panel)


# 일시정지 메뉴를 열 때 보유 무기·누적 피해량 목록을 갱신합니다.
func refresh_owned_weapons() -> void:
	var game := _get_game()
	if game == null or not game.has_method("get_weapon_damage_display_rows"):
		return

	WeaponDamageUi.populate_list(
		_owned_weapons_list,
		game.get_weapon_damage_display_rows(),
		UiLocale.t(&"pause.no_weapons"),
		true,
		WEAPON_TYPE_FONT_COLORS
	)
