extends Resource
class_name BuffData

## 버프 정의 데이터. 실제 남은 시간·스택은 ActiveBuff가 보관합니다.

const STACK_REFRESH := &"refresh"
const STACK_EXTEND := &"extend"
const STACK_STACK := &"stack"
const STACK_INDEPENDENT := &"independent"

@export var buff_id := ""
@export var display_name := ""
@export var display_name_ko := ""
@export var duration_type: StringName = BuffDuration.TYPE_SECONDS
@export var duration_seconds := 0.0
@export var duration_waves := 0
@export var charges := 0
@export var max_stacks := 1
@export var stacking_policy: StringName = STACK_REFRESH
@export var stat_modifiers: Dictionary = {}
@export var tags: Array[StringName] = []


func get_unique_key() -> String:
	if not buff_id.is_empty():
		return buff_id
	if not resource_path.is_empty():
		return resource_path
	return display_name


func get_display_name_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not display_name.is_empty():
		return display_name
	return display_name_ko if not display_name_ko.is_empty() else display_name


func should_merge_with_existing() -> bool:
	return stacking_policy != STACK_INDEPENDENT
