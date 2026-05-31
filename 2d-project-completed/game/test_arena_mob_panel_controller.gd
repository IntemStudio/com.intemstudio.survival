class_name TestArenaMobPanelController
extends RefCounted

## 테스트 아레나 몹 패널(선택/설명/전투 튜닝 UI) 제어 컨트롤러.

const CHASE_MODE_LABELS: Array[String] = ["직선 추격", "포위 추격"]
const CHASE_MODE_PROPERTY := "chase_mode"

var _mob_snapshots: TestArenaMobSnapshot
var _update_status: Callable
var _get_test_mob_hp_multiplier: Callable
var _apply_mob_tuning_live: Callable
var _is_selected_scene_active: Callable
var _on_tuning_spin_tree_entered: Callable
var _wire_spin_box_text_commit: Callable
var _commit_spin_box_pending: Callable

var _mob_options: Array[Dictionary] = []
var _mob_kind_labels_ko: Dictionary = {}
var _mob_role_hints_ko: Dictionary = {}
var _mob_tuning_color_default := Color(0.78, 0.78, 0.82, 1.0)
var _mob_tuning_color_saved := Color(0.55, 0.75, 0.95, 1.0)
var _mob_tuning_color_session := Color(0.95, 0.82, 0.38, 1.0)

var _mob_combat_field_defs: Array = []
var _mob_death_burst_field_defs: Array = []
var _mob_charge_field_defs: Array = []
var _mob_chase_skill_field_defs: Array = []
var _mob_tuning_ui_refreshing := false

var _mob_type_option: OptionButton
var _mob_desc_label: RichTextLabel
var _mob_combat_tuning_status_label: Label
var _mob_combat_spins: Array[SpinBox] = []
var _mob_combat_step_buttons: Array[Button] = []
var _mob_combat_field_labels: Array[Label] = []
var _apply_mob_combat_tuning_button: Button
var _save_mob_combat_tuning_button: Button
var _reset_mob_combat_tuning_button: Button
var _mob_death_burst_section: Control
var _mob_death_burst_spins: Array[SpinBox] = []
var _mob_death_burst_step_buttons: Array[Button] = []
var _mob_death_burst_field_labels: Array[Label] = []
var _mob_charge_section: Control
var _mob_charge_spins: Array[SpinBox] = []
var _mob_charge_step_buttons: Array[Button] = []
var _mob_charge_field_labels: Array[Label] = []
var _mob_chase_skill_section: Control
var _mob_chase_skill_spins: Array[SpinBox] = []
var _mob_chase_skill_step_buttons: Array[Button] = []
var _mob_chase_skill_field_labels: Array[Label] = []
var _mob_chase_mode_label: Label
var _mob_chase_mode_option: OptionButton


func configure(
	mob_snapshots: TestArenaMobSnapshot,
	update_status: Callable,
	get_test_mob_hp_multiplier: Callable,
	apply_mob_tuning_live: Callable,
	is_selected_scene_active: Callable,
	on_tuning_spin_tree_entered: Callable,
	wire_spin_box_text_commit: Callable,
	commit_spin_box_pending: Callable,
	mob_options: Array[Dictionary],
	mob_kind_labels_ko: Dictionary,
	mob_role_hints_ko: Dictionary,
	mob_tuning_color_default: Color,
	mob_tuning_color_saved: Color,
	mob_tuning_color_session: Color,
	mob_type_option: OptionButton,
	mob_desc_label: RichTextLabel,
	mob_combat_tuning_status_label: Label,
	mob_combat_spins: Array[SpinBox],
	mob_combat_step_buttons: Array[Button],
	mob_combat_field_labels: Array[Label],
	apply_mob_combat_tuning_button: Button,
	save_mob_combat_tuning_button: Button,
	reset_mob_combat_tuning_button: Button,
	mob_death_burst_section: Control,
	mob_death_burst_spins: Array[SpinBox],
	mob_death_burst_step_buttons: Array[Button],
	mob_death_burst_field_labels: Array[Label],
	mob_charge_section: Control,
	mob_charge_spins: Array[SpinBox],
	mob_charge_step_buttons: Array[Button],
	mob_charge_field_labels: Array[Label],
	mob_chase_skill_section: Control,
	mob_chase_skill_spins: Array[SpinBox],
	mob_chase_skill_step_buttons: Array[Button],
	mob_chase_skill_field_labels: Array[Label],
	mob_chase_mode_label: Label,
	mob_chase_mode_option: OptionButton
) -> void:
	_mob_snapshots = mob_snapshots
	_update_status = update_status
	_get_test_mob_hp_multiplier = get_test_mob_hp_multiplier
	_apply_mob_tuning_live = apply_mob_tuning_live
	_is_selected_scene_active = is_selected_scene_active
	_on_tuning_spin_tree_entered = on_tuning_spin_tree_entered
	_wire_spin_box_text_commit = wire_spin_box_text_commit
	_commit_spin_box_pending = commit_spin_box_pending
	_mob_options = mob_options
	_mob_kind_labels_ko = mob_kind_labels_ko
	_mob_role_hints_ko = mob_role_hints_ko
	_mob_tuning_color_default = mob_tuning_color_default
	_mob_tuning_color_saved = mob_tuning_color_saved
	_mob_tuning_color_session = mob_tuning_color_session
	_mob_type_option = mob_type_option
	_mob_desc_label = mob_desc_label
	_mob_combat_tuning_status_label = mob_combat_tuning_status_label
	_mob_combat_spins = mob_combat_spins
	_mob_combat_step_buttons = mob_combat_step_buttons
	_mob_combat_field_labels = mob_combat_field_labels
	_apply_mob_combat_tuning_button = apply_mob_combat_tuning_button
	_save_mob_combat_tuning_button = save_mob_combat_tuning_button
	_reset_mob_combat_tuning_button = reset_mob_combat_tuning_button
	_mob_death_burst_section = mob_death_burst_section
	_mob_death_burst_spins = mob_death_burst_spins
	_mob_death_burst_step_buttons = mob_death_burst_step_buttons
	_mob_death_burst_field_labels = mob_death_burst_field_labels
	_mob_charge_section = mob_charge_section
	_mob_charge_spins = mob_charge_spins
	_mob_charge_step_buttons = mob_charge_step_buttons
	_mob_charge_field_labels = mob_charge_field_labels
	_mob_chase_skill_section = mob_chase_skill_section
	_mob_chase_skill_spins = mob_chase_skill_spins
	_mob_chase_skill_step_buttons = mob_chase_skill_step_buttons
	_mob_chase_skill_field_labels = mob_chase_skill_field_labels
	_mob_chase_mode_label = mob_chase_mode_label
	_mob_chase_mode_option = mob_chase_mode_option


