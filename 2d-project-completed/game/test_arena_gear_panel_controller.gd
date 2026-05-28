class_name TestArenaGearPanelController
extends RefCounted

## 테스트 아레나 장비 패널(보조손/방어구 선택·장착·튜닝 UI) 제어 컨트롤러.

const GearCatalog = preload("res://inventory/gear_catalog.gd")
const GearStatDisplayScript = preload("res://inventory/gear_stat_display.gd")
const TestArenaGearTuningUiUtil = preload("res://game/test_arena_gear_tuning_ui.gd")
const LoadoutGrantPassiveScript = preload("res://inventory/loadout_grant_passive.gd")

var _gear_snapshots: TestArenaGearSnapshot
var _update_status: Callable
var _apply_inventory_loadout_to_player: Callable
var _get_inventory_menu: Callable
var _is_inventory_loadout_enabled: Callable
var _refresh_status_tab_options: Callable
var _on_tuning_spin_tree_entered: Callable
var _wire_spin_box_text_commit: Callable
var _commit_spin_box_pending: Callable

var _armor_slot_labels_ko: Dictionary = {}
var _all_offhand_options: Array[GearData] = []
var _armor_gear_by_slot: Dictionary = {}
var _filtered_armor_gear_options: Array[GearData] = []
var _equipped_offhand_id := ""
var _offhand_tuning_spin_rows: Array[Dictionary] = []
var _armor_gear_tuning_spin_rows: Array[Dictionary] = []
var _offhand_tuning_ui_refreshing := false
var _armor_gear_tuning_ui_refreshing := false
var _gear_tuning_presets: Dictionary = {}

var _offhand_option: OptionButton
var _offhand_desc_label: RichTextLabel
var _offhand_status_row: Control
var _offhand_status_hint_label: Label
var _offhand_status_option: OptionButton
var _edit_offhand_status_button: Button
var _offhand_tuning_fields: VBoxContainer
var _offhand_tuning_status_label: Label
var _save_offhand_tuning_button: Button
var _reset_offhand_tuning_button: Button

var _armor_slot_filter: OptionButton
var _armor_gear_option: OptionButton
var _armor_gear_desc_label: RichTextLabel
var _armor_gear_tuning_fields: VBoxContainer
var _armor_gear_tuning_status_label: Label
var _save_armor_gear_tuning_button: Button
var _reset_armor_gear_tuning_button: Button

var _gear_section_label: Control
var _armor_slot_row: Control
var _armor_gear_row: Control
var _armor_gear_tuning_label: Control
var _armor_gear_tuning_buttons: Control
var _offhand_section_label: Control
var _offhand_row: Control
var _offhand_tuning_label: Control
var _offhand_tuning_buttons: Control
var _status_effect_nav_label: Control
var _status_effect_option: OptionButton

var _tuning_spin_button_size := Vector2.ZERO
var _tuning_spin_min_height := 0
var _tuning_spin_button_font_size := 0


