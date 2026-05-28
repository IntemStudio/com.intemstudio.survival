class_name TestArenaGearTuningUi
extends RefCounted

## 테스트 아레나 기어(보조손/장비) 튜닝 UI 공통 유틸.

const TestArenaTuningUiUtil = preload("res://game/test_arena_tuning_ui.gd")


static func clear_fields(fields: VBoxContainer, spin_rows: Array[Dictionary]) -> void:
	for child in fields.get_children():
		fields.remove_child(child)
		child.free()
	spin_rows.clear()


static func refresh_ui(
	fields: VBoxContainer,
	status_label: Label,
	save_button: Button,
	reset_button: Button,
	spin_rows: Array[Dictionary],
	get_selected_gear: Callable,
	is_equipped: Callable,
	on_value_changed: Callable,
	on_spin_tree_entered: Callable,
	on_spin_step_pressed: Callable,
	empty_message: String,
	unsupported_message: String,
	gear_snapshots: TestArenaGearSnapshot,
	set_refreshing: Callable,
	refresh_status_only: Callable,
	button_size: Vector2,
	button_font_size: int,
	spin_min_height: float
) -> void:
	clear_fields(fields, spin_rows)
	if not fields.visible:
		return
	var catalog_gear: GearData = get_selected_gear.call()
	if catalog_gear == null:
		status_label.text = empty_message
		save_button.disabled = true
		reset_button.disabled = true
		return
	if not gear_snapshots.supports_gear_tuning(catalog_gear):
		status_label.text = unsupported_message
		save_button.disabled = true
		reset_button.disabled = true
		return

	var gear_id := catalog_gear.get_unique_key()
	var tuned_mods := gear_snapshots.build_tuned_stat_modifiers(gear_id)
	var field_defs: Array = gear_snapshots.get_field_defs(catalog_gear)
	set_refreshing.call(true)
	for field_def in field_defs:
		add_row(
			fields,
			spin_rows,
			catalog_gear,
			field_def,
			tuned_mods,
			on_value_changed,
			on_spin_tree_entered,
			on_spin_step_pressed,
			gear_snapshots,
			button_size,
			button_font_size,
			spin_min_height
		)
	set_refreshing.call(false)
	refresh_status_only.call(catalog_gear)
	save_button.disabled = false
	reset_button.disabled = false


static func add_row(
	fields: VBoxContainer,
	spin_rows: Array[Dictionary],
	catalog_gear: GearData,
	field_def: Dictionary,
	tuned_modifiers: Dictionary,
	on_value_changed: Callable,
	on_spin_tree_entered: Callable,
	on_spin_step_pressed: Callable,
	gear_snapshots: TestArenaGearSnapshot,
	button_size: Vector2,
	button_font_size: int,
	spin_min_height: float
) -> void:
	var property: String = field_def["property"]
	var initial_value := gear_snapshots.get_tuning_spin_display_value(tuned_modifiers, property)
	var row := TestArenaTuningUiUtil.create_tuning_row(
		fields,
		field_def,
		initial_value,
		on_value_changed.bind(catalog_gear, property),
		on_spin_tree_entered.bind(catalog_gear, property),
		func(spin: SpinBox, direction: int) -> void:
			on_spin_step_pressed.call(spin, catalog_gear, property, direction),
		button_size,
		button_font_size,
		spin_min_height
	)
	spin_rows.append(row)


static func on_spin_tree_entered(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String,
	on_value_changed: Callable,
	on_tuning_spin_tree_entered: Callable,
	wire_spin_box_text_commit: Callable
) -> void:
	on_tuning_spin_tree_entered.call(spin)
	wire_spin_box_text_commit.call(
		spin,
		func(new_value: float) -> void:
			on_value_changed.call(new_value, catalog_gear, property)
	)


static func on_spin_step_pressed(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String,
	direction: int,
	on_value_changed: Callable,
	sync_spin_display: Callable
) -> void:
	on_value_changed.call(spin.value + spin.step * float(direction), catalog_gear, property)
	sync_spin_display.call(property, catalog_gear)


static func on_value_changed(
	new_value: float,
	catalog_gear: GearData,
	property: String,
	is_refreshing: Callable,
	store_value: Callable,
	apply_live: Callable,
	sync_spin_display: Callable,
	refresh_status: Callable
) -> void:
	if is_refreshing.call() or catalog_gear == null:
		return
	store_value.call(catalog_gear, property, new_value)
	apply_live.call(catalog_gear)
	sync_spin_display.call(property, catalog_gear)
	refresh_status.call(catalog_gear)


static func sync_spin_display(
	property: String,
	catalog_gear: GearData,
	spin_rows: Array[Dictionary],
	gear_snapshots: TestArenaGearSnapshot,
	set_refreshing: Callable
) -> void:
	var gear_id := catalog_gear.get_unique_key()
	var tuned_mods := gear_snapshots.build_tuned_stat_modifiers(gear_id)
	for row in spin_rows:
		if row.get("property") != property:
			continue
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			return
		set_refreshing.call(true)
		spin.value = gear_snapshots.get_tuning_spin_display_value(tuned_mods, property)
		set_refreshing.call(false)
		return


static func refresh_status_only(
	catalog_gear: GearData,
	status_label: Label,
	is_equipped: Callable,
	gear_snapshots: TestArenaGearSnapshot
) -> void:
	var gear_id := catalog_gear.get_unique_key()
	var status_parts: PackedStringArray = []
	if gear_snapshots.has_saved_snapshot(gear_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not gear_snapshots.get_session_overrides(gear_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if is_equipped.call(catalog_gear):
		status_parts.append("장착 중 — 값 변경 시 즉시 반영")
	status_label.text = " · ".join(status_parts) if not status_parts.is_empty() else "카탈로그 기본값"


static func commit_and_apply_from_spins(
	get_selected_gear: Callable,
	spin_rows: Array[Dictionary],
	commit_spin_box_pending: Callable,
	store_value: Callable,
	apply_live: Callable
) -> void:
	var catalog_gear: GearData = get_selected_gear.call()
	if catalog_gear == null:
		return
	for row in spin_rows:
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			continue
		commit_spin_box_pending.call(spin)
		var property: String = row.get("property", "")
		if property.is_empty():
			continue
		store_value.call(catalog_gear, property, spin.value)
	apply_live.call(catalog_gear)
