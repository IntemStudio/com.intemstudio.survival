class_name TestArenaPlayerPanelController
extends RefCounted

## F6 플레이어 탭 — 직업 선택·이동속도·직업 보너스(%) 튜닝·스탯 요약.

const TestArenaTuningUiUtil = preload("res://game/test_arena_tuning_ui.gd")

var _player: Node
var _update_status: Callable
var _apply_loadout: Callable
var _equip_default_weapon: Callable
var _player_snapshot: TestArenaPlayerSnapshot
var _class_option: OptionButton
var _default_weapon_option: OptionButton
var _all_weapon_options: Array[WeaponData] = []
var _class_desc_label: Label
var _stats_label: Label
var _heal_button: Button
var _create_player_button: Button
var _move_speed_fields: VBoxContainer
var _class_mult_fields: VBoxContainer
var _move_speed_tuning_status_label: Label
var _save_player_tuning_button: Button
var _reset_player_tuning_button: Button
var _move_speed_field_label: Label
var _move_speed_spin: SpinBox
var _class_mult_field_defs: Array = []
var _class_mult_field_labels: Array[Label] = []
var _class_mult_spins: Array[SpinBox] = []
var _spawn_global_position: Vector2 = Vector2.ZERO
var _tuning_button_size := Vector2(52, 52)
var _tuning_spin_min_height := 48.0
var _tuning_button_font_size := 24
var _tuning_spin_value_font_size := 17
var _tuning_color_default := Color(0.78, 0.78, 0.82, 1.0)
var _tuning_color_saved := Color(0.55, 0.75, 0.95, 1.0)
var _tuning_color_session := Color(0.95, 0.82, 0.38, 1.0)
var _move_speed_ui_refreshing := false
var _class_mult_ui_refreshing := false


func configure(
	player: Node,
	update_status: Callable,
	apply_loadout: Callable,
	equip_default_weapon: Callable,
	player_snapshot: TestArenaPlayerSnapshot,
	class_option: OptionButton,
	default_weapon_option: OptionButton,
	all_weapon_options: Array[WeaponData],
	class_desc_label: Label,
	stats_label: Label,
	heal_button: Button,
	create_player_button: Button,
	move_speed_fields: VBoxContainer,
	class_mult_fields: VBoxContainer,
	move_speed_tuning_status_label: Label,
	save_player_tuning_button: Button,
	reset_player_tuning_button: Button,
	spawn_global_position: Vector2,
	tuning_button_size: Vector2,
	tuning_spin_min_height: float,
	tuning_button_font_size: int,
	tuning_spin_value_font_size: int,
	tuning_color_default: Color,
	tuning_color_saved: Color,
	tuning_color_session: Color
) -> void:
	_player = player
	_update_status = update_status
	_apply_loadout = apply_loadout
	_equip_default_weapon = equip_default_weapon
	_player_snapshot = player_snapshot
	_class_option = class_option
	_default_weapon_option = default_weapon_option
	_all_weapon_options = all_weapon_options
	_class_desc_label = class_desc_label
	_stats_label = stats_label
	_heal_button = heal_button
	_create_player_button = create_player_button
	_move_speed_fields = move_speed_fields
	_class_mult_fields = class_mult_fields
	_move_speed_tuning_status_label = move_speed_tuning_status_label
	_save_player_tuning_button = save_player_tuning_button
	_reset_player_tuning_button = reset_player_tuning_button
	_spawn_global_position = spawn_global_position
	_tuning_button_size = tuning_button_size
	_tuning_spin_min_height = tuning_spin_min_height
	_tuning_button_font_size = tuning_button_font_size
	_tuning_spin_value_font_size = tuning_spin_value_font_size
	_tuning_color_default = tuning_color_default
	_tuning_color_saved = tuning_color_saved
	_tuning_color_session = tuning_color_session
	_hide_readonly_info_labels()


func _hide_readonly_info_labels() -> void:
	if _class_desc_label != null:
		_class_desc_label.visible = false
	if _stats_label != null:
		_stats_label.visible = false
	if _move_speed_tuning_status_label != null:
		_move_speed_tuning_status_label.visible = false


