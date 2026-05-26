class_name InteractionInput
extends RefCounted

## 상호작용 액션 입력과 표시 문자열을 한 곳에서 관리합니다.

const ACTION_INTERACT := &"interact"
const DEFAULT_INTERACT_LABEL := "Interact"


static func is_interact_pressed(event: InputEvent) -> bool:
	if not InputMap.has_action(ACTION_INTERACT):
		return false
	return event.is_action_pressed(ACTION_INTERACT)


static func get_interact_label() -> String:
	if not InputMap.has_action(ACTION_INTERACT):
		return DEFAULT_INTERACT_LABEL

	for event in InputMap.action_get_events(ACTION_INTERACT):
		var label := _event_to_label(event)
		if not label.is_empty():
			return label
	return DEFAULT_INTERACT_LABEL


static func _event_to_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.physical_keycode != KEY_NONE:
			return OS.get_keycode_string(key_event.physical_keycode)
		if key_event.keycode != KEY_NONE:
			return OS.get_keycode_string(key_event.keycode)
		if key_event.key_label != KEY_NONE:
			return OS.get_keycode_string(key_event.key_label)

	var text := event.as_text().strip_edges()
	if text.is_empty():
		return ""
	return text
