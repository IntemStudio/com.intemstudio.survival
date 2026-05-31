class_name EliteAffixCatalog
extends RefCounted

## tier 1 affix 정의 카탈로그 — StatusEffectCatalog와 동일한 코드 등록 패턴.

static var _cache: Dictionary = {}


static func get_affix(affix_id: StringName) -> EliteAffixData:
	_ensure_cache()
	return _cache.get(affix_id)


static func has_affix(affix_id: StringName) -> bool:
	_ensure_cache()
	return _cache.has(affix_id)


static func get_tier1_roll_pool(include_gilded: bool = false) -> Array[StringName]:
	_ensure_cache()
	var pool: Array[StringName] = [
		EliteAffixIds.BLAZING,
		EliteAffixIds.OVERLOADING,
		EliteAffixIds.GLACIAL,
		EliteAffixIds.MENDING,
	]
	if include_gilded:
		var gilded := get_affix(EliteAffixIds.GILDED)
		if gilded != null and gilded.enabled:
			pool.append(EliteAffixIds.GILDED)
	return pool


static func build_gui_description_bbcode(affix_id: StringName) -> String:
	if affix_id.is_empty():
		return "[color=#a9a9b0]affix 없음 — 기본 stat만 적용해 스폰합니다.[/color]"
	var data := get_affix(affix_id)
	if data == null:
		return "[color=#a9a9b0]알 수 없는 affix: %s[/color]" % String(affix_id)
	return data.build_gui_description_bbcode()


static func _ensure_cache() -> void:
	if not _cache.is_empty():
		return
	_register(_create(
		EliteAffixIds.BLAZING,
		4.0,
		2.0,
		Color(1.0, 0.35, 0.2),
		"불타는",
		"피격 시 4초 화상(재생 차단 + 최대 HP 20% DoT). 지나간 자리 잔불 접촉 시 동일 화상.",
		&"relic_blazing"
	))
	_register(_create(
		EliteAffixIds.OVERLOADING,
		4.0,
		2.0,
		Color(0.35, 0.55, 1.0),
		"과전하",
		"피격 시 1.5초 후 폭탄 부착(160px, 해당 피해 50%). 방어막 최대 HP 50%, 7초 무피해 후 재충전.",
		&"relic_overloading"
	))
	_register(_create(
		EliteAffixIds.GLACIAL,
		4.0,
		2.0,
		Color(0.65, 0.95, 1.0),
		"빙하의",
		"피격 시 1.5초 80% 감속. 사망 2초 후 얼음 폭탄(기본 피해 150% + 1.5초 동결).",
		&"relic_glacial"
	))
	_register(_create(
		EliteAffixIds.MENDING,
		3.0,
		2.0,
		Color(0.72, 0.58, 0.38),
		"수리 중인",
		"주변 아군 몹 지속 치유 오라. 사망 시 치유 코어 잔류 후 중립 치유 폭발.",
		&"relic_mending"
	))
	_register(_create(
		EliteAffixIds.GILDED,
		6.0,
		3.0,
		Color(1.0, 0.82, 0.25),
		"금빛",
		"DLC 후속 — 피격 골드 강탈, 주기 장판, 사망 금덩어리 드랍.",
		&"relic_gilded",
		false
	))


static func _register(data: EliteAffixData) -> void:
	_cache[data.get_unique_key()] = data


static func _create(
	affix_id: StringName,
	hp_mult: float,
	damage_mult: float,
	tint: Color,
	display_prefix_ko: String,
	description_ko: String,
	relic_item_id: StringName,
	enabled: bool = true
) -> EliteAffixData:
	var data := EliteAffixData.new()
	data.affix_id = affix_id
	data.hp_mult = hp_mult
	data.damage_mult = damage_mult
	data.tint = tint
	data.display_prefix_ko = display_prefix_ko
	data.description_ko = description_ko
	data.relic_item_id = relic_item_id
	data.drops_relic = true
	data.enabled = enabled
	return data