func configure(
	gear_snapshots: TestArenaGearSnapshot,
	update_status: Callable,
	apply_inventory_loadout_to_player: Callable,
	get_inventory_menu: Callable,
	is_inventory_loadout_enabled: Callable,
	refresh_status_tab_options: Callable,
	on_tuning_spin_tree_entered: Callable,
	wire_spin_box_text_commit: Callable,
	commit_spin_box_pending: Callable,
	armor_slot_labels_ko: Dictionary,
	tuning_spin_button_size: Vector2,
	tuning_spin_min_height: int,
	tuning_spin_button_font_size: int,
	offhand_option: OptionButton,
	offhand_desc_label: RichTextLabel,
	offhand_status_row: Control,
	offhand_status_hint_label: Label,
	offhand_status_option: OptionButton,
	edit_offhand_status_button: Button,
	offhand_tuning_fields: VBoxContainer,
	offhand_tuning_status_label: Label,
	save_offhand_tuning_button: Button,
	reset_offhand_tuning_button: Button,
	armor_slot_filter: OptionButton,
	armor_gear_option: OptionButton,
	armor_gear_desc_label: RichTextLabel,
	armor_gear_tuning_fields: VBoxContainer,
	armor_gear_tuning_status_label: Label,
	save_armor_gear_tuning_button: Button,
	reset_armor_gear_tuning_button: Button,
	gear_section_label: Control,
	armor_slot_row: Control,
	armor_gear_row: Control,
	armor_gear_tuning_label: Control,
	armor_gear_tuning_buttons: Control,
	offhand_section_label: Control,
	offhand_row: Control,
	offhand_tuning_label: Control,
	offhand_tuning_buttons: Control,
	status_effect_nav_label: Control,
	status_effect_option: OptionButton
) -> void:
	_gear_snapshots = gear_snapshots
	_update_status = update_status
	_apply_inventory_loadout_to_player = apply_inventory_loadout_to_player
	_get_inventory_menu = get_inventory_menu
	_is_inventory_loadout_enabled = is_inventory_loadout_enabled
	_refresh_status_tab_options = refresh_status_tab_options
	_on_tuning_spin_tree_entered = on_tuning_spin_tree_entered
	_wire_spin_box_text_commit = wire_spin_box_text_commit
	_commit_spin_box_pending = commit_spin_box_pending
	_armor_slot_labels_ko = armor_slot_labels_ko
	_tuning_spin_button_size = tuning_spin_button_size
	_tuning_spin_min_height = tuning_spin_min_height
	_tuning_spin_button_font_size = tuning_spin_button_font_size
	_offhand_option = offhand_option
	_offhand_desc_label = offhand_desc_label
	_offhand_status_row = offhand_status_row
	_offhand_status_hint_label = offhand_status_hint_label
	_offhand_status_option = offhand_status_option
	_edit_offhand_status_button = edit_offhand_status_button
	_offhand_tuning_fields = offhand_tuning_fields
	_offhand_tuning_status_label = offhand_tuning_status_label
	_save_offhand_tuning_button = save_offhand_tuning_button
	_reset_offhand_tuning_button = reset_offhand_tuning_button
	_armor_slot_filter = armor_slot_filter
	_armor_gear_option = armor_gear_option
	_armor_gear_desc_label = armor_gear_desc_label
	_armor_gear_tuning_fields = armor_gear_tuning_fields
	_armor_gear_tuning_status_label = armor_gear_tuning_status_label
	_save_armor_gear_tuning_button = save_armor_gear_tuning_button
	_reset_armor_gear_tuning_button = reset_armor_gear_tuning_button
	_gear_section_label = gear_section_label
	_armor_slot_row = armor_slot_row
	_armor_gear_row = armor_gear_row
	_armor_gear_tuning_label = armor_gear_tuning_label
	_armor_gear_tuning_buttons = armor_gear_tuning_buttons
	_offhand_section_label = offhand_section_label
	_offhand_row = offhand_row
	_offhand_tuning_label = offhand_tuning_label
	_offhand_tuning_buttons = offhand_tuning_buttons
	_status_effect_nav_label = status_effect_nav_label
	_status_effect_option = status_effect_option


func build_offhand_options() -> void:
	_all_offhand_options.clear()
	for gear in GearCatalog.get_all():
		if gear.fits_slot(EquipSlots.OFFHAND):
			_all_offhand_options.append(gear)
			_gear_snapshots.register_catalog_gear(gear)
	_all_offhand_options.sort_custom(_sort_gear_for_picker)


func build_armor_gear_options() -> void:
	_armor_gear_by_slot.clear()
	for slot_key in EquipSlots.ARMOR_STAT_SLOTS:
		_armor_gear_by_slot[slot_key] = [] as Array[GearData]
	for gear in GearCatalog.get_all():
		for slot_key in EquipSlots.ARMOR_STAT_SLOTS:
			if gear.fits_slot(slot_key):
				var bucket: Array = _armor_gear_by_slot[slot_key]
				bucket.append(gear)
				_gear_snapshots.register_catalog_gear(gear)
	for slot_key in EquipSlots.ARMOR_STAT_SLOTS:
		var options: Array = _armor_gear_by_slot[slot_key]
		options.sort_custom(_sort_gear_for_picker)


func setup_offhand_picker() -> void:
	_refresh_offhand_option_list()


func setup_armor_gear_picker() -> void:
	_armor_slot_filter.clear()
	for slot_key in EquipSlots.ARMOR_STAT_SLOTS:
		var label: String = _armor_slot_labels_ko.get(slot_key, EquipSlots.slot_key_to_string(slot_key))
		_armor_slot_filter.add_item(label)
		_armor_slot_filter.set_item_metadata(_armor_slot_filter.get_item_count() - 1, slot_key)
	if _armor_slot_filter.get_item_count() > 0:
		_armor_slot_filter.select(0)
	_refresh_armor_gear_option_list()


func setup_offhand_section_visibility(enabled: bool) -> void:
	_offhand_section_label.visible = enabled
	_offhand_row.visible = enabled
	_offhand_desc_label.visible = enabled
	_offhand_status_row.visible = enabled
	_offhand_status_option.visible = enabled
	_offhand_tuning_label.visible = enabled
	_offhand_tuning_status_label.visible = enabled
	_offhand_tuning_fields.visible = enabled
	_offhand_tuning_buttons.visible = enabled
	_status_effect_nav_label.visible = enabled
	_status_effect_option.visible = enabled
	if not enabled:
		return
	_update_offhand_description()
	_refresh_offhand_status_hint()
	refresh_offhand_tuning_ui()


