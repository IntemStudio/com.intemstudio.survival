extends Control

const GAME_SCENE_PATH := "res://survivors_game.tscn"

@onready var _title_label: Label = %LobbyTitleLabel
@onready var _start_button: Button = %StartGameButton
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
	_start_button.text = UiLocale.t(&"lobby.start")
	_quit_button.text = UiLocale.t(&"lobby.quit")


# 메인 게임 씬으로 전환합니다.
func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
