extends Node2D

## 몹·무기 전투를 빠르게 검증하는 테스트 아레나(메인 루프·밸런스 스폰 없음).

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const TestArenaWeaponSnapshot = preload("res://game/test_arena_weapon_snapshot.gd")
const EQUIPMENT_DROP_SCENE := preload("res://effects/equipment_drop/equipment_drop.tscn")

const START_WEAPON := preload("res://weapons/data/revolver.tres")
const PLAYER_RESPAWN_DELAY := 3.0
const MOB_SPAWN_OFFSET_FROM_PLAYER := Vector2(280.0, 0.0)
const TUNING_SPIN_BUTTON_SIZE := Vector2(52, 52)
const TUNING_SPIN_MIN_HEIGHT := 48
const TUNING_SPIN_BUTTON_FONT_SIZE := 24
const TUNING_SPIN_VALUE_FONT_SIZE := 17
const DUMMY_BASE_MAX_HEALTH := 500
const NON_DUMMY_HP_VS_DUMMY_MULTIPLIER := 10.0

const WEAPON_TYPE_ORDER: Array[String] = ["Ranged", "Magic", "Melee"]
const WEAPON_TYPE_LABELS_KO := {
	"Ranged": "원거리",
	"Magic": "마법",
	"Melee": "근접",
}

# 카탈로그에 아직 없어도 필터에 미리 노출할 등급(추가 시 자동 반영).
const WEAPON_RARITY_ORDER: Array[String] = [
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
]
const WEAPON_RARITY_LABELS_KO := {
	"Common": "커먼",
	"Uncommon": "언커먼",
	"Rare": "레어",
	"Epic": "에픽",
	"Legendary": "전설",
}

const MOB_OPTIONS: Array[Dictionary] = [
	{"label": "Basic", "scene": MobSpawnSelector.MOB_BASIC_SCENE},
	{"label": "Fast", "scene": MobSpawnSelector.MOB_FAST_SCENE},
	{"label": "Ranged", "scene": MobSpawnSelector.MOB_RANGED_SCENE},
	{"label": "Elite", "scene": MobSpawnSelector.MOB_ELITE_SCENE},
	{"label": "Boss", "scene": MobSpawnSelector.MOB_BOSS_SCENE},
	{"label": "Special A", "scene": MobSpawnSelector.MOB_SPECIAL_A_SCENE},
	{"label": "Special B", "scene": MobSpawnSelector.MOB_SPECIAL_B_SCENE},
	{"label": "Dummy (static)", "scene": MobSpawnSelector.MOB_DUMMY_SCENE},
]

@export var mob_respawn_enabled := false
@export_range(0.0, 30.0, 0.1, "or_greater") var mob_respawn_delay := 2.0
## true면 인벤 활성 세트 weapon + 투사체 튜닝 스냅샷으로 장착합니다.
@export var use_inventory_loadout := true

var _all_weapon_options: Array[WeaponData] = []
var _available_rarities: Array[String] = []
var _filtered_weapon_options: Array[WeaponData] = []
var _active_mob: Mob = null
var _last_mob_scene: PackedScene = null
var _player_is_dead := false
var _saved_player_collision_layer := 0
var _saved_player_collision_mask := 0
var _saved_auto_attack_enabled := true
var _mob_respawn_token := 0
var _weapon_damage := WeaponDamageTracker.new()
var _weapon_snapshots := TestArenaWeaponSnapshot.new()
var _equipped_weapon_id := ""
var _tuning_spin_rows: Array[Dictionary] = []
var _tuning_ui_refreshing := false

var _pause_menu: CanvasLayer
var _inventory_menu: CanvasLayer


