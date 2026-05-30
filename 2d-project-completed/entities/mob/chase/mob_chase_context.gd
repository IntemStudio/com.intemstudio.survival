class_name MobChaseContext
extends RefCounted

## 몹 추격 판정용 physics tick 입력 — Mob 참조 없이 offset·거리·속도만 전달합니다.

var target_offset: Vector2 = Vector2.ZERO
var stop_distance: float = 0.0
var effective_speed: float = 0.0
var orbit_clockwise: bool = true
var orbit_radius_buffer: float = 48.0
var orbit_approach_blend: float = 72.0