func setup_armor_gear_section_visibility(enabled: bool) -> void:
	_gear_section_label.visible = enabled
	_armor_slot_row.visible = enabled
	_armor_gear_row.visible = enabled
	_armor_gear_desc_label.visible = enabled
	_armor_gear_tuning_label.visible = enabled
	_armor_gear_tuning_status_label.visible = enabled
	_armor_gear_tuning_fields.visible = enabled
	_armor_gear_tuning_buttons.visible = enabled
	if not enabled:
		return
	_update_armor_gear_description()
	refresh_armor_gear_tuning_ui()


func on_equip_offhand_button_pressed() -> void:
	var gear := _get_selected_offhand()
	if gear == null:
		return
	_equip_offhand_from_gui(gear)


func on_equip_armor_button_pressed() -> void:
	var gear := _get_selected_armor_gear()
	if gear == null:
		return
	_equip_armor_gear_from_gui(gear)


func on_offhand_option_selected() -> void:
	_update_offhand_description()
	_refresh_offhand_status_hint()
	refresh_offhand_tuning_ui()


func on_armor_slot_filter_selected() -> void:
	var slot_key := _get_selected_armor_slot_key()
	var preserve_key := ""
	var inventory_menu: CanvasLayer = _get_inventory_menu.call()
	if inventory_menu != null:
		var menu_service: InventoryService = inventory_menu.get_service()
		if menu_service != null:
			preserve_key = menu_service.loadout.get_set_item_id(
				EquipSlots.SHARED_ARMOR_SET_INDEX,
				slot_key
			)
	_refresh_armor_gear_option_list(preserve_key)
	_update_armor_gear_description()
	refresh_armor_gear_tuning_ui()


func on_armor_gear_option_selected() -> void:
	_update_armor_gear_description()
	refresh_armor_gear_tuning_ui()


func setup_offhand_gear_tuning_ui() -> void:
	_setup_gear_tuning_ui_by_kind(&"offhand")


func refresh_offhand_tuning_ui() -> void:
	_refresh_gear_tuning_ui_by_kind(&"offhand")


func on_apply_offhand_tuning_pressed() -> void:
	_on_apply_gear_tuning_pressed_by_kind(&"offhand")


func on_save_offhand_tuning_pressed() -> void:
	_on_save_gear_tuning_pressed_by_kind(&"offhand")


func on_reset_offhand_tuning_pressed() -> void:
	_on_reset_gear_tuning_pressed_by_kind(&"offhand")


func setup_armor_gear_tuning_ui() -> void:
	_setup_gear_tuning_ui_by_kind(&"armor")


func refresh_armor_gear_tuning_ui() -> void:
	_refresh_gear_tuning_ui_by_kind(&"armor")


func on_apply_armor_gear_tuning_pressed() -> void:
	_on_apply_gear_tuning_pressed_by_kind(&"armor")


func on_save_armor_gear_tuning_pressed() -> void:
	_on_save_gear_tuning_pressed_by_kind(&"armor")


func on_reset_armor_gear_tuning_pressed() -> void:
	_on_reset_gear_tuning_pressed_by_kind(&"armor")


func update_offhand_description() -> void:
	_update_offhand_description()


func update_armor_gear_description() -> void:
	_update_armor_gear_description()


func refresh_offhand_status_hint() -> void:
	_refresh_offhand_status_hint()


func get_selected_offhand_status_ids() -> Array[StringName]:
	return _get_selected_offhand_status_ids()


func get_selected_offhand() -> GearData:
	return _get_selected_offhand()


func get_selected_armor_slot_key() -> StringName:
	return _get_selected_armor_slot_key()


func get_selected_armor_gear() -> GearData:
	return _get_selected_armor_gear()


func refresh_armor_gear_option_list(preserve_key: String = "", rebuild_tuning: bool = true) -> void:
	_refresh_armor_gear_option_list(preserve_key, rebuild_tuning)


func refresh_offhand_option_list(preserve_key: String = "") -> void:
	_refresh_offhand_option_list(preserve_key)


func equip_offhand_from_gui(gear: GearData) -> void:
	_equip_offhand_from_gui(gear)


func equip_armor_gear_from_gui(gear: GearData) -> void:
	_equip_armor_gear_from_gui(gear)


func _sort_gear_for_picker(a: GearData, b: GearData) -> bool:
	return a.get_display_name_localized() < b.get_display_name_localized()


func _get_selected_offhand() -> GearData:
	var index: int = _offhand_option.selected
	if index < 0 or index >= _all_offhand_options.size():
		return null
	return _all_offhand_options[index]