func setup_class_option() -> void:
	if _class_option == null:
		return
	var selected_id := RunConfig.get_player_class_id()
	_class_option.clear()
	var player_classes := PlayerClassCatalog.get_all()
	for player_class in player_classes:
		_class_option.add_item(player_class.get_display_name_localized())
	_select_class_in_option(selected_id)
	setup_default_weapon_option()
	setup_move_speed_tuning_ui()
	setup_class_stat_tuning_ui()
	_apply_move_speed_to_player()
	_apply_selected_class()
	refresh_panel()


func setup_default_weapon_option() -> void:
	if _default_weapon_option == null or _player_snapshot == null:
		return
	var selected_id := _player_snapshot.get_effective_default_weapon_id()
	_default_weapon_option.clear()
	var select_index := 0
	for index in _all_weapon_options.size():
		var weapon: WeaponData = _all_weapon_options[index]
		_default_weapon_option.add_item(weapon.get_display_name_localized())
		if weapon.get_unique_key() == selected_id:
			select_index = index
	if _all_weapon_options.is_empty():
		_default_weapon_option.add_item("(무기 없음)")
		_default_weapon_option.disabled = true
	else:
		_default_weapon_option.disabled = false
		_default_weapon_option.select(select_index)


func on_default_weapon_option_selected(index: int) -> void:
	if _player_snapshot == null or _default_weapon_option == null:
		return
	if index < 0 or index >= _all_weapon_options.size():
		return
	var weapon: WeaponData = _all_weapon_options[index]
	_player_snapshot.set_session_default_weapon_id(weapon.get_unique_key())
	refresh_panel()
	if _update_status.is_valid():
		_update_status.call("기본 무기: %s" % weapon.get_display_name_localized())


func setup_move_speed_tuning_ui() -> void:
	if _move_speed_fields == null or _player_snapshot == null:
		return
	for child in _move_speed_fields.get_children():
		child.free()
	var row := TestArenaTuningUiUtil.create_tuning_row(
		_move_speed_fields,
		TestArenaPlayerSnapshot.BASE_MOVE_SPEED_DEF,
		_player_snapshot.get_effective_base_move_speed(),
		_on_move_speed_value_changed,
		_on_move_speed_spin_tree_entered,
		_on_move_speed_step_pressed,
		_tuning_button_size,
		_tuning_button_font_size,
		_tuning_spin_min_height
	)
	_move_speed_spin = row["spin"] as SpinBox
	var row_container := row.get("row") as HBoxContainer
	if row_container != null and row_container.get_child_count() > 0:
		_move_speed_field_label = row_container.get_child(0) as Label


func setup_class_stat_tuning_ui() -> void:
	if _class_mult_fields == null or _player_snapshot == null:
		return
	for child in _class_mult_fields.get_children():
		child.free()
	_class_mult_field_defs.clear()
	_class_mult_field_labels.clear()
	_class_mult_spins.clear()
	var player_class := RunConfig.get_player_class()
	if player_class == null:
		return
	_class_mult_field_defs = _player_snapshot.get_class_stat_field_defs(player_class)
	var class_id := player_class.class_id
	for field_def in _class_mult_field_defs:
		var property: String = field_def["property"]
		var initial_value := _player_snapshot.get_spin_display_value(class_id, field_def)
		var row := TestArenaTuningUiUtil.create_tuning_row(
			_class_mult_fields,
			field_def,
			initial_value,
			_on_class_stat_value_changed.bind(property),
			_on_class_stat_spin_tree_entered.bind(property),
			func(spin: SpinBox, direction: int) -> void:
				_on_class_stat_step_pressed(spin, property, direction),
			_tuning_button_size,
			_tuning_button_font_size,
			_tuning_spin_min_height
		)
		var spin := row["spin"] as SpinBox
		_class_mult_spins.append(spin)
		var row_container := row.get("row") as HBoxContainer
		if row_container != null and row_container.get_child_count() > 0:
			var label := row_container.get_child(0) as Label
			_class_mult_field_labels.append(label)