func _ready() -> void:
	_pause_menu = get_node_or_null("PauseMenu") as CanvasLayer
	_inventory_menu = get_node_or_null("InventoryMenu") as CanvasLayer
	if _pause_menu == null:
		push_error("TestArena: PauseMenu missing — check pause_menu_overlay.tscn.")
	if _inventory_menu == null:
		push_error("TestArena: InventoryMenu missing — check inventory_overlay.tscn.")
	ActionManager.initialize()
	LocaleSettings.load_and_apply()
	DisplaySettings.load_and_apply()
	AudioSettings.load_and_apply()
	GameplaySettings.load_and_apply()
	_place_player_at_spawn()
	%Player.set_contact_damage_enabled(true)
	_weapon_snapshots.load_from_disk()
	_build_weapon_options()
	_setup_mob_type_option()
	_setup_weapon_filters()
	_setup_projectile_tuning_ui()
	if not use_inventory_loadout:
		_equip_weapon(START_WEAPON)
	else:
		call_deferred("apply_inventory_loadout_to_player")
	%SpawnMobButton.pressed.connect(_on_spawn_mob_button_pressed)
	%EquipWeaponButton.pressed.connect(_on_equip_weapon_button_pressed)
	%WeaponOption.item_selected.connect(_on_weapon_option_selected)
	%SaveProjectileTuningButton.pressed.connect(_on_save_projectile_tuning_pressed)
	%ResetProjectileTuningButton.pressed.connect(_on_reset_projectile_tuning_pressed)
	%ProjectileMovementOption.item_selected.connect(_on_projectile_movement_selected)
	%WeaponTypeFilter.item_selected.connect(_on_weapon_filters_changed)
	%WeaponRarityFilter.item_selected.connect(_on_weapon_filters_changed)
	%Player.health_depleted.connect(_on_player_health_depleted)
	%MobRespawnCheck.toggled.connect(_on_mob_respawn_toggled)
	_on_mob_respawn_toggled(%MobRespawnCheck.button_pressed)


# player.gd F키 차단 훅(메인 Game API 호환).
func is_weapon_select_open() -> bool:
	return false


func is_pause_menu_open() -> bool:
	return _pause_menu != null and _pause_menu.visible


func is_inventory_open() -> bool:
	return InventoryGameBridge.is_inventory_open(_inventory_menu)


func is_game_over() -> bool:
	return _player_is_dead


func register_weapon_damage(weapon: WeaponData, amount: int) -> void:
	_weapon_damage.register(weapon, amount)


func get_weapon_damage_display_rows() -> Array[Dictionary]:
	return _weapon_damage.build_display_rows(%Player.get_owned_weapons())


func show_pause_menu() -> void:
	if is_weapon_select_open() or is_inventory_open() or _pause_menu == null:
		return
	_pause_menu.refresh_owned_weapons()
	_pause_menu.show()
	get_tree().paused = true


func resume_game() -> void:
	if _pause_menu == null:
		return
	_pause_menu.hide()
	if not is_game_over() and not is_inventory_open():
		get_tree().paused = false


func show_inventory() -> void:
	InventoryGameBridge.show_inventory(self, _inventory_menu)


func hide_inventory() -> void:
	InventoryGameBridge.hide_inventory(self, _inventory_menu)


func toggle_inventory() -> void:
	InventoryGameBridge.toggle_inventory(self, _inventory_menu)


func show_inventory_swap_toast(message: String) -> void:
	if has_node("%StatusLabel"):
		%StatusLabel.text = message


func try_acquire_dropped_equipment_item(item_id: String) -> StringName:
	if not use_inventory_loadout or _inventory_menu == null:
		return InventoryService.ERROR_INVALID_SLOT
	var menu_service: InventoryService = _inventory_menu.get_service()
	if menu_service == null:
		return InventoryService.ERROR_UNKNOWN_ITEM
	var err := menu_service.acquire_item(item_id)
	if not err.is_empty():
		return err
	if _inventory_menu.has_method("refresh_all_slots"):
		_inventory_menu.refresh_all_slots()
	apply_inventory_loadout_to_player()
	return &""


# 인벤토리에서 버린 장비를 플레이어 앞에 월드 드롭으로 생성합니다.
func can_drop_equipment_item(item_id: String) -> bool:
	return not item_id.strip_edges().is_empty() and EQUIPMENT_DROP_SCENE != null


func drop_equipment_item(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var drop := EQUIPMENT_DROP_SCENE.instantiate() as EquipmentDrop
	if drop == null:
		push_error("TestArena: EquipmentDrop scene must instantiate EquipmentDrop.")
		return false
	add_child(drop)
	drop.global_position = _get_equipment_drop_position()
	drop.setup(item_id)
	return true


func _get_equipment_drop_position() -> Vector2:
	var direction := Vector2.RIGHT
	if %Player.has_method("get_last_move_direction"):
		direction = %Player.get_last_move_direction()
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	return %Player.global_position + direction.normalized() * 96.0


func apply_inventory_loadout_to_player() -> void:
	if not use_inventory_loadout or _inventory_menu == null:
		InventoryCombatBridge.clear_loadout_from_player(%Player)
		InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)
		return
	var menu_service: InventoryService = _inventory_menu.get_service()
	if menu_service == null:
		InventoryCombatBridge.clear_loadout_from_player(%Player)
		InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)
		return
	var weapon_id := InventoryCombatBridge.get_active_weapon_id(menu_service.loadout)
	if weapon_id.is_empty():
		%Player.clear_weapons()
		_equipped_weapon_id = ""
	else:
		var weapon := menu_service.registry.resolve_weapon(weapon_id)
		if weapon:
			_equip_weapon(weapon)
	if %Player.has_method(&"refresh_stats_from_loadout"):
		%Player.refresh_stats_from_loadout(menu_service.registry, menu_service.loadout)
	InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)


