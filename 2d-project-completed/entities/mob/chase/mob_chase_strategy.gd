class_name MobChaseStrategy
extends RefCounted

## 몹 추격 방식의 기본 전략 — context만 읽고 desired velocity를 반환합니다.


func reset() -> void:
	pass


func compute_desired_velocity(_context: MobChaseContext) -> Vector2:
	return Vector2.ZERO
