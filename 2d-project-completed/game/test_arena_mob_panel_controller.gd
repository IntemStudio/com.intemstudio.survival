class_name TestArenaMobPanelController
extends RefCounted

## 테스트 아레나 몹 패널(선택/설명/전투 튜닝 UI) 제어 컨트롤러.

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
	mob_charge_field_labels: Array[Label]
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
	_mob_combat_step_buttons[0].pressed.connect(_on_mob_combat_step_pressed.bind(0, -1))
	_mob_combat_step_buttons[1].pressed.connect(_on_mob_combat_step_pressed.bind(0, 1))
	_mob_combat_step_buttons[2].pressed.connect(_on_mob_combat_step_pressed.bind(1, -1))
	_mob_combat_step_buttons[3].pressed.connect(_on_mob_combat_step_pressed.bind(1, 1))
	_mob_combat_step_buttons[4].pressed.connect(_on_mob_combat_step_pressed.bind(2, -1))
	_mob_combat_step_buttons[5].pressed.connect(_on_mob_combat_step_pressed.bind(2, 1))
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
	refresh_mob_combat_tuning_ui()


func on_apply_mob_combat_tuning_pressed() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	_commit_and_apply_mob_tuning_from_spins()
	var label: String = _mob_options[_mob_type_option.selected]["label"]
	_update_status.call("몹 전투 튜닝 적용: %s" % label)


