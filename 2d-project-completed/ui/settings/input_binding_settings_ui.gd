extends VBoxContainer

## 일시정지 설정 — 조작 키 리맵.

const ACTION_LABEL_MIN_WIDTH := 220.0
const BIND_BUTTON_MIN_WIDTH := 150.0
const RESET_BUTTON_MIN_WIDTH := 90.0

@onready var _input_title: Label = $InputBindingSettingsTitle

var _reset_all_button: Button
var _input_status_label: Label
var _capture_action: StringName = &""
var _status_locale_key: StringName = &"input.rebind_hint"
var _status_args: Array = []
var _action_label_keys := {}
var _action_name_labels := {}
var _binding_buttons := {}
var _reset_buttons := {}
var _category_labels := {}


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_build_input_bindings_ui()
	sync_from_input_bindings()
	refresh_locale()


func _input(event: InputEvent) -> void:
	if String(_capture_action).is_empty():
		return

	var binding_event = _capture_binding_event(event)
	if binding_event == null:
		return

	get_viewport().set_input_as_handled()
	_apply_captured_binding(binding_event)


func refresh_locale() -> void:
	_input_title.text = UiLocale.t(&"settings.input_bindings")
	if _reset_all_button:
		_reset_all_button.text = UiLocale.t(&"input.reset_all")
	for action in _action_name_labels.keys():
		var label := _action_name_labels[action] as Label
		if label:
			label.text = _get_action_display_name(action)
	for action in _reset_buttons.keys():
		var reset_button := _reset_buttons[action] as Button
		if reset_button:
			reset_button.text = UiLocale.t(&"input.reset_action")
	for category_key in _category_labels.keys():
		var category_label := _category_labels[category_key] as Label
		if category_label:
			category_label.text = UiLocale.t(category_key)
	_refresh_binding_buttons()
	_refresh_status_text()


# 저장·적용된 조작 바인딩으로 UI를 맞춥니다.
func sync_from_input_bindings() -> void:
	_refresh_binding_buttons()
	if String(_capture_action).is_empty():
		_set_status(&"input.rebind_hint")


func cancel_input_capture() -> void:
	_cancel_capture(false)


# ActionManager 정의를 기준으로 조작 키 설정 행을 동적으로 만듭니다.
func _build_input_bindings_ui() -> void:
	ActionManager.initialize()

	var definitions_by_category := {}
	var category_order: Array[StringName] = []
	for definition in ActionManager.get_action_definitions():
		var category_key: StringName = definition["category_key"]
		if not definitions_by_category.has(category_key):
			definitions_by_category[category_key] = []
			category_order.append(category_key)
		var category_definitions: Array = definitions_by_category[category_key]
		category_definitions.append(definition)

	for category_key in category_order:
		_add_input_category(category_key)
		for definition in definitions_by_category[category_key]:
			_add_input_action_row(definition)

	_reset_all_button = Button.new()
	_reset_all_button.custom_minimum_size = Vector2(220, 36)
	_reset_all_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reset_all_button.pressed.connect(_on_reset_all_bindings_pressed)
	add_child(_reset_all_button)

	_input_status_label = Label.new()
	_input_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_input_status_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78, 1))
	_input_status_label.add_theme_font_size_override("font_size", 16)
	add_child(_input_status_label)


func _add_input_category(category_key: StringName) -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 1))
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	_category_labels[category_key] = label


func _add_input_action_row(definition: Dictionary) -> void:
	var action: StringName = definition["action"]
	var label_key: StringName = definition["label_key"]
	_action_label_keys[action] = label_key

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	var action_label := Label.new()
	action_label.custom_minimum_size = Vector2(ACTION_LABEL_MIN_WIDTH, 0)
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_label.add_theme_color_override("font_color", Color(0.8, 0.84, 0.9, 1))
	action_label.add_theme_font_size_override("font_size", 18)
	row.add_child(action_label)
	_action_name_labels[action] = action_label

	var binding_button := Button.new()
	binding_button.custom_minimum_size = Vector2(BIND_BUTTON_MIN_WIDTH, 36)
	binding_button.add_theme_font_size_override("font_size", 18)
	binding_button.pressed.connect(_on_binding_button_pressed.bind(action))
	row.add_child(binding_button)
	_binding_buttons[action] = binding_button

	var reset_button := Button.new()
	reset_button.custom_minimum_size = Vector2(RESET_BUTTON_MIN_WIDTH, 36)
	reset_button.add_theme_font_size_override("font_size", 16)
	reset_button.pressed.connect(_on_reset_action_pressed.bind(action))
	row.add_child(reset_button)
	_reset_buttons[action] = reset_button


