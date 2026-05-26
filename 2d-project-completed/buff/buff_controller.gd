class_name BuffController
extends RefCounted

signal buffs_changed

## 대상 하나의 활성 버프 목록과 만료 처리를 담당합니다.

var _active_buffs: Array[ActiveBuff] = []


func add_buff(buff_data: BuffData, source_id: String = "", stacks: int = 1) -> ActiveBuff:
	if buff_data == null:
		return null
	if not BuffDuration.is_runtime_duration(buff_data.duration_type):
		push_warning("BuffController: '%s'는 런타임 버프로 보관하지 않습니다." % buff_data.get_unique_key())
		return null

	var existing := _find_stack_target(buff_data, source_id)
	if existing != null:
		_apply_stacking(existing, buff_data, stacks)
		buffs_changed.emit()
		return existing

	var active := ActiveBuff.create(buff_data, source_id, stacks)
	if not active.is_valid():
		return null
	_active_buffs.append(active)
	buffs_changed.emit()
	return active


func remove_buff(buff_id: String, source_id: String = "") -> void:
	var changed := false
	for index in range(_active_buffs.size() - 1, -1, -1):
		var active := _active_buffs[index]
		if active.get_key() != buff_id:
			continue
		if not source_id.is_empty() and active.source_id != source_id:
			continue
		_active_buffs.remove_at(index)
		changed = true
	if changed:
		buffs_changed.emit()


func clear() -> void:
	if _active_buffs.is_empty():
		return
	_active_buffs.clear()
	buffs_changed.emit()


func tick_seconds(delta: float) -> void:
	if delta <= 0.0 or _active_buffs.is_empty():
		return
	var changed := false
	for index in range(_active_buffs.size() - 1, -1, -1):
		if _active_buffs[index].tick_seconds(delta):
			_active_buffs.remove_at(index)
			changed = true
	if changed:
		buffs_changed.emit()


func on_wave_completed() -> void:
	if _active_buffs.is_empty():
		return
	var changed := false
	for index in range(_active_buffs.size() - 1, -1, -1):
		if _active_buffs[index].on_wave_completed():
			_active_buffs.remove_at(index)
			changed = true
	if changed:
		buffs_changed.emit()


func consume_charge(buff_id: String, amount: int = 1) -> void:
	for index in range(_active_buffs.size() - 1, -1, -1):
		var active := _active_buffs[index]
		if active.get_key() != buff_id:
			continue
		if active.consume_charge(amount):
			_active_buffs.remove_at(index)
		buffs_changed.emit()
		return


func get_stat_modifiers() -> Dictionary:
	return BuffStatMerge.merge_active_buffs(_active_buffs)


func get_active_buff_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for active in _active_buffs:
		summaries.append(active.build_summary())
	return summaries


func has_buff(buff_id: String) -> bool:
	for active in _active_buffs:
		if active.get_key() == buff_id:
			return true
	return false


func _find_stack_target(buff_data: BuffData, source_id: String) -> ActiveBuff:
	if not buff_data.should_merge_with_existing():
		return null
	var key := buff_data.get_unique_key()
	for active in _active_buffs:
		if active.get_key() != key:
			continue
		if not source_id.is_empty() and active.source_id != source_id:
			continue
		return active
	return null


func _apply_stacking(active: ActiveBuff, buff_data: BuffData, stacks: int) -> void:
	match buff_data.stacking_policy:
		BuffData.STACK_EXTEND:
			active.extend_duration()
		BuffData.STACK_STACK:
			active.add_stacks(stacks)
		_:
			active.refresh_duration()
