class_name BuffDuration
extends RefCounted

## 버프 지속 타입과 만료 판정 보조값을 한 곳에 모읍니다.

const TYPE_SECONDS := &"seconds"
const TYPE_WAVES := &"waves"
const TYPE_CHARGES := &"charges"
const TYPE_UNTIL_EVENT := &"until_event"
const TYPE_WHILE_EQUIPPED := &"while_equipped"
const TYPE_PERMANENT := &"permanent"


static func is_runtime_duration(duration_type: StringName) -> bool:
	return duration_type in [
		TYPE_SECONDS,
		TYPE_WAVES,
		TYPE_CHARGES,
		TYPE_UNTIL_EVENT,
	]


static func uses_seconds(duration_type: StringName) -> bool:
	return duration_type == TYPE_SECONDS


static func uses_waves(duration_type: StringName) -> bool:
	return duration_type == TYPE_WAVES


static func uses_charges(duration_type: StringName) -> bool:
	return duration_type == TYPE_CHARGES
