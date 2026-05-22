extends CanvasLayer

const WEAPON_TYPE_FONT_COLORS := {
	"Melee": Color(0.95, 0.72, 0.68, 1),
	"Ranged": Color(0.68, 0.95, 0.78, 1),
	"Magic": Color(0.78, 0.82, 0.98, 1),
}
@onready var _owned_weapons_list: VBoxContainer = %PauseOwnedWeaponsList


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


# 일시정지 메뉴를 열 때 보유 무기·누적 피해량 목록을 갱신합니다.
func refresh_owned_weapons() -> void:
	var game := get_parent()
	if game == null or not game.has_method("get_weapon_damage_display_rows"):
		return

	game.populate_weapon_damage_list(
		_owned_weapons_list,
		game.get_weapon_damage_display_rows(),
		"보유 무기 없음",
		true,
		WEAPON_TYPE_FONT_COLORS
	)
