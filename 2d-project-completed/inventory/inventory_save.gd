class_name InventorySave
extends RefCounted

## PlayerLoadoutState ↔ ConfigFile (user://).

const SAVE_PATH := "user://player_loadout.cfg"
const VERSION := 1

const SECTION_INVENTORY := "inventory"
const KEY_VERSION := "version"
const KEY_ACTIVE_SET := "active_set"
const SECTION_SET_PREFIX := "set/"
const SECTION_BAG := "bag"
const BAG_SLOT_PREFIX := "slot"


static func load_state() -> PlayerLoadoutState:
	var state := PlayerLoadoutState.create_empty()
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		if err != ERR_FILE_NOT_FOUND:
			push_warning("InventorySave: load failed (%s)" % error_string(err))
		return state

	var file_version := _read_inventory_section(cfg, state)
	if file_version > 0 and file_version != VERSION:
		push_warning(
			"InventorySave: unsupported version %d (expected %d), loading best-effort."
			% [file_version, VERSION]
		)
	for set_index in EquipSlots.SET_COUNT:
		_read_set_section(cfg, set_index, state)
	_read_bag_section(cfg, state)
	return state


static func save_state(state: PlayerLoadoutState) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_INVENTORY, KEY_VERSION, VERSION)
	cfg.set_value(SECTION_INVENTORY, KEY_ACTIVE_SET, state.active_set_index)
	for set_index in EquipSlots.SET_COUNT:
		var section := "%s%d" % [SECTION_SET_PREFIX, set_index]
		for slot_key in EquipSlots.ALL:
			cfg.set_value(
				section,
				EquipSlots.slot_key_to_string(slot_key),
				state.get_set_item_id(set_index, slot_key)
			)
	for bag_index in EquipSlots.BAG_SIZE:
		var key := "%s%d" % [BAG_SLOT_PREFIX, bag_index]
		cfg.set_value(SECTION_BAG, key, state.get_bag_item_id(bag_index))
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


static func _read_inventory_section(cfg: ConfigFile, state: PlayerLoadoutState) -> int:
	if not cfg.has_section(SECTION_INVENTORY):
		return 0
	state.active_set_index = clampi(
		int(cfg.get_value(SECTION_INVENTORY, KEY_ACTIVE_SET, 0)),
		0,
		EquipSlots.SET_COUNT - 1
	)
	return int(cfg.get_value(SECTION_INVENTORY, KEY_VERSION, 0))


static func _read_set_section(cfg: ConfigFile, set_index: int, state: PlayerLoadoutState) -> void:
	var section := "%s%d" % [SECTION_SET_PREFIX, set_index]
	if not cfg.has_section(section):
		return
	for slot_key in EquipSlots.ALL:
		var slot_str := EquipSlots.slot_key_to_string(slot_key)
		var item_id := str(cfg.get_value(section, slot_str, ""))
		state.set_set_item_id(set_index, slot_key, item_id)


static func _read_bag_section(cfg: ConfigFile, state: PlayerLoadoutState) -> void:
	if not cfg.has_section(SECTION_BAG):
		return
	for bag_index in EquipSlots.BAG_SIZE:
		var key := "%s%d" % [BAG_SLOT_PREFIX, bag_index]
		var item_id := str(cfg.get_value(SECTION_BAG, key, ""))
		state.set_bag_item_id(bag_index, item_id)