func on_save_player_tuning_pressed() -> void:
	if _player_snapshot == null:
		return
	_commit_all_player_tuning_spins()
	_player_snapshot.save_player()
	setup_class_stat_tuning_ui()
	refresh_panel()
	if _update_status.is_valid():
		_update_status.call("플레이어 튜닝 스냅샷 저장")


func on_reset_player_tuning_pressed() -> void:
	if _player_snapshot == null:
		return
	_player_snapshot.reset_player()
	_on_move_speed_spin_changed(_player_snapshot.get_effective_base_move_speed())
	setup_default_weapon_option()
	setup_class_stat_tuning_ui()
	_apply_selected_class()
	if _update_status.is_valid():
		_update_status.call("플레이어 튜닝 되돌리기")


func on_class_option_selected(index: int) -> void:
	var player_classes := PlayerClassCatalog.get_all()
	if index < 0 or index >= player_classes.size():
		return
	RunConfig.set_player_class_id(StringName(player_classes[index].class_id))
	setup_class_stat_tuning_ui()
	_apply_selected_class()
	refresh_panel()
	if _update_status.is_valid():
		_update_status.call(
			"직업: %s" % player_classes[index].get_display_name_localized()
		)


func on_create_player_pressed() -> void:
	var player_classes := PlayerClassCatalog.get_all()
	var index := _class_option.selected if _class_option != null else -1
	if index >= 0 and index < player_classes.size():
		RunConfig.set_player_class_id(StringName(player_classes[index].class_id))
	if _player != null and _player.has_method(&"recreate_at"):
		_player.recreate_at(_spawn_global_position)
	if _equip_default_weapon.is_valid():
		_equip_default_weapon.call()
	_apply_selected_class()
	_apply_move_speed_to_player()
	if _apply_loadout.is_valid():
		_apply_loadout.call()
	refresh_panel()
	if _update_status.is_valid():
		var player_class := RunConfig.get_player_class()
		var label := player_class.get_display_name_localized() if player_class else "-"
		var weapon_label := "-"
		if _default_weapon_option != null and _default_weapon_option.selected >= 0:
			weapon_label = _default_weapon_option.get_item_text(_default_weapon_option.selected)
		_update_status.call("플레이어 생성: %s · %s" % [label, weapon_label])


func on_heal_player_pressed() -> void:
	if _player == null or not _player.has_method(&"get_max_health"):
		return
	var max_hp: float = _player.get_max_health()
	if _player.get("health") != null:
		_player.set("health", max_hp)
	if _player.has_method(&"_update_health_hud"):
		_player.call(&"_update_health_hud")
	refresh_panel()
	if _update_status.is_valid():
		_update_status.call("체력 만충")


func refresh_panel() -> void:
	_apply_move_speed_field_style()
	_apply_class_stat_field_styles()
	_refresh_player_tuning_action_buttons()


func _apply_selected_class() -> void:
	if _player == null:
		return
	var player_class := RunConfig.get_player_class()
	if player_class == null:
		if _player.has_method(&"apply_player_class_from_run_config"):
			_player.apply_player_class_from_run_config()
	elif _player.has_method(&"apply_player_class_with_modifiers") and _player_snapshot != null:
		_player.apply_player_class_with_modifiers(
			_player_snapshot.build_class_stat_modifiers(player_class.class_id)
		)
	elif _player.has_method(&"apply_player_class_from_run_config"):
		_player.apply_player_class_from_run_config()
	if _apply_loadout.is_valid():
		_apply_loadout.call()


func _apply_move_speed_to_player() -> void:
	if _player == null or _player_snapshot == null:
		return
	if _player.has_method(&"set_base_move_speed"):
		_player.set_base_move_speed(_player_snapshot.get_effective_base_move_speed())


