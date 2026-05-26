extends RefCounted
class_name FloatingInfoText

const INFO_TEXT_COLOR := Color(0.95, 0.95, 1.0)


# 장비 획득 실패 등 짧은 안내 문구를 표시합니다.
static func spawn_info(world_position: Vector2, text: String) -> void:
	FloatingText.spawn(world_position, text, INFO_TEXT_COLOR, false)


static func spawn_equipment_status(world_position: Vector2, text: String) -> void:
	spawn_info(world_position, text)
