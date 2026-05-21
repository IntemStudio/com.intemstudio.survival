extends Node2D

const BASE_SCALE := Vector2(1.1, 1.1)


func pool_reset() -> void:
	position = Vector2.ZERO
	scale = BASE_SCALE


func pool_on_acquire() -> void:
	pass


# 몹 머리 위 로컬 위치·색으로 공격 예고 마크를 표시합니다.
func setup(local_offset: Vector2, tint: Color) -> void:
	position = local_offset
	scale = BASE_SCALE
	if has_node("Sprite"):
		var mark_color := Color(
			minf(tint.r * 1.15, 1.0),
			minf(tint.g * 0.45, 1.0),
			minf(tint.b * 0.35, 1.0),
			0.95
		)
		$Sprite.modulate = mark_color
