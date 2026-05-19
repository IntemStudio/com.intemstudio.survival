extends CanvasLayer


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return

	var game := get_parent()
	if game.is_game_over() or game.is_weapon_select_open():
		return

	if visible:
		game.resume_game()
	else:
		game.show_pause_menu()

	get_viewport().set_input_as_handled()
