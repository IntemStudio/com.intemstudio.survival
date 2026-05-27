class_name PassiveCatalog
extends RefCounted

## 런 패시브 정의 카탈로그.

const _PassiveCatalogEntries: GDScript = preload("res://passive/passive_catalog_entries.gd")

static var _cache: Array[PassiveData] = []


static func get_all() -> Array[PassiveData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func get_passive(passive_id: String) -> PassiveData:
	for passive in get_all():
		if passive.passive_id == passive_id:
			return passive
	return null


static func _build_cache() -> void:
	_cache = []
	_PassiveCatalogEntries.append_all(_cache, Callable(_create_passive))


static func _create_passive(
	id: String,
	name_en: String,
	name_ko: String,
	max_level: int,
	stats_by_level: Array,
	grant_tags_by_level: Array,
	effect_ko: String,
	evolves_into_id: String = "",
	evolved_only: bool = false
) -> PassiveData:
	var data := PassiveData.new()
	data.passive_id = id
	data.display_name = name_en
	data.display_name_ko = name_ko
	data.max_level = maxi(max_level, 1)
	data.evolves_into_id = evolves_into_id
	data.stat_modifiers_by_level.assign(stats_by_level)
	data.grant_tags_by_level.assign(grant_tags_by_level)
	if not effect_ko.is_empty():
		data.tags.append(&"utility")
	if evolved_only:
		data.tags.append(&"evolved")
	return data