func setup_mob_type_option() -> void:
	_mob_type_option.clear()
	for entry in _mob_options:
		_mob_type_option.add_item(entry["label"])
	update_mob_description()
	refresh_mob_combat_tuning_ui()


func on_mob_type_option_selected(_index: int) -> void:
	update_mob_description()
	refresh_mob_combat_tuning_ui()


func get_selected_mob_scene(default_scene: PackedScene) -> PackedScene:
	var index: int = _mob_type_option.selected
	if index < 0 or index >= _mob_options.size():
		return default_scene
	return _mob_options[index]["scene"] as PackedScene


func setup_mob_combat_tuning_ui() -> void:
	for spin_index in _mob_combat_spins.size():
		var spin: SpinBox = _mob_combat_spins[spin_index]
		spin.add_theme_constant_override("updown_width", 0)
		spin.value_changed.connect(_on_mob_combat_spin_changed.bind(spin_index))
		spin.tree_entered.connect(_on_mob_combat_spin_tree_entered.bind(spin_index, spin), CONNECT_ONE_SHOT)
	for spin_index in _mob_combat_spins.size():
		var dec_index := spin_index * 2
		var inc_index := dec_index + 1
		if inc_index >= _mob_combat_step_buttons.size():
			break
		_mob_combat_step_buttons[dec_index].pressed.connect(
			_on_mob_combat_step_pressed.bind(spin_index, -1)
		)
		_mob_combat_step_buttons[inc_index].pressed.connect(
			_on_mob_combat_step_pressed.bind(spin_index, 1)
		)
	for burst_index in _mob_death_burst_spins.size():
		var burst_spin: SpinBox = _mob_death_burst_spins[burst_index]
		burst_spin.add_theme_constant_override("updown_width", 0)
		burst_spin.value_changed.connect(_on_mob_death_burst_spin_changed.bind(burst_index))
		burst_spin.tree_entered.connect(_on_mob_death_burst_spin_tree_entered.bind(burst_index, burst_spin), CONNECT_ONE_SHOT)
	_mob_death_burst_step_buttons[0].pressed.connect(_on_mob_death_burst_step_pressed.bind(0, -1))
	_mob_death_burst_step_buttons[1].pressed.connect(_on_mob_death_burst_step_pressed.bind(0, 1))
	_mob_death_burst_step_buttons[2].pressed.connect(_on_mob_death_burst_step_pressed.bind(1, -1))
	_mob_death_burst_step_buttons[3].pressed.connect(_on_mob_death_burst_step_pressed.bind(1, 1))
	_mob_death_burst_step_buttons[4].pressed.connect(_on_mob_death_burst_step_pressed.bind(2, -1))
	_mob_death_burst_step_buttons[5].pressed.connect(_on_mob_death_burst_step_pressed.bind(2, 1))
	_mob_charge_spins[0].add_theme_constant_override("updown_width", 0)
	_mob_charge_spins[0].value_changed.connect(_on_mob_charge_spin_changed.bind(0))
	_mob_charge_spins[0].tree_entered.connect(_on_mob_charge_spin_tree_entered.bind(0, _mob_charge_spins[0]), CONNECT_ONE_SHOT)
	_mob_charge_step_buttons[0].pressed.connect(_on_mob_charge_step_pressed.bind(0, -1))
	_mob_charge_step_buttons[1].pressed.connect(_on_mob_charge_step_pressed.bind(0, 1))
	for chase_skill_index in _mob_chase_skill_spins.size():
		var chase_skill_spin: SpinBox = _mob_chase_skill_spins[chase_skill_index]
		chase_skill_spin.add_theme_constant_override("updown_width", 0)
		chase_skill_spin.value_changed.connect(
			_on_mob_chase_skill_spin_changed.bind(chase_skill_index)
		)
		chase_skill_spin.tree_entered.connect(
			_on_mob_chase_skill_spin_tree_entered.bind(chase_skill_index, chase_skill_spin),
			CONNECT_ONE_SHOT
		)
	for button_index in _mob_chase_skill_step_buttons.size():
		var chase_skill_index := button_index >> 1
		var direction := -1 if button_index % 2 == 0 else 1
		_mob_chase_skill_step_buttons[button_index].pressed.connect(
			_on_mob_chase_skill_step_pressed.bind(chase_skill_index, direction)
		)
	_mob_chase_mode_option.item_selected.connect(_on_mob_chase_mode_selected)
	_populate_mob_chase_mode_dropdown()
	refresh_mob_combat_tuning_ui()


