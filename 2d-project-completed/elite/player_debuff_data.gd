class_name PlayerDebuffData
extends RefCounted

## 플레이어 전용 엘리트 debuff 정의 — 몹 status/와 분리합니다.

var debuff_id: StringName = &""
var display_name_ko: String = ""
var duration_sec := 0.0
var move_speed_mult := 1.0
var blocks_healing := false
var blocks_stamina_regen := false
var locks_movement := false
var has_dot := false
var dot_tick_interval := 0.0
var dot_percent_max_hp := 0.0
var has_expire_burst := false
var burst_radius := 0.0
var burst_damage_mult := 0.0


func get_unique_key() -> StringName:
	return debuff_id


func provides_dot() -> bool:
	return has_dot and dot_tick_interval > 0.0 and dot_percent_max_hp > 0.0


func provides_expire_burst() -> bool:
	return has_expire_burst and burst_radius > 0.0 and burst_damage_mult > 0.0


func affects_move_speed() -> bool:
	return locks_movement or not is_equal_approx(move_speed_mult, 1.0)
