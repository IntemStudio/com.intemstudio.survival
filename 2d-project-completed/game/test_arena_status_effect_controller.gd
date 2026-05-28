class_name TestArenaStatusEffectController
extends RefCounted

## 테스트 아레나 상태이상 탭/튜닝 UI 제어 컨트롤러.

const TestArenaTuningUiUtil = preload("res://game/test_arena_tuning_ui.gd")

const POISON_STATUS_ID := &"poison"
const STATUS_POISON_LOCKED_PROPERTIES := {
	"duration_seconds": true,
	"tick_damage_min": true,
	"tick_damage_max": true,
	"tick_interval": true,
}

var _status_effect_snapshots: TestArenaStatusEffectSnapshot
var _get_active_mob: Callable
var _get_selected_offhand_status_ids: Callable
var _update_status: Callable
var _test_tab_index_status_effect := 0
var _tuning_spin_button_size := Vector2.ZERO
var _tuning_spin_min_height := 0
var _tuning_spin_button_font_size := 0
var _tuning_spin_value_font_size := 0

var _test_panels_tab: TabContainer
var _status_effect_option: OptionButton
var _status_effect_nav_label: Label
var _status_effect_rule_hint_label: Label
var _status_effect_tuning_fields: VBoxContainer
var _status_effect_tuning_status_label: Label
var _apply_status_effect_tuning_button: Button
var _save_status_effect_tuning_button: Button
var _reset_status_effect_tuning_button: Button

var _status_effect_tuning_spin_rows: Array[Dictionary] = []
var _status_effect_tuning_ui_refreshing := false


func configure(
	status_effect_snapshots: TestArenaStatusEffectSnapshot,
	get_active_mob: Callable,
	get_selected_offhand_status_ids: Callable,
	update_status: Callable,
	test_tab_index_status_effect: int,
	tuning_spin_button_size: Vector2,
	tuning_spin_min_height: int,
	tuning_spin_button_font_size: int,
	tuning_spin_value_font_size: int,
	test_panels_tab: TabContainer,
	status_effect_option: OptionButton,
	status_effect_nav_label: Label,
	status_effect_rule_hint_label: Label,
	status_effect_tuning_fields: VBoxContainer,
	status_effect_tuning_status_label: Label,
	apply_status_effect_tuning_button: Button,
	save_status_effect_tuning_button: Button,
	reset_status_effect_tuning_button: Button
) -> void:
	_status_effect_snapshots = status_effect_snapshots
	_get_active_mob = get_active_mob
	_get_selected_offhand_status_ids = get_selected_offhand_status_ids
	_update_status = update_status
	_test_tab_index_status_effect = test_tab_index_status_effect
	_tuning_spin_button_size = tuning_spin_button_size
	_tuning_spin_min_height = tuning_spin_min_height
	_tuning_spin_button_font_size = tuning_spin_button_font_size
	_tuning_spin_value_font_size = tuning_spin_value_font_size
	_test_panels_tab = test_panels_tab
	_status_effect_option = status_effect_option
	_status_effect_nav_label = status_effect_nav_label
	_status_effect_rule_hint_label = status_effect_rule_hint_label
	_status_effect_tuning_fields = status_effect_tuning_fields
	_status_effect_tuning_status_label = status_effect_tuning_status_label
	_apply_status_effect_tuning_button = apply_status_effect_tuning_button
	_save_status_effect_tuning_button = save_status_effect_tuning_button
	_reset_status_effect_tuning_button = reset_status_effect_tuning_button


func setup_tuning_ui() -> void:
	_clear_status_effect_tuning_fields()
	_apply_status_effect_tuning_button.disabled = true
	_save_status_effect_tuning_button.disabled = true
	_reset_status_effect_tuning_button.disabled = true
	_status_effect_tuning_status_label.text = "장비 탭에서 상태이상을 선택하세요."


func on_status_effect_option_selected(_index: int) -> void:
	if _status_effect_tuning_ui_refreshing:
		return
	refresh_status_effect_tuning_ui()


