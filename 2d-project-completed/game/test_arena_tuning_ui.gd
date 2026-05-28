class_name TestArenaTuningUi
extends RefCounted

## 테스트 아레나 튜닝 SpinBox 행 생성/입력 확정 공통 유틸.

const DEFAULT_COMMIT_META_KEY := &"tuning_commit_wired"


static func create_tuning_row(
	container: VBoxContainer,
	field_def: Dictionary,
	initial_value: float,
	on_value_changed: Callable,
	on_tree_entered: Callable,
	on_step_pressed: Callable,
	button_size: Vector2,
	button_font_size: int,
	spin_min_height: float
) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	var label := Label.new()
	label.text = str(field_def.get("label", field_def["property"]))
	label.custom_minimum_size = Vector2(120, 0)
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)

	var property: String = field_def["property"]
	var value_row := HBoxContainer.new()
	value_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_row.add_theme_constant_override("separation", 6)
	row.add_child(value_row)

	var dec_button := _create_step_button("−", button_size, button_font_size)
	value_row.add_child(dec_button)

	var spin := SpinBox.new()
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.custom_minimum_size.y = spin_min_height
	spin.add_theme_constant_override("updown_width", 0)
	spin.min_value = float(field_def.get("min", 0.0))
	spin.max_value = float(field_def.get("max", 9999.0))
	spin.step = float(field_def.get("step", 1.0))
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.rounded = (
		bool(field_def.get("integer", false))
		or bool(field_def.get("bool", false))
		or spin.step >= 1.0
	)
	spin.value = initial_value
	spin.value_changed.connect(on_value_changed)
	value_row.add_child(spin)
	spin.tree_entered.connect(on_tree_entered.bind(spin), CONNECT_ONE_SHOT)

	var inc_button := _create_step_button("+", button_size, button_font_size)
	value_row.add_child(inc_button)

	dec_button.pressed.connect(func() -> void: on_step_pressed.call(spin, -1))
	inc_button.pressed.connect(func() -> void: on_step_pressed.call(spin, 1))

	return {
		"property": property,
		"spin": spin,
		"row": row,
		"dec_button": dec_button,
		"inc_button": inc_button,
	}


static func style_spin_line_edit(
	spin: SpinBox,
	spin_min_height: float,
	value_font_size: int
) -> void:
	var line_edit := spin.get_line_edit()
	if line_edit == null:
		return
	line_edit.custom_minimum_size.y = spin_min_height
	line_edit.add_theme_font_size_override("font_size", value_font_size)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER


static func commit_spin_box_pending(spin: SpinBox) -> void:
	if spin == null or not is_instance_valid(spin):
		return
	spin.apply()


static func wire_spin_box_text_commit(
	spin: SpinBox,
	on_committed: Callable,
	meta_key: StringName = DEFAULT_COMMIT_META_KEY
) -> void:
	var line_edit := spin.get_line_edit()
	if line_edit == null:
		return
	if line_edit.has_meta(meta_key):
		return
	line_edit.set_meta(meta_key, true)
	line_edit.text_submitted.connect(
		func(_text: String) -> void:
			commit_spin_box_pending(spin)
			on_committed.call(spin.value)
	)
	line_edit.focus_exited.connect(
		func() -> void:
			commit_spin_box_pending(spin)
			on_committed.call(spin.value)
	)


static func _create_step_button(text: String, button_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_size
	button.add_theme_font_size_override("font_size", font_size)
	return button