func _get_selected_armor_slot_key() -> StringName:
	var index := _armor_slot_filter.selected
	if index < 0 or index >= EquipSlots.ARMOR_STAT_SLOTS.size():
		return EquipSlots.HELMET
	return _armor_slot_filter.get_item_metadata(index) as StringName


func _get_selected_armor_gear() -> GearData:
	var index: int = _armor_gear_option.selected
	if index < 0 or index >= _filtered_armor_gear_options.size():
		return null
	return _filtered_armor_gear_options[index]


func _refresh_armor_gear_option_list(preserve_key: String = "", rebuild_tuning: bool = true) -> void:
	var slot_key := _get_selected_armor_slot_key()
	_filtered_armor_gear_options.clear()
	var bucket: Variant = _armor_gear_by_slot.get(slot_key, [])
	if bucket is Array:
		for gear in bucket:
			if gear is GearData:
				_filtered_armor_gear_options.append(gear)

	_armor_gear_option.clear()
	if _filtered_armor_gear_options.is_empty():
		_update_armor_gear_description()
		return

	var selected_index := 0
	for i in _filtered_armor_gear_options.size():
		var gear: GearData = _filtered_armor_gear_options[i]
		_armor_gear_option.add_item(gear.get_display_name_localized())
		if not preserve_key.is_empty() and gear.get_unique_key() == preserve_key:
			selected_index = i
	_armor_gear_option.select(selected_index)
	_update_armor_gear_description()
	if rebuild_tuning:
		refresh_armor_gear_tuning_ui()


func _refresh_offhand_option_list(preserve_key: String = "") -> void:
	_offhand_option.clear()
	if _all_offhand_options.is_empty():
		_update_offhand_description()
		return

	var select_index := 0
	for i in _all_offhand_options.size():
		var gear: GearData = _all_offhand_options[i]
		_offhand_option.add_item(gear.get_display_name_localized())
		if not preserve_key.is_empty() and gear.get_unique_key() == preserve_key:
			select_index = i
	_offhand_option.select(select_index)
	_update_offhand_description()


func _equip_offhand_from_gui(gear: GearData) -> void:
	if gear == null:
		return
	if not _is_inventory_loadout_enabled.call():
		_update_status.call("보조손 장착은 인벤 로드아웃(use_inventory_loadout)이 필요합니다.")
		return
	var inventory_menu: CanvasLayer = _get_inventory_menu.call()
	if inventory_menu == null:
		return
	var menu_service: InventoryService = inventory_menu.get_service()
	if menu_service == null:
		return
	var gear_id := gear.get_unique_key()
	var err := menu_service.try_force_equip_offhand_on_active_set(gear_id)
	if not err.is_empty():
		_update_status.call(UiLocale.t(err))
		return
	if inventory_menu.has_method("refresh_all_slots"):
		inventory_menu.refresh_all_slots()
	if inventory_menu.has_method("persist_loadout_if_enabled"):
		inventory_menu.persist_loadout_if_enabled()
	_apply_inventory_loadout_to_player.call()
	_refresh_offhand_option_list(gear_id)
	_update_status.call("보조손 장착: %s" % gear.get_display_name_localized())
	_equipped_offhand_id = gear_id
	refresh_offhand_tuning_ui()


func _equip_armor_gear_from_gui(gear: GearData) -> void:
	if gear == null:
		return
	if not _is_inventory_loadout_enabled.call():
		_update_status.call("방어구 장착은 인벤 로드아웃(use_inventory_loadout)이 필요합니다.")
		return
	var inventory_menu: CanvasLayer = _get_inventory_menu.call()
	if inventory_menu == null:
		return
	var slot_key := _get_selected_armor_slot_key()
	if not gear.fits_slot(slot_key):
		_update_status.call("선택 부위(%s)에 맞지 않는 장비입니다." % _armor_slot_labels_ko.get(
			slot_key,
			EquipSlots.slot_key_to_string(slot_key)
		))
		return
	var menu_service: InventoryService = inventory_menu.get_service()
	if menu_service == null:
		return
	var gear_id := gear.get_unique_key()
	var err := menu_service.try_force_equip_shared_armor_slot(gear_id, slot_key)
	if not err.is_empty():
		_update_status.call(UiLocale.t(err))
		return
	if inventory_menu.has_method("refresh_all_slots"):
		inventory_menu.refresh_all_slots()
	if inventory_menu.has_method("persist_loadout_if_enabled"):
		inventory_menu.persist_loadout_if_enabled()
	_apply_inventory_loadout_to_player.call()
	_refresh_armor_gear_option_list(gear_id)
	var slot_label: String = _armor_slot_labels_ko.get(slot_key, EquipSlots.slot_key_to_string(slot_key))
	_update_status.call("%s 장착: %s" % [slot_label, gear.get_display_name_localized()])
	refresh_armor_gear_tuning_ui()


