class_name TestArenaWeaponPanelController
extends RefCounted

## 테스트 아레나 무기 패널(필터/장착/튜닝 UI) 제어 컨트롤러.

const TestArenaTuningUiUtil = preload("res://game/test_arena_tuning_ui.gd")
const ItemLockFilterScript = preload("res://inventory/item_lock_filter.gd")

var _weapon_snapshots: TestArenaWeaponSnapshot
var _update_status: Callable
var _apply_inventory_loadout_to_player: Callable
var _get_inventory_menu: Callable
var _is_inventory_loadout_enabled: Callable
var _is_player_dead: Callable

var _weapon_type_order: Array[String] = []
var _weapon_type_labels_ko: Dictionary = {}
var _weapon_rarity_order: Array[String] = []
var _weapon_rarity_labels_ko: Dictionary = {}
var _start_weapon: WeaponData
var _all_weapon_options: Array[WeaponData] = []
var _available_rarities: Array[String] = []

var _equipped_weapon_id := ""
var _filtered_weapon_options: Array[WeaponData] = []
var _tuning_spin_rows: Array[Dictionary] = []
var _tuning_ui_refreshing := false

var _player: CharacterBody2D
var _weapon_type_filter: OptionButton
var _weapon_rarity_filter: OptionButton
var _weapon_lock_filter: OptionButton
var _weapon_option: OptionButton
var _weapon_desc_label: RichTextLabel
var _projectile_tuning_fields: VBoxContainer
var _projectile_tuning_status_label: Label
var _projectile_movement_row: HBoxContainer
var _projectile_movement_option: OptionButton
var _save_projectile_tuning_button: Button
var _reset_projectile_tuning_button: Button

var _tuning_spin_button_size := Vector2.ZERO
var _tuning_spin_min_height := 0
var _tuning_spin_button_font_size := 0
var _tuning_spin_value_font_size := 0


func configure(
	weapon_snapshots: TestArenaWeaponSnapshot,
	update_status: Callable,
	apply_inventory_loadout_to_player: Callable,
	get_inventory_menu: Callable,
	is_inventory_loadout_enabled: Callable,
	is_player_dead: Callable,
	weapon_type_order: Array[String],
	weapon_type_labels_ko: Dictionary,
	weapon_rarity_order: Array[String],
	weapon_rarity_labels_ko: Dictionary,
	start_weapon: WeaponData,
	all_weapon_options: Array[WeaponData],
	available_rarities: Array[String],
	player: CharacterBody2D,
	weapon_type_filter: OptionButton,
	weapon_rarity_filter: OptionButton,
	weapon_lock_filter: OptionButton,
	weapon_option: OptionButton,
	weapon_desc_label: RichTextLabel,
	projectile_tuning_fields: VBoxContainer,
	projectile_tuning_status_label: Label,
	projectile_movement_row: HBoxContainer,
	projectile_movement_option: OptionButton,
	save_projectile_tuning_button: Button,
	reset_projectile_tuning_button: Button,
	tuning_spin_button_size: Vector2,
	tuning_spin_min_height: int,
	tuning_spin_button_font_size: int,
	tuning_spin_value_font_size: int
) -> void:
	_weapon_snapshots = weapon_snapshots
	_update_status = update_status
	_apply_inventory_loadout_to_player = apply_inventory_loadout_to_player
	_get_inventory_menu = get_inventory_menu
	_is_inventory_loadout_enabled = is_inventory_loadout_enabled
	_is_player_dead = is_player_dead
	_weapon_type_order = weapon_type_order
	_weapon_type_labels_ko = weapon_type_labels_ko
	_weapon_rarity_order = weapon_rarity_order
	_weapon_rarity_labels_ko = weapon_rarity_labels_ko
	_start_weapon = start_weapon
	_all_weapon_options = all_weapon_options
	_available_rarities = available_rarities
	_player = player
	_weapon_type_filter = weapon_type_filter
	_weapon_rarity_filter = weapon_rarity_filter
	_weapon_lock_filter = weapon_lock_filter
	_weapon_option = weapon_option
	_weapon_desc_label = weapon_desc_label
	_projectile_tuning_fields = projectile_tuning_fields
	_projectile_tuning_status_label = projectile_tuning_status_label
	_projectile_movement_row = projectile_movement_row
	_projectile_movement_option = projectile_movement_option
	_save_projectile_tuning_button = save_projectile_tuning_button
	_reset_projectile_tuning_button = reset_projectile_tuning_button
	_tuning_spin_button_size = tuning_spin_button_size
	_tuning_spin_min_height = tuning_spin_min_height
	_tuning_spin_button_font_size = tuning_spin_button_font_size
	_tuning_spin_value_font_size = tuning_spin_value_font_size