func refresh_status_tab_options(status_ids: Array[StringName], preferred_status_id: StringName) -> void:
	_status_effect_tuning_ui_refreshing = true
	_status_effect_option.clear()
	if status_ids.is_empty():
		_status_effect_nav_label.text = "장비 탭에서 상태이상 수정을 선택하세요."
		_status_effect_rule_hint_label.text = ""
		_status_effect_tuning_ui_refreshing = false
		refresh_status_effect_tuning_ui()
		return
	var selected_index := 0
	for i in status_ids.size():
		var status_id := status_ids[i]
		_status_effect_option.add_item(StatusEffectCatalog.get_display_name(status_id))
		_status_effect_option.set_item_metadata(i, status_id)
		if preferred_status_id != &"" and status_id == preferred_status_id:
			selected_index = i
	_status_effect_option.select(selected_index)
	var selected_id := StringName(_status_effect_option.get_item_metadata(selected_index))
	_status_effect_nav_label.text = "선택됨: %s" % StatusEffectCatalog.get_display_name(selected_id)
	_status_effect_rule_hint_label.text = _build_status_rule_hint(selected_id)
	_status_effect_tuning_ui_refreshing = false
	refresh_status_effect_tuning_ui()


func open_status_tab_with_status(status_id: StringName) -> void:
	var status_ids: Array[StringName] = _get_selected_offhand_status_ids.call()
	refresh_status_tab_options(status_ids, status_id)
	_test_panels_tab.current_tab = _test_tab_index_status_effect
	var selected_label := StatusEffectCatalog.get_display_name(status_id)
	_status_effect_nav_label.text = "선택됨: %s" % selected_label


func on_apply_status_effect_tuning_pressed() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	_commit_and_apply_status_effect_tuning_from_spins()
	refresh_status_effect_tuning_ui()
	_update_status.call("상태이상 튜닝 적용: %s" % StatusEffectCatalog.get_display_name(status_id))


func on_save_status_effect_tuning_pressed() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	_commit_and_apply_status_effect_tuning_from_spins()
	_status_effect_snapshots.save_status(status_id)
	refresh_status_effect_tuning_ui()
	_update_status.call("상태이상 스냅샷 저장: %s" % StatusEffectCatalog.get_display_name(status_id))


func on_reset_status_effect_tuning_pressed() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	_status_effect_snapshots.reset_status(status_id)
	refresh_status_effect_tuning_ui()
	_update_status.call("상태이상 스냅샷 초기화: %s" % StatusEffectCatalog.get_display_name(status_id))


func get_selected_status_effect_id() -> StringName:
	return _get_selected_status_effect_id()


func build_status_rule_hint(status_id: StringName) -> String:
	return _build_status_rule_hint(status_id)


func refresh_status_effect_tuning_ui() -> void:
	_clear_status_effect_tuning_fields()
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		_status_effect_tuning_status_label.text = "장비 탭에서 상태이상을 선택하세요."
		_apply_status_effect_tuning_button.disabled = true
		_save_status_effect_tuning_button.disabled = true
		_reset_status_effect_tuning_button.disabled = true
		return
	if not _status_effect_snapshots.supports_status_tuning(status_id):
		_status_effect_tuning_status_label.text = "이 상태이상은 튜닝을 지원하지 않습니다."
		_apply_status_effect_tuning_button.disabled = true
		_save_status_effect_tuning_button.disabled = true
		_reset_status_effect_tuning_button.disabled = true
		return
	var tuned := _status_effect_snapshots.build_tuned_values(status_id)
	var field_defs := _status_effect_snapshots.get_field_defs(status_id)
	_status_effect_tuning_ui_refreshing = true
	for field_def in field_defs:
		_add_status_effect_tuning_row(status_id, field_def, tuned)
	_status_effect_tuning_ui_refreshing = false
	_refresh_status_effect_tuning_status_only(status_id)
	_apply_status_effect_tuning_button.disabled = false
	_save_status_effect_tuning_button.disabled = false
	_reset_status_effect_tuning_button.disabled = false


func _clear_status_effect_tuning_fields() -> void:
	for child in _status_effect_tuning_fields.get_children():
		_status_effect_tuning_fields.remove_child(child)
		child.free()
	_status_effect_tuning_spin_rows.clear()


func _add_status_effect_tuning_row(status_id: StringName, field_def: Dictionary, tuned: Dictionary) -> void:
	var property: String = field_def["property"]
	var initial_value := float(tuned.get(property, 0.0))
	var row := TestArenaTuningUiUtil.create_tuning_row(
		_status_effect_tuning_fields,
		field_def,
		initial_value,
		_on_status_effect_tuning_value_changed.bind(status_id, property),
		_on_status_effect_tuning_spin_tree_entered.bind(status_id, property),
		func(spin: SpinBox, direction: int) -> void:
			_on_status_effect_tuning_step_pressed(spin, status_id, property, direction),
		_tuning_spin_button_size,
		_tuning_spin_button_font_size,
		_tuning_spin_min_height
	)
	_apply_status_effect_tuning_row_lock_state(status_id, property, row)
	_status_effect_tuning_spin_rows.append(row)


