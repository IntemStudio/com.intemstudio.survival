class_name PlayerClassCatalog
extends RefCounted

## 플레이어 직업 정의 카탈로그.

const DEFAULT_CLASS_ID := "knight"

const _PlayerClassCatalogEntries: GDScript = preload(
	"res://entities/player/class/player_class_catalog_entries.gd"
)

static var _cache: Array[PlayerClassData] = []


static func get_all() -> Array[PlayerClassData]:
	if _cache.is_empty():
		_build_cache()
	return _cache.duplicate()


static func get_by_id(class_id: StringName) -> PlayerClassData:
	var id := String(class_id)
	if id.is_empty():
		id = DEFAULT_CLASS_ID
	for player_class in get_all():
		if player_class.class_id == id:
			return player_class
	return null


static func has_class(class_id: StringName) -> bool:
	return get_by_id(class_id) != null


static func get_default_class_id() -> StringName:
	return StringName(DEFAULT_CLASS_ID)


static func _build_cache() -> void:
	_cache = []
	_PlayerClassCatalogEntries.append_all(_cache, Callable(_create_class))


static func _create_class(
	id: String,
	name_en: String,
	name_ko: String,
	description_en: String,
	description_ko: String,
	visual_scene: PackedScene,
	base_max_health: float,
	max_health_per_level: float,
	base_attack: float,
	attack_per_level: float,
	base_health_regen: float,
	health_regen_per_level: float,
	move_speed_mult: float,
	base_defense: int
) -> PlayerClassData:
	var data := PlayerClassData.new()
	data.class_id = id
	data.display_name = name_en
	data.display_name_ko = name_ko
	data.description_en = description_en
	data.description_ko = description_ko
	data.visual_scene = visual_scene
	data.base_max_health = base_max_health
	data.max_health_per_level = max_health_per_level
	data.base_attack = base_attack
	data.attack_per_level = attack_per_level
	data.base_health_regen = base_health_regen
	data.health_regen_per_level = health_regen_per_level
	data.move_speed_mult = move_speed_mult
	data.base_defense = base_defense
	data.stat_modifiers = data.build_stat_modifiers()
	return data