func on_apply_mob_combat_tuning_pressed() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	_commit_and_apply_mob_tuning_from_spins()
	var label: String = _mob_options[_mob_type_option.selected]["label"]
	_update_status.call("몹 전투 튜닝 적용: %s" % label)
	refresh_mob_combat_tuning_ui()
	update_mob_description()


func on_save_mob_combat_tuning_pressed() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	_commit_and_apply_mob_tuning_from_spins()
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	var label: String = _mob_options[_mob_type_option.selected]["label"]
	if not _mob_snapshots.save_mob(scene_id):
		_update_status.call(_format_mob_persistence_failure("저장", label))
		return
	_update_status.call("몹 전투 스냅샷 저장: %s" % label)
	_apply_mob_tuning_live.call(scene)
	refresh_mob_combat_tuning_ui()


func on_reset_mob_combat_tuning_pressed() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.reset_mob(scene_id)
	var label: String = _mob_options[_mob_type_option.selected]["label"]
	_update_status.call("몹 전투 튜닝 되돌리기: %s" % label)
	_apply_mob_tuning_live.call(scene)
	refresh_mob_combat_tuning_ui()
	update_mob_description()


func update_mob_description() -> void:
	_mob_desc_label.text = build_mob_info_bbcode(get_selected_mob_scene(null))


func build_mob_info_bbcode(scene: PackedScene) -> String:
	if scene == null:
		return "몹 정보를 불러올 수 없습니다."
	var mob := scene.instantiate() as Mob
	if mob == null:
		return "몹 정보를 불러올 수 없습니다."
	_mob_snapshots.apply_to_mob(mob, scene)
	var hp_mult := float(_get_test_mob_hp_multiplier.call(scene, mob))
	var test_hp := maxi(1, roundi(float(mob.base_max_health) * maxf(hp_mult, 0.01)))
	var kind_label: String = _mob_kind_labels_ko.get(mob.mob_kind, str(mob.mob_kind))
	var role_hint: String = _mob_role_hints_ko.get(mob.mob_kind, "")
	var rewards := KillRewards.compute(mob.mob_kind, null)
	var lines: PackedStringArray = []
	lines.append("[color=#ffdd55]%s[/color] · %s" % [kind_label, mob.mob_kind])
	if not role_hint.is_empty():
		lines.append(role_hint)
	lines.append("체력: %d (프리팹) → %d (F6 스폰)" % [mob.base_max_health, test_hp])
	lines.append("이동 속도: %.0f~%.0f" % [mob.speed_min, mob.speed_max])
	lines.append("추격 방식: %s" % _get_chase_mode_label(int(mob.chase_mode)))
	if not mob.movement_enabled:
		lines.append("[color=#a9a9b0]이동 없음[/color]")
	if not mob.combat_enabled:
		lines.append("[color=#a9a9b0]전투 없음[/color]")
	elif mob.ranged_attack_enabled:
		lines.append("예고: %.1fs" % mob.ranged_telegraph_delay)
	if mob.death_burst_enabled and not _mob_snapshots.supports_death_burst_tuning(scene) and not _mob_snapshots.supports_charge_tuning(scene):
		var burst_line := "사망 폭발: 반경 %.0f · %d 피해" % [mob.death_burst_radius, mob.death_burst_damage]
		if mob.death_burst_delay > 0.0:
			burst_line += " · %.1fs 후" % mob.death_burst_delay
		lines.append(burst_line)
	if mob.charge_attack_enabled:
		lines.append("돌진 발동 거리: %.0f" % mob.charge_trigger_distance)
		if not _mob_snapshots.supports_charge_tuning(scene):
			var travel := mob.speed * mob.charge_speed_mult * mob.charge_duration
			lines.append("돌진 거리(참고): %.0f · ×%.1f 속도 · %.2fs" % [travel, mob.charge_speed_mult, mob.charge_duration])
		if mob.charge_end_burst_radius > 0.0:
			lines.append("돌진 종료 폭발: 반경 %.0f · %d 피해" % [mob.charge_end_burst_radius, mob.charge_end_burst_damage])
	if mob.jump_chase_enabled:
		lines.append("점프 추격: 발동 %.0f · 예고 %.1fs · 거리 %.0f · 높이 %.0f" % [
			mob.jump_chase_trigger_distance,
			mob.jump_chase_windup_delay,
			mob.jump_chase_travel_distance,
			mob.jump_chase_arc_height,
		])
		if mob.jump_chase_landing_burst_radius > 0.0 or mob.jump_chase_landing_burst_damage > 0:
			lines.append(
				"착지 burst: 반경 %.0f · %d 피해"
				% [mob.jump_chase_landing_burst_radius, mob.jump_chase_landing_burst_damage]
			)
	if mob.self_destruct_enabled:
		lines.append("자폭: 체력 %.0f%% 이하" % (mob.self_destruct_health_ratio * 100.0))
	if int(rewards.get("xp", 0)) > 0:
		lines.append("처치 보상(기본): XP %d · 골드 %d" % [rewards["xp"], rewards["gold"]])
	else:
		lines.append("[color=#a9a9b0]처치 보상 없음[/color]")
	mob.free()
	return "\n".join(lines)