func _commit_all_player_tuning_spins() -> void:
	if _move_speed_spin != null:
		TestArenaTuningUiUtil.commit_spin_box_pending(_move_speed_spin)
		_on_move_speed_spin_changed(float(_move_speed_spin.value))
	for index in _class_mult_spins.size():
		if index >= _class_mult_field_defs.size():
			break
		var spin: SpinBox = _class_mult_spins[index]
		var property: String = _class_mult_field_defs[index]["property"]
		var field_def: Dictionary = _class_mult_field_defs[index]
		TestArenaTuningUiUtil.commit_spin_box_pending(spin)
		_on_class_stat_spin_changed(property, float(spin.value), field_def)


func _on_move_speed_spin_changed(new_value: float) -> void:
	if _move_speed_ui_refreshing or _player_snapshot == null:
		return
	_player_snapshot.set_session_base_move_speed(new_value)
	_apply_move_speed_to_player()
	if _move_speed_spin != null and not is_equal_approx(_move_speed_spin.value, new_value):
		_move_speed_ui_refreshing = true
		_move_speed_spin.value = new_value
		_move_speed_ui_refreshing = false
	refresh_panel()


func _on_move_speed_value_changed(value: float) -> void:
	_on_move_speed_spin_changed(value)


func _on_move_speed_spin_tree_entered(spin: SpinBox) -> void:
	TestArenaTuningUiUtil.style_spin_line_edit(
		spin,
		_tuning_spin_min_height,
		_tuning_spin_value_font_size
	)
	TestArenaTuningUiUtil.wire_spin_box_text_commit(
		spin,
		func(_new_value: float) -> void:
			TestArenaTuningUiUtil.commit_spin_box_pending(spin)
			_on_move_speed_spin_changed(float(spin.value))
	)


func _on_move_speed_step_pressed(spin: SpinBox, direction: int) -> void:
	if spin == null:
		return
	_on_move_speed_spin_changed(spin.value + spin.step * float(direction))


func _on_class_stat_spin_changed(property: String, spin_value: float, field_def: Dictionary) -> void:
	if _class_mult_ui_refreshing or _player_snapshot == null:
		return
	var player_class := RunConfig.get_player_class()
	if player_class == null:
		return
	var stored_value: Variant = _player_snapshot.spin_value_to_stored(field_def, spin_value)
	_player_snapshot.set_session_class_stat(player_class.class_id, property, stored_value)
	_sync_class_stat_spin_display(property, spin_value, field_def)
	_apply_selected_class()
	refresh_panel()


func _get_class_stat_field_def(property: String) -> Dictionary:
	for field_def in _class_mult_field_defs:
		if field_def["property"] == property:
			return field_def
	return {}


func _on_class_stat_value_changed(spin_value: float, property: String) -> void:
	_on_class_stat_spin_changed(property, spin_value, _get_class_stat_field_def(property))


func _on_class_stat_spin_tree_entered(spin: SpinBox, property: String) -> void:
	TestArenaTuningUiUtil.style_spin_line_edit(
		spin,
		_tuning_spin_min_height,
		_tuning_spin_value_font_size
	)
	TestArenaTuningUiUtil.wire_spin_box_text_commit(
		spin,
		func(_new_value: float) -> void:
			TestArenaTuningUiUtil.commit_spin_box_pending(spin)
			_on_class_stat_spin_changed(
				property,
				float(spin.value),
				_get_class_stat_field_def(property)
			)
	)


func _on_class_stat_step_pressed(spin: SpinBox, property: String, direction: int) -> void:
	if spin == null:
		return
	_on_class_stat_spin_changed(
		property,
		spin.value + spin.step * float(direction),
		_get_class_stat_field_def(property)
	)


func _sync_class_stat_spin_display(property: String, spin_value: float, field_def: Dictionary) -> void:
	var spin_index := _get_class_stat_spin_index(property)
	if spin_index < 0:
		return
	var spin: SpinBox = _class_mult_spins[spin_index]
	if is_equal_approx(spin.value, spin_value):
		return
	_class_mult_ui_refreshing = true
	spin.value = spin_value
	_class_mult_ui_refreshing = false


func _get_class_stat_spin_index(property: String) -> int:
	for index in _class_mult_field_defs.size():
		if _class_mult_field_defs[index]["property"] == property:
			return index
	return -1


