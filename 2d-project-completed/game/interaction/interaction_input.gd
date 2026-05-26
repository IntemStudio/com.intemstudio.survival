class_name InteractionInput
extends RefCounted

## 상호작용 액션 입력과 표시 문자열을 한 곳에서 관리합니다.

const ACTION_INTERACT := &"interact"
const DEFAULT_INTERACT_LABEL := "Interact"


static func is_interact_pressed(event: InputEvent) -> bool:
	return ActionManager.event_is_pressed(event, ACTION_INTERACT)


static func get_interact_label() -> String:
	return ActionManager.get_action_label(ACTION_INTERACT, DEFAULT_INTERACT_LABEL)