func _update_offhand_description() -> void:
	if not _offhand_desc_label.visible:
		return
	var gear := _get_selected_offhand()
	if gear:
		var tuned := _gear_snapshots.build_tuned_gear(gear)
		var slot_label := UiLocale.t(&"slot.offhand")
		_offhand_desc_label.text = GearStatDisplayScript.build_gear_tooltip(tuned, slot_label)
	else:
		_offhand_desc_label.text = "보조손 목록이 비어 있습니다."


func _update_armor_gear_description() -> void:
	if not _armor_gear_desc_label.visible:
		return
	var slot_key := _get_selected_armor_slot_key()
	var slot_label: String = _armor_slot_labels_ko.get(slot_key, EquipSlots.slot_key_to_string(slot_key))
	var gear := _get_selected_armor_gear()
	if gear:
		var tuned := _gear_snapshots.build_tuned_gear(gear)
		_armor_gear_desc_label.text = GearStatDisplayScript.build_gear_tooltip(tuned, slot_label)
	else:
		_armor_gear_desc_label.text = "%s 목록이 비어 있습니다." % slot_label


func _refresh_offhand_status_hint() -> void:
	if not _offhand_status_row.visible:
		return
	var status_ids := _get_selected_offhand_status_ids()
	if status_ids.is_empty():
		_offhand_status_hint_label.text = "적중 상태이상: 없음"
		_offhand_status_option.clear()
		_edit_offhand_status_button.disabled = true
		var empty_status_ids: Array[StringName] = []
		_refresh_status_tab_options.call(empty_status_ids, &"")
		return
	_offhand_status_hint_label.text = "적중 상태이상:"
	_offhand_status_option.clear()
	for status_id in status_ids:
		_offhand_status_option.add_item(StatusEffectCatalog.get_display_name(status_id))
		_offhand_status_option.set_item_metadata(_offhand_status_option.get_item_count() - 1, status_id)
	_edit_offhand_status_button.disabled = false
	var selected_id := status_ids[0]
	if _status_effect_option.get_item_count() > 0 and _status_effect_option.selected >= 0:
		var current_id := StringName(_status_effect_option.get_item_metadata(_status_effect_option.selected))
		if current_id != &"":
			selected_id = current_id
	var selected_index := 0
	for i in status_ids.size():
		if status_ids[i] == selected_id:
			selected_index = i
			break
	_offhand_status_option.select(selected_index)
	_refresh_status_tab_options.call(status_ids, selected_id)


func _get_selected_offhand_status_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var gear := _get_selected_offhand()
	if gear == null:
		return result
	var stats := GearStatMerge.normalize_modifiers(gear.stat_modifiers)
	_append_grant_on_hit_status_ids(stats, result)
	_append_orbital_weapon_status_ids(stats, result)
	return result


func _append_grant_on_hit_status_ids(stats: Dictionary, result: Array[StringName]) -> void:
	if not stats.has("grant_on_hit"):
		return
	var raw_tags: Variant = stats["grant_on_hit"]
	_append_status_ids_from_variant(raw_tags, result)


func _append_orbital_weapon_status_ids(stats: Dictionary, result: Array[StringName]) -> void:
	if not stats.has("grant_orbital"):
		return
	var raw_tags: Variant = stats["grant_orbital"]
	var orbital_tags: Array[String] = _to_string_array(raw_tags)
	if orbital_tags.is_empty():
		return
	for orbital_tag in orbital_tags:
		var weapon_id_variant: Variant = LoadoutGrantPassiveScript.ORBITAL_WEAPON_BY_TAG.get(orbital_tag, "")
		var weapon_id: String = String(weapon_id_variant).strip_edges()
		if weapon_id.is_empty():
			continue
		var weapon: WeaponData = _resolve_weapon_data(weapon_id)
		if weapon == null or weapon.status_effects.is_empty():
			continue
		for status_id in weapon.status_effects:
			_append_status_id(status_id, result)


func _resolve_weapon_data(weapon_id: String) -> WeaponData:
	var inventory_menu: CanvasLayer = _get_inventory_menu.call()
	if inventory_menu == null:
		return null
	var menu_service: InventoryService = inventory_menu.get_service()
	if menu_service == null:
		return null
	return menu_service.registry.resolve_weapon(weapon_id)


