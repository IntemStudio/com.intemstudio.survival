extends CanvasLayer

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const CHOICE_COUNT := 3
const MAX_REROLLS_PER_RUN := 3
const MAX_DISCARDS_PER_RUN := 3
const AUTO_SELECT_DELAY_SEC := 3.0
const DEFAULT_AUTO_PRIORITY_ORDER: Array[String] = ["Ranged", "Magic", "Melee"]

const WEAPON_TYPE_BUTTON_COLORS := {
	"Melee": Color(0.55, 0.24, 0.2, 1),
	"Ranged": Color(0.2, 0.48, 0.32, 1),
	"Magic": Color(0.32, 0.38, 0.72, 1),
}
const DEFAULT_BUTTON_COLOR := Color(0.28, 0.28, 0.32, 1)
const PASSIVE_BUTTON_COLOR := Color(0.42, 0.26, 0.58, 1)
const WEAPON_UPGRADE_BUTTON_COLOR := Color(0.72, 0.52, 0.14, 1)
const CHOICE_FONT_COLOR := Color(0.95, 0.95, 0.98, 1)
const AUTO_GAUGE_DIM_ALPHA := 0.42
const AUTO_GAUGE_FILL_ALPHA := 0.92

var _current_choices: Array[WeaponData] = []
var _reward_choices: Array = []
var _use_reward_choices := false
var _passive_run_state: PassiveRunState = null
var _weapon_run_state: WeaponRunState = null
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
var _menu_title_key: StringName = &"weapon_select.title"
var _detail_hover_index := -1

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
@onready var _auto_priority_title: Label = (
	$MenuOverlay/CenterContainer/VBoxContainer/AutoPriorityPanel/AutoPriorityTitle
)
@onready var _discarded_title_label: Label = (
	$MenuOverlay/CenterContainer/VBoxContainer/ContentHBox/RightColumnVBox/DiscardedPanel/MarginContainer/VBoxContainer/DiscardedTitleLabel
)


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
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
	refresh_locale()
	set_process(false)
	hide()


func refresh_locale() -> void:
	if not is_node_ready():
		return
	_title_label.text = UiLocale.t(_menu_title_key)
	_auto_select_toggle.text = UiLocale.t(&"weapon_select.auto_toggle")
	_auto_priority_title.text = UiLocale.t(&"weapon_select.auto_priority_title")
	_discarded_title_label.text = UiLocale.t(&"weapon_select.discarded_title")
	_update_reroll_button_state()
	_update_discarded_list_ui()
	_refresh_auto_priority_ui()
	if _current_choices.is_empty():
		_detail_label.text = UiLocale.t(&"weapon_select.detail_hint")
	else:
		_update_button_labels()
	if _auto_select_active:
		var remaining := maxf(AUTO_SELECT_DELAY_SEC - _auto_select_elapsed, 0.0)
		var ratio := clampf(_auto_select_elapsed / AUTO_SELECT_DELAY_SEC, 0.0, 1.0)
		_update_auto_select_ui(ratio, remaining)


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


func present_random_choices(title_key: StringName = &"weapon_select.title", owned_weapons: Array[WeaponData] = []) -> bool:
	_use_reward_choices = false
	_reward_choices.clear()
	_passive_run_state = null
	_cancel_auto_select()
	_menu_title_key = title_key
	_owned_weapons = owned_weapons.duplicate()
	_current_choices = _pick_random_weapons(CHOICE_COUNT, _owned_weapons)
	_title_label.text = UiLocale.t(_menu_title_key)
	_detail_hover_index = -1
	_update_button_labels()
	_update_reroll_button_state()
	_update_discarded_list_ui()
	return not _current_choices.is_empty()


func present_reward_choices(
	title_key: StringName,
	choices: Array,
	owned_weapons: Array[WeaponData] = [],
	passive_state: PassiveRunState = null,
	weapon_state: WeaponRunState = null
) -> bool:
	_use_reward_choices = true
	_reward_choices = choices.duplicate()
	_passive_run_state = passive_state
	_weapon_run_state = weapon_state
	_cancel_auto_select()
	_menu_title_key = title_key
	_owned_weapons = owned_weapons.duplicate()
	_current_choices.clear()
	for choice_variant in _reward_choices:
		var choice := choice_variant as RewardChoice
		if choice != null and choice.is_weapon():
			_current_choices.append(choice.weapon)
	_title_label.text = UiLocale.t(_menu_title_key)
	_detail_hover_index = -1
	_update_button_labels()
	_update_reroll_button_state()
	_update_discarded_list_ui()
	return not _reward_choices.is_empty()


func reroll_choices() -> void:
	if _rerolls_remaining <= 0:
		return
	_rerolls_remaining -= 1
	_cancel_auto_select()
	var game := get_parent()
	if _use_reward_choices and game != null and game.has_method(&"reroll_reward_choices"):
		game.call("reroll_reward_choices")
	else:
		_current_choices = _pick_random_weapons(CHOICE_COUNT, _owned_weapons)
		_update_button_labels()
	_update_reroll_button_state()
	if visible and _auto_select_toggle.button_pressed:
		_begin_auto_select_if_enabled()


