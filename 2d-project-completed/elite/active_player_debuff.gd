class_name ActivePlayerDebuff
extends RefCounted

## 적용 중인 플레이어 debuff 런타임 상태입니다.

var data
var remaining_seconds := 0.0
var payload: Dictionary = {}
var dot_timer := 0.0


func setup(debuff_data, payload: Dictionary = {}) -> void:
	data = debuff_data
	self.payload = payload.duplicate(true)
	refresh_duration()
	dot_timer = 0.0


func get_id() -> StringName:
	return data.get_unique_key() if data != null else &""


func is_valid() -> bool:
	return data != null and not get_id().is_empty()


func refresh(payload: Dictionary = {}) -> void:
	if not payload.is_empty():
		self.payload = payload.duplicate(true)
	refresh_duration()


func refresh_duration() -> void:
	if data == null:
		return
	remaining_seconds = maxf(data.duration_sec, 0.0)


func advance_time(delta: float) -> bool:
	if data == null:
		return true
	remaining_seconds = maxf(remaining_seconds - delta, 0.0)
	return remaining_seconds <= 0.0


func advance_dot_timer(delta: float) -> void:
	if data == null or not data.provides_dot():
		return
	dot_timer -= delta


func is_dot_due() -> bool:
	return data != null and data.provides_dot() and dot_timer <= 0.0


func consume_dot_tick() -> void:
	if data == null or not data.provides_dot():
		return
	dot_timer += data.dot_tick_interval