func _unhandled_input(event: InputEvent) -> void:
	if InventoryGameBridge.handle_inventory_input(self, _inventory_menu, event):
		get_viewport().set_input_as_handled()


func _on_pause_continue_pressed() -> void:
	resume_game()


func _on_pause_restart_pressed() -> void:
	$SpeedCheat.reset_speed()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_pause_quit_pressed() -> void:
	get_tree().quit()


func _build_weapon_options() -> void:
	_all_weapon_options.clear()
	for weapon in RangedWeaponCatalog.get_all():
		_all_weapon_options.append(weapon)
	for weapon in MagicWeaponCatalog.get_all():
		_all_weapon_options.append(weapon)
	for weapon in MeleeWeaponCatalog.get_all():
		_all_weapon_options.append(weapon)
	for weapon in _all_weapon_options:
		_weapon_snapshots.register_catalog_weapon(weapon)
	_all_weapon_options.sort_custom(_sort_weapons_for_picker)
	_collect_available_rarities()


func _collect_available_rarities() -> void:
	var seen: Dictionary = {}
	for weapon in _all_weapon_options:
		var rarity_key := weapon.rarity if not weapon.rarity.is_empty() else "Common"
		seen[rarity_key] = true

	_available_rarities.clear()
	for rarity in WEAPON_RARITY_ORDER:
		if seen.has(rarity):
			_available_rarities.append(rarity)
			seen.erase(rarity)
	for rarity in seen.keys():
		_available_rarities.append(str(rarity))


func _sort_weapons_for_picker(a: WeaponData, b: WeaponData) -> bool:
	var type_a := WEAPON_TYPE_ORDER.find(a.weapon_type)
	var type_b := WEAPON_TYPE_ORDER.find(b.weapon_type)
	if type_a < 0:
		type_a = WEAPON_TYPE_ORDER.size()
	if type_b < 0:
		type_b = WEAPON_TYPE_ORDER.size()
	if type_a != type_b:
		return type_a < type_b
	return a.get_display_name_localized() < b.get_display_name_localized()


func _setup_mob_type_option() -> void:
	var option: OptionButton = %MobTypeOption
	option.clear()
	for entry in MOB_OPTIONS:
		option.add_item(entry["label"])


func _setup_weapon_filters() -> void:
	var type_filter: OptionButton = %WeaponTypeFilter
	type_filter.clear()
	type_filter.add_item("전체")
	for weapon_type in WEAPON_TYPE_ORDER:
		type_filter.add_item(WEAPON_TYPE_LABELS_KO[weapon_type])
	var ranged_index := WEAPON_TYPE_ORDER.find("Ranged") + 1
	type_filter.select(maxi(ranged_index, 0))

	var rarity_filter: OptionButton = %WeaponRarityFilter
	rarity_filter.clear()
	rarity_filter.add_item("전체")
	for rarity in _available_rarities:
		var label: String = WEAPON_RARITY_LABELS_KO.get(rarity, rarity)
		rarity_filter.add_item(label)
	var common_index := _available_rarities.find("Common")
	if common_index >= 0:
		rarity_filter.select(common_index + 1)
	else:
		rarity_filter.select(0)

	_refresh_weapon_option_list(START_WEAPON.get_unique_key())


func _on_weapon_filters_changed(_index: int = -1) -> void:
	var current := _get_selected_weapon()
	var preserve_key := current.get_unique_key() if current else ""
	_refresh_weapon_option_list(preserve_key)


func _on_weapon_option_selected(_index: int) -> void:
	_update_weapon_description()
	_refresh_projectile_tuning_ui()


func _get_weapon_filter_type() -> String:
	var index: int = %WeaponTypeFilter.selected
	if index <= 0:
		return ""
	return WEAPON_TYPE_ORDER[index - 1]