func _append_status_ids_from_variant(raw_status_ids: Variant, result: Array[StringName]) -> void:
	if raw_status_ids is Array:
		for raw_status_id in raw_status_ids:
			var status_id := StringName(String(raw_status_id).strip_edges())
			_append_status_id(status_id, result)
		return
	var single_status_id := StringName(String(raw_status_ids).strip_edges())
	_append_status_id(single_status_id, result)


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			var normalized := String(entry).strip_edges()
			if normalized.is_empty():
				continue
			result.append(normalized)
		return result
	var normalized_single := String(value).strip_edges()
	if not normalized_single.is_empty():
		result.append(normalized_single)
	return result


func _append_status_id(status_id: StringName, result: Array[StringName]) -> void:
	if status_id == &"" or status_id in result:
		return
	if not StatusEffectCatalog.has_status(status_id):
		return
	result.append(status_id)


func _apply_gear_tuning_live(_catalog_gear: GearData) -> void:
	if not _is_inventory_loadout_enabled.call():
		return
	_apply_inventory_loadout_to_player.call()


func _store_gear_tuning_value(catalog_gear: GearData, property: String, new_value: float) -> void:
	var gear_id := catalog_gear.get_unique_key()
	var tuned_mods := _gear_snapshots.build_tuned_stat_modifiers(gear_id)
	var stored: Variant = new_value
	for field_def in _gear_snapshots.get_field_defs(catalog_gear):
		if field_def["property"] != property:
			continue
		if field_def.get("integer", false):
			stored = int(roundf(new_value))
		break

	if property == "block_min":
		var block_max := int(tuned_mods.get("block_max", int(stored)))
		stored = mini(int(stored), block_max)
	elif property == "block_max":
		var block_min := int(tuned_mods.get("block_min", int(stored)))
		stored = maxi(int(stored), block_min)
	elif property == "armor_min":
		var armor_max := int(tuned_mods.get("armor_max", int(stored)))
		stored = mini(int(stored), armor_max)
	elif property == "armor_max":
		var armor_min := int(tuned_mods.get("armor_min", int(stored)))
		stored = maxi(int(stored), armor_min)
	elif property == "revive_min":
		var revive_max := int(tuned_mods.get("revive_max", int(stored)))
		stored = mini(int(stored), revive_max)
	elif property == "revive_max":
		var revive_min := int(tuned_mods.get("revive_min", int(stored)))
		stored = maxi(int(stored), revive_min)

	_gear_snapshots.set_session_value(gear_id, property, stored)


func _setup_gear_tuning_ui_by_kind(ui_kind: StringName) -> void:
	_clear_gear_tuning_fields_by_kind(ui_kind)
	var preset := _get_gear_tuning_preset(ui_kind)
	var save_button: Button = preset.get("save_button")
	var reset_button: Button = preset.get("reset_button")
	save_button.disabled = true
	reset_button.disabled = true


func _clear_gear_tuning_fields_by_kind(ui_kind: StringName) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.clear_fields(
		preset.get("fields"),
		preset.get("spin_rows")
	)


func _refresh_gear_tuning_ui_by_kind(ui_kind: StringName) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.refresh_ui(
		preset.get("fields"),
		preset.get("status_label"),
		preset.get("save_button"),
		preset.get("reset_button"),
		preset.get("spin_rows"),
		preset.get("selected_callable"),
		preset.get("is_equipped_callable"),
		preset.get("on_value_changed_callable"),
		preset.get("on_spin_tree_entered_callable"),
		preset.get("on_spin_step_pressed_callable"),
		String(preset.get("empty_message", "")),
		String(preset.get("unsupported_message", "")),
		_gear_snapshots,
		func(is_refreshing: bool) -> void:
			_set_gear_tuning_refreshing(ui_kind, is_refreshing),
		func(catalog_gear: GearData) -> void:
			_refresh_gear_tuning_status_only_core(
				catalog_gear,
				preset.get("status_label"),
				preset.get("is_equipped_callable")
			),
		_tuning_spin_button_size,
		_tuning_spin_button_font_size,
		_tuning_spin_min_height
	)


func _on_gear_tuning_spin_tree_entered_by_kind(
	ui_kind: StringName,
	spin: SpinBox,
	catalog_gear: GearData,
	property: String
) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.on_spin_tree_entered(
		spin,
		catalog_gear,
		property,
		preset.get("on_value_changed_callable"),
		_on_tuning_spin_tree_entered,
		_wire_spin_box_text_commit
	)


func _on_gear_tuning_spin_step_pressed_by_kind(
	ui_kind: StringName,
	spin: SpinBox,
	catalog_gear: GearData,
	property: String,
	direction: int
) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.on_spin_step_pressed(
		spin,
		catalog_gear,
		property,
		direction,
		preset.get("on_value_changed_callable"),
		preset.get("sync_spin_display_callable")
	)


