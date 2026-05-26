class_name ActiveStatusEffect
extends RefCounted

## 적용 중인 몹 상태이상의 런타임 상태입니다.

var data: StatusEffectData
var source_weapon: WeaponData
var source_id := ""
var remaining_seconds := 0.0
var stacks := 1
var tick_timer := 0.0
var tick_damage_min := 0
var tick_damage_max := 0
var tick_interval := 0.0


static func create(status_data: StatusEffectData, weapon: WeaponData = null) -> ActiveStatusEffect:
	var active := ActiveStatusEffect.new()
	active.data = status_data
	active.source_weapon = weapon
	active.source_id = weapon.get_unique_key() if weapon != null else ""
	active.stacks = 1
	active._refresh_tick_profile()
	active.refresh_duration()
	return active


func is_valid() -> bool:
	return data != null and not data.get_unique_key().is_empty()


func get_key() -> StringName:
	return data.get_unique_key() if data != null else &""


func refresh_duration() -> void:
	if data == null:
		return
	remaining_seconds = _get_duration_seconds()


func add_stack(amount: int = 1) -> void:
	if data == null:
		return
	if data.should_stack():
		stacks += maxi(amount, 1)
		if not data.allows_unlimited_stacks():
			stacks = mini(stacks, maxi(data.max_stacks, 1))
	refresh_duration()


func advance_time(delta: float) -> bool:
	if data == null:
		return true
	remaining_seconds = maxf(remaining_seconds - delta, 0.0)
	return remaining_seconds <= 0.0


func is_tick_due() -> bool:
	return data != null and data.has_dot() and tick_timer <= 0.0


func consume_tick() -> int:
	if data == null or not data.has_dot():
		return 0
	var total_damage := 0
	for _i in stacks:
		total_damage += randi_range(tick_damage_min, tick_damage_max)
	tick_timer += tick_interval
	return total_damage


func advance_tick_timer(delta: float) -> void:
	if data == null or not data.has_dot():
		return
	tick_timer -= delta


func _refresh_tick_profile() -> void:
	if data == null:
		return
	tick_damage_min = data.tick_damage_min
	tick_damage_max = data.tick_damage_max
	tick_interval = data.tick_interval
	if get_key() == &"poison" and source_weapon != null:
		tick_damage_min = source_weapon.poison_damage_min
		tick_damage_max = source_weapon.poison_damage_max
		tick_interval = 1.0 / maxf(source_weapon.poison_ticks_per_second, 0.01)
	tick_damage_min = maxi(tick_damage_min, 0)
	tick_damage_max = maxi(tick_damage_max, tick_damage_min)
	tick_interval = maxf(tick_interval, 0.01)
	tick_timer = 0.0


func _get_duration_seconds() -> float:
	if get_key() == &"poison" and source_weapon != null:
		return maxf(source_weapon.poison_duration, 0.0)
	return maxf(data.duration_seconds, 0.0)