func discard_weapon_at_index(index: int) -> void:
	if _discards_remaining <= 0:
		return
	var weapon: WeaponData = null
	if _use_reward_choices:
		if index < 0 or index >= _reward_choices.size():
			return
		var reward_choice := _reward_choices[index] as RewardChoice
		if reward_choice == null or not reward_choice.is_weapon():
			return
		weapon = reward_choice.weapon
	elif index < 0 or index >= _current_choices.size():
		return
	else:
		weapon = _current_choices[index]
	_discards_remaining -= 1
	_cancel_auto_select()
	_register_discarded_weapon(weapon)
	var replacement := _pick_replacement_weapon()
	if _use_reward_choices:
		if replacement:
			_reward_choices[index] = RewardChoice.from_weapon(replacement)
		else:
			_reward_choices.remove_at(index)
		_rebuild_weapon_choices_from_rewards()
	else:
		if replacement:
			_current_choices[index] = replacement
		else:
			_current_choices.remove_at(index)
	_update_button_labels()
	_update_discarded_list_ui()
	_update_reroll_button_state()
	if visible and _auto_select_toggle.button_pressed:
		_begin_auto_select_if_enabled()


func _rebuild_weapon_choices_from_rewards() -> void:
	_current_choices.clear()
	for choice_variant in _reward_choices:
		var choice := choice_variant as RewardChoice
		if choice != null and choice.is_weapon():
			_current_choices.append(choice.weapon)


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
	_reroll_button.text = UiLocale.t(&"weapon_select.reroll_remaining") % _rerolls_remaining
	var can_reroll := _rerolls_remaining > 0
	if _use_reward_choices:
		var game := get_parent()
		can_reroll = can_reroll and game != null and game.has_method(&"reroll_reward_choices")
	else:
		can_reroll = can_reroll and not _build_selectable_weapon_pool(_owned_weapons).is_empty()
	_reroll_button.disabled = not can_reroll


func _update_discard_buttons_state() -> void:
	var show_discard := _discards_remaining > 0
	for i in _discard_buttons.size():
		var has_choice := _has_reward_row(i)
		var row: HBoxContainer = _choice_rows[i]
		row.visible = has_choice
		var discard_button := _discard_buttons[i]
		var can_discard := show_discard and has_choice and _is_weapon_reward_row(i)
		discard_button.visible = can_discard
		if can_discard:
			discard_button.text = UiLocale.t(&"weapon_select.discard")


func _update_discarded_list_ui() -> void:
	if _discarded_weapons.is_empty():
		_discarded_list_label.text = UiLocale.t(&"weapon_select.discarded_none")
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
		if _has_reward_row(i) and i < _choice_rows.size():
			button.visible = true
			button.disabled = false
			if _use_reward_choices:
				var choice := _reward_choices[i] as RewardChoice
				button.text = choice.get_choice_label()
				if choice.is_weapon():
					_apply_choice_button_style(button, choice.weapon)
				elif choice.is_weapon_upgrade():
					_apply_weapon_upgrade_button_style(button)
				else:
					_apply_passive_button_style(button)
			else:
				var weapon := _current_choices[i]
				button.text = weapon.get_select_label()
				_apply_choice_button_style(button, weapon)
		else:
			button.visible = false
			button.disabled = true
	_update_discard_buttons_state()
	if _detail_hover_index >= 0 and _has_reward_row(_detail_hover_index):
		_show_reward_detail(_detail_hover_index)
	elif _has_any_reward_row():
		_show_reward_detail(0)
	else:
		_detail_label.text = UiLocale.t(&"weapon_select.detail_hint")


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
	if not _auto_select_toggle.button_pressed or not _has_any_reward_row():
		_auto_select_countdown_label.text = ""
		return
	_auto_select_target_index = _pick_auto_select_index()
	if _auto_select_target_index < 0:
		return
	_auto_select_active = true
	_auto_select_elapsed = 0.0
	_show_reward_detail(_auto_select_target_index)
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
	var row_count := _reward_choices.size() if _use_reward_choices else _current_choices.size()
	for i in row_count:
		if _use_reward_choices:
			var choice := _reward_choices[i] as RewardChoice
			if choice == null:
				continue
			if choice.is_weapon() or choice.is_weapon_upgrade():
				var weapon_data := choice.weapon
				var priority := _get_auto_type_priority(weapon_data.weapon_type)
				if priority < best_priority:
					best_priority = priority
					best_index = i
		else:
			var priority := _get_auto_type_priority(_current_choices[i].weapon_type)
			if priority < best_priority:
				best_priority = priority
				best_index = i
	return best_index


func _refresh_auto_priority_ui() -> void:
	for i in _priority_type_labels.size():
		var weapon_type: String = _auto_priority_order[i]
		var label: String = UiLocale.weapon_type_label(weapon_type)
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
	_auto_select_countdown_label.text = UiLocale.t(&"weapon_select.auto_countdown") % remaining_sec
	_update_auto_gauge_fills(fill_ratio)
	_refresh_choice_button_styles()


