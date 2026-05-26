class_name ActionBindingStore
extends RefCounted

## 조작 바인딩을 user:// 설정 파일로 저장하고 다시 InputEvent로 복원합니다.

const SAVE_PATH := "user://input_bindings.cfg"
const SECTION_BINDINGS := "bindings"
const TYPE_KEY := "key"
const TYPE_MOUSE_BUTTON := "mouse_button"


static func load_bindings() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}

	var bindings := {}
	for action in ActionBindingDefaults.get_actions():
		var key := String(action)
		if not cfg.has_section_key(SECTION_BINDINGS, key):
			continue
		bindings[action] = _specs_to_events(cfg.get_value(SECTION_BINDINGS, key, []))
	return bindings


static func save_bindings(bindings: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for action in ActionBindingDefaults.get_actions():
		var events: Array = bindings.get(action, [])
		cfg.set_value(SECTION_BINDINGS, String(action), _events_to_specs(events))
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


static func _events_to_specs(events: Array) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for event in events:
		var spec := _event_to_spec(event)
		if not spec.is_empty():
			specs.append(spec)
	return specs


static func _specs_to_events(specs: Array) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for spec in specs:
		if not spec is Dictionary:
			continue
		var event := _spec_to_event(spec)
		if event != null:
			events.append(event)
	return events


static func _event_to_spec(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return {
			"type": TYPE_KEY,
			"physical_keycode": key_event.physical_keycode,
			"keycode": key_event.keycode,
			"key_label": key_event.key_label,
			"unicode": key_event.unicode,
			"location": key_event.location,
			"alt_pressed": key_event.alt_pressed,
			"shift_pressed": key_event.shift_pressed,
			"ctrl_pressed": key_event.ctrl_pressed,
			"meta_pressed": key_event.meta_pressed,
		}

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return {
			"type": TYPE_MOUSE_BUTTON,
			"button_index": mouse_event.button_index,
			"alt_pressed": mouse_event.alt_pressed,
			"shift_pressed": mouse_event.shift_pressed,
			"ctrl_pressed": mouse_event.ctrl_pressed,
			"meta_pressed": mouse_event.meta_pressed,
		}

	return {}


static func _spec_to_event(spec: Dictionary) -> InputEvent:
	match String(spec.get("type", "")):
		TYPE_KEY:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(spec.get("physical_keycode", KEY_NONE))
			key_event.keycode = int(spec.get("keycode", KEY_NONE))
			key_event.key_label = int(spec.get("key_label", KEY_NONE))
			key_event.unicode = int(spec.get("unicode", 0))
			key_event.location = int(spec.get("location", KEY_LOCATION_UNSPECIFIED))
			key_event.alt_pressed = bool(spec.get("alt_pressed", false))
			key_event.shift_pressed = bool(spec.get("shift_pressed", false))
			key_event.ctrl_pressed = bool(spec.get("ctrl_pressed", false))
			key_event.meta_pressed = bool(spec.get("meta_pressed", false))
			return key_event
		TYPE_MOUSE_BUTTON:
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = int(spec.get("button_index", MOUSE_BUTTON_NONE))
			mouse_event.alt_pressed = bool(spec.get("alt_pressed", false))
			mouse_event.shift_pressed = bool(spec.get("shift_pressed", false))
			mouse_event.ctrl_pressed = bool(spec.get("ctrl_pressed", false))
			mouse_event.meta_pressed = bool(spec.get("meta_pressed", false))
			return mouse_event
	return null