func _on_binding_button_pressed(action: StringName) -> void:
	_capture_action = action
	_refresh_binding_buttons()
	_set_status(&"input.rebind_waiting", [_get_action_display_name(action)])


func _on_reset_action_pressed(action: StringName) -> void:
	_cancel_capture(false)
	var conflicts := _find_default_conflicts(action)
	if not conflicts.is_empty():
		_set_status(
			&"input.rebind_conflict",
			[_get_action_display_name(action), _format_action_names(conflicts)]
		)
		return

	ActionManager.reset_action_to_default(action)
	_refresh_binding_buttons()
	_set_status(&"input.rebind_reset_action", [_get_action_display_name(action)])
	_notify_input_labels_changed()


func _on_reset_all_bindings_pressed() -> void:
	_cancel_capture(false)
	ActionManager.reset_all_to_default()
	_refresh_binding_buttons()
	_set_status(&"input.rebind_reset_all")
	_notify_input_labels_changed()


func _capture_binding_event(event: InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return null
		if (
			key_event.physical_keycode == KEY_NONE
			and key_event.keycode == KEY_NONE
			and key_event.key_label == KEY_NONE
		):
			return null
		return _copy_key_event(key_event)

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if (
			not mouse_event.pressed
			or mouse_event.button_index == MOUSE_BUTTON_NONE
			or _is_mouse_wheel_button(mouse_event.button_index)
		):
			return null
		return _copy_mouse_button_event(mouse_event)

	return null


func _apply_captured_binding(event: InputEvent) -> void:
	var action := _capture_action
	var conflicts := ActionManager.find_conflicts(action, event)
	_capture_action = &""
	if not conflicts.is_empty():
		_refresh_binding_buttons()
		_set_status(
			&"input.rebind_conflict",
			[_get_action_display_name(action), _format_action_names(conflicts)]
		)
		return

	ActionManager.rebind_action(action, event)
	_refresh_binding_buttons()
	_set_status(
		&"input.rebind_saved",
		[_get_action_display_name(action), ActionManager.get_action_label(action, "-")]
	)
	_notify_input_labels_changed()


func _copy_key_event(source: InputEventKey) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = source.physical_keycode
	event.keycode = source.keycode
	event.key_label = source.key_label
	event.unicode = source.unicode
	event.location = source.location
	event.alt_pressed = source.alt_pressed
	event.shift_pressed = source.shift_pressed
	event.ctrl_pressed = source.ctrl_pressed
	event.meta_pressed = source.meta_pressed
	return event


func _copy_mouse_button_event(source: InputEventMouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = source.button_index
	event.alt_pressed = source.alt_pressed
	event.shift_pressed = source.shift_pressed
	event.ctrl_pressed = source.ctrl_pressed
	event.meta_pressed = source.meta_pressed
	return event


func _is_mouse_wheel_button(button_index: MouseButton) -> bool:
	match button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			return true
		MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT:
			return true
		_:
			return false


func _find_default_conflicts(action: StringName) -> Array[StringName]:
	var conflicts: Array[StringName] = []
	for event in ActionBindingDefaults.get_default_events(action):
		for conflict in ActionManager.find_conflicts(action, event):
			if not conflicts.has(conflict):
				conflicts.append(conflict)
	return conflicts


func _refresh_binding_buttons() -> void:
	for action in _binding_buttons.keys():
		var button := _binding_buttons[action] as Button
		if button == null:
			continue
		if action == _capture_action:
			button.text = UiLocale.t(&"input.rebind_waiting_button")
		else:
			button.text = ActionManager.get_action_label(action, "-")


func _set_status(locale_key: StringName, args: Array = []) -> void:
	_status_locale_key = locale_key
	_status_args = args.duplicate()
	_refresh_status_text()


func _refresh_status_text() -> void:
	if _input_status_label == null:
		return
	var text := UiLocale.t(_status_locale_key)
	if not _status_args.is_empty():
		text = text % _status_args
	_input_status_label.text = text


func _cancel_capture(reset_status := true) -> void:
	if String(_capture_action).is_empty():
		return
	_capture_action = &""
	_refresh_binding_buttons()
	if reset_status:
		_set_status(&"input.rebind_hint")


func _get_action_display_name(action: StringName) -> String:
	var label_key: StringName = _action_label_keys.get(action, &"")
	if String(label_key).is_empty():
		return String(action)
	return UiLocale.t(label_key)


func _format_action_names(actions: Array[StringName]) -> String:
	var labels := PackedStringArray()
	for action in actions:
		labels.append(_get_action_display_name(action))
	return ", ".join(labels)


func _notify_input_labels_changed() -> void:
	UiLocale.notify_refresh()