func _on_status_effect_tuning_spin_tree_entered(
	spin: SpinBox,
	status_id: StringName,
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
			_on_status_effect_tuning_value_changed(new_value, status_id, property)
	)


func _on_status_effect_tuning_step_pressed(
	spin: SpinBox,
	status_id: StringName,
	property: String,
	direction: int
) -> void:
	_on_status_effect_tuning_value_changed(
		spin.value + spin.step * float(direction),
		status_id,
		property
	)


func _on_status_effect_tuning_value_changed(
	new_value: float,
	status_id: StringName,
	property: String
) -> void:
	if _status_effect_tuning_ui_refreshing:
		return
	_store_status_effect_tuning_value(status_id, property, new_value)
	_apply_status_effect_tuning_live(status_id)
	_sync_status_effect_tuning_spin_display(status_id, property)
	_refresh_status_effect_tuning_status_only(status_id)


func _store_status_effect_tuning_value(status_id: StringName, property: String, new_value: float) -> void:
	var stored: Variant = new_value
	for field_def in _status_effect_snapshots.get_field_defs(status_id):
		if field_def.get("property") != property:
			continue
		if bool(field_def.get("integer", false)):
			stored = int(roundf(new_value))
		break
	_status_effect_snapshots.set_session_value(status_id, property, stored)


func _apply_status_effect_tuning_live(status_id: StringName) -> void:
	_status_effect_snapshots.apply_to_catalog(status_id)
	var active_mob: Mob = _get_active_mob.call()
	if active_mob != null and is_instance_valid(active_mob):
		# 수치 변경 시 활성 효과의 남은 지속시간은 유지합니다.
		active_mob.refresh_status_effect_profiles(status_id, false)


func _sync_status_effect_tuning_spin_display(status_id: StringName, property: String) -> void:
	var tuned := _status_effect_snapshots.build_tuned_values(status_id)
	for row in _status_effect_tuning_spin_rows:
		if row.get("property") != property:
			continue
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			return
		_status_effect_tuning_ui_refreshing = true
		spin.value = float(tuned.get(property, 0.0))
		_status_effect_tuning_ui_refreshing = false
		return


func _refresh_status_effect_tuning_status_only(status_id: StringName) -> void:
	var status_parts: PackedStringArray = []
	if _status_effect_snapshots.has_saved_snapshot(status_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _status_effect_snapshots.get_session_overrides(status_id).is_empty():
		status_parts.append("미저장 변경 있음")
	_status_effect_tuning_status_label.text = (
		" · ".join(status_parts)
		if not status_parts.is_empty()
		else "카탈로그 기본값"
	)
	_status_effect_rule_hint_label.text = _build_status_rule_hint(status_id)


func _commit_and_apply_status_effect_tuning_from_spins() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	for row in _status_effect_tuning_spin_rows:
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			continue
		TestArenaTuningUiUtil.commit_spin_box_pending(spin)
		var property: String = row.get("property", "")
		if property.is_empty():
			continue
		_store_status_effect_tuning_value(status_id, property, spin.value)
	_apply_status_effect_tuning_live(status_id)


func _get_selected_status_effect_id() -> StringName:
	if _status_effect_option.get_item_count() <= 0 or _status_effect_option.selected < 0:
		return &""
	return StringName(_status_effect_option.get_item_metadata(_status_effect_option.selected))


func _apply_status_effect_tuning_row_lock_state(
	status_id: StringName,
	property: String,
	row: Dictionary
) -> void:
	var spin: SpinBox = row.get("spin")
	var dec_button: Button = row.get("dec_button")
	var inc_button: Button = row.get("inc_button")
	var is_locked := _is_status_effect_property_locked(status_id, property)
	if is_instance_valid(spin):
		spin.editable = not is_locked
		var lock_color := Color(0.95, 0.82, 0.38, 1.0) if is_locked else Color.WHITE
		spin.add_theme_color_override("font_color", lock_color)
		var line_edit := spin.get_line_edit()
		if line_edit:
			line_edit.add_theme_color_override("font_color", lock_color)
	if is_instance_valid(dec_button):
		dec_button.disabled = is_locked
	if is_instance_valid(inc_button):
		inc_button.disabled = is_locked


func _is_status_effect_property_locked(status_id: StringName, property: String) -> bool:
	if status_id != POISON_STATUS_ID:
		return false
	return STATUS_POISON_LOCKED_PROPERTIES.has(property)


func _build_status_rule_hint(status_id: StringName) -> String:
	if status_id == POISON_STATUS_ID:
		return "독은 무기 source 기준 지속/틱을 우선 사용합니다(잠금 필드 참고)."
	return ""
