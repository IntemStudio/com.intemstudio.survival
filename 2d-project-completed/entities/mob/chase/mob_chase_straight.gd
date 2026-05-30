class_name MobChaseStraight
extends MobChaseStrategy

## 플레이어 방향 직선 추격 — standoff 이내면 정지(velocity 0).


func compute_desired_velocity(context: MobChaseContext) -> Vector2:
	var distance := context.target_offset.length()
	if distance > context.stop_distance:
		return context.target_offset / distance * context.effective_speed
	return Vector2.ZERO
