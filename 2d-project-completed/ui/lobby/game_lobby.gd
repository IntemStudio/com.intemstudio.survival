extends Control

const RunConfigScript = preload("res://game/run_config.gd")
const GAME_SCENE_PATH := "res://survivors_game.tscn"

@onready var _title_label: Label = %LobbyTitleLabel
@onready var _class_label: Label = %ClassLabel
@onready var _class_option: OptionButton = %ClassOptionButton
@onready var _class_description_label: Label = %ClassDescriptionLabel
@onready var _start_survival_button: Button = %StartGameButton
@onready var _start_arena_button: Button = %ArenaGameButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	ActionManager.initialize()
	LocaleSettings.load_and_apply()
	DisplaySettings.load_and_apply()
	AudioSettings.load_and_apply()
	add_to_group(UiLocale.GROUP_REFRESH)
	_populate_class_options()
	_class_option.item_selected.connect(_on_class_option_item_selected)
	refresh_locale()


func refresh_locale() -> void:
	if not is_node_ready():
		return
	_title_label.text = UiLocale.t(&"lobby.title")
	_class_label.text = UiLocale.t(&"lobby.class_label")
	_start_survival_button.text = UiLocale.t(&"lobby.start_survival")
	_start_arena_button.text = UiLocale.t(&"lobby.start_arena")
	_quit_button.text = UiLocale.t(&"lobby.quit")
	_populate_class_options()
	_update_class_description()


# 직업 OptionButton을 카탈로그로 채우고 RunConfig 선택을 반영합니다.
func _populate_class_options() -> void:
	if _class_option == null:
		return
	var selected_id := RunConfigScript.get_player_class_id()
	_class_option.clear()
	var player_classes := PlayerClassCatalog.get_all()
	for player_class in player_classes:
		_class_option.add_item(player_class.get_display_name_localized())
	_select_class_in_option(selected_id)


func _select_class_in_option(class_id: StringName) -> void:
	var player_classes := PlayerClassCatalog.get_all()
	for index in player_classes.size():
		if player_classes[index].class_id == String(class_id):
			_class_option.select(index)
			return
	if not player_classes.is_empty():
		_class_option.select(0)
		RunConfigScript.set_player_class_id(StringName(player_classes[0].class_id))


func _update_class_description() -> void:
	var player_class := RunConfigScript.get_player_class()
	if player_class == null:
		_class_description_label.text = ""
		return
	var lines: PackedStringArray = []
	var description := player_class.get_description_localized()
	if not description.is_empty():
		lines.append(description)
	lines.append_array(player_class.build_stat_summary_lines())
	_class_description_label.text = "\n".join(lines)


func _on_class_option_item_selected(index: int) -> void:
	var player_classes := PlayerClassCatalog.get_all()
	if index < 0 or index >= player_classes.size():
		return
	RunConfigScript.set_player_class_id(StringName(player_classes[index].class_id))
	_update_class_description()


# 서바이벌 규칙으로 메인 게임 씬을 시작합니다.
func _on_start_game_button_pressed() -> void:
	RunConfigScript.set_game_mode(RunConfigScript.MODE_SURVIVAL)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


# 웨이브 아레나 규칙으로 메인 게임 씬을 시작합니다.
func _on_arena_game_button_pressed() -> void:
	RunConfigScript.set_game_mode(RunConfigScript.MODE_ARENA)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