func refresh_mob_combat_tuning_ui() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null or not _mob_snapshots.supports_combat_tuning(scene):
		_mob_combat_field_defs.clear()
		_mob_death_burst_field_defs.clear()
		_mob_charge_field_defs.clear()
		_mob_chase_skill_field_defs.clear()
		_mob_combat_tuning_status_label.text = "몹 정보를 불러올 수 없습니다."
		_set_mob_combat_tuning_enabled(false)
		_set_mob_combat_row_visibility(0)
		_set_mob_death_burst_tuning_enabled(false)
		_set_mob_charge_tuning_enabled(false)
		_set_mob_chase_skill_tuning_enabled(false)
		_set_mob_action_buttons_enabled(false, false, false)
		return
	_mob_combat_field_defs = _mob_snapshots.get_field_defs(scene)
	_mob_tuning_ui_refreshing = true
	var field_count := mini(_mob_combat_field_defs.size(), _mob_combat_spins.size())
	for spin_index in field_count:
		var field_def: Dictionary = _mob_combat_field_defs[spin_index]
		var spin: SpinBox = _mob_combat_spins[spin_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_set_mob_combat_row_visibility(field_count)
	_refresh_mob_death_burst_tuning_ui(scene)
	_refresh_mob_charge_tuning_ui(scene)
	_refresh_mob_chase_skill_tuning_ui(scene)
	_sync_mob_chase_mode_dropdown(scene)
	_refresh_mob_tuning_field_styles(scene)
	_refresh_mob_combat_tuning_status_only(scene)
	_set_mob_combat_tuning_enabled(true)
	_refresh_mob_action_buttons(scene)


func _set_mob_combat_tuning_enabled(enabled: bool) -> void:
	for spin_index in _mob_combat_spins.size():
		var spin: SpinBox = _mob_combat_spins[spin_index]
		var row := spin.get_parent() as CanvasItem
		var row_visible := row == null or row.visible
		spin.editable = enabled and row_visible
	for button_index in _mob_combat_step_buttons.size():
		var spin_index := button_index >> 1
		var row_visible := true
		if spin_index < _mob_combat_spins.size():
			var row := _mob_combat_spins[spin_index].get_parent() as CanvasItem
			row_visible = row == null or row.visible
		_mob_combat_step_buttons[button_index].disabled = not enabled or not row_visible
	if _mob_chase_mode_option:
		_mob_chase_mode_option.disabled = not enabled
	if not enabled:
		_set_mob_action_buttons_enabled(false, false, false)


func _set_mob_action_buttons_enabled(
	apply_enabled: bool,
	save_enabled: bool,
	reset_enabled: bool
) -> void:
	_apply_mob_combat_tuning_button.disabled = not apply_enabled
	_save_mob_combat_tuning_button.disabled = not save_enabled
	_reset_mob_combat_tuning_button.disabled = not reset_enabled


# 스핀 미반영·세션 여부에 따라 적용/저장/되돌리기 버튼을 켭니다.
func _refresh_mob_action_buttons(scene: PackedScene) -> void:
	if scene == null or not _mob_snapshots.supports_combat_tuning(scene):
		_set_mob_action_buttons_enabled(false, false, false)
		return
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	var has_session := _mob_snapshots.has_unsaved_session_changes(scene_id)
	var has_pending := _has_pending_spin_changes(scene)
	_set_mob_action_buttons_enabled(
		has_pending,
		has_pending or has_session,
		has_pending or has_session
	)


func _has_pending_spin_changes(scene: PackedScene) -> bool:
	var field_count := mini(_mob_combat_field_defs.size(), _mob_combat_spins.size())
	for spin_index in field_count:
		if not _spin_matches_tuned_value(scene, _mob_combat_spins[spin_index], _mob_combat_field_defs[spin_index]):
			return true
	for burst_index in _mob_death_burst_field_defs.size():
		if not _spin_matches_tuned_value(
			scene, _mob_death_burst_spins[burst_index], _mob_death_burst_field_defs[burst_index]
		):
			return true
	for charge_index in _mob_charge_field_defs.size():
		if not _spin_matches_tuned_value(
			scene, _mob_charge_spins[charge_index], _mob_charge_field_defs[charge_index]
		):
			return true
	for chase_skill_index in _mob_chase_skill_field_defs.size():
		if not _spin_matches_tuned_value(
			scene,
			_mob_chase_skill_spins[chase_skill_index],
			_mob_chase_skill_field_defs[chase_skill_index]
		):
			return true
	if not _chase_mode_matches_tuned_value(scene):
		return true
	return false


func _spin_matches_tuned_value(scene: PackedScene, spin: SpinBox, field_def: Dictionary) -> bool:
	var property: String = field_def["property"]
	return is_equal_approx(spin.value, _mob_snapshots.get_tuned_value(scene, property))


func _set_mob_death_burst_tuning_enabled(enabled: bool) -> void:
	_mob_death_burst_section.visible = enabled
	for spin in _mob_death_burst_spins:
		spin.editable = enabled
	for button in _mob_death_burst_step_buttons:
		button.disabled = not enabled


func _set_mob_charge_tuning_enabled(enabled: bool) -> void:
	_mob_charge_section.visible = enabled
	for spin in _mob_charge_spins:
		spin.editable = enabled
	for button in _mob_charge_step_buttons:
		button.disabled = not enabled


func _set_mob_chase_skill_tuning_enabled(enabled: bool, detail_enabled: bool = enabled) -> void:
	_mob_chase_skill_section.visible = enabled
	for spin_index in _mob_chase_skill_spins.size():
		var spin: SpinBox = _mob_chase_skill_spins[spin_index]
		var row := spin.get_parent() as CanvasItem
		var row_visible := row == null or row.visible
		var row_editable := enabled and row_visible and (spin_index == 0 or detail_enabled)
		spin.editable = row_editable
	for button_index in _mob_chase_skill_step_buttons.size():
		var spin_index := button_index >> 1
		var row_visible := true
		if spin_index < _mob_chase_skill_spins.size():
			var row := _mob_chase_skill_spins[spin_index].get_parent() as CanvasItem
			row_visible = row == null or row.visible
		var button_enabled := enabled and row_visible and (spin_index == 0 or detail_enabled)
		_mob_chase_skill_step_buttons[button_index].disabled = not button_enabled


func _set_mob_chase_skill_row_visibility(active_field_count: int) -> void:
	for spin_index in _mob_chase_skill_spins.size():
		var row := _mob_chase_skill_spins[spin_index].get_parent() as CanvasItem
		if row:
			row.visible = spin_index < active_field_count


func _is_chase_skill_detail_enabled(_scene: PackedScene) -> bool:
	if _mob_chase_skill_spins.is_empty():
		return false
	return int(_mob_chase_skill_spins[0].value) != 0


func _set_mob_combat_row_visibility(active_field_count: int) -> void:
	for spin_index in _mob_combat_spins.size():
		var row := _mob_combat_spins[spin_index].get_parent() as CanvasItem
		if row:
			row.visible = spin_index < active_field_count


func _configure_mob_combat_spin(spin: SpinBox, field_def: Dictionary) -> void:
	spin.min_value = float(field_def.get("min", 0.0))
	spin.max_value = float(field_def.get("max", 9999.0))
	spin.step = float(field_def.get("step", 1.0))
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.rounded = spin.step >= 1.0


func _apply_mob_tuning_field_style(label: Label, spin: SpinBox, scene: PackedScene, field_def: Dictionary) -> void:
	var property: String = field_def["property"]
	var base_label: String = str(field_def.get("label", property))
	var tuned_value := _mob_snapshots.get_tuned_value(scene, property)
	var is_pending := not is_equal_approx(spin.value, tuned_value)
	var color := _mob_tuning_color_default
	var suffix := ""
	if is_pending:
		color = _mob_tuning_color_session
		suffix = " *"
	else:
		var state := _mob_snapshots.get_property_tuning_state(scene, property)
		if state == TestArenaMobSnapshot.TUNING_STATE_SAVED:
			color = _mob_tuning_color_saved
		elif state == TestArenaMobSnapshot.TUNING_STATE_SESSION:
			color = _mob_tuning_color_session
			suffix = " *"
	label.text = base_label + suffix
	label.add_theme_color_override("font_color", color)
	spin.add_theme_color_override("font_color", color)
	var line_edit := spin.get_line_edit()
	if line_edit:
		line_edit.add_theme_color_override("font_color", color)


func _refresh_mob_tuning_field_styles(scene: PackedScene) -> void:
	for i in mini(_mob_combat_field_labels.size(), _mob_combat_field_defs.size()):
		_apply_mob_tuning_field_style(_mob_combat_field_labels[i], _mob_combat_spins[i], scene, _mob_combat_field_defs[i])
	for i in mini(_mob_death_burst_field_labels.size(), _mob_death_burst_field_defs.size()):
		_apply_mob_tuning_field_style(_mob_death_burst_field_labels[i], _mob_death_burst_spins[i], scene, _mob_death_burst_field_defs[i])
	for i in mini(_mob_charge_field_labels.size(), _mob_charge_field_defs.size()):
		_apply_mob_tuning_field_style(_mob_charge_field_labels[i], _mob_charge_spins[i], scene, _mob_charge_field_defs[i])
	for i in mini(_mob_chase_skill_field_labels.size(), _mob_chase_skill_field_defs.size()):
		_apply_mob_tuning_field_style(
			_mob_chase_skill_field_labels[i],
			_mob_chase_skill_spins[i],
			scene,
			_mob_chase_skill_field_defs[i]
		)
	_refresh_mob_chase_mode_field_style(scene)


func _refresh_mob_chase_mode_field_style(scene: PackedScene) -> void:
	if _mob_chase_mode_label == null or _mob_chase_mode_option == null:
		return
	var tuned_index := clampi(
		int(_mob_snapshots.get_tuned_value(scene, CHASE_MODE_PROPERTY)),
		0,
		CHASE_MODE_LABELS.size() - 1
	)
	var is_pending := _mob_chase_mode_option.selected != tuned_index
	var color := _mob_tuning_color_default
	var suffix := ""
	if is_pending:
		color = _mob_tuning_color_session
		suffix = " *"
	else:
		var state := _mob_snapshots.get_property_tuning_state(scene, CHASE_MODE_PROPERTY)
		if state == TestArenaMobSnapshot.TUNING_STATE_SAVED:
			color = _mob_tuning_color_saved
		elif state == TestArenaMobSnapshot.TUNING_STATE_SESSION:
			color = _mob_tuning_color_session
			suffix = " *"
	_mob_chase_mode_label.text = "추격 방식" + suffix
	_mob_chase_mode_label.add_theme_color_override("font_color", color)
	_mob_chase_mode_option.add_theme_color_override("font_color", color)


func _populate_mob_chase_mode_dropdown() -> void:
	if _mob_chase_mode_option == null:
		return
	_mob_chase_mode_option.clear()
	for label in CHASE_MODE_LABELS:
		_mob_chase_mode_option.add_item(label)


func _sync_mob_chase_mode_dropdown(scene: PackedScene) -> void:
	if _mob_chase_mode_option == null or scene == null:
		return
	if _mob_chase_mode_option.get_item_count() != CHASE_MODE_LABELS.size():
		_populate_mob_chase_mode_dropdown()
	var select_index := clampi(
		int(_mob_snapshots.get_tuned_value(scene, CHASE_MODE_PROPERTY)),
		0,
		CHASE_MODE_LABELS.size() - 1
	)
	_mob_tuning_ui_refreshing = true
	_mob_chase_mode_option.select(select_index)
	_mob_tuning_ui_refreshing = false


func _chase_mode_matches_tuned_value(scene: PackedScene) -> bool:
	if _mob_chase_mode_option == null:
		return true
	var expected := clampi(
		int(_mob_snapshots.get_tuned_value(scene, CHASE_MODE_PROPERTY)),
		0,
		CHASE_MODE_LABELS.size() - 1
	)
	return _mob_chase_mode_option.selected == expected


func _get_chase_mode_label(mode_index: int) -> String:
	var index := clampi(mode_index, 0, CHASE_MODE_LABELS.size() - 1)
	return CHASE_MODE_LABELS[index]


func on_mob_chase_mode_selected(index: int) -> void:
	_on_mob_chase_mode_selected(index)


func _on_mob_chase_mode_selected(index: int) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := get_selected_mob_scene(null)
	if scene == null or index < 0 or index >= CHASE_MODE_LABELS.size():
		return
	_refresh_mob_chase_mode_field_style(scene)
	_refresh_mob_combat_tuning_status_only(scene)
	_refresh_mob_action_buttons(scene)


func _refresh_mob_death_burst_tuning_ui(scene: PackedScene) -> void:
	if not _mob_snapshots.supports_death_burst_tuning(scene):
		_mob_death_burst_field_defs.clear()
		_set_mob_death_burst_tuning_enabled(false)
		return
	_mob_death_burst_field_defs = _mob_snapshots.get_death_burst_field_defs(scene)
	_mob_tuning_ui_refreshing = true
	for burst_index in _mob_death_burst_spins.size():
		var field_def: Dictionary = _mob_death_burst_field_defs[burst_index]
		var spin: SpinBox = _mob_death_burst_spins[burst_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_refresh_mob_tuning_field_styles(scene)
	_set_mob_death_burst_tuning_enabled(true)


func _refresh_mob_charge_tuning_ui(scene: PackedScene) -> void:
	if not _mob_snapshots.supports_charge_tuning(scene):
		_mob_charge_field_defs.clear()
		_set_mob_charge_tuning_enabled(false)
		return
	_mob_charge_field_defs = _mob_snapshots.get_charge_field_defs(scene)
	_mob_tuning_ui_refreshing = true
	for charge_index in _mob_charge_spins.size():
		var field_def: Dictionary = _mob_charge_field_defs[charge_index]
		var spin: SpinBox = _mob_charge_spins[charge_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_refresh_mob_tuning_field_styles(scene)
	_set_mob_charge_tuning_enabled(true)


func _refresh_mob_chase_skill_tuning_ui(scene: PackedScene) -> void:
	if not _mob_snapshots.supports_chase_skill_tuning(scene):
		_mob_chase_skill_field_defs.clear()
		_set_mob_chase_skill_tuning_enabled(false)
		return
	_mob_chase_skill_field_defs = _mob_snapshots.get_chase_skill_field_defs(scene)
	_mob_tuning_ui_refreshing = true
	var field_count := mini(_mob_chase_skill_field_defs.size(), _mob_chase_skill_spins.size())
	for chase_skill_index in field_count:
		var field_def: Dictionary = _mob_chase_skill_field_defs[chase_skill_index]
		var spin: SpinBox = _mob_chase_skill_spins[chase_skill_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_set_mob_chase_skill_row_visibility(field_count)
	_refresh_mob_tuning_field_styles(scene)
	_set_mob_chase_skill_tuning_enabled(true, _is_chase_skill_detail_enabled(scene))


func _on_mob_combat_spin_tree_entered(spin_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered.call(spin)
	_wire_spin_box_text_commit.call(spin, func(new_value: float) -> void:
		_on_mob_combat_spin_changed(spin_index, new_value))


func _on_mob_death_burst_spin_tree_entered(burst_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered.call(spin)
	_wire_spin_box_text_commit.call(spin, func(new_value: float) -> void:
		_on_mob_death_burst_spin_changed(burst_index, new_value))


func _on_mob_charge_spin_tree_entered(charge_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered.call(spin)
	_wire_spin_box_text_commit.call(spin, func(new_value: float) -> void:
		_on_mob_charge_spin_changed(charge_index, new_value))


func _on_mob_chase_skill_spin_tree_entered(chase_skill_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered.call(spin)
	_wire_spin_box_text_commit.call(spin, func(new_value: float) -> void:
		_on_mob_chase_skill_spin_changed(chase_skill_index, new_value))


func _commit_mob_tuning_to_session(scene: PackedScene) -> void:
	if scene == null:
		return
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	var field_count := mini(_mob_combat_field_defs.size(), _mob_combat_spins.size())
	for spin_index in field_count:
		var spin: SpinBox = _mob_combat_spins[spin_index]
		_commit_spin_box_pending.call(spin)
		var property: String = _mob_combat_field_defs[spin_index]["property"]
		_mob_snapshots.set_session_value(scene_id, property, spin.value)
	for burst_index in _mob_death_burst_field_defs.size():
		var burst_spin: SpinBox = _mob_death_burst_spins[burst_index]
		_commit_spin_box_pending.call(burst_spin)
		var burst_property: String = _mob_death_burst_field_defs[burst_index]["property"]
		_mob_snapshots.set_session_value(scene_id, burst_property, burst_spin.value)
	for charge_index in _mob_charge_field_defs.size():
		var charge_spin: SpinBox = _mob_charge_spins[charge_index]
		_commit_spin_box_pending.call(charge_spin)
		var charge_property: String = _mob_charge_field_defs[charge_index]["property"]
		_mob_snapshots.set_session_value(scene_id, charge_property, charge_spin.value)
	for chase_skill_index in _mob_chase_skill_field_defs.size():
		var chase_skill_spin: SpinBox = _mob_chase_skill_spins[chase_skill_index]
		_commit_spin_box_pending.call(chase_skill_spin)
		var chase_skill_property: String = _mob_chase_skill_field_defs[chase_skill_index]["property"]
		_mob_snapshots.set_session_value(scene_id, chase_skill_property, chase_skill_spin.value)
	if _mob_chase_mode_option != null:
		_mob_snapshots.set_session_value(scene_id, CHASE_MODE_PROPERTY, _mob_chase_mode_option.selected)


func _commit_and_apply_mob_tuning_from_spins() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	_commit_mob_tuning_to_session(scene)
	_apply_mob_tuning_live.call(scene)


func _on_mob_combat_step_pressed(spin_index: int, direction: int) -> void:
	if spin_index < 0 or spin_index >= _mob_combat_spins.size():
		return
	var spin: SpinBox = _mob_combat_spins[spin_index]
	_on_mob_combat_spin_changed(spin_index, spin.value + spin.step * float(direction))


func _on_mob_combat_spin_changed(spin_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := get_selected_mob_scene(null)
	if scene == null or spin_index < 0 or spin_index >= _mob_combat_field_defs.size():
		return
	if spin_index >= _mob_combat_spins.size() or spin_index >= _mob_combat_field_labels.size():
		return
	var spin: SpinBox = _mob_combat_spins[spin_index]
	if not is_equal_approx(spin.value, new_value):
		_mob_tuning_ui_refreshing = true
		spin.value = new_value
		_mob_tuning_ui_refreshing = false
	_apply_mob_tuning_field_style(_mob_combat_field_labels[spin_index], spin, scene, _mob_combat_field_defs[spin_index])
	_refresh_mob_combat_tuning_status_only(scene)
	_refresh_mob_action_buttons(scene)


func _on_mob_death_burst_step_pressed(burst_index: int, direction: int) -> void:
	if burst_index < 0 or burst_index >= _mob_death_burst_spins.size():
		return
	var spin: SpinBox = _mob_death_burst_spins[burst_index]
	_on_mob_death_burst_spin_changed(burst_index, spin.value + spin.step * float(direction))


func _on_mob_death_burst_spin_changed(burst_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := get_selected_mob_scene(null)
	if scene == null or burst_index < 0 or burst_index >= _mob_death_burst_field_defs.size():
		return
	var spin: SpinBox = _mob_death_burst_spins[burst_index]
	if not is_equal_approx(spin.value, new_value):
		_mob_tuning_ui_refreshing = true
		spin.value = new_value
		_mob_tuning_ui_refreshing = false
	_apply_mob_tuning_field_style(_mob_death_burst_field_labels[burst_index], spin, scene, _mob_death_burst_field_defs[burst_index])
	_refresh_mob_combat_tuning_status_only(scene)
	_refresh_mob_action_buttons(scene)


func _on_mob_charge_step_pressed(charge_index: int, direction: int) -> void:
	if charge_index < 0 or charge_index >= _mob_charge_spins.size():
		return
	var spin: SpinBox = _mob_charge_spins[charge_index]
	_on_mob_charge_spin_changed(charge_index, spin.value + spin.step * float(direction))


func _on_mob_charge_spin_changed(charge_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := get_selected_mob_scene(null)
	if scene == null or charge_index < 0 or charge_index >= _mob_charge_field_defs.size():
		return
	var spin: SpinBox = _mob_charge_spins[charge_index]
	if not is_equal_approx(spin.value, new_value):
		_mob_tuning_ui_refreshing = true
		spin.value = new_value
		_mob_tuning_ui_refreshing = false
	_apply_mob_tuning_field_style(_mob_charge_field_labels[charge_index], spin, scene, _mob_charge_field_defs[charge_index])
	_refresh_mob_combat_tuning_status_only(scene)
	_refresh_mob_action_buttons(scene)


func _on_mob_chase_skill_step_pressed(chase_skill_index: int, direction: int) -> void:
	if chase_skill_index < 0 or chase_skill_index >= _mob_chase_skill_spins.size():
		return
	var spin: SpinBox = _mob_chase_skill_spins[chase_skill_index]
	_on_mob_chase_skill_spin_changed(
		chase_skill_index,
		spin.value + spin.step * float(direction)
	)


func _on_mob_chase_skill_spin_changed(chase_skill_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := get_selected_mob_scene(null)
	if scene == null or chase_skill_index < 0 or chase_skill_index >= _mob_chase_skill_field_defs.size():
		return
	if (
		chase_skill_index >= _mob_chase_skill_spins.size()
		or chase_skill_index >= _mob_chase_skill_field_labels.size()
	):
		return
	var spin: SpinBox = _mob_chase_skill_spins[chase_skill_index]
	if not is_equal_approx(spin.value, new_value):
		_mob_tuning_ui_refreshing = true
		spin.value = new_value
		_mob_tuning_ui_refreshing = false
	_apply_mob_tuning_field_style(
		_mob_chase_skill_field_labels[chase_skill_index],
		spin,
		scene,
		_mob_chase_skill_field_defs[chase_skill_index]
	)
	if chase_skill_index == 0:
		_set_mob_chase_skill_tuning_enabled(true, int(spin.value) != 0)
	_refresh_mob_combat_tuning_status_only(scene)
	_refresh_mob_action_buttons(scene)


func _format_mob_persistence_failure(action_label: String, mob_label: String) -> String:
	if not DevTuningPersistence.can_write_project_resources():
		return (
			"몹 튜닝 %s 실패(%s) — Godot 에디터에서 실행할 때만 res://game/tuning/mobs/에 저장할 수 있습니다."
			% [action_label, mob_label]
		)
	var detail := DevTuningStore.get_last_persistence_error()
	if detail.is_empty():
		detail = "알 수 없는 오류"
	return "몹 튜닝 %s 실패(%s): %s" % [action_label, mob_label, detail]


func _refresh_mob_combat_tuning_status_only(scene: PackedScene) -> void:
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	var status_parts: PackedStringArray = []
	if _mob_snapshots.has_saved_snapshot(scene_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if _has_pending_spin_changes(scene):
		status_parts.append("미적용 변경 있음")
	elif not _mob_snapshots.get_session_overrides(scene_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if _is_selected_scene_active.call(scene):
		status_parts.append("스폰 중 — 적용 버튼으로 반영")
	var legend := "색: 기본 · 저장 · 미저장*"
	if status_parts.is_empty():
		_mob_combat_tuning_status_label.text = "프리팹 기본값 — %s" % legend
	else:
		_mob_combat_tuning_status_label.text = "%s — %s" % [" · ".join(status_parts), legend]