func setup_weapon_filters() -> void:
	_weapon_type_filter.clear()
	_weapon_type_filter.add_item("전체")
	for weapon_type in _weapon_type_order:
		_weapon_type_filter.add_item(_weapon_type_labels_ko[weapon_type])
	var ranged_index := _weapon_type_order.find("Ranged") + 1
	_weapon_type_filter.select(maxi(ranged_index, 0))

	_weapon_rarity_filter.clear()
	_weapon_rarity_filter.add_item("전체")
	for rarity in _available_rarities:
		var label: String = _weapon_rarity_labels_ko.get(rarity, rarity)
		_weapon_rarity_filter.add_item(label)
	var common_index := _available_rarities.find("Common")
	if common_index >= 0:
		_weapon_rarity_filter.select(common_index + 1)
	else:
		_weapon_rarity_filter.select(0)

	ItemLockFilterScript.populate_option_button(_weapon_lock_filter)

	_refresh_weapon_option_list(_start_weapon.get_unique_key())


func on_weapon_filters_changed() -> void:
	var current := _get_selected_weapon()
	var preserve_key := current.get_unique_key() if current else ""
	_refresh_weapon_option_list(preserve_key)


func on_weapon_option_selected() -> void:
	_update_weapon_description()
	_refresh_projectile_tuning_ui()


func on_equip_weapon_button_pressed() -> void:
	var weapon := _get_selected_weapon()
	if weapon == null:
		return
	_equip_weapon_from_gui(weapon)


func on_projectile_movement_selected(index: int) -> void:
	if _tuning_ui_refreshing:
		return
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	var tuned := _weapon_snapshots.build_tuned_weapon(catalog_weapon)
	var movement_options := tuned.get_projectile_movement_options()
	if index < 0 or index >= movement_options.size():
		return
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.set_session_value(weapon_id, "projectile_movement", movement_options[index])
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_status_only(catalog_weapon)


func on_apply_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	_commit_and_apply_projectile_tuning_from_spins()
	_update_status.call("무기 튜닝 적용: %s" % catalog_weapon.get_display_name_localized())


func on_save_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	_commit_and_apply_projectile_tuning_from_spins()
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.save_weapon(weapon_id)
	_update_status.call("무기 스냅샷 저장: %s" % catalog_weapon.get_display_name_localized())
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


func on_reset_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.reset_weapon(weapon_id)
	_update_status.call("무기 스냅샷 초기화: %s" % catalog_weapon.get_display_name_localized())
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


func setup_projectile_tuning_ui() -> void:
	_clear_projectile_tuning_fields()
	_projectile_movement_row.visible = false
	_save_projectile_tuning_button.disabled = true
	_reset_projectile_tuning_button.disabled = true


func refresh_projectile_tuning_ui() -> void:
	_refresh_projectile_tuning_ui()


func equip_weapon(catalog_weapon: WeaponData) -> void:
	_equip_weapon(catalog_weapon)


func equip_weapon_from_gui(catalog_weapon: WeaponData) -> void:
	_equip_weapon_from_gui(catalog_weapon)


func apply_tuning_live(catalog_weapon: WeaponData) -> void:
	_apply_tuning_live(catalog_weapon)


func get_selected_weapon() -> WeaponData:
	return _get_selected_weapon()


func get_weapon_filter_type() -> String:
	return _get_weapon_filter_type()


func get_weapon_filter_rarity() -> String:
	return _get_weapon_filter_rarity()


func weapon_matches_rarity(weapon: WeaponData, rarity_filter: String) -> bool:
	return _weapon_matches_rarity(weapon, rarity_filter)


func refresh_weapon_option_list(preserve_key: String = "") -> void:
	_refresh_weapon_option_list(preserve_key)


func clear_projectile_tuning_fields() -> void:
	_clear_projectile_tuning_fields()


func add_projectile_tuning_row(catalog_weapon: WeaponData, field_def: Dictionary, tuned: WeaponData) -> void:
	_add_projectile_tuning_row(catalog_weapon, field_def, tuned)


func on_projectile_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	_on_projectile_tuning_spin_tree_entered(spin, catalog_weapon, property)