func _get_weapon_filter_rarity() -> String:
	var index: int = %WeaponRarityFilter.selected
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


func _refresh_weapon_option_list(preserve_key: String = "") -> void:
	var filter_type := _get_weapon_filter_type()
	var filter_rarity := _get_weapon_filter_rarity()
	_filtered_weapon_options.clear()
	for weapon in _all_weapon_options:
		if not filter_type.is_empty() and weapon.weapon_type != filter_type:
			continue
		if not _weapon_matches_rarity(weapon, filter_rarity):
			continue
		_filtered_weapon_options.append(weapon)

	var option: OptionButton = %WeaponOption
	option.clear()
	if _filtered_weapon_options.is_empty():
		if not _player_is_dead:
			_update_status("조건에 맞는 무기가 없습니다.")
		_update_weapon_description()
		return

	var select_index := 0
	for i in _filtered_weapon_options.size():
		var weapon: WeaponData = _filtered_weapon_options[i]
		option.add_item(weapon.get_display_name_localized())
		if not preserve_key.is_empty() and weapon.get_unique_key() == preserve_key:
			select_index = i
	option.select(select_index)
	if not _player_is_dead and _filtered_weapon_options.size() > 0:
		_update_status("")
	_update_weapon_description()
	_refresh_projectile_tuning_ui()


func _on_mob_respawn_toggled(enabled: bool) -> void:
	mob_respawn_enabled = enabled


func _on_spawn_mob_button_pressed() -> void:
	spawn_test_mob(_get_selected_mob_scene())


func _on_equip_weapon_button_pressed() -> void:
	var weapon := _get_selected_weapon()
	if weapon:
		_equip_weapon(weapon)


func _get_selected_mob_scene() -> PackedScene:
	var index: int = %MobTypeOption.selected
	if index < 0 or index >= MOB_OPTIONS.size():
		return MobSpawnSelector.MOB_BASIC_SCENE
	return MOB_OPTIONS[index]["scene"] as PackedScene


func _get_selected_weapon() -> WeaponData:
	var index: int = %WeaponOption.selected
	if index < 0 or index >= _filtered_weapon_options.size():
		return null
	return _filtered_weapon_options[index]


# 플레이어 무기 슬롯을 비운 뒤 튜닝된 무기만 장착합니다.
func _equip_weapon(catalog_weapon: WeaponData) -> void:
	if catalog_weapon == null:
		return
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


# 스냅샷 값을 장착 중인 Gun에 반영합니다(UI는 갱신하지 않음).
func _apply_tuning_live(catalog_weapon: WeaponData) -> void:
	var tuned := _weapon_snapshots.build_tuned_weapon(catalog_weapon)
	_equipped_weapon_id = catalog_weapon.get_unique_key()
	var player: CharacterBody2D = %Player
	player.clear_weapons()
	player.add_weapon(tuned)
	player.set_auto_attack_enabled(true)
	if player.has_method(&"_refresh_weapon_combat_modifiers"):
		player._refresh_weapon_combat_modifiers()


func _setup_projectile_tuning_ui() -> void:
	_clear_projectile_tuning_fields()
	%ProjectileMovementRow.visible = false
	%SaveProjectileTuningButton.disabled = true
	%ResetProjectileTuningButton.disabled = true


func _clear_projectile_tuning_fields() -> void:
	var fields := %ProjectileTuningFields
	for child in fields.get_children():
		fields.remove_child(child)
		child.free()
	_tuning_spin_rows.clear()


func _refresh_projectile_tuning_ui() -> void:
	_clear_projectile_tuning_fields()
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		%ProjectileTuningStatusLabel.text = "조건에 맞는 무기가 없습니다."
		%ProjectileMovementRow.visible = false
		%SaveProjectileTuningButton.disabled = true
		%ResetProjectileTuningButton.disabled = true
		return

	if not _weapon_snapshots.supports_projectile_tuning(catalog_weapon):
		%ProjectileTuningStatusLabel.text = "이 무기는 발사체 튜닝을 지원하지 않습니다."
		%ProjectileMovementRow.visible = false
		%SaveProjectileTuningButton.disabled = true
		%ResetProjectileTuningButton.disabled = true
		return

	var weapon_id := catalog_weapon.get_unique_key()
	var tuned := _weapon_snapshots.build_tuned_weapon(catalog_weapon)
	var field_defs: Array = _weapon_snapshots.get_field_defs(catalog_weapon)
	_tuning_ui_refreshing = true
	var show_movement := _weapon_snapshots.supports_projectile_movement_tuning(catalog_weapon)
	if show_movement:
		_populate_projectile_movement_dropdown(catalog_weapon, tuned)
	%ProjectileMovementRow.visible = show_movement
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
		%ProjectileTuningStatusLabel.text = "카탈로그 기본값"
	else:
		%ProjectileTuningStatusLabel.text = " · ".join(status_parts)
	%SaveProjectileTuningButton.disabled = false
	%ResetProjectileTuningButton.disabled = false


