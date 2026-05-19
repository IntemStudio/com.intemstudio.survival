extends CanvasLayer

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const CHOICE_COUNT := 3

var _current_choices: Array[WeaponData] = []

@onready var _buttons: Array[Button] = [
	$MenuOverlay/CenterContainer/VBoxContainer/RevolverButton,
	$MenuOverlay/CenterContainer/VBoxContainer/TommyGunsButton,
	$MenuOverlay/CenterContainer/VBoxContainer/BoomerangButton,
	$MenuOverlay/CenterContainer/VBoxContainer/ConcoctionButton,
]
@onready var _title_label: Label = $MenuOverlay/CenterContainer/VBoxContainer/TitleLabel


func _ready() -> void:
	hide()


func _get_all_weapons() -> Array[WeaponData]:
	var pool: Array[WeaponData] = RangedWeaponCatalog.get_all()
	pool.append_array(MeleeWeaponCatalog.get_all())
	pool.append_array(MagicWeaponCatalog.get_all())
	return pool


func present_random_choices(title: String = "무기 선택", owned_weapons: Array[WeaponData] = []) -> bool:
	_current_choices = _pick_random_weapons(CHOICE_COUNT, owned_weapons)
	_title_label.text = title
	_update_button_labels()
	return not _current_choices.is_empty()


func _pick_random_weapons(count: int, owned_weapons: Array[WeaponData]) -> Array[WeaponData]:
	var pool: Array[WeaponData] = []
	for weapon in _get_all_weapons():
		if not _is_weapon_owned(weapon, owned_weapons):
			pool.append(weapon)

	pool.shuffle()
	var choice_count := mini(count, pool.size())
	return pool.slice(0, choice_count)


func _is_weapon_owned(weapon: WeaponData, owned_weapons: Array[WeaponData]) -> bool:
	var key := weapon.get_unique_key()
	for owned in owned_weapons:
		if owned.get_unique_key() == key:
			return true
	return false


func _update_button_labels() -> void:
	for i in _buttons.size():
		var button := _buttons[i]
		if i < _current_choices.size():
			button.visible = true
			button.text = _current_choices[i].get_select_label()
			button.disabled = false
		else:
			button.visible = false
			button.disabled = true


func _select_weapon_at_index(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return
	var game := get_parent()
	if game.has_method("on_weapon_chosen"):
		game.on_weapon_chosen(_current_choices[index])


func _on_revolver_button_pressed() -> void:
	_select_weapon_at_index(0)


func _on_tommy_guns_button_pressed() -> void:
	_select_weapon_at_index(1)


func _on_boomerang_button_pressed() -> void:
	_select_weapon_at_index(2)


func _on_concoction_button_pressed() -> void:
	_select_weapon_at_index(3)
