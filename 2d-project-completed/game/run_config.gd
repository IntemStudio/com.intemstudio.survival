class_name RunConfig
extends RefCounted

const MODE_SURVIVAL := &"survival"
const MODE_ARENA := &"arena"

static var _game_mode: StringName = MODE_SURVIVAL
static var _player_class_id: StringName = PlayerClassCatalog.get_default_class_id()


static func set_game_mode(mode: StringName) -> void:
	if mode == MODE_ARENA:
		_game_mode = MODE_ARENA
	else:
		_game_mode = MODE_SURVIVAL


static func get_game_mode() -> StringName:
	return _game_mode


static func is_arena_mode() -> bool:
	return _game_mode == MODE_ARENA


static func set_player_class_id(class_id: StringName) -> void:
	if PlayerClassCatalog.has_class(class_id):
		_player_class_id = class_id
	else:
		_player_class_id = PlayerClassCatalog.get_default_class_id()


static func get_player_class_id() -> StringName:
	return _player_class_id


static func get_player_class() -> PlayerClassData:
	var player_class := PlayerClassCatalog.get_by_id(_player_class_id)
	if player_class != null:
		return player_class
	return PlayerClassCatalog.get_by_id(PlayerClassCatalog.get_default_class_id())