func on_save_mob_combat_tuning_pressed() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	_commit_and_apply_mob_tuning_from_spins()
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.save_mob(scene_id)
	var label: String = _mob_options[_mob_type_option.selected]["label"]
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
	_update_status.call("몹 전투 스냅샷 초기화: %s" % label)
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
		_mob_combat_tuning_status_label.text = "몹 정보를 불러올 수 없습니다."
		_set_mob_combat_tuning_enabled(false)
		_set_mob_death_burst_tuning_enabled(false)
		_set_mob_charge_tuning_enabled(false)
		return
	_mob_combat_field_defs = _mob_snapshots.get_field_defs(scene)
	_mob_tuning_ui_refreshing = true
	for spin_index in _mob_combat_spins.size():
		var field_def: Dictionary = _mob_combat_field_defs[spin_index]
		var spin: SpinBox = _mob_combat_spins[spin_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_refresh_mob_death_burst_tuning_ui(scene)
	_refresh_mob_charge_tuning_ui(scene)
	_refresh_mob_tuning_field_styles(scene)
	_refresh_mob_combat_tuning_status_only(scene)
	_set_mob_combat_tuning_enabled(true)


func _set_mob_combat_tuning_enabled(enabled: bool) -> void:
	for spin in _mob_combat_spins:
		spin.editable = enabled
	for button in _mob_combat_step_buttons:
		button.disabled = not enabled
	_apply_mob_combat_tuning_button.disabled = not enabled
	_save_mob_combat_tuning_button.disabled = not enabled
	_reset_mob_combat_tuning_button.disabled = not enabled


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
	var state := _mob_snapshots.get_property_tuning_state(scene, property)
	var color := _mob_tuning_color_default
	var suffix := ""
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


func _commit_and_apply_mob_tuning_from_spins() -> void:
	var scene := get_selected_mob_scene(null)
	if scene == null:
		return
	for spin_index in _mob_combat_field_defs.size():
		var spin: SpinBox = _mob_combat_spins[spin_index]
		_commit_spin_box_pending.call(spin)
		_on_mob_combat_spin_changed(spin_index, spin.value)
	for burst_index in _mob_death_burst_field_defs.size():
		var burst_spin: SpinBox = _mob_death_burst_spins[burst_index]
		_commit_spin_box_pending.call(burst_spin)
		_on_mob_death_burst_spin_changed(burst_index, burst_spin.value)
	for charge_index in _mob_charge_field_defs.size():
		var charge_spin: SpinBox = _mob_charge_spins[charge_index]
		_commit_spin_box_pending.call(charge_spin)
		_on_mob_charge_spin_changed(charge_index, charge_spin.value)


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
	var property: String = _mob_combat_field_defs[spin_index]["property"]
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.set_session_value(scene_id, property, new_value)
	_apply_mob_tuning_live.call(scene)
	_sync_mob_combat_spin_display(spin_index, scene)
	_apply_mob_tuning_field_style(_mob_combat_field_labels[spin_index], _mob_combat_spins[spin_index], scene, _mob_combat_field_defs[spin_index])
	update_mob_description()
	_refresh_mob_combat_tuning_status_only(scene)


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
	var property: String = _mob_death_burst_field_defs[burst_index]["property"]
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.set_session_value(scene_id, property, new_value)
	_apply_mob_tuning_live.call(scene)
	_sync_mob_death_burst_spin_display(burst_index, scene)
	_apply_mob_tuning_field_style(_mob_death_burst_field_labels[burst_index], _mob_death_burst_spins[burst_index], scene, _mob_death_burst_field_defs[burst_index])
	update_mob_description()
	_refresh_mob_combat_tuning_status_only(scene)


func _sync_mob_death_burst_spin_display(burst_index: int, scene: PackedScene) -> void:
	if burst_index < 0 or burst_index >= _mob_death_burst_spins.size() or burst_index >= _mob_death_burst_field_defs.size():
		return
	var property: String = _mob_death_burst_field_defs[burst_index]["property"]
	_mob_tuning_ui_refreshing = true
	_mob_death_burst_spins[burst_index].value = _mob_snapshots.get_tuned_value(scene, property)
	_mob_tuning_ui_refreshing = false


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
	var property: String = _mob_charge_field_defs[charge_index]["property"]
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.set_session_value(scene_id, property, new_value)
	_apply_mob_tuning_live.call(scene)
	_sync_mob_charge_spin_display(charge_index, scene)
	_apply_mob_tuning_field_style(_mob_charge_field_labels[charge_index], _mob_charge_spins[charge_index], scene, _mob_charge_field_defs[charge_index])
	update_mob_description()
	_refresh_mob_combat_tuning_status_only(scene)


func _sync_mob_charge_spin_display(charge_index: int, scene: PackedScene) -> void:
	if charge_index < 0 or charge_index >= _mob_charge_spins.size() or charge_index >= _mob_charge_field_defs.size():
		return
	var property: String = _mob_charge_field_defs[charge_index]["property"]
	_mob_tuning_ui_refreshing = true
	_mob_charge_spins[charge_index].value = _mob_snapshots.get_tuned_value(scene, property)
	_mob_tuning_ui_refreshing = false


func _sync_mob_combat_spin_display(spin_index: int, scene: PackedScene) -> void:
	if spin_index < 0 or spin_index >= _mob_combat_spins.size() or spin_index >= _mob_combat_field_defs.size():
		return
	var property: String = _mob_combat_field_defs[spin_index]["property"]
	_mob_tuning_ui_refreshing = true
	_mob_combat_spins[spin_index].value = _mob_snapshots.get_tuned_value(scene, property)
	_mob_tuning_ui_refreshing = false


func _refresh_mob_combat_tuning_status_only(scene: PackedScene) -> void:
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	var status_parts: PackedStringArray = []
	if _mob_snapshots.has_saved_snapshot(scene_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _mob_snapshots.get_session_overrides(scene_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if _is_selected_scene_active.call(scene):
		status_parts.append("스폰 중 — 값 변경 시 즉시 반영")
	var legend := "색: 기본 · 저장 · 미저장*"
	if status_parts.is_empty():
		_mob_combat_tuning_status_label.text = "프리팹 기본값 — %s" % legend
	else:
		_mob_combat_tuning_status_label.text = "%s — %s" % [" · ".join(status_parts), legend]
