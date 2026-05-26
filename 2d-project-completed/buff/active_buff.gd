class_name ActiveBuff
extends RefCounted

## 적용 중인 버프 1개의 런타임 상태입니다.

var data: BuffData
var source_id := ""
var remaining_seconds := 0.0
var remaining_waves := 0
var remaining_charges := 0
var stacks := 1


static func create(buff_data: BuffData, source: String = "", stack_count: int = 1) -> ActiveBuff:
	var buff := ActiveBuff.new()
	buff.data = buff_data
	buff.source_id = source
	buff.stacks = clampi(stack_count, 1, maxi(buff_data.max_stacks, 1))
	buff.refresh_duration()
	return buff


func is_valid() -> bool:
	return data != null and not data.get_unique_key().is_empty()


func get_key() -> String:
	return data.get_unique_key() if data != null else ""


func refresh_duration() -> void:
	if data == null:
		return
	remaining_seconds = data.duration_seconds
	remaining_waves = data.duration_waves
	remaining_charges = data.charges


func extend_duration() -> void:
	if data == null:
		return
	remaining_seconds += data.duration_seconds
	remaining_waves += data.duration_waves
	remaining_charges += data.charges


func add_stacks(amount: int) -> void:
	if data == null:
		return
	stacks = clampi(stacks + amount, 1, maxi(data.max_stacks, 1))
	refresh_duration()


func tick_seconds(delta: float) -> bool:
	if data == null or not BuffDuration.uses_seconds(data.duration_type):
		return false
	remaining_seconds = maxf(remaining_seconds - delta, 0.0)
	return remaining_seconds <= 0.0


func on_wave_completed() -> bool:
	if data == null or not BuffDuration.uses_waves(data.duration_type):
		return false
	remaining_waves = maxi(remaining_waves - 1, 0)
	return remaining_waves <= 0


func consume_charge(amount: int = 1) -> bool:
	if data == null or not BuffDuration.uses_charges(data.duration_type):
		return false
	remaining_charges = maxi(remaining_charges - amount, 0)
	return remaining_charges <= 0


func build_summary() -> Dictionary:
	return {
		"id": get_key(),
		"name": data.get_display_name_localized() if data != null else "",
		"duration_type": data.duration_type if data != null else &"",
		"remaining_seconds": remaining_seconds,
		"remaining_waves": remaining_waves,
		"remaining_charges": remaining_charges,
		"stacks": stacks,
		"source_id": source_id,
	}