func on_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String,
	direction: int
) -> void:
	_on_tuning_spin_step_pressed(spin, catalog_weapon, property, direction)


func populate_projectile_movement_dropdown(tuned: WeaponData) -> void:
	_populate_projectile_movement_dropdown(tuned)


func on_projectile_tuning_value_changed(
	new_value: float,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	_on_projectile_tuning_value_changed(new_value, catalog_weapon, property)


func sync_tuning_spin_display(property: String, catalog_weapon: WeaponData) -> void:
	_sync_tuning_spin_display(property, catalog_weapon)


func resolve_projectile_pierce_spin_value(catalog_weapon: WeaponData, new_value: int):
	return _resolve_projectile_pierce_spin_value(catalog_weapon, new_value)


func refresh_projectile_tuning_status_only(catalog_weapon: WeaponData) -> void:
	_refresh_projectile_tuning_status_only(catalog_weapon)


func commit_and_apply_projectile_tuning_from_spins() -> void:
	_commit_and_apply_projectile_tuning_from_spins()


func update_weapon_description() -> void:
	_update_weapon_description()


func get_weapon_omit_properties(catalog_weapon: WeaponData) -> Array[String]:
	return _get_weapon_omit_properties(catalog_weapon)


func _get_weapon_filter_type() -> String:
	var index: int = _weapon_type_filter.selected
	if index <= 0:
		return ""
	return _weapon_type_order[index - 1]


func _get_weapon_filter_rarity() -> String:
	var index: int = _weapon_rarity_filter.selected
	if index <= 0:
		return ""
	if index - 1 < _available_rarities.size():
		return _available_rarities[index - 1]
	return ""


func _weapon_matches_rarity(weapon: WeaponData, rarity_filter: String) -> bool:
	if rarity_filter.is_empty():
		return true
	var weapon_rarity := weapon.rarity if not weapon.rarity.is_empty() else "Common"
	return weapon_rarity == rarity_filter


func _weapon_matches_lock(weapon: WeaponData, lock_mode: int) -> bool:
	return ItemLockFilterScript.matches(weapon.is_locked, lock_mode)


func _refresh_weapon_option_list(preserve_key: String = "") -> void:
	var filter_type := _get_weapon_filter_type()
	var filter_rarity := _get_weapon_filter_rarity()
	var filter_lock := ItemLockFilterScript.get_mode(_weapon_lock_filter)
	_filtered_weapon_options.clear()
	for weapon in _all_weapon_options:
		if not filter_type.is_empty() and weapon.weapon_type != filter_type:
			continue
		if not _weapon_matches_rarity(weapon, filter_rarity):
			continue
		if not _weapon_matches_lock(weapon, filter_lock):
			continue
		_filtered_weapon_options.append(weapon)

	_weapon_option.clear()
	if _filtered_weapon_options.is_empty():
		if not _is_player_dead.call():
			_update_status.call("조건에 맞는 무기가 없습니다.")
		_update_weapon_description()
		return

	var select_index := 0
	for i in _filtered_weapon_options.size():
		var weapon: WeaponData = _filtered_weapon_options[i]
		_weapon_option.add_item(weapon.get_display_name_localized())
		if not preserve_key.is_empty() and weapon.get_unique_key() == preserve_key:
			select_index = i
	_weapon_option.select(select_index)
	if not _is_player_dead.call() and _filtered_weapon_options.size() > 0:
		_update_status.call("")
	_update_weapon_description()
	_refresh_projectile_tuning_ui()


func _get_selected_weapon() -> WeaponData:
	var index: int = _weapon_option.selected
	if index < 0 or index >= _filtered_weapon_options.size():
		return null
	return _filtered_weapon_options[index]


func _equip_weapon_from_gui(catalog_weapon: WeaponData) -> void:
	if catalog_weapon == null:
		return
	if _is_inventory_loadout_enabled.call():
		var inventory_menu: CanvasLayer = _get_inventory_menu.call()
		if inventory_menu != null:
			var menu_service: InventoryService = inventory_menu.get_service()
			if menu_service != null:
				var weapon_id := catalog_weapon.get_unique_key()
				var err := menu_service.try_force_equip_weapon_on_active_set(weapon_id)
				if not err.is_empty():
					_update_status.call("무기 장착 실패 (%s)" % String(err))
					return
				if inventory_menu.has_method("refresh_all_slots"):
					inventory_menu.refresh_all_slots()
				if inventory_menu.has_method("persist_loadout_if_enabled"):
					inventory_menu.persist_loadout_if_enabled()
				_apply_inventory_loadout_to_player.call()
				return
	_equip_weapon(catalog_weapon)


func _equip_weapon(catalog_weapon: WeaponData) -> void:
	if catalog_weapon == null:
		return
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


func _apply_tuning_live(catalog_weapon: WeaponData) -> void:
	var tuned := _weapon_snapshots.build_tuned_weapon(catalog_weapon)
	_equipped_weapon_id = catalog_weapon.get_unique_key()
	_player.clear_weapons()
	_player.add_weapon(tuned)
	_player.set_auto_attack_enabled(true)
	if _player.has_method(&"_refresh_weapon_combat_modifiers"):
		_player._refresh_weapon_combat_modifiers()


func _clear_projectile_tuning_fields() -> void:
	for child in _projectile_tuning_fields.get_children():
		_projectile_tuning_fields.remove_child(child)
		child.free()
	_tuning_spin_rows.clear()


func _refresh_projectile_tuning_ui() -> void:
	_clear_projectile_tuning_fields()
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		_projectile_tuning_status_label.text = "조건에 맞는 무기가 없습니다."
		_projectile_movement_row.visible = false
		_save_projectile_tuning_button.disabled = true
		_reset_projectile_tuning_button.disabled = true
		return

	if not _weapon_snapshots.supports_projectile_tuning(catalog_weapon):
		_projectile_tuning_status_label.text = "이 무기는 무기 튜닝을 지원하지 않습니다."
		_projectile_movement_row.visible = false
		_save_projectile_tuning_button.disabled = true
		_reset_projectile_tuning_button.disabled = true
		return

	var weapon_id := catalog_weapon.get_unique_key()
	var tuned := _weapon_snapshots.build_tuned_weapon(catalog_weapon)
	var field_defs: Array = _weapon_snapshots.get_field_defs(catalog_weapon)
	_tuning_ui_refreshing = true
	var show_movement := _weapon_snapshots.supports_projectile_movement_tuning(catalog_weapon)
	if show_movement:
		_populate_projectile_movement_dropdown(tuned)
	_projectile_movement_row.visible = show_movement
	for field_def in field_defs:
		_add_projectile_tuning_row(catalog_weapon, field_def, tuned)
	_tuning_ui_refreshing = false

	var status_parts: PackedStringArray = []
	if _weapon_snapshots.has_saved_snapshot(weapon_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _weapon_snapshots.get_session_overrides(weapon_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if _equipped_weapon_id == weapon_id:
		status_parts.append("장착 중 — 값 변경 시 즉시 반영")
	if status_parts.is_empty():
		_projectile_tuning_status_label.text = "카탈로그 기본값"
	else:
		_projectile_tuning_status_label.text = " · ".join(status_parts)
	_save_projectile_tuning_button.disabled = false
	_reset_projectile_tuning_button.disabled = false


func _add_projectile_tuning_row(catalog_weapon: WeaponData, field_def: Dictionary, tuned: WeaponData) -> void:
	var property: String = field_def["property"]
	var initial_value := 0.0
	if field_def.get("bool", false):
		initial_value = 1.0 if bool(tuned.get(property)) else 0.0
	else:
		initial_value = _weapon_snapshots.get_tuning_spin_display_value(tuned, property)
	var row := TestArenaTuningUiUtil.create_tuning_row(
		_projectile_tuning_fields,
		field_def,
		initial_value,
		_on_projectile_tuning_value_changed.bind(catalog_weapon, property),
		_on_projectile_tuning_spin_tree_entered.bind(catalog_weapon, property),
		func(spin: SpinBox, direction: int) -> void:
			_on_tuning_spin_step_pressed(spin, catalog_weapon, property, direction),
		_tuning_spin_button_size,
		_tuning_spin_button_font_size,
		_tuning_spin_min_height
	)
	_tuning_spin_rows.append(row)


func _on_projectile_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	TestArenaTuningUiUtil.style_spin_line_edit(
		spin,
		_tuning_spin_min_height,
		_tuning_spin_value_font_size
	)
	TestArenaTuningUiUtil.wire_spin_box_text_commit(
		spin,
		func(new_value: float) -> void:
			_on_projectile_tuning_value_changed(new_value, catalog_weapon, property)
	)


func _on_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String,
	direction: int
) -> void:
	_on_projectile_tuning_value_changed(
		spin.value + spin.step * float(direction),
		catalog_weapon,
		property
	)
	_sync_tuning_spin_display(property, catalog_weapon)


func _populate_projectile_movement_dropdown(tuned: WeaponData) -> void:
	_projectile_movement_option.clear()
	var movement_options := tuned.get_projectile_movement_options()
	var select_index := 0
	for i in movement_options.size():
		var movement_id: String = movement_options[i]
		var label: String = WeaponData.PROJECTILE_MOVEMENT_LABELS_KO.get(movement_id, movement_id)
		_projectile_movement_option.add_item(label)
		if movement_id == tuned.projectile_movement:
			select_index = i
	_projectile_movement_option.select(select_index)


func _on_projectile_tuning_value_changed(
	new_value: float,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	if _tuning_ui_refreshing or catalog_weapon == null:
		return
	var weapon_id := catalog_weapon.get_unique_key()
	var stored: Variant = new_value
	if property == "projectile_pierce_count":
		stored = _resolve_projectile_pierce_spin_value(catalog_weapon, int(roundf(new_value)))
		if stored == null:
			_update_status.call("관통 수는 0일 수 없습니다. 1 이상 또는 -1(무제한)을 사용하세요.")
			_refresh_projectile_tuning_ui()
			return
	elif property in [
		"melee_spread_count",
		"hit_count",
		"burst_count",
		"poison_damage_min",
		"poison_damage_max",
	]:
		stored = int(roundf(new_value))
	elif property in ["melee_range_override", "projectile_range_override", "throw_range"]:
		stored = maxf(new_value, 1.0)
	_weapon_snapshots.set_session_value(weapon_id, property, stored)
	_apply_tuning_live(catalog_weapon)
	_sync_tuning_spin_display(property, catalog_weapon)
	_refresh_projectile_tuning_status_only(catalog_weapon)


func _sync_tuning_spin_display(property: String, catalog_weapon: WeaponData) -> void:
	var tuned := _weapon_snapshots.build_tuned_weapon(catalog_weapon)
	for row in _tuning_spin_rows:
		if row.get("property") != property:
			continue
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			return
		_tuning_ui_refreshing = true
		spin.value = _weapon_snapshots.get_tuning_spin_display_value(tuned, property)
		_tuning_ui_refreshing = false
		return


func _resolve_projectile_pierce_spin_value(catalog_weapon: WeaponData, new_value: int):
	if WeaponData.is_valid_projectile_pierce_count(new_value):
		return new_value
	if new_value != 0:
		return null
	var previous: int = _weapon_snapshots.build_tuned_weapon(catalog_weapon).projectile_pierce_count
	if previous == 1:
		return -1
	if previous == -1:
		return 1
	return null


func _refresh_projectile_tuning_status_only(catalog_weapon: WeaponData) -> void:
	var weapon_id := catalog_weapon.get_unique_key()
	var status_parts: PackedStringArray = []
	if _weapon_snapshots.has_saved_snapshot(weapon_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _weapon_snapshots.get_session_overrides(weapon_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if _equipped_weapon_id == weapon_id:
		status_parts.append("장착 중 — 값 변경 시 즉시 반영")
	_projectile_tuning_status_label.text = (
		" · ".join(status_parts)
		if not status_parts.is_empty()
		else "카탈로그 기본값"
	)


func _commit_and_apply_projectile_tuning_from_spins() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	for row in _tuning_spin_rows:
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			continue
		TestArenaTuningUiUtil.commit_spin_box_pending(spin)
		var property: String = row.get("property", "")
		if property.is_empty():
			continue
		_on_projectile_tuning_value_changed(spin.value, catalog_weapon, property)


func _get_weapon_omit_properties(catalog_weapon: WeaponData) -> Array[String]:
	var omit: Array[String] = []
	if catalog_weapon == null or not _weapon_snapshots.supports_projectile_tuning(catalog_weapon):
		return omit
	for field_def in _weapon_snapshots.get_field_defs(catalog_weapon):
		omit.append(field_def["property"])
	if _weapon_snapshots.supports_projectile_movement_tuning(catalog_weapon):
		omit.append("projectile_movement")
	return omit


func _update_weapon_description() -> void:
	var weapon := _get_selected_weapon()
	if weapon:
		var tuned := _weapon_snapshots.build_tuned_weapon(weapon)
		_weapon_desc_label.text = tuned.build_test_arena_info_bbcode(_get_weapon_omit_properties(weapon))
	else:
		_weapon_desc_label.text = "조건에 맞는 무기가 없습니다."
