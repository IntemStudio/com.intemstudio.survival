extends CanvasLayer

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const CHOICE_COUNT := 3
const MAX_REROLLS_PER_RUN := 3
const MAX_DISCARDS_PER_RUN := 3
const AUTO_SELECT_DELAY_SEC := 3.0
const DEFAULT_AUTO_PRIORITY_ORDER: Array[String] = ["Ranged", "Magic", "Melee"]
const WEAPON_TYPE_LABELS_KO := {
	"Ranged": "원거리",
	"Magic": "마법",
	"Melee": "근접",
}

const WEAPON_TYPE_BUTTON_COLORS := {
	"Melee": Color(0.55, 0.24, 0.2, 1),
	"Ranged": Color(0.2, 0.48, 0.32, 1),
	"Magic": Color(0.32, 0.38, 0.72, 1),
}
const DEFAULT_BUTTON_COLOR := Color(0.28, 0.28, 0.32, 1)
const CHOICE_FONT_COLOR := Color(0.95, 0.95, 0.98, 1)
const AUTO_GAUGE_DIM_ALPHA := 0.42
const AUTO_GAUGE_FILL_ALPHA := 0.92

var _current_choices: Array[WeaponData] = []
var _owned_weapons: Array[WeaponData] = []
var _discarded_weapons: Array[WeaponData] = []
var _rerolls_remaining := MAX_REROLLS_PER_RUN
var _discards_remaining := MAX_DISCARDS_PER_RUN
var _button_styles_by_type: Dictionary = {}
var _auto_select_active := false
var _auto_select_elapsed := 0.0
var _auto_select_target_index := -1
var _auto_priority_order: Array[String] = DEFAULT_AUTO_PRIORITY_ORDER.duplicate()
var _gauge_tracks: Array[ColorRect] = []
var _gauge_fills: Array[ColorRect] = []

@onready var _choice_rows: Array[HBoxContainer] = [
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow0,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow1,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow2,
]
@onready var _buttons: Array[Button] = [
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow0/RevolverButton,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow1/TommyGunsButton,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow2/BoomerangButton,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ConcoctionButton,
]
@onready var _title_label: Label = $MenuOverlay/CenterContainer/VBoxContainer/TitleLabel
@onready var _detail_label: RichTextLabel = (
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/RightColumnVBox/DetailPanel/MarginContainer/DetailLabel
)
@onready var _discarded_list_label: Label = (
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/RightColumnVBox/DiscardedPanel/MarginContainer/VBoxContainer/DiscardedListLabel
)
@onready var _discard_buttons: Array[Button] = [
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow0/DiscardSlot0Button,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow1/DiscardSlot1Button,
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/ChoiceRow2/DiscardSlot2Button,
]
@onready var _auto_select_toggle: CheckButton = (
	$MenuOverlay/CenterContainer/VBoxContainer/AutoSelectRow/AutoSelectToggle
)
@onready var _auto_select_countdown_label: Label = (
	$MenuOverlay/CenterContainer/VBoxContainer/AutoSelectRow/AutoSelectCountdownLabel
)
@onready var _priority_type_labels: Array[Label] = [
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot0/TypeLabel,
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot1/TypeLabel,
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot2/TypeLabel,
]
@onready var _priority_up_buttons: Array[Button] = [
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot0/UpButton,
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot1/UpButton,
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot2/UpButton,
]
@onready var _priority_down_buttons: Array[Button] = [
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot0/DownButton,
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot1/DownButton,
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/PrioritySlot2/DownButton,
]
@onready var _reroll_button: Button = (
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/ChoicesVBox/RerollButton
)


func _ready() -> void:
	_button_styles_by_type = _build_button_styles_by_type()
	_setup_auto_gauge_fills()
	for i in _buttons.size():
		var button := _buttons[i]
		button.mouse_entered.connect(_on_choice_hovered.bind(i))
		button.focus_entered.connect(_on_choice_hovered.bind(i))
	_auto_select_toggle.toggled.connect(_on_auto_select_toggle_toggled)
	for i in _priority_up_buttons.size():
		_priority_up_buttons[i].pressed.connect(_on_priority_up_pressed.bind(i))
		_priority_down_buttons[i].pressed.connect(_on_priority_down_pressed.bind(i))
	_refresh_auto_priority_ui()
	set_process(false)
	hide()


func on_menu_opened() -> void:
	_begin_auto_select_if_enabled()


func on_menu_closed() -> void:
	_cancel_auto_select()


func _process(delta: float) -> void:
	if not _auto_select_active:
		return
	_auto_select_elapsed += delta
	var ratio := clampf(_auto_select_elapsed / AUTO_SELECT_DELAY_SEC, 0.0, 1.0)
	var remaining := maxf(AUTO_SELECT_DELAY_SEC - _auto_select_elapsed, 0.0)
	_update_auto_select_ui(ratio, remaining)
	if _auto_select_elapsed >= AUTO_SELECT_DELAY_SEC:
		_auto_select_active = false
		_select_weapon_at_index(_auto_select_target_index)