func _add_projectile_tuning_row(
	catalog_weapon: WeaponData,
	field_def: Dictionary,
	tuned: WeaponData
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	%ProjectileTuningFields.add_child(row)

	var label := Label.new()
	label.text = str(field_def.get("label", field_def["property"]))
	label.custom_minimum_size = Vector2(120, 0)
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)

	var property: String = field_def["property"]
	var value_row := HBoxContainer.new()
	value_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_row.add_theme_constant_override("separation", 6)
	row.add_child(value_row)

	var dec_button := _create_tuning_step_button("−")
	value_row.add_child(dec_button)

	var spin := SpinBox.new()
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.custom_minimum_size.y = TUNING_SPIN_MIN_HEIGHT
	spin.add_theme_constant_override("updown_width", 0)
	spin.min_value = float(field_def.get("min", 0.0))
	spin.max_value = float(field_def.get("max", 9999.0))
	spin.step = float(field_def.get("step", 1.0))
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.rounded = spin.step >= 1.0
	if field_def.get("bool", false):
		spin.value = 1.0 if bool(tuned.get(property)) else 0.0
	else:
		spin.value = float(tuned.get(property))
	spin.value_changed.connect(_on_projectile_tuning_value_changed.bind(catalog_weapon, property))
	value_row.add_child(spin)
	spin.tree_entered.connect(_on_tuning_spin_tree_entered.bind(spin), CONNECT_ONE_SHOT)

	var inc_button := _create_tuning_step_button("+")
	value_row.add_child(inc_button)

	dec_button.pressed.connect(_on_tuning_spin_step_pressed.bind(spin, catalog_weapon, property, -1))
	inc_button.pressed.connect(_on_tuning_spin_step_pressed.bind(spin, catalog_weapon, property, 1))

	_tuning_spin_rows.append({"property": property, "spin": spin, "row": row})


func _create_tuning_step_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = TUNING_SPIN_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", TUNING_SPIN_BUTTON_FONT_SIZE)
	return button


func _on_tuning_spin_tree_entered(spin: SpinBox) -> void:
	var line_edit := spin.get_line_edit()
	if line_edit == null:
		return
	line_edit.custom_minimum_size.y = TUNING_SPIN_MIN_HEIGHT
	line_edit.add_theme_font_size_override("font_size", TUNING_SPIN_VALUE_FONT_SIZE)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _on_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String,
	direction: int
) -> void:
	_on_projectile_tuning_value_changed(spin.value + spin.step * float(direction), catalog_weapon, property)
	_sync_tuning_spin_display(property, catalog_weapon)


func _populate_projectile_movement_dropdown(catalog_weapon: WeaponData, tuned: WeaponData) -> void:
	var option: OptionButton = %ProjectileMovementOption
	option.clear()
	var movement_options := tuned.get_projectile_movement_options()
	var select_index := 0
	for i in movement_options.size():
		var movement_id: String = movement_options[i]
		var label: String = WeaponData.PROJECTILE_MOVEMENT_LABELS_KO.get(movement_id, movement_id)
		option.add_item(label)
		if movement_id == tuned.projectile_movement:
			select_index = i
	option.select(select_index)


func _on_projectile_movement_selected(index: int) -> void:
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
			_update_status("관통 수는 0일 수 없습니다. 1 이상 또는 -1(무제한)을 사용하세요.")
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
		spin.value = float(tuned.get(property))
		_tuning_ui_refreshing = false
		return


# SpinBox 화살표가 1↔-1 사이에서 0을 거치지 않도록 보정합니다.
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
	%ProjectileTuningStatusLabel.text = " · ".join(status_parts) if not status_parts.is_empty() else "카탈로그 기본값"


func _on_save_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.save_weapon(weapon_id)
	_update_status("발사체 스냅샷 저장: %s" % catalog_weapon.get_display_name_localized())
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


func _on_reset_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.reset_weapon(weapon_id)
	_update_status("발사체 스냅샷 초기화: %s" % catalog_weapon.get_display_name_localized())
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


