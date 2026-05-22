extends CanvasLayer

const WEAPON_TYPE_FONT_COLORS := {
	"Melee": Color(0.95, 0.72, 0.68, 1),
	"Ranged": Color(0.68, 0.95, 0.78, 1),
	"Magic": Color(0.78, 0.82, 0.98, 1),
}
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
@onready var _locale_settings: VBoxContainer = %LocaleSettings
@onready var _video_display_settings: VBoxContainer = %VideoDisplaySettings
@onready var _audio_settings: VBoxContainer = %AudioSettings
@onready var _gameplay_settings: VBoxContainer = %GameplaySettings
@onready var _tree_density_settings: VBoxContainer = %TreeDensitySettings


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	visibility_changed.connect(_on_visibility_changed)
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
	if not event.is_action_pressed("pause"):
		return

	var game := get_parent()
	if game.is_game_over() or game.is_weapon_select_open():
		return

	if visible:
		if _settings_panel.visible:
			_close_settings_view()
		else:
			game.resume_game()
	else:
		game.show_pause_menu()

	get_viewport().set_input_as_handled()


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
	if _tree_density_settings.has_method("sync_from_arena"):
		_tree_density_settings.sync_from_arena()


func _on_settings_back_pressed() -> void:
	_close_settings_view()


# 설정 화면을 닫고 일시정지 메인 목록을 다시 표시합니다.
func _close_settings_view() -> void:
	_settings_panel.hide()
	_main_content.show()


# 일시정지 메뉴를 열 때 보유 무기·누적 피해량 목록을 갱신합니다.
func refresh_owned_weapons() -> void:
	var game := get_parent()
	if game == null or not game.has_method("get_weapon_damage_display_rows"):
		return

	game.populate_weapon_damage_list(
		_owned_weapons_list,
		game.get_weapon_damage_display_rows(),
		UiLocale.t(&"pause.no_weapons"),
		true,
		WEAPON_TYPE_FONT_COLORS
	)
