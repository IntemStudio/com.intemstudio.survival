class_name PassiveRunState
extends RefCounted

## 한 런 동안 보유한 패시브 id → 레벨(1부터).

const MAX_SLOTS := 6

var _levels: Dictionary = {}


func clear() -> void:
	_levels.clear()


func get_level(passive_id: String) -> int:
	return int(_levels.get(passive_id, 0))


func get_owned_count() -> int:
	return _levels.size()


func has_empty_slot() -> bool:
	return get_owned_count() < MAX_SLOTS


func can_accept(passive: PassiveData) -> bool:
	if passive == null:
		return false
	var current := get_level(passive.passive_id)
	if current >= passive.max_level:
		return false
	if current == 0 and not has_empty_slot():
		return false
	return true


# 패시브 레벨을 1 올리고 새 레벨을 반환합니다. 실패 시 0.
func add_level(passive_id: String, max_level: int) -> int:
	var current := get_level(passive_id)
	if current >= max_level:
		return 0
	if current == 0 and not has_empty_slot():
		return 0
	current += 1
	_levels[passive_id] = current
	return current


# 최대 레벨 도달 후 evolves_into_id로 교체합니다. 성공 시 새 id를 반환합니다.
func try_evolve(passive: PassiveData) -> String:
	if passive == null or passive.evolves_into_id.is_empty():
		return ""
	if get_level(passive.passive_id) < passive.max_level:
		return ""
	var next_id := passive.evolves_into_id
	if PassiveCatalog.get_passive(next_id) == null:
		return ""
	_levels.erase(passive.passive_id)
	_levels[next_id] = 1
	return next_id


func get_owned_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _levels:
		ids.append(String(key))
	return ids


func has_upgradeable(passives: Array[PassiveData]) -> bool:
	for passive in passives:
		if can_accept(passive):
			return true
	return false
