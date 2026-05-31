class_name StatusEffectCatalog
extends RefCounted

## 1차 몹 상태이상 정의를 코드 카탈로그로 제공합니다.

const CATEGORY_BLEED := &"bleed"
const CATEGORY_BURN := &"burn"
const CATEGORY_LIGHTNING := &"lightning"
const CATEGORY_POISON := &"poison"
const CATEGORY_COLD := &"cold"

static var _cache: Dictionary = {}


static func get_status(status_id: StringName) -> StatusEffectData:
	_ensure_cache()
	return _cache.get(status_id)


static func has_status(status_id: StringName) -> bool:
	_ensure_cache()
	return _cache.has(status_id)


static func get_display_name(status_id: StringName) -> String:
	var data := get_status(status_id)
	return data.get_display_name_localized() if data != null else String(status_id)


static func get_all_status_ids() -> Array[StringName]:
	_ensure_cache()
	var ids: Array[StringName] = []
	for key in _cache.keys():
		ids.append(key)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


static func _ensure_cache() -> void:
	if not _cache.is_empty():
		return
	_register(_create_dot(
		&"bleed",
		"Bleed",
		"출혈",
		CATEGORY_BLEED,
		&"physical",
		70,
		105,
		8.0,
		0.5,
		1,
		Color(0.95, 0.18, 0.18)
	))
	_register(_create_dot(
		&"burn",
		"Burn",
		"화상",
		CATEGORY_BURN,
		&"fire",
		55,
		75,
		8.0,
		0.5,
		1,
		Color(1.0, 0.45, 0.2)
	))
	_register(_create_damage_taken_mult(
		&"scorch",
		"Scorch",
		"불타오르기",
		CATEGORY_BURN,
		&"fire",
		1.25,
		4.0,
		Color(1.0, 0.32, 0.12)
	))
	_register(_create_damage_taken_mult(
		&"zap",
		"Zap",
		"번개",
		CATEGORY_LIGHTNING,
		&"lightning",
		1.25,
		4.0,
		Color(0.55, 0.85, 1.0)
	))
	_register(_create_dot(
		&"poison",
		"Poison",
		"독",
		CATEGORY_POISON,
		&"poison",
		10,
		20,
		4.0,
		0.5,
		0,
		Color(0.45, 0.95, 0.35)
	))
	_register(_create_damage_taken_mult(
		&"toxic",
		"Toxic",
		"독성",
		CATEGORY_POISON,
		&"poison",
		1.25,
		4.0,
		Color(0.35, 0.85, 0.2)
	))
	_register(_create_move_speed_mult(
		&"chill",
		"Chill",
		"냉기",
		CATEGORY_COLD,
		0.8,
		8.0,
		Color(0.45, 0.8, 1.0)
	))
	_register(_create_move_speed_mult(
		&"relic_chill",
		"Relic Chill",
		"유물 냉기",
		CATEGORY_COLD,
		0.6,
		1.5,
		Color(0.55, 0.9, 1.0)
	))
	_register(_create_move_speed_mult(
		&"sticky_goo",
		"Sticky Goo",
		"끈적이",
		CATEGORY_COLD,
		0.7,
		4.0,
		Color(0.62, 0.95, 0.62)
	))
	_register(_create_damage_taken_mult(
		&"frostbite",
		"Frostbite",
		"동상",
		CATEGORY_COLD,
		&"cold",
		1.25,
		4.0,
		Color(0.65, 0.95, 1.0)
	))


static func _register(data: StatusEffectData) -> void:
	_cache[data.get_unique_key()] = data


static func _create_base(
	status_id: StringName,
	display_name: String,
	display_name_ko: String,
	category: StringName,
	duration_seconds: float,
	max_stacks: int,
	color: Color
) -> StatusEffectData:
	var data := StatusEffectData.new()
	data.status_id = status_id
	data.display_name = display_name
	data.display_name_ko = display_name_ko
	data.category = category
	data.duration_seconds = duration_seconds
	data.max_stacks = max_stacks
	data.effect_color = color
	return data


static func _create_dot(
	status_id: StringName,
	display_name: String,
	display_name_ko: String,
	category: StringName,
	damage_element: StringName,
	damage_min: int,
	damage_max: int,
	duration_seconds: float,
	tick_interval: float,
	max_stacks: int,
	color: Color
) -> StatusEffectData:
	var data := _create_base(
		status_id,
		display_name,
		display_name_ko,
		category,
		duration_seconds,
		max_stacks,
		color
	)
	data.stacking_policy = StatusEffectData.STACK_STACK if max_stacks != 1 else StatusEffectData.STACK_REFRESH
	data.damage_element = damage_element
	data.tick_damage_min = damage_min
	data.tick_damage_max = damage_max
	data.tick_interval = tick_interval
	return data


static func _create_damage_taken_mult(
	status_id: StringName,
	display_name: String,
	display_name_ko: String,
	category: StringName,
	damage_element: StringName,
	damage_mult: float,
	duration_seconds: float,
	color: Color
) -> StatusEffectData:
	var data := _create_base(status_id, display_name, display_name_ko, category, duration_seconds, 1, color)
	data.damage_taken_element = damage_element
	data.damage_taken_mult = damage_mult
	return data


static func _create_move_speed_mult(
	status_id: StringName,
	display_name: String,
	display_name_ko: String,
	category: StringName,
	move_speed_mult: float,
	duration_seconds: float,
	color: Color
) -> StatusEffectData:
	var data := _create_base(status_id, display_name, display_name_ko, category, duration_seconds, 1, color)
	data.move_speed_mult = move_speed_mult
	return data