func _get_all_weapons() -> Array[WeaponData]:
	var pool: Array[WeaponData] = RangedWeaponCatalog.get_all()
	pool.append_array(MeleeWeaponCatalog.get_all())
	pool.append_array(MagicWeaponCatalog.get_all())
	return pool


func present_random_choices(title: String = "무기 선택", owned_weapons: Array[WeaponData] = []) -> bool:
	_cancel_auto_select()
	_owned_weapons = owned_weapons.duplicate()
	_current_choices = _pick_random_weapons(CHOICE_COUNT, _owned_weapons)
	_title_label.text = title
	_update_button_labels()
	_update_reroll_button_state()
	_update_discarded_list_ui()
	return not _current_choices.is_empty()


func reroll_choices() -> void:
	if _rerolls_remaining <= 0:
		return
	_rerolls_remaining -= 1
	_cancel_auto_select()
	_current_choices = _pick_random_weapons(CHOICE_COUNT, _owned_weapons)
	_update_button_labels()
	_update_reroll_button_state()
	if visible and _auto_select_toggle.button_pressed:
		_begin_auto_select_if_enabled()


func discard_weapon_at_index(index: int) -> void:
	if _discards_remaining <= 0:
		return
	if index < 0 or index >= _current_choices.size():
		return
	_discards_remaining -= 1
	_cancel_auto_select()
	var weapon := _current_choices[index]
	_register_discarded_weapon(weapon)
	var replacement := _pick_replacement_weapon()
	if replacement:
		_current_choices[index] = replacement
	else:
		_current_choices.remove_at(index)
	_update_button_labels()
	_update_discarded_list_ui()
	_update_reroll_button_state()
	if visible and _auto_select_toggle.button_pressed:
		_begin_auto_select_if_enabled()


func _pick_random_weapons(count: int, owned_weapons: Array[WeaponData]) -> Array[WeaponData]:
	var pool := _build_selectable_weapon_pool(owned_weapons)
	pool.shuffle()
	var choice_count := mini(count, pool.size())
	return pool.slice(0, choice_count)


func _pick_replacement_weapon() -> WeaponData:
	var pool := _build_selectable_weapon_pool(_owned_weapons)
	var used_keys: Dictionary = {}
	for weapon in _current_choices:
		used_keys[weapon.get_unique_key()] = true
	pool.shuffle()
	for weapon in pool:
		if not used_keys.has(weapon.get_unique_key()):
			return weapon
	return null


func _build_selectable_weapon_pool(owned_weapons: Array[WeaponData]) -> Array[WeaponData]:
	var pool: Array[WeaponData] = []
	for weapon in _get_all_weapons():
		if _is_weapon_owned(weapon, owned_weapons):
			continue
		if _is_weapon_discarded(weapon):
			continue
		pool.append(weapon)
	return pool


func _register_discarded_weapon(weapon: WeaponData) -> void:
	if _is_weapon_discarded(weapon):
		return
	_discarded_weapons.append(weapon)


func _is_weapon_discarded(weapon: WeaponData) -> bool:
	var key := weapon.get_unique_key()
	for discarded in _discarded_weapons:
		if discarded.get_unique_key() == key:
			return true
	return false


func _update_reroll_button_state() -> void:
	_reroll_button.text = "리롤 (%d회 남음)" % _rerolls_remaining
	_reroll_button.disabled = (
		_rerolls_remaining <= 0
		or _build_selectable_weapon_pool(_owned_weapons).is_empty()
	)


func _update_discard_buttons_state() -> void:
	var show_discard := _discards_remaining > 0
	for i in _discard_buttons.size():
		var has_choice := i < _current_choices.size()
		var row: HBoxContainer = _choice_rows[i]
		row.visible = has_choice
		var discard_button := _discard_buttons[i]
		discard_button.visible = show_discard and has_choice
		if show_discard:
			discard_button.text = "버리기"


func _update_discarded_list_ui() -> void:
	if _discarded_weapons.is_empty():
		_discarded_list_label.text = "(없음)"
		return
	var lines: PackedStringArray = []
	for weapon in _discarded_weapons:
		lines.append("• %s" % weapon.get_display_name_localized())
	_discarded_list_label.text = "\n".join(lines)


func _is_weapon_owned(weapon: WeaponData, owned_weapons: Array[WeaponData]) -> bool:
	var key := weapon.get_unique_key()
	for owned in owned_weapons:
		if owned.get_unique_key() == key:
			return true
	return false