func _on_gear_tuning_value_changed_by_kind(
	ui_kind: StringName,
	new_value: float,
	catalog_gear: GearData,
	property: String
) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.on_value_changed(
		new_value,
		catalog_gear,
		property,
		func() -> bool:
			return _is_gear_tuning_refreshing(ui_kind),
		_store_gear_tuning_value,
		_apply_gear_tuning_live,
		preset.get("sync_spin_display_callable"),
		preset.get("refresh_status_only_callable")
	)


func _sync_gear_tuning_spin_display_by_kind(
	ui_kind: StringName,
	property: String,
	catalog_gear: GearData
) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.sync_spin_display(
		property,
		catalog_gear,
		preset.get("spin_rows"),
		_gear_snapshots,
		func(is_refreshing: bool) -> void:
			_set_gear_tuning_refreshing(ui_kind, is_refreshing)
	)


func _refresh_gear_tuning_status_only_by_kind(ui_kind: StringName, catalog_gear: GearData) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	_refresh_gear_tuning_status_only_core(
		catalog_gear,
		preset.get("status_label"),
		preset.get("is_equipped_callable")
	)


func _refresh_gear_tuning_status_only_core(
	catalog_gear: GearData,
	status_label: Label,
	is_equipped: Callable
) -> void:
	TestArenaGearTuningUiUtil.refresh_status_only(
		catalog_gear,
		status_label,
		is_equipped,
		_gear_snapshots
	)


func _commit_and_apply_gear_tuning_from_spins_by_kind(ui_kind: StringName) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	TestArenaGearTuningUiUtil.commit_and_apply_from_spins(
		preset.get("selected_callable"),
		preset.get("spin_rows"),
		_commit_spin_box_pending,
		_store_gear_tuning_value,
		_apply_gear_tuning_live
	)


func _on_apply_gear_tuning_pressed_by_kind(ui_kind: StringName) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	var catalog_gear: GearData = preset.get("selected_callable").call()
	if catalog_gear == null:
		return
	_commit_and_apply_gear_tuning_from_spins_by_kind(ui_kind)
	_refresh_gear_tuning_ui_by_kind(ui_kind)
	_update_status.call("%s 튜닝 적용: %s" % [String(preset.get("label", "장비")), catalog_gear.get_display_name_localized()])


func _on_save_gear_tuning_pressed_by_kind(ui_kind: StringName) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	var catalog_gear: GearData = preset.get("selected_callable").call()
	if catalog_gear == null:
		return
	_commit_and_apply_gear_tuning_from_spins_by_kind(ui_kind)
	var gear_id := catalog_gear.get_unique_key()
	_gear_snapshots.save_gear(gear_id)
	_update_status.call("%s 스냅샷 저장: %s" % [String(preset.get("label", "장비")), catalog_gear.get_display_name_localized()])
	_apply_gear_tuning_live(catalog_gear)
	_refresh_gear_tuning_ui_by_kind(ui_kind)
	preset.get("after_save_or_reset_callable").call()


func _on_reset_gear_tuning_pressed_by_kind(ui_kind: StringName) -> void:
	var preset := _get_gear_tuning_preset(ui_kind)
	var catalog_gear: GearData = preset.get("selected_callable").call()
	if catalog_gear == null:
		return
	var gear_id := catalog_gear.get_unique_key()
	_gear_snapshots.reset_gear(gear_id)
	_update_status.call("%s 스냅샷 초기화: %s" % [String(preset.get("label", "장비")), catalog_gear.get_display_name_localized()])
	_apply_gear_tuning_live(catalog_gear)
	_refresh_gear_tuning_ui_by_kind(ui_kind)
	preset.get("after_save_or_reset_callable").call()


func _set_gear_tuning_refreshing(ui_kind: StringName, is_refreshing: bool) -> void:
	match ui_kind:
		&"offhand":
			_offhand_tuning_ui_refreshing = is_refreshing
		&"armor":
			_armor_gear_tuning_ui_refreshing = is_refreshing


func _is_gear_tuning_refreshing(ui_kind: StringName) -> bool:
	match ui_kind:
		&"offhand":
			return _offhand_tuning_ui_refreshing
		&"armor":
			return _armor_gear_tuning_ui_refreshing
	return false


func _is_armor_gear_equipped_in_selected_slot(gear: GearData) -> bool:
	if gear == null or not _is_inventory_loadout_enabled.call():
		return false
	var inventory_menu: CanvasLayer = _get_inventory_menu.call()
	if inventory_menu == null:
		return false
	var menu_service: InventoryService = inventory_menu.get_service()
	if menu_service == null:
		return false
	var slot_key := _get_selected_armor_slot_key()
	return (
		menu_service.loadout.get_set_item_id(EquipSlots.SHARED_ARMOR_SET_INDEX, slot_key)
		== gear.get_unique_key()
	)


