class_name SpeedCheat
extends Node

const _SPEED_KEYS := {
	KEY_0: 0.1,
	KEY_1: 1.0,
	KEY_2: 2.0,
	KEY_3: 3.0,
	KEY_4: 4.0,
	KEY_5: 5.0,
}

var _left_shift_down := false
var _game: Node2D


func _ready() -> void:
	_game = get_parent() as Node2D
	reset_speed()


# 배속 치트를 기본(1×)으로 되돌림
func reset_speed() -> void:
	Engine.time_scale = 1.0


func _is_blocked() -> bool:
	if not _game:
		return true
	if _game.is_weapon_select_open() or _game.is_pause_menu_open() or _game.is_game_over():
		return true
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		if event.location == KEY_LOCATION_RIGHT:
			return
		if event.location == KEY_LOCATION_LEFT or event.location == KEY_LOCATION_UNSPECIFIED:
			_left_shift_down = event.pressed


func _unhandled_input(event: InputEvent) -> void:
	if _is_blocked():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not _left_shift_down:
		return
	var speed: float = _SPEED_KEYS.get(event.keycode, -1.0)
	if speed < 0.0:
		return
	Engine.time_scale = speed
	get_viewport().set_input_as_handled()
