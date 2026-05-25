extends Control

const RunConfigScript = preload("res://game/run_config.gd")
const GAME_SCENE_PATH := "res://survivors_game.tscn"

@onready var _title_label: Label = %LobbyTitleLabel
@onready var _start_survival_button: Button = %StartGameButton
@onready var _start_arena_button: Button = %ArenaGameButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	LocaleSettings.load_and_apply()
	DisplaySettings.load_and_apply()
	AudioSettings.load_and_apply()
	add_to_group(UiLocale.GROUP_REFRESH)
	refresh_locale()


func refresh_locale() -> void:
	if not is_node_ready():
		return
	_title_label.text = UiLocale.t(&"lobby.title")
	_start_survival_button.text = UiLocale.t(&"lobby.start_survival")
	_start_arena_button.text = UiLocale.t(&"lobby.start_arena")
	_quit_button.text = UiLocale.t(&"lobby.quit")


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