func _get_reward_choice_highlight_color(index: int) -> Color:
	if _use_reward_choices and index >= 0 and index < _reward_choices.size():
		var choice := _reward_choices[index] as RewardChoice
		if choice == null:
			return DEFAULT_BUTTON_COLOR
		if choice.is_passive():
			return PASSIVE_BUTTON_COLOR
		if choice.is_weapon_upgrade():
			return WEAPON_UPGRADE_BUTTON_COLOR
		if choice.weapon != null:
			return WEAPON_TYPE_BUTTON_COLORS.get(choice.weapon.weapon_type, DEFAULT_BUTTON_COLOR)
	if index >= 0 and index < _current_choices.size():
		var weapon := _current_choices[index]
		return WEAPON_TYPE_BUTTON_COLORS.get(weapon.weapon_type, DEFAULT_BUTTON_COLOR)
	return DEFAULT_BUTTON_COLOR


func _update_auto_gauge_fills(fill_ratio: float) -> void:
	for i in _gauge_fills.size():
		var track: ColorRect = _gauge_tracks[i]
		var fill: ColorRect = _gauge_fills[i]
		if i != _auto_select_target_index or not _auto_select_active:
			track.visible = false
			fill.visible = false
			fill.anchor_right = 0.0
			continue
		if not _has_reward_row(i):
			track.visible = false
			fill.visible = false
			fill.anchor_right = 0.0
			continue
		var base_color: Color = _get_reward_choice_highlight_color(i)
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
		if not _has_reward_row(i):
			continue
		var button := _buttons[i]
		if _auto_select_active and i == _auto_select_target_index:
			_apply_gauge_target_button_style(button, _get_reward_choice_highlight_color(i))
		elif _use_reward_choices:
			var choice := _reward_choices[i] as RewardChoice
			if choice.is_weapon():
				_apply_choice_button_style(button, choice.weapon)
			elif choice.is_weapon_upgrade():
				_apply_weapon_upgrade_button_style(button)
			else:
				_apply_passive_button_style(button)
		else:
			_apply_choice_button_style(button, _current_choices[i])


func _apply_gauge_target_button_style(button: Button, base_color: Color) -> void:
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
	_detail_hover_index = index
	_show_reward_detail(index)


func _show_reward_detail(index: int) -> void:
	if not _has_reward_row(index):
		_detail_label.text = UiLocale.t(&"weapon_select.detail_hint")
		return
	if _use_reward_choices:
		var choice := _reward_choices[index] as RewardChoice
		if choice == null:
			_detail_label.text = UiLocale.t(&"weapon_select.detail_hint")
			return
		var current_passive_level := 0
		var current_weapon_level := 1
		if choice.is_passive() and _passive_run_state != null:
			current_passive_level = _passive_run_state.get_level(choice.passive.passive_id)
		if choice.is_weapon_upgrade() and _weapon_run_state != null:
			current_weapon_level = _weapon_run_state.get_level(choice.weapon)
		_detail_label.text = choice.get_detail_bbcode(current_passive_level, current_weapon_level)
	else:
		_detail_label.text = _current_choices[index].build_select_tooltip_bbcode()


func _select_weapon_at_index(index: int) -> void:
	if not _has_reward_row(index):
		return
	_cancel_auto_select()
	var game := get_parent()
	if _use_reward_choices and game.has_method(&"on_reward_chosen"):
		game.call("on_reward_chosen", _reward_choices[index])
	elif game.has_method("on_weapon_chosen"):
		game.on_weapon_chosen(_current_choices[index])


func _has_reward_row(index: int) -> bool:
	if _use_reward_choices:
		return index >= 0 and index < _reward_choices.size()
	return index >= 0 and index < _current_choices.size()


func _has_any_reward_row() -> bool:
	return _reward_choices.size() > 0 if _use_reward_choices else not _current_choices.is_empty()


func _is_weapon_reward_row(index: int) -> bool:
	if not _has_reward_row(index):
		return false
	if _use_reward_choices:
		var choice := _reward_choices[index] as RewardChoice
		return choice != null and choice.is_weapon()
	return true


func _apply_passive_button_style(button: Button) -> void:
	var state_styles: Dictionary = _build_button_state_styles(PASSIVE_BUTTON_COLOR)
	button.add_theme_stylebox_override("normal", state_styles["normal"])
	button.add_theme_stylebox_override("hover", state_styles["hover"])
	button.add_theme_stylebox_override("pressed", state_styles["pressed"])
	button.add_theme_stylebox_override("disabled", state_styles["disabled"])
	button.add_theme_stylebox_override("focus", state_styles["hover"])
	_apply_choice_button_font_colors(button)


func _apply_weapon_upgrade_button_style(button: Button) -> void:
	var state_styles: Dictionary = _build_button_state_styles(WEAPON_UPGRADE_BUTTON_COLOR)
	button.add_theme_stylebox_override("normal", state_styles["normal"])
	button.add_theme_stylebox_override("hover", state_styles["hover"])
	button.add_theme_stylebox_override("pressed", state_styles["pressed"])
	button.add_theme_stylebox_override("disabled", state_styles["disabled"])
	button.add_theme_stylebox_override("focus", state_styles["hover"])
	_apply_choice_button_font_colors(button)


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
