class_name BuffCatalog
extends RefCounted

## 런타임 버프 정의의 작은 카탈로그입니다.

const BUFF_EN_GARDE := "en_garde"
const BUFF_DASH_HASTE := "dash_haste"

static var _cache: Dictionary = {}


static func get_buff(buff_id: String) -> BuffData:
	if _cache.is_empty():
		_build_cache()
	return _cache.get(buff_id) as BuffData


static func _build_cache() -> void:
	_cache[BUFF_EN_GARDE] = _create_buff(
		BUFF_EN_GARDE,
		"En Garde",
		"앙 가르드",
		BuffDuration.TYPE_SECONDS,
		8.0,
		{"attack_speed_mult": 1.2}
	)
	_cache[BUFF_DASH_HASTE] = _create_buff(
		BUFF_DASH_HASTE,
		"Haste",
		"가속",
		BuffDuration.TYPE_SECONDS,
		2.0,
		{"move_speed_mult": 1.25}
	)


static func _create_buff(
	buff_id: String,
	display_name: String,
	display_name_ko: String,
	duration_type: StringName,
	duration_seconds: float,
	stat_modifiers: Dictionary
) -> BuffData:
	var data := BuffData.new()
	data.buff_id = buff_id
	data.display_name = display_name
	data.display_name_ko = display_name_ko
	data.duration_type = duration_type
	data.duration_seconds = duration_seconds
	data.stat_modifiers = stat_modifiers
	return data
