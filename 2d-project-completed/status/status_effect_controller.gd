class_name StatusEffectController
extends RefCounted

## 몹 하나에 적용된 상태이상 목록과 만료·틱·배율 계산을 담당합니다.

var _active_statuses: Array[ActiveStatusEffect] = []


func clear() -> void:
	_active_statuses.clear()


func apply_status(status_id: StringName, source_weapon: WeaponData = null) -> ActiveStatusEffect:
	var apply_result: Dictionary = apply_status_with_result(status_id, source_weapon)
	if not apply_result.has("active"):
		return null
	return apply_result["active"] as ActiveStatusEffect


func apply_status_with_result(status_id: StringName, source_weapon: WeaponData = null) -> Dictionary:
	var data := StatusEffectCatalog.get_status(status_id)
	if data == null:
		push_warning("StatusEffectController: unknown status '%s'" % String(status_id))
		return {
			"active": null,
			"is_new": false
		}

	var source_id := source_weapon.get_unique_key() if source_weapon != null else ""
	var existing := _find_stack_target(data, source_id)
	if existing != null:
		existing.source_weapon = source_weapon
		existing.source_id = source_id
		existing.add_stack()
		return {
			"active": existing,
			"is_new": false
		}

	var active := ActiveStatusEffect.create(data, source_weapon)
	if not active.is_valid():
		return {
			"active": null,
			"is_new": false
		}
	_active_statuses.append(active)
	return {
		"active": active,
		"is_new": true
	}


func apply_statuses(status_ids: Array[StringName], source_weapon: WeaponData = null) -> Array[ActiveStatusEffect]:
	var applied: Array[ActiveStatusEffect] = []
	for status_id in status_ids:
		var active := apply_status(status_id, source_weapon)
		if active != null:
			applied.append(active)
	return applied


func tick(delta: float, owner_mob: Node) -> void:
	if delta <= 0.0 or _active_statuses.is_empty():
		return

	for index in range(_active_statuses.size() - 1, -1, -1):
		var active := _active_statuses[index]
		active.advance_tick_timer(delta)
		var expired := active.advance_time(delta)
		if not expired:
			_apply_due_ticks(active, owner_mob)
		if expired:
			_active_statuses.remove_at(index)


func get_damage_taken_mult(element: String) -> float:
	if element.is_empty():
		return 1.0

	var mult := 1.0
	for active in _active_statuses:
		if active == null or active.data == null or not active.data.has_damage_taken_mult():
			continue
		if String(active.data.damage_taken_element) != element:
			continue
		for _i in active.stacks:
			mult *= active.data.damage_taken_mult
	return mult


func get_move_speed_mult() -> float:
	var mult := 1.0
	for active in _active_statuses:
		if active == null or active.data == null or not active.data.has_move_speed_mult():
			continue
		for _i in active.stacks:
			mult *= active.data.move_speed_mult
	return mult


func has_status(status_id: StringName) -> bool:
	for active in _active_statuses:
		if active != null and active.get_key() == status_id:
			return true
	return false


func get_active_statuses() -> Array[ActiveStatusEffect]:
	var active_list: Array[ActiveStatusEffect] = []
	for active in _active_statuses:
		if active == null or active.data == null:
			continue
		if active.remaining_seconds <= 0.0:
			continue
		active_list.append(active)
	return active_list


func refresh_active_status_profiles(status_id: StringName = &"", reset_duration: bool = false) -> void:
	for active in _active_statuses:
		if active == null:
			continue
		if status_id != &"" and active.get_key() != status_id:
			continue
		active.refresh_from_data(reset_duration)


func _find_stack_target(data: StatusEffectData, source_id: String) -> ActiveStatusEffect:
	if data.allows_unlimited_stacks():
		return null
	for active in _active_statuses:
		if active == null or active.get_key() != data.get_unique_key():
			continue
		if data.get_unique_key() == &"poison" and active.source_id != source_id:
			continue
		return active
	return null


func _apply_due_ticks(active: ActiveStatusEffect, owner_mob: Node) -> void:
	if not active.data.has_dot() or not owner_mob or not owner_mob.has_method(&"apply_status_tick_damage"):
		return

	while active.is_tick_due() and active.remaining_seconds > 0.0:
		var owner_mob_ref: Mob = owner_mob as Mob if owner_mob is Mob else null
		var amount := active.consume_tick(owner_mob_ref)
		if amount > 0:
			owner_mob.call(
				&"apply_status_tick_damage",
				amount,
				active.data.damage_element,
				active.source_weapon,
				active.data.effect_color
			)
