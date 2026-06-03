extends Resource
class_name StatusEffectData

## 몹에게 적용되는 상태이상 정의 데이터입니다.

const STACK_REFRESH := &"refresh"
const STACK_STACK := &"stack"

@export var status_id: StringName = &""
@export var display_name := ""
@export var display_name_ko := ""
@export var category: StringName = &""
@export var duration_seconds := 0.0
@export var max_stacks := 1
@export var stacking_policy: StringName = STACK_REFRESH
@export var damage_element: StringName = &""
@export var tick_damage_min := 0
@export var tick_damage_max := 0
@export var tick_percent_max_hp := 0.0
@export var tick_interval := 0.0
@export var damage_taken_element: StringName = &""
@export var damage_taken_mult := 1.0
@export var move_speed_mult := 1.0
@export var effect_color := Color.WHITE


func get_unique_key() -> StringName:
	return status_id


func get_display_name_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not display_name.is_empty():
		return display_name
	return display_name_ko if not display_name_ko.is_empty() else display_name


func has_dot() -> bool:
	return tick_interval > 0.0 and (tick_damage_max > 0 or tick_percent_max_hp > 0.0)


func has_damage_taken_mult() -> bool:
	return not damage_taken_element.is_empty() and not is_equal_approx(damage_taken_mult, 1.0)


func has_move_speed_mult() -> bool:
	return not is_equal_approx(move_speed_mult, 1.0)


func allows_unlimited_stacks() -> bool:
	return max_stacks <= 0


func should_stack() -> bool:
	return stacking_policy == STACK_STACK
