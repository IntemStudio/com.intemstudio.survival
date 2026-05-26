class_name ActionManager
extends RefCounted

## 게임 입력 액션 질의와 리맵 API를 제공합니다.

const ACTION_MOVE_LEFT := ActionBindingDefaults.ACTION_MOVE_LEFT
const ACTION_MOVE_RIGHT := ActionBindingDefaults.ACTION_MOVE_RIGHT
const ACTION_MOVE_UP := ActionBindingDefaults.ACTION_MOVE_UP
const ACTION_MOVE_DOWN := ActionBindingDefaults.ACTION_MOVE_DOWN
const ACTION_ATTACK := ActionBindingDefaults.ACTION_ATTACK
const ACTION_INTERACT := ActionBindingDefaults.ACTION_INTERACT
const ACTION_TOGGLE_INVENTORY := ActionBindingDefaults.ACTION_TOGGLE_INVENTORY
const ACTION_TOGGLE_AUTO_TARGET := ActionBindingDefaults.ACTION_TOGGLE_AUTO_TARGET
const ACTION_TOGGLE_AUTO_ATTACK := ActionBindingDefaults.ACTION_TOGGLE_AUTO_ATTACK
const ACTION_DASH := ActionBindingDefaults.ACTION_DASH
const ACTION_PAUSE := ActionBindingDefaults.ACTION_PAUSE
const ACTION_SWAP_COMBAT_SET := ActionBindingDefaults.ACTION_SWAP_COMBAT_SET

static var _initialized := false


# 기본값 적용 후 저장된 사용자 바인딩을 덮어씁니다.
static func initialize(force := false) -> void:
	if _initialized and not force:
		return
	_ensure_actions()
	_apply_default_bindings()
	_apply_saved_bindings(ActionBindingStore.load_bindings())
	_initialized = true


static func ensure_default_bindings() -> void:
	initialize()


static func get_move_vector() -> Vector2:
	_ensure_initialized()
	return Input.get_vector(
		ACTION_MOVE_LEFT,
		ACTION_MOVE_RIGHT,
		ACTION_MOVE_UP,
		ACTION_MOVE_DOWN
	)


static func is_pressed(action: StringName) -> bool:
	_ensure_initialized()
	return Input.is_action_pressed(action)


static func is_just_pressed(action: StringName) -> bool:
	_ensure_initialized()
	return Input.is_action_just_pressed(action)


static func is_just_released(action: StringName) -> bool:
	_ensure_initialized()
	return Input.is_action_just_released(action)


static func event_is_pressed(event: InputEvent, action: StringName, allow_echo := false) -> bool:
	_ensure_initialized()
	if event is InputEventKey and event.echo and not allow_echo:
		return false
	return event.is_action_pressed(action)


static func get_action_label(action: StringName, fallback := "") -> String:
	_ensure_initialized()
	if not InputMap.has_action(action):
		return fallback

	for event in InputMap.action_get_events(action):
		var label := _event_to_label(event)
		if not label.is_empty():
			return label
	return fallback


static func get_actions() -> Array[StringName]:
	return ActionBindingDefaults.get_actions()


static func get_action_definitions() -> Array[Dictionary]:
	return ActionBindingDefaults.get_action_definitions()


static func get_action_events(action: StringName) -> Array[InputEvent]:
	_ensure_initialized()
	if not InputMap.has_action(action):
		return []
	return InputMap.action_get_events(action)


static func rebind_action(
	action: StringName,
	event: InputEvent,
	append := false,
	save := true
) -> void:
	_ensure_initialized()
	_ensure_action(action)
	if not append:
		InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	if save:
		_save_current_bindings()


static func clear_action(action: StringName, save := true) -> void:
	_ensure_initialized()
	_ensure_action(action)
	InputMap.action_erase_events(action)
	if save:
		_save_current_bindings()


static func reset_action_to_default(action: StringName, save := true) -> void:
	_ensure_initialized()
	_ensure_action(action)
	_apply_events(action, ActionBindingDefaults.get_default_events(action))
	if save:
		_save_current_bindings()


static func reset_all_to_default(save := true) -> void:
	_ensure_initialized()
	_apply_default_bindings()
	if save:
		_save_current_bindings()


static func find_conflicts(action: StringName, event: InputEvent) -> Array[StringName]:
	_ensure_initialized()
	var conflicts: Array[StringName] = []
	for other_action in ActionBindingDefaults.get_actions():
		if other_action == action:
			continue
		for other_event in get_action_events(other_action):
			if _events_match(other_event, event):
				conflicts.append(other_action)
				break
	return conflicts


static func _ensure_initialized() -> void:
	if not _initialized:
		initialize()


static func _ensure_actions() -> void:
	for definition in ActionBindingDefaults.get_action_definitions():
		_ensure_action(definition["action"])


static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, ActionBindingDefaults.get_deadzone(action))


static func _apply_default_bindings() -> void:
	for action in ActionBindingDefaults.get_actions():
		_apply_events(action, ActionBindingDefaults.get_default_events(action))


static func _apply_saved_bindings(bindings: Dictionary) -> void:
	for action in bindings.keys():
		_apply_events(action, bindings[action])


static func _apply_events(action: StringName, events: Array) -> void:
	_ensure_action(action)
	InputMap.action_erase_events(action)
	for event in events:
		if event is InputEvent:
			InputMap.action_add_event(action, event)


static func _save_current_bindings() -> void:
	var bindings := {}
	for action in ActionBindingDefaults.get_actions():
		bindings[action] = get_action_events(action)
	ActionBindingStore.save_bindings(bindings)


static func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var key_a := a as InputEventKey
		var key_b := b as InputEventKey
		if key_a.physical_keycode != KEY_NONE and key_b.physical_keycode != KEY_NONE:
			return key_a.physical_keycode == key_b.physical_keycode
		if key_a.keycode != KEY_NONE and key_b.keycode != KEY_NONE:
			return key_a.keycode == key_b.keycode
		if key_a.key_label != KEY_NONE and key_b.key_label != KEY_NONE:
			return key_a.key_label == key_b.key_label
		return false

	if a is InputEventMouseButton and b is InputEventMouseButton:
		var mouse_a := a as InputEventMouseButton
		var mouse_b := b as InputEventMouseButton
		return mouse_a.button_index == mouse_b.button_index

	return false


static func _event_to_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.physical_keycode != KEY_NONE:
			return OS.get_keycode_string(key_event.physical_keycode)
		if key_event.keycode != KEY_NONE:
			return OS.get_keycode_string(key_event.keycode)
		if key_event.key_label != KEY_NONE:
			return OS.get_keycode_string(key_event.key_label)

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return _mouse_button_to_label(mouse_event.button_index)

	var text := event.as_text().strip_edges()
	if text.is_empty():
		return ""
	return text


static func _mouse_button_to_label(button_index: MouseButton) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "Mouse Left"
		MOUSE_BUTTON_RIGHT:
			return "Mouse Right"
		MOUSE_BUTTON_MIDDLE:
			return "Mouse Middle"
		_:
			return "Mouse %d" % button_index
