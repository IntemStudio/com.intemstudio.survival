extends Resource
class_name BalanceTable

## 분 단위 키프레임을 선형 보간해 현재 구간 밸런스를 반환합니다.

@export var phases: Array[BalancePhase] = []

var _sorted_phases_cache: Array[BalancePhase] = []
var _phases_cache_key: int = -1


# 경과 시간(초)에 맞는 보간된 밸런스 구간을 반환합니다.
func get_phase_for_time(elapsed_seconds: float) -> BalancePhase:
	if phases.is_empty():
		return BalancePhase.new()

	var sorted: Array[BalancePhase] = _get_sorted_phases()
	var minutes: float = maxf(elapsed_seconds, 0.0) / 60.0

	if minutes <= sorted[0].minute:
		return _finalize_phase(sorted[0].duplicate_phase(), sorted, minutes)

	var last_index := sorted.size() - 1
	if minutes >= sorted[last_index].minute:
		return _finalize_phase(sorted[last_index].duplicate_phase(), sorted, minutes)

	var lower := sorted[0]
	var upper := sorted[last_index]
	for index in range(last_index):
		var current: BalancePhase = sorted[index]
		var next: BalancePhase = sorted[index + 1]
		if minutes >= current.minute and minutes <= next.minute:
			lower = current
			upper = next
			break

	var span := upper.minute - lower.minute
	var weight := 0.0 if span <= 0.0 else (minutes - lower.minute) / span
	var result := _lerp_phases(lower, upper, weight)
	return _finalize_phase(result, sorted, minutes)


func _get_sorted_phases() -> Array[BalancePhase]:
	var cache_key := _compute_phases_cache_key()
	if cache_key != _phases_cache_key:
		_sorted_phases_cache = phases.duplicate()
		_sorted_phases_cache.sort_custom(func(a: BalancePhase, b: BalancePhase) -> bool:
			return a.minute < b.minute
		)
		_phases_cache_key = cache_key
	return _sorted_phases_cache


func _compute_phases_cache_key() -> int:
	var cache_key := phases.size()
	for phase in phases:
		if not phase:
			continue
		cache_key = hash([
			cache_key,
			phase.minute,
			phase.hp_multiplier,
			phase.spawn_density,
			phase.fast_spawn_ratio,
			phase.ranged_spawn_ratio,
			phase.elite_spawn_ratio,
			phase.special_spawn_ratio,
			phase.special_mob_count,
			phase.boss_spawn_ratio,
			phase.boss_spawn_enabled,
		])
	return cache_key


func _lerp_phases(lower: BalancePhase, upper: BalancePhase, weight: float) -> BalancePhase:
	var result := lower.duplicate_phase()
	result.minute = lerpf(lower.minute, upper.minute, weight)
	result.hp_multiplier = lerpf(lower.hp_multiplier, upper.hp_multiplier, weight)
	result.spawn_density = lerpf(lower.spawn_density, upper.spawn_density, weight)
	result.threat = lerpf(lower.threat, upper.threat, weight)
	result.fast_spawn_ratio = lerpf(lower.fast_spawn_ratio, upper.fast_spawn_ratio, weight)
	result.ranged_spawn_ratio = lerpf(lower.ranged_spawn_ratio, upper.ranged_spawn_ratio, weight)
	result.elite_spawn_ratio = lerpf(lower.elite_spawn_ratio, upper.elite_spawn_ratio, weight)
	result.special_spawn_ratio = lerpf(lower.special_spawn_ratio, upper.special_spawn_ratio, weight)
	result.boss_spawn_ratio = lerpf(lower.boss_spawn_ratio, upper.boss_spawn_ratio, weight)
	result.special_mob_count = roundi(
		lerpf(float(lower.special_mob_count), float(upper.special_mob_count), weight)
	)
	result.design_intent = lower.design_intent if weight < 0.5 else upper.design_intent
	return result


# bool·스폰 비율 등은 보간 후 단계형/정규화 규칙을 적용합니다.
func _finalize_phase(phase: BalancePhase, sorted: Array[BalancePhase], minutes: float) -> BalancePhase:
	phase.boss_spawn_enabled = _resolve_step_bool(sorted, minutes, "boss_spawn_enabled")
	phase.special_mob_count = _resolve_step_int(sorted, minutes, "special_mob_count")
	if not phase.boss_spawn_enabled:
		phase.boss_spawn_ratio = 0.0
	if phase.special_mob_count <= 0:
		phase.special_spawn_ratio = 0.0
	_normalize_spawn_ratios(phase)
	return phase


func _resolve_step_bool(sorted: Array[BalancePhase], minutes: float, property: String) -> bool:
	var value := false
	for phase in sorted:
		if minutes + 0.0001 < phase.minute:
			break
		value = phase.get(property)
	return value


func _resolve_step_int(sorted: Array[BalancePhase], minutes: float, property: String) -> int:
	var value := 0
	for phase in sorted:
		if minutes + 0.0001 < phase.minute:
			break
		value = phase.get(property)
	return value


func _normalize_spawn_ratios(phase: BalancePhase) -> void:
	var ratio_sum := (
		phase.fast_spawn_ratio
		+ phase.ranged_spawn_ratio
		+ phase.elite_spawn_ratio
		+ phase.special_spawn_ratio
		+ phase.boss_spawn_ratio
	)
	if ratio_sum <= 1.0:
		return
	var scale := 1.0 / ratio_sum
	phase.fast_spawn_ratio *= scale
	phase.ranged_spawn_ratio *= scale
	phase.elite_spawn_ratio *= scale
	phase.special_spawn_ratio *= scale
	phase.boss_spawn_ratio *= scale