# 선택한 몹 프리팹을 스폰 포인트에 배치합니다.
func spawn_test_mob(scene: PackedScene) -> void:
	if scene == null:
		push_error("TestArena.spawn_test_mob: scene is null.")
		return
	_cancel_pending_mob_respawn()
	_clear_active_mob()
	var spawn_pos: Vector2 = %Player.global_position + MOB_SPAWN_OFFSET_FROM_PLAYER
	var pool: ScenePool = $ObjectPools as ScenePool
	var mob: Mob
	if pool:
		mob = pool.acquire(scene, self, spawn_pos) as Mob
	else:
		mob = scene.instantiate() as Mob
		add_child(mob)
		mob.global_position = spawn_pos
	if not mob:
		push_error("TestArena.spawn_test_mob: scene must instantiate a Mob.")
		return
	mob.initialize_spawn_health(_get_test_mob_hp_multiplier(scene, mob))
	_active_mob = mob
	_last_mob_scene = scene


# 더미는 프리팹 기본 HP, 그 외 몹은 더미 최대 체력의 10배가 되도록 배수를 맞춥니다.
func _get_test_mob_hp_multiplier(scene: PackedScene, mob: Mob) -> float:
	if scene == MobSpawnSelector.MOB_DUMMY_SCENE:
		return 1.0
	var target_max := float(DUMMY_BASE_MAX_HEALTH * NON_DUMMY_HP_VS_DUMMY_MULTIPLIER)
	return target_max / maxf(float(mob.base_max_health), 1.0)


# 몹 사망 시 선택적으로 동일 프리팹을 재스폰합니다.
func register_kill() -> void:
	_active_mob = null
	if not mob_respawn_enabled or _last_mob_scene == null:
		return
	_cancel_pending_mob_respawn()
	var scene := _last_mob_scene
	var token := _mob_respawn_token
	get_tree().create_timer(mob_respawn_delay).timeout.connect(
		func() -> void:
			if token != _mob_respawn_token:
				return
			spawn_test_mob(scene)
	)


func _on_player_health_depleted() -> void:
	if _player_is_dead:
		return
	_begin_player_death()


func _begin_player_death() -> void:
	_player_is_dead = true
	var player: CharacterBody2D = %Player
	_saved_player_collision_layer = player.collision_layer
	_saved_player_collision_mask = player.collision_mask
	_saved_auto_attack_enabled = player.is_auto_attack_enabled()
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_physics_process(false)
	player.set_auto_attack_enabled(false)
	player.visible = false
	_update_status("플레이어 사망 — %.1f초 후 리스폰" % PLAYER_RESPAWN_DELAY)
	get_tree().create_timer(PLAYER_RESPAWN_DELAY).timeout.connect(_respawn_player)


func _respawn_player() -> void:
	if not _player_is_dead:
		return
	var player: CharacterBody2D = %Player
	var max_hp: float = player.get_max_health() if player.has_method(&"get_max_health") else player.get_node("%HealthBar").max_value
	player.health = max_hp
	player.get_node("%HealthBar").max_value = max_hp
	player.get_node("%HealthBar").value = max_hp
	player.global_position = %PlayerSpawnPoint.global_position
	player.collision_layer = _saved_player_collision_layer
	player.collision_mask = _saved_player_collision_mask
	player.set_physics_process(true)
	player.visible = true
	player.set_auto_attack_enabled(_saved_auto_attack_enabled)
	player.reset_health_depleted_state()
	_player_is_dead = false
	_update_status("")


func _update_status(text: String) -> void:
	%StatusLabel.text = text


# 드롭다운에서 선택 중인 무기 설명을 표시합니다.
func _update_weapon_description() -> void:
	var weapon := _get_selected_weapon()
	if weapon:
		%WeaponDescLabel.text = _weapon_snapshots.build_tuned_weapon(weapon).build_select_tooltip_bbcode()
	else:
		%WeaponDescLabel.text = "조건에 맞는 무기가 없습니다."


func _place_player_at_spawn() -> void:
	var player: Node2D = %Player
	player.global_position = %PlayerSpawnPoint.global_position


func _cancel_pending_mob_respawn() -> void:
	_mob_respawn_token += 1


func _clear_active_mob() -> void:
	if _active_mob == null or not is_instance_valid(_active_mob):
		_active_mob = null
		return
	PoolUtil.release_node(_active_mob)
	_active_mob = null
