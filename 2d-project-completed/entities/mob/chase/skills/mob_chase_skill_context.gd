class_name MobChaseSkillContext
extends RefCounted

## 추격 기술 완료 시 효과 체인에 넘기는 DTO — 완료 시점 export 스냅샷을 포함합니다.

var mob: Mob = null
var landing_position: Vector2 = Vector2.ZERO
var landing_direction: Vector2 = Vector2.RIGHT
var landing_burst_radius: float = 0.0
var landing_burst_damage: int = 0