func _build_gear_tuning_presets() -> void:
	_gear_tuning_presets = {
		&"offhand": {
			"label": "보조손",
			"empty_message": "보조손 목록이 비어 있습니다.",
			"unsupported_message": "이 보조손은 F6 수치 튜닝 대상 stat이 없습니다.",
			"fields": _offhand_tuning_fields,
			"status_label": _offhand_tuning_status_label,
			"save_button": _save_offhand_tuning_button,
			"reset_button": _reset_offhand_tuning_button,
			"spin_rows": _offhand_tuning_spin_rows,
			"selected_callable": _get_selected_offhand,
			"is_equipped_callable": func(gear: GearData) -> bool:
				return _equipped_offhand_id == gear.get_unique_key(),
			"on_value_changed_callable": _on_offhand_tuning_value_changed,
			"on_spin_tree_entered_callable": _on_offhand_tuning_spin_tree_entered,
			"on_spin_step_pressed_callable": _on_offhand_tuning_spin_step_pressed,
			"sync_spin_display_callable": _sync_offhand_tuning_spin_display,
			"refresh_status_only_callable": _refresh_offhand_tuning_status_only,
			"after_save_or_reset_callable": _update_offhand_description,
		},
		&"armor": {
			"label": "장비",
			"empty_message": "장비 목록이 비어 있습니다.",
			"unsupported_message": "이 장비는 F6 수치 튜닝 대상 stat이 없습니다.",
			"fields": _armor_gear_tuning_fields,
			"status_label": _armor_gear_tuning_status_label,
			"save_button": _save_armor_gear_tuning_button,
			"reset_button": _reset_armor_gear_tuning_button,
			"spin_rows": _armor_gear_tuning_spin_rows,
			"selected_callable": _get_selected_armor_gear,
			"is_equipped_callable": _is_armor_gear_equipped_in_selected_slot,
			"on_value_changed_callable": _on_armor_gear_tuning_value_changed,
			"on_spin_tree_entered_callable": _on_armor_gear_tuning_spin_tree_entered,
			"on_spin_step_pressed_callable": _on_armor_gear_tuning_spin_step_pressed,
			"sync_spin_display_callable": _sync_armor_gear_tuning_spin_display,
			"refresh_status_only_callable": _refresh_armor_gear_tuning_status_only,
			"after_save_or_reset_callable": _update_armor_gear_description,
		},
	}


func _get_gear_tuning_preset(ui_kind: StringName) -> Dictionary:
	if _gear_tuning_presets.is_empty():
		_build_gear_tuning_presets()
	if _gear_tuning_presets.has(ui_kind):
		return _gear_tuning_presets[ui_kind]
	return _gear_tuning_presets.get(&"offhand", {})


func _on_offhand_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String
) -> void:
	_on_gear_tuning_spin_tree_entered_by_kind(&"offhand", spin, catalog_gear, property)


func _on_offhand_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String,
	direction: int
) -> void:
	_on_gear_tuning_spin_step_pressed_by_kind(&"offhand", spin, catalog_gear, property, direction)


func _on_offhand_tuning_value_changed(
	new_value: float,
	catalog_gear: GearData,
	property: String
) -> void:
	_on_gear_tuning_value_changed_by_kind(&"offhand", new_value, catalog_gear, property)


func _sync_offhand_tuning_spin_display(property: String, catalog_gear: GearData) -> void:
	_sync_gear_tuning_spin_display_by_kind(&"offhand", property, catalog_gear)


func _refresh_offhand_tuning_status_only(catalog_gear: GearData) -> void:
	_refresh_gear_tuning_status_only_by_kind(&"offhand", catalog_gear)


func _on_armor_gear_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String
) -> void:
	_on_gear_tuning_spin_tree_entered_by_kind(&"armor", spin, catalog_gear, property)


func _on_armor_gear_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String,
	direction: int
) -> void:
	_on_gear_tuning_spin_step_pressed_by_kind(&"armor", spin, catalog_gear, property, direction)


func _on_armor_gear_tuning_value_changed(
	new_value: float,
	catalog_gear: GearData,
	property: String
) -> void:
	_on_gear_tuning_value_changed_by_kind(&"armor", new_value, catalog_gear, property)


func _sync_armor_gear_tuning_spin_display(property: String, catalog_gear: GearData) -> void:
	_sync_gear_tuning_spin_display_by_kind(&"armor", property, catalog_gear)


func _refresh_armor_gear_tuning_status_only(catalog_gear: GearData) -> void:
	_refresh_gear_tuning_status_only_by_kind(&"armor", catalog_gear)
