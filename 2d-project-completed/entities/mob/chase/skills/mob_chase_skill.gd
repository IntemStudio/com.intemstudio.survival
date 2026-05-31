class_name MobChaseSkill
extends RefCounted

## 몹 추격 기술 베이스 — windup·이동·완료 콜백을 tick 단위로 진행합니다.

enum Phase {
	INACTIVE,
	WINDUP,
	MOVING,
}

var _phase: Phase = Phase.INACTIVE


func reset() -> void:
	_phase = Phase.INACTIVE


func is_active() -> bool:
	return _phase != Phase.INACTIVE


func is_windup() -> bool:
	return _phase == Phase.WINDUP


func is_moving() -> bool:
	return _phase == Phase.MOVING


## mob.gd에서 트리거·쿨다운·standoff 등을 검사한 뒤 호출합니다.
func can_start(_mob: Mob, _target_offset: Vector2) -> bool:
	return true


func begin(_mob: Mob, _target_offset: Vector2) -> void:
	pass


## 진행 중이면 null, 완료 tick이면 MobChaseSkillContext를 반환합니다.
func tick(_mob: Mob, _delta: float) -> MobChaseSkillContext:
	return null


## 이동 종료 시 completion context를 구성합니다. tick 내부에서 호출됩니다.
func complete(_mob: Mob) -> MobChaseSkillContext:
	return null


func get_cooldown() -> float:
	return 0.0