func _apply_move_speed_field_style() -> void:
	_apply_tuning_field_style(
		_move_speed_field_label,
		_move_speed_spin,
		TestArenaPlayerSnapshot.BASE_MOVE_SPEED_DEF,
		"",
		TestArenaPlayerSnapshot.BASE_MOVE_SPEED_PROPERTY
	)


func _apply_class_stat_field_styles() -> void:
	var player_class := RunConfig.get_player_class()
	if player_class == null:
		return
	for index in mini(_class_mult_field_labels.size(), _class_mult_field_defs.size()):
		var field_def: Dictionary = _class_mult_field_defs[index]
		var property: String = field_def["property"]
		_apply_tuning_field_style(
			_class_mult_field_labels[index],
			_class_mult_spins[index],
			field_def,
			player_class.class_id,
			property
		)


func _apply_tuning_field_style(
	label: Label,
	spin: SpinBox,
	field_def: Dictionary,
	class_id: String,
	property: String
) -> void:
	if label == null or spin == null or _player_snapshot == null:
		return
	var base_label := str(field_def.get("label", property))
	var tuned_value := (
		_player_snapshot.get_spin_display_value(class_id, field_def)
		if not class_id.is_empty()
		else _player_snapshot.get_tuned_value(property)
	)
	var is_pending := not is_equal_approx(spin.value, tuned_value)
	var color := _tuning_color_default
	var suffix := ""
	if is_pending:
		color = _tuning_color_session
		suffix = " *"
	else:
		var state := _player_snapshot.get_property_tuning_state(property, class_id)
		if state == TestArenaPlayerSnapshot.TUNING_STATE_SAVED:
			color = _tuning_color_saved
		elif state == TestArenaPlayerSnapshot.TUNING_STATE_SESSION:
			color = _tuning_color_session
			suffix = " *"
	if field_def.get("value_kind", "") == TestArenaPlayerSnapshot.VALUE_KIND_MULT_BONUS_PERCENT:
		label.text = "%s (%%)" % (base_label + suffix)
	else:
		label.text = base_label + suffix
	label.add_theme_color_override("font_color", color)
	spin.add_theme_color_override("font_color", color)
	var line_edit := spin.get_line_edit()
	if line_edit:
		line_edit.add_theme_color_override("font_color", color)


func _has_pending_player_tuning_spin_change() -> bool:
	if _has_pending_move_speed_spin_change():
		return true
	return _has_pending_class_stat_spin_change()


func _has_pending_move_speed_spin_change() -> bool:
	if _move_speed_spin == null or _player_snapshot == null:
		return false
	return not is_equal_approx(
		_move_speed_spin.value,
		_player_snapshot.get_tuned_value(TestArenaPlayerSnapshot.BASE_MOVE_SPEED_PROPERTY)
	)


func _has_pending_class_stat_spin_change() -> bool:
	var player_class := RunConfig.get_player_class()
	if player_class == null or _player_snapshot == null:
		return false
	for index in _class_mult_spins.size():
		if index >= _class_mult_field_defs.size():
			break
		var field_def: Dictionary = _class_mult_field_defs[index]
		var tuned_value := _player_snapshot.get_spin_display_value(
			player_class.class_id,
			field_def
		)
		if not is_equal_approx(_class_mult_spins[index].value, tuned_value):
			return true
	return false


func _refresh_player_tuning_action_buttons() -> void:
	if _player_snapshot == null:
		return
	var has_session := _player_snapshot.has_unsaved_session_changes()
	var has_pending := _has_pending_player_tuning_spin_change()
	var enabled := has_pending or has_session
	if _save_player_tuning_button != null:
		_save_player_tuning_button.disabled = not enabled
	if _reset_player_tuning_button != null:
		_reset_player_tuning_button.disabled = not enabled


func _select_class_in_option(class_id: StringName) -> void:
	if _class_option == null:
		return
	var player_classes := PlayerClassCatalog.get_all()
	for index in player_classes.size():
		if player_classes[index].class_id == String(class_id):
			_class_option.select(index)
			return
	if not player_classes.is_empty():
		_class_option.select(0)
