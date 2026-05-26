class_name ActionBindingDefaults
extends RefCounted

## 조작 액션 목록과 기본 바인딩 정의를 제공합니다.

const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_MOVE_UP := &"move_up"
const ACTION_MOVE_DOWN := &"move_down"
const ACTION_ATTACK := &"attack"
const ACTION_INTERACT := &"interact"
const ACTION_TOGGLE_INVENTORY := &"toggle_inventory"
const ACTION_TOGGLE_AUTO_TARGET := &"toggle_auto_target"
const ACTION_TOGGLE_AUTO_ATTACK := &"toggle_auto_attack"
const ACTION_DASH := &"dash"
const ACTION_PAUSE := &"pause"
const ACTION_SWAP_COMBAT_SET := &"swap_combat_set"

const DEFAULT_DEADZONE := 0.5


static func get_action_definitions() -> Array[Dictionary]:
	return [
		_make_definition(ACTION_MOVE_LEFT, &"input.category_movement", &"input.move_left"),
		_make_definition(ACTION_MOVE_RIGHT, &"input.category_movement", &"input.move_right"),
		_make_definition(ACTION_MOVE_UP, &"input.category_movement", &"input.move_up"),
		_make_definition(ACTION_MOVE_DOWN, &"input.category_movement", &"input.move_down"),
		_make_definition(ACTION_ATTACK, &"input.category_combat", &"input.attack"),
		_make_definition(ACTION_INTERACT, &"input.category_gameplay", &"input.interact"),
		_make_definition(ACTION_TOGGLE_INVENTORY, &"input.category_ui", &"input.toggle_inventory"),
		_make_definition(ACTION_TOGGLE_AUTO_TARGET, &"input.category_combat", &"input.toggle_auto_target"),
		_make_definition(ACTION_TOGGLE_AUTO_ATTACK, &"input.category_combat", &"input.toggle_auto_attack"),
		_make_definition(ACTION_DASH, &"input.category_movement", &"input.dash"),
		_make_definition(ACTION_PAUSE, &"input.category_ui", &"input.pause"),
		_make_definition(ACTION_SWAP_COMBAT_SET, &"input.category_gameplay", &"input.swap_combat_set"),
	]


static func get_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for definition in get_action_definitions():
		actions.append(definition["action"])
	return actions


static func get_deadzone(action: StringName) -> float:
	for definition in get_action_definitions():
		if definition["action"] == action:
			return float(definition["deadzone"])
	return DEFAULT_DEADZONE


static func get_default_events(action: StringName) -> Array[InputEvent]:
	match action:
		ACTION_MOVE_LEFT:
			return [_make_key_event(KEY_A, "a".unicode_at(0))]
		ACTION_MOVE_RIGHT:
			return [_make_key_event(KEY_D, "d".unicode_at(0))]
		ACTION_MOVE_UP:
			return [_make_key_event(KEY_W, "w".unicode_at(0))]
		ACTION_MOVE_DOWN:
			return [_make_key_event(KEY_S, "s".unicode_at(0))]
		ACTION_ATTACK:
			return [_make_mouse_button_event(MOUSE_BUTTON_LEFT)]
		ACTION_INTERACT:
			return [_make_key_event(KEY_E, "e".unicode_at(0))]
		ACTION_TOGGLE_INVENTORY:
			return [_make_key_event(KEY_I, "i".unicode_at(0))]
		ACTION_TOGGLE_AUTO_TARGET:
			return [_make_key_event(KEY_F, "f".unicode_at(0))]
		ACTION_TOGGLE_AUTO_ATTACK:
			return [_make_key_event(KEY_G, "g".unicode_at(0))]
		ACTION_DASH:
			return [_make_key_event(KEY_SPACE, " ".unicode_at(0))]
		ACTION_PAUSE:
			return [_make_key_event(KEY_ESCAPE)]
		ACTION_SWAP_COMBAT_SET:
			return [_make_key_event(KEY_TAB)]
	return []


static func _make_definition(
	action: StringName,
	category_key: StringName,
	label_key: StringName
) -> Dictionary:
	return {
		"action": action,
		"category_key": category_key,
		"label_key": label_key,
		"deadzone": DEFAULT_DEADZONE,
	}


static func _make_key_event(physical_keycode: Key, unicode := 0) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	event.unicode = unicode
	return event


static func _make_mouse_button_event(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	return event