func _update_button_labels() -> void:
	for i in _buttons.size():
		var button := _buttons[i]
		if i < _current_choices.size() and i < _choice_rows.size():
			var weapon := _current_choices[i]
			button.visible = true
			button.text = weapon.get_select_label()
			button.disabled = false
			_apply_choice_button_style(button, weapon)
		else:
			button.visible = false
			button.disabled = true
	_update_discard_buttons_state()
	_show_weapon_detail(0)


func _setup_auto_gauge_fills() -> void:
	_gauge_tracks.clear()
	_gauge_fills.clear()
	for button in _buttons:
		var track := ColorRect.new()
		track.name = "AutoGaugeTrack"
		track.show_behind_parent = true
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.visible = false
		track.set_anchors_preset(Control.PRESET_FULL_RECT)
		var fill := ColorRect.new()
		fill.name = "AutoGaugeFill"
		fill.show_behind_parent = true
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.visible = false
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.anchor_right = 0.0
		button.add_child(track)
		button.add_child(fill)
		button.move_child(track, 0)
		button.move_child(fill, 1)
		_gauge_tracks.append(track)
		_gauge_fills.append(fill)


func _begin_auto_select_if_enabled() -> void:
	_cancel_auto_select()
	if not _auto_select_toggle.button_pressed or _current_choices.is_empty():
		_auto_select_countdown_label.text = ""
		return
	_auto_select_target_index = _pick_auto_select_index()
	if _auto_select_target_index < 0:
		return
	_auto_select_active = true
	_auto_select_elapsed = 0.0
	_show_weapon_detail(_auto_select_target_index)
	_update_auto_select_ui(0.0, AUTO_SELECT_DELAY_SEC)
	set_process(true)


func _cancel_auto_select() -> void:
	_auto_select_active = false
	_auto_select_elapsed = 0.0
	_auto_select_target_index = -1
	_auto_select_countdown_label.text = ""
	_reset_auto_gauge_fills()
	_refresh_choice_button_styles()
	set_process(false)


func _get_auto_type_priority(weapon_type: String) -> int:
	var rank := _auto_priority_order.find(weapon_type)
	return rank if rank >= 0 else 99


func _pick_auto_select_index() -> int:
	var best_index := -1
	var best_priority := 99
	for i in _current_choices.size():
		var priority := _get_auto_type_priority(_current_choices[i].weapon_type)
		if priority < best_priority:
			best_priority = priority
			best_index = i
	return best_index


func _refresh_auto_priority_ui() -> void:
	for i in _priority_type_labels.size():
		var weapon_type: String = _auto_priority_order[i]
		var label: String = WEAPON_TYPE_LABELS_KO.get(weapon_type, weapon_type)
		var type_color: Color = WEAPON_TYPE_BUTTON_COLORS.get(weapon_type, CHOICE_FONT_COLOR)
		_priority_type_labels[i].text = label
		_priority_type_labels[i].add_theme_color_override("font_color", type_color)
		_priority_up_buttons[i].disabled = i == 0
		_priority_down_buttons[i].disabled = i == _priority_type_labels.size() - 1


func _move_auto_priority_slot(slot_index: int, direction: int) -> void:
	var target_index := slot_index + direction
	if slot_index < 0 or slot_index >= _auto_priority_order.size():
		return
	if target_index < 0 or target_index >= _auto_priority_order.size():
		return
	var swapped := _auto_priority_order[slot_index]
	_auto_priority_order[slot_index] = _auto_priority_order[target_index]
	_auto_priority_order[target_index] = swapped
	_refresh_auto_priority_ui()
	if visible and _auto_select_toggle.button_pressed:
		_begin_auto_select_if_enabled()


func _on_priority_up_pressed(slot_index: int) -> void:
	_move_auto_priority_slot(slot_index, -1)


func _on_priority_down_pressed(slot_index: int) -> void:
	_move_auto_priority_slot(slot_index, 1)


func _update_auto_select_ui(fill_ratio: float, remaining_sec: float) -> void:
	_auto_select_countdown_label.text = "자동 선택까지 %.1f초" % remaining_sec
	_update_auto_gauge_fills(fill_ratio)
	_refresh_choice_button_styles()


func _update_auto_gauge_fills(fill_ratio: float) -> void:
	for i in _gauge_fills.size():
		var track: ColorRect = _gauge_tracks[i]
		var fill: ColorRect = _gauge_fills[i]
		if i != _auto_select_target_index or not _auto_select_active:
			track.visible = false
			fill.visible = false
			fill.anchor_right = 0.0
			continue
		var weapon := _current_choices[i]
		var base_color: Color = WEAPON_TYPE_BUTTON_COLORS.get(weapon.weapon_type, DEFAULT_BUTTON_COLOR)
		var dimmed := base_color.darkened(0.35)
		dimmed.a = AUTO_GAUGE_DIM_ALPHA
		track.color = dimmed
		track.visible = true
		fill.color = base_color
		fill.color.a = AUTO_GAUGE_FILL_ALPHA
		fill.visible = true
		fill.anchor_right = fill_ratio


