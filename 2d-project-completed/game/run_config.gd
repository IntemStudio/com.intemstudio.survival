class_name RunConfig
extends RefCounted

const MODE_SURVIVAL := &"survival"
const MODE_ARENA := &"arena"

static var _game_mode: StringName = MODE_SURVIVAL


static func set_game_mode(mode: StringName) -> void:
	if mode == MODE_ARENA:
		_game_mode = MODE_ARENA
	else:
		_game_mode = MODE_SURVIVAL


static func get_game_mode() -> StringName:
	return _game_mode


static func is_arena_mode() -> bool:
	return _game_mode == MODE_ARENA