func _reset_auto_gauge_fills() -> void:
	for track in _gauge_tracks:
		track.visible = false
	for fill in _gauge_fills:
		fill.visible = false
		fill.anchor_right = 0.0


func _refresh_choice_button_styles() -> void:
	for i in _buttons.size():
		if i >= _current_choices.size():
			continue
		var button := _buttons[i]
		var weapon := _current_choices[i]
		if _auto_select_active and i == _auto_select_target_index:
			_apply_gauge_target_button_style(button, weapon)
		else:
			_apply_choice_button_style(button, weapon)


func _apply_gauge_target_button_style(button: Button, weapon: WeaponData) -> void:
	var base_color: Color = WEAPON_TYPE_BUTTON_COLORS.get(weapon.weapon_type, DEFAULT_BUTTON_COLOR)
	var state_styles := _build_gauge_overlay_button_styles(base_color)
	button.add_theme_stylebox_override("normal", state_styles["normal"])
	button.add_theme_stylebox_override("hover", state_styles["hover"])
	button.add_theme_stylebox_override("pressed", state_styles["pressed"])
	button.add_theme_stylebox_override("disabled", state_styles["disabled"])
	button.add_theme_stylebox_override("focus", state_styles["hover"])
	_apply_choice_button_font_colors(button)


func _build_gauge_overlay_button_styles(border_color: Color) -> Dictionary:
	return {
		"normal": _create_gauge_overlay_stylebox(border_color),
		"hover": _create_gauge_overlay_stylebox(border_color.lightened(0.14)),
		"pressed": _create_gauge_overlay_stylebox(border_color.darkened(0.1)),
		"disabled": _create_gauge_overlay_stylebox(border_color.darkened(0.22), 0.55),
	}


func _create_gauge_overlay_stylebox(border_color: Color, border_alpha: float = 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	var border := border_color
	border.a = border_alpha
	style.border_color = border.lightened(0.28)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style


func _apply_choice_button_font_colors(button: Button) -> void:
	button.add_theme_color_override("font_color", CHOICE_FONT_COLOR)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", CHOICE_FONT_COLOR)
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.75, 0.78, 1))
	button.add_theme_color_override("font_focus_color", Color.WHITE)


func _on_auto_select_toggle_toggled(_pressed: bool) -> void:
	if visible:
		if _auto_select_toggle.button_pressed:
			_begin_auto_select_if_enabled()
		else:
			_cancel_auto_select()


func _build_button_styles_by_type() -> Dictionary:
	var styles := {}
	for weapon_type in WEAPON_TYPE_BUTTON_COLORS:
		styles[weapon_type] = _build_button_state_styles(WEAPON_TYPE_BUTTON_COLORS[weapon_type])
	styles["_default"] = _build_button_state_styles(DEFAULT_BUTTON_COLOR)
	return styles


func _build_button_state_styles(base_color: Color) -> Dictionary:
	return {
		"normal": _create_choice_stylebox(base_color),
		"hover": _create_choice_stylebox(base_color.lightened(0.14)),
		"pressed": _create_choice_stylebox(base_color.darkened(0.1)),
		"disabled": _create_choice_stylebox(base_color.darkened(0.22), 0.55),
	}


func _create_choice_stylebox(bg_color: Color, bg_alpha: float = 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill := bg_color
	fill.a = bg_alpha
	style.bg_color = fill
	style.border_color = bg_color.lightened(0.28)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style


func _apply_choice_button_style(button: Button, weapon: WeaponData) -> void:
	var type_key := weapon.weapon_type
	if not _button_styles_by_type.has(type_key):
		type_key = "_default"
	var state_styles: Dictionary = _button_styles_by_type[type_key]
	button.add_theme_stylebox_override("normal", state_styles["normal"])
	button.add_theme_stylebox_override("hover", state_styles["hover"])
	button.add_theme_stylebox_override("pressed", state_styles["pressed"])
	button.add_theme_stylebox_override("disabled", state_styles["disabled"])
	button.add_theme_stylebox_override("focus", state_styles["hover"])
	_apply_choice_button_font_colors(button)


func _on_choice_hovered(index: int) -> void:
	_show_weapon_detail(index)


func _show_weapon_detail(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		_detail_label.text = ""
		return
	_detail_label.text = _current_choices[index].build_select_tooltip_bbcode()


func _select_weapon_at_index(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return
	_cancel_auto_select()
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


func _on_reroll_button_pressed() -> void:
	reroll_choices()


func _on_discard_slot_0_pressed() -> void:
	discard_weapon_at_index(0)


func _on_discard_slot_1_pressed() -> void:
	discard_weapon_at_index(1)


func _on_discard_slot_2_pressed() -> void:
	discard_weapon_at_index(2)
