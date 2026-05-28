extends Node2D

## 몹·무기 전투를 빠르게 검증하는 테스트 아레나(메인 루프·밸런스 스폰 없음).

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const GearCatalog = preload("res://inventory/gear_catalog.gd")
const GearStatDisplay = preload("res://inventory/gear_stat_display.gd")
const TestArenaTuningUiUtil = preload("res://game/test_arena_tuning_ui.gd")
const TestArenaStatusEffectSnapshot = preload("res://game/test_arena_status_effect_snapshot.gd")
const EQUIPMENT_DROP_SCENE := preload("res://effects/equipment_drop/equipment_drop.tscn")

const START_WEAPON := preload("res://weapons/data/revolver.tres")
const PLAYER_RESPAWN_DELAY := 3.0
const TUNING_SPIN_BUTTON_SIZE := Vector2(52, 52)
const TUNING_SPIN_MIN_HEIGHT := 48
const TUNING_SPIN_BUTTON_FONT_SIZE := 24
const TUNING_SPIN_VALUE_FONT_SIZE := 17
const TEST_TAB_INDEX_MOB := 0
const TEST_TAB_INDEX_WEAPON := 1
const TEST_TAB_INDEX_STATUS_EFFECT := 2
const POISON_STATUS_ID := &"poison"
const STATUS_POISON_LOCKED_PROPERTIES := {
	"duration_seconds": true,
	"tick_damage_min": true,
	"tick_damage_max": true,
	"tick_interval": true,
}
const DUMMY_BASE_MAX_HEALTH := 500
const NON_DUMMY_HP_VS_DUMMY_MULTIPLIER := 10.0
const MOB_TUNING_COLOR_DEFAULT := Color(0.78, 0.78, 0.82, 1.0)
const MOB_TUNING_COLOR_SAVED := Color(0.55, 0.75, 0.95, 1.0)
const MOB_TUNING_COLOR_SESSION := Color(0.95, 0.82, 0.38, 1.0)

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
const MOB_KIND_LABELS_KO := {
	&"basic": "기본",
	&"fast": "빠른",
	&"ranged": "원거리",
	&"elite": "엘리트",
	&"special_a": "특수 A",
	&"special_b": "특수 B",
	&"boss": "보스",
	&"dummy": "더미",
}
const MOB_ROLE_HINTS_KO := {
	&"basic": "접근형 기본 몹",
	&"fast": "빠른 접근형 압박",
	&"ranged": "거리 유지 후 투사체 공격",
	&"elite": "강화 스탯 변종",
	&"special_a": "사망 시 범위 폭발",
	&"special_b": "돌진·저체력 자폭",
	&"boss": "25분 보스 후보",
	&"dummy": "테스트용 정지 허수아비",
}

@export var mob_respawn_enabled := false
@export_range(0.0, 30.0, 0.1, "or_greater") var mob_respawn_delay := 2.0
## true면 인벤 활성 세트 weapon + 투사체 튜닝 스냅샷으로 장착합니다.
@export var use_inventory_loadout := true

var _all_weapon_options: Array[WeaponData] = []
var _all_offhand_options: Array[GearData] = []
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
var _gear_snapshots := TestArenaGearSnapshot.new()
var _mob_snapshots := TestArenaMobSnapshot.new()
var _status_effect_snapshots := TestArenaStatusEffectSnapshot.new()
var _equipped_weapon_id := ""
var _equipped_offhand_id := ""
var _tuning_spin_rows: Array[Dictionary] = []
var _offhand_tuning_spin_rows: Array[Dictionary] = []
var _status_effect_tuning_spin_rows: Array[Dictionary] = []
var _mob_combat_field_defs: Array = []
var _mob_death_burst_field_defs: Array = []
var _mob_charge_field_defs: Array = []
var _tuning_ui_refreshing := false
var _offhand_tuning_ui_refreshing := false
var _status_effect_tuning_ui_refreshing := false
var _mob_tuning_ui_refreshing := false

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
	_gear_snapshots.load_from_disk()
	_mob_snapshots.load_from_disk()
	_status_effect_snapshots.load_from_disk()
	_build_weapon_options()
	_build_offhand_options()
	_status_effect_snapshots.register_all_catalog_statuses()
	_status_effect_snapshots.apply_saved_to_catalog()
	_register_mob_scenes()
	_setup_test_panels_tab()
	_setup_mob_type_option()
	_setup_weapon_filters()
	_setup_offhand_picker()
	_setup_offhand_section_visibility()
	_setup_offhand_gear_tuning_ui()
	_setup_status_effect_tuning_ui()
	call_deferred("_wire_gear_snapshot_to_registry")
	_setup_projectile_tuning_ui()
	_setup_mob_combat_tuning_ui()
	if not use_inventory_loadout:
		_equip_weapon(START_WEAPON)
	else:
		call_deferred("apply_inventory_loadout_to_player")
	%SpawnMobButton.pressed.connect(_on_spawn_mob_button_pressed)
	%MobTypeOption.item_selected.connect(_on_mob_type_option_selected)
	%EquipWeaponButton.pressed.connect(_on_equip_weapon_button_pressed)
	%EquipOffhandButton.pressed.connect(_on_equip_offhand_button_pressed)
	%WeaponOption.item_selected.connect(_on_weapon_option_selected)
	%OffhandOption.item_selected.connect(_on_offhand_option_selected)
	%ApplyOffhandTuningButton.pressed.connect(_on_apply_offhand_tuning_pressed)
	%SaveOffhandTuningButton.pressed.connect(_on_save_offhand_tuning_pressed)
	%ResetOffhandTuningButton.pressed.connect(_on_reset_offhand_tuning_pressed)
	%ApplyProjectileTuningButton.pressed.connect(_on_apply_projectile_tuning_pressed)
	%SaveProjectileTuningButton.pressed.connect(_on_save_projectile_tuning_pressed)
	%ResetProjectileTuningButton.pressed.connect(_on_reset_projectile_tuning_pressed)
	%ApplyMobCombatTuningButton.pressed.connect(_on_apply_mob_combat_tuning_pressed)
	%SaveMobCombatTuningButton.pressed.connect(_on_save_mob_combat_tuning_pressed)
	%ResetMobCombatTuningButton.pressed.connect(_on_reset_mob_combat_tuning_pressed)
	%ProjectileMovementOption.item_selected.connect(_on_projectile_movement_selected)
	%WeaponTypeFilter.item_selected.connect(_on_weapon_filters_changed)
	%WeaponRarityFilter.item_selected.connect(_on_weapon_filters_changed)
	%StatusEffectOption.item_selected.connect(_on_status_effect_option_selected)
	%ApplyStatusEffectTuningButton.pressed.connect(_on_apply_status_effect_tuning_pressed)
	%SaveStatusEffectTuningButton.pressed.connect(_on_save_status_effect_tuning_pressed)
	%ResetStatusEffectTuningButton.pressed.connect(_on_reset_status_effect_tuning_pressed)
	%Player.health_depleted.connect(_on_player_health_depleted)
	%MobRespawnCheck.toggled.connect(_on_mob_respawn_toggled)
	%EditOffhandStatusButton.pressed.connect(_on_edit_offhand_status_button_pressed)
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
	_equipped_offhand_id = menu_service.loadout.get_set_item_id(
		menu_service.loadout.active_set_index,
		EquipSlots.OFFHAND
	)
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


func _build_offhand_options() -> void:
	_all_offhand_options.clear()
	for gear in GearCatalog.get_all():
		if gear.fits_slot(EquipSlots.OFFHAND):
			_all_offhand_options.append(gear)
			_gear_snapshots.register_catalog_gear(gear)
	_all_offhand_options.sort_custom(_sort_gear_for_picker)


func _sort_gear_for_picker(a: GearData, b: GearData) -> bool:
	return a.get_display_name_localized() < b.get_display_name_localized()


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


# 몹·무기 패널 탭 제목을 한국어로 맞추고, 고정 너비 탭 바를 갱신합니다.
func _setup_test_panels_tab() -> void:
	var tabs: TabContainer = %TestPanelsTab
	tabs.set_tab_title(TEST_TAB_INDEX_MOB, "몹")
	tabs.set_tab_title(TEST_TAB_INDEX_WEAPON, "무기")
	tabs.set_tab_title(TEST_TAB_INDEX_STATUS_EFFECT, "상태이상")
	var tab_bar: VBoxContainer = %TabBarHost
	if tab_bar.has_method("rebuild_tabs"):
		tab_bar.rebuild_tabs()


func _setup_mob_type_option() -> void:
	var option: OptionButton = %MobTypeOption
	option.clear()
	for entry in MOB_OPTIONS:
		option.add_item(entry["label"])
	_update_mob_description()
	_refresh_mob_combat_tuning_ui()


func _on_mob_type_option_selected(_index: int) -> void:
	_update_mob_description()
	_refresh_mob_combat_tuning_ui()


func _register_mob_scenes() -> void:
	for entry in MOB_OPTIONS:
		_mob_snapshots.register_scene(entry["scene"] as PackedScene)


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


func _setup_offhand_picker() -> void:
	_refresh_offhand_option_list()


func _setup_offhand_section_visibility() -> void:
	var enabled := use_inventory_loadout and _inventory_menu != null
	%OffhandSectionLabel.visible = enabled
	%OffhandRow.visible = enabled
	%OffhandDescLabel.visible = enabled
	%OffhandStatusRow.visible = enabled
	%OffhandStatusOption.visible = enabled
	%OffhandTuningLabel.visible = enabled
	%OffhandTuningStatusLabel.visible = enabled
	%OffhandTuningFields.visible = enabled
	%OffhandTuningButtons.visible = enabled
	%StatusEffectNavLabel.visible = enabled
	%StatusEffectOption.visible = enabled
	if not enabled:
		return
	_update_offhand_description()
	_refresh_offhand_status_hint()
	_refresh_offhand_tuning_ui()


func _wire_gear_snapshot_to_registry() -> void:
	if not use_inventory_loadout or _inventory_menu == null:
		return
	var menu_service: InventoryService = _inventory_menu.get_service()
	if menu_service == null:
		return
	menu_service.registry.set_gear_modifier_resolver(
		Callable(_gear_snapshots, "resolve_modifiers")
	)


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
	if weapon == null:
		return
	_equip_weapon_from_gui(weapon)


func _on_equip_offhand_button_pressed() -> void:
	var gear := _get_selected_offhand()
	if gear == null:
		return
	_equip_offhand_from_gui(gear)


func _on_offhand_option_selected(_index: int) -> void:
	_update_offhand_description()
	_refresh_offhand_status_hint()
	_refresh_offhand_tuning_ui()


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


func _get_selected_offhand() -> GearData:
	var index: int = %OffhandOption.selected
	if index < 0 or index >= _all_offhand_options.size():
		return null
	return _all_offhand_options[index]


func _refresh_offhand_option_list(preserve_key: String = "") -> void:
	var option: OptionButton = %OffhandOption
	option.clear()
	if _all_offhand_options.is_empty():
		_update_offhand_description()
		return

	var select_index := 0
	for i in _all_offhand_options.size():
		var gear: GearData = _all_offhand_options[i]
		option.add_item(gear.get_display_name_localized())
		if not preserve_key.is_empty() and gear.get_unique_key() == preserve_key:
			select_index = i
	option.select(select_index)
	_update_offhand_description()


# 무기 GUI 착용 — 인벤 활성 세트에 반영한 뒤 플레이어에 튜닝 무기를 적용합니다.
func _equip_weapon_from_gui(catalog_weapon: WeaponData) -> void:
	if catalog_weapon == null:
		return
	if use_inventory_loadout and _inventory_menu != null:
		var menu_service: InventoryService = _inventory_menu.get_service()
		if menu_service != null:
			var weapon_id := catalog_weapon.get_unique_key()
			var err := menu_service.try_force_equip_weapon_on_active_set(weapon_id)
			if not err.is_empty():
				if has_node("%StatusLabel"):
					%StatusLabel.text = "무기 장착 실패 (%s)" % String(err)
				return
			if _inventory_menu.has_method("refresh_all_slots"):
				_inventory_menu.refresh_all_slots()
			if _inventory_menu.has_method("persist_loadout_if_enabled"):
				_inventory_menu.persist_loadout_if_enabled()
			apply_inventory_loadout_to_player()
			return
	_equip_weapon(catalog_weapon)


# 보조손 GUI 착용 — 인벤 활성 세트 offhand에 반영한 뒤 로드아웃을 재적용합니다.
func _equip_offhand_from_gui(gear: GearData) -> void:
	if gear == null:
		return
	if not use_inventory_loadout or _inventory_menu == null:
		if has_node("%StatusLabel"):
			%StatusLabel.text = "보조손 장착은 인벤 로드아웃(use_inventory_loadout)이 필요합니다."
		return
	var menu_service: InventoryService = _inventory_menu.get_service()
	if menu_service == null:
		return
	var gear_id := gear.get_unique_key()
	var err := menu_service.try_force_equip_offhand_on_active_set(gear_id)
	if not err.is_empty():
		if has_node("%StatusLabel"):
			%StatusLabel.text = UiLocale.t(err)
		return
	if _inventory_menu.has_method("refresh_all_slots"):
		_inventory_menu.refresh_all_slots()
	if _inventory_menu.has_method("persist_loadout_if_enabled"):
		_inventory_menu.persist_loadout_if_enabled()
	apply_inventory_loadout_to_player()
	var preserve_key := gear_id
	_refresh_offhand_option_list(preserve_key)
	if has_node("%StatusLabel"):
		%StatusLabel.text = "보조손 장착: %s" % gear.get_display_name_localized()
	_equipped_offhand_id = gear_id
	_refresh_offhand_tuning_ui()


# 플레이어에 튜닝된 무기를 장착하고 발사체 튜닝 UI를 갱신합니다.
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
		%ProjectileTuningStatusLabel.text = "이 무기는 무기 튜닝을 지원하지 않습니다."
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
		_populate_projectile_movement_dropdown(tuned)
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
	var property: String = field_def["property"]
	var initial_value := 0.0
	if field_def.get("bool", false):
		initial_value = 1.0 if bool(tuned.get(property)) else 0.0
	else:
		initial_value = _weapon_snapshots.get_tuning_spin_display_value(tuned, property)
	var row := TestArenaTuningUiUtil.create_tuning_row(
		%ProjectileTuningFields,
		field_def,
		initial_value,
		_on_projectile_tuning_value_changed.bind(catalog_weapon, property),
		_on_projectile_tuning_spin_tree_entered.bind(catalog_weapon, property),
		func(spin: SpinBox, direction: int) -> void:
			_on_tuning_spin_step_pressed(spin, catalog_weapon, property, direction),
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		TUNING_SPIN_MIN_HEIGHT
	)
	_tuning_spin_rows.append(row)


func _on_tuning_spin_tree_entered(spin: SpinBox) -> void:
	TestArenaTuningUiUtil.style_spin_line_edit(spin, TUNING_SPIN_MIN_HEIGHT, TUNING_SPIN_VALUE_FONT_SIZE)


func _on_projectile_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	_on_tuning_spin_tree_entered(spin)
	_wire_spin_box_text_commit(
		spin,
		func(new_value: float) -> void:
			_on_projectile_tuning_value_changed(new_value, catalog_weapon, property)
	)


# SpinBox LineEdit 직접 입력을 확정합니다(Godot 4 apply).
func _commit_spin_box_pending(spin: SpinBox) -> void:
	TestArenaTuningUiUtil.commit_spin_box_pending(spin)


# LineEdit에서 Enter·포커스 이탈 시 값을 세션에 반영합니다.
func _wire_spin_box_text_commit(spin: SpinBox, on_committed: Callable) -> void:
	TestArenaTuningUiUtil.wire_spin_box_text_commit(spin, on_committed)


func _on_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String,
	direction: int
) -> void:
	_on_projectile_tuning_value_changed(spin.value + spin.step * float(direction), catalog_weapon, property)
	_sync_tuning_spin_display(property, catalog_weapon)


func _populate_projectile_movement_dropdown(tuned: WeaponData) -> void:
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
		"min_damage",
		"max_damage",
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


func _commit_and_apply_projectile_tuning_from_spins() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	for row in _tuning_spin_rows:
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			continue
		_commit_spin_box_pending(spin)
		var property: String = row.get("property", "")
		if property.is_empty():
			continue
		_on_projectile_tuning_value_changed(spin.value, catalog_weapon, property)


func _on_apply_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	_commit_and_apply_projectile_tuning_from_spins()
	_update_status("무기 튜닝 적용: %s" % catalog_weapon.get_display_name_localized())


func _on_save_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	_commit_and_apply_projectile_tuning_from_spins()
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.save_weapon(weapon_id)
	_update_status("무기 스냅샷 저장: %s" % catalog_weapon.get_display_name_localized())
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


func _on_reset_projectile_tuning_pressed() -> void:
	var catalog_weapon := _get_selected_weapon()
	if catalog_weapon == null:
		return
	var weapon_id := catalog_weapon.get_unique_key()
	_weapon_snapshots.reset_weapon(weapon_id)
	_update_status("무기 스냅샷 초기화: %s" % catalog_weapon.get_display_name_localized())
	_apply_tuning_live(catalog_weapon)
	_refresh_projectile_tuning_ui()


func _setup_offhand_gear_tuning_ui() -> void:
	_clear_offhand_tuning_fields()
	%SaveOffhandTuningButton.disabled = true
	%ResetOffhandTuningButton.disabled = true


func _clear_offhand_tuning_fields() -> void:
	var fields := %OffhandTuningFields
	for child in fields.get_children():
		fields.remove_child(child)
		child.free()
	_offhand_tuning_spin_rows.clear()


func _refresh_offhand_tuning_ui() -> void:
	_clear_offhand_tuning_fields()
	var catalog_gear := _get_selected_offhand()
	if catalog_gear == null:
		%OffhandTuningStatusLabel.text = "보조손 목록이 비어 있습니다."
		%SaveOffhandTuningButton.disabled = true
		%ResetOffhandTuningButton.disabled = true
		return

	if not _gear_snapshots.supports_gear_tuning(catalog_gear):
		%OffhandTuningStatusLabel.text = "이 보조손은 수치 튜닝(막기·방어·무기 피해·파워)이 없습니다."
		%SaveOffhandTuningButton.disabled = true
		%ResetOffhandTuningButton.disabled = true
		return

	var gear_id := catalog_gear.get_unique_key()
	var tuned_mods := _gear_snapshots.build_tuned_stat_modifiers(gear_id)
	var field_defs: Array = _gear_snapshots.get_field_defs(catalog_gear)
	_offhand_tuning_ui_refreshing = true
	for field_def in field_defs:
		_add_offhand_tuning_row(catalog_gear, field_def, tuned_mods)
	_offhand_tuning_ui_refreshing = false

	var status_parts: PackedStringArray = []
	if _gear_snapshots.has_saved_snapshot(gear_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _gear_snapshots.get_session_overrides(gear_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if _equipped_offhand_id == gear_id:
		status_parts.append("장착 중 — 값 변경 시 즉시 반영")
	if status_parts.is_empty():
		%OffhandTuningStatusLabel.text = "카탈로그 기본값"
	else:
		%OffhandTuningStatusLabel.text = " · ".join(status_parts)
	%SaveOffhandTuningButton.disabled = false
	%ResetOffhandTuningButton.disabled = false


func _add_offhand_tuning_row(
	catalog_gear: GearData,
	field_def: Dictionary,
	tuned_modifiers: Dictionary
) -> void:
	var property: String = field_def["property"]
	var initial_value := _gear_snapshots.get_tuning_spin_display_value(tuned_modifiers, property)
	var row := TestArenaTuningUiUtil.create_tuning_row(
		%OffhandTuningFields,
		field_def,
		initial_value,
		_on_offhand_tuning_value_changed.bind(catalog_gear, property),
		_on_offhand_tuning_spin_tree_entered.bind(catalog_gear, property),
		func(spin: SpinBox, direction: int) -> void:
			_on_offhand_tuning_spin_step_pressed(spin, catalog_gear, property, direction),
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		TUNING_SPIN_MIN_HEIGHT
	)
	_offhand_tuning_spin_rows.append(row)


func _on_offhand_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String
) -> void:
	_on_tuning_spin_tree_entered(spin)
	_wire_spin_box_text_commit(
		spin,
		func(new_value: float) -> void:
			_on_offhand_tuning_value_changed(new_value, catalog_gear, property)
	)


func _on_offhand_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_gear: GearData,
	property: String,
	direction: int
) -> void:
	_on_offhand_tuning_value_changed(
		spin.value + spin.step * float(direction),
		catalog_gear,
		property
	)
	_sync_offhand_tuning_spin_display(property, catalog_gear)


func _on_offhand_tuning_value_changed(
	new_value: float,
	catalog_gear: GearData,
	property: String
) -> void:
	if _offhand_tuning_ui_refreshing or catalog_gear == null:
		return
	_store_offhand_tuning_value(catalog_gear, property, new_value)
	_apply_offhand_tuning_live(catalog_gear)
	_sync_offhand_tuning_spin_display(property, catalog_gear)
	_refresh_offhand_tuning_status_only(catalog_gear)


func _apply_offhand_tuning_live(catalog_gear: GearData) -> void:
	if not use_inventory_loadout:
		return
	apply_inventory_loadout_to_player()


func _sync_offhand_tuning_spin_display(property: String, catalog_gear: GearData) -> void:
	var gear_id := catalog_gear.get_unique_key()
	var tuned_mods := _gear_snapshots.build_tuned_stat_modifiers(gear_id)
	for row in _offhand_tuning_spin_rows:
		if row.get("property") != property:
			continue
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			return
		_offhand_tuning_ui_refreshing = true
		spin.value = _gear_snapshots.get_tuning_spin_display_value(tuned_mods, property)
		_offhand_tuning_ui_refreshing = false
		return


func _refresh_offhand_tuning_status_only(catalog_gear: GearData) -> void:
	var gear_id := catalog_gear.get_unique_key()
	var status_parts: PackedStringArray = []
	if _gear_snapshots.has_saved_snapshot(gear_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _gear_snapshots.get_session_overrides(gear_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if _equipped_offhand_id == gear_id:
		status_parts.append("장착 중 — 값 변경 시 즉시 반영")
	%OffhandTuningStatusLabel.text = " · ".join(status_parts) if not status_parts.is_empty() else "카탈로그 기본값"


func _store_offhand_tuning_value(
	catalog_gear: GearData,
	property: String,
	new_value: float
) -> void:
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

	_gear_snapshots.set_session_value(gear_id, property, stored)


func _commit_and_apply_offhand_tuning_from_spins() -> void:
	var catalog_gear := _get_selected_offhand()
	if catalog_gear == null:
		return
	for row in _offhand_tuning_spin_rows:
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			continue
		_commit_spin_box_pending(spin)
		var property: String = row.get("property", "")
		if property.is_empty():
			continue
		_store_offhand_tuning_value(catalog_gear, property, spin.value)
	_apply_offhand_tuning_live(catalog_gear)


func _on_apply_offhand_tuning_pressed() -> void:
	var catalog_gear := _get_selected_offhand()
	if catalog_gear == null:
		return
	_commit_and_apply_offhand_tuning_from_spins()
	_refresh_offhand_tuning_ui()
	_update_status("보조손 튜닝 적용: %s" % catalog_gear.get_display_name_localized())


func _on_save_offhand_tuning_pressed() -> void:
	var catalog_gear := _get_selected_offhand()
	if catalog_gear == null:
		return
	_commit_and_apply_offhand_tuning_from_spins()
	var gear_id := catalog_gear.get_unique_key()
	_gear_snapshots.save_gear(gear_id)
	_update_status("보조손 스냅샷 저장: %s" % catalog_gear.get_display_name_localized())
	_apply_offhand_tuning_live(catalog_gear)
	_refresh_offhand_tuning_ui()
	_update_offhand_description()


func _on_reset_offhand_tuning_pressed() -> void:
	var catalog_gear := _get_selected_offhand()
	if catalog_gear == null:
		return
	var gear_id := catalog_gear.get_unique_key()
	_gear_snapshots.reset_gear(gear_id)
	_update_status("보조손 스냅샷 초기화: %s" % catalog_gear.get_display_name_localized())
	_apply_offhand_tuning_live(catalog_gear)
	_refresh_offhand_tuning_ui()
	_update_offhand_description()


func _get_mob_combat_field_labels() -> Array[Label]:
	return [%MobDamageLabel, %MobRangeLabel, %MobIntervalLabel]


func _get_mob_death_burst_field_labels() -> Array[Label]:
	return [%MobBurstRadiusLabel, %MobBurstDamageLabel, %MobBurstDelayLabel]


func _get_mob_charge_field_labels() -> Array[Label]:
	return [%MobChargeDistanceLabel]


func _get_mob_combat_spins() -> Array[SpinBox]:
	return [%MobDamageSpin, %MobRangeSpin, %MobIntervalSpin]


func _get_mob_combat_step_buttons() -> Array[Button]:
	return [
		%MobDamageDecButton,
		%MobDamageIncButton,
		%MobRangeDecButton,
		%MobRangeIncButton,
		%MobIntervalDecButton,
		%MobIntervalIncButton,
	]


func _get_mob_death_burst_spins() -> Array[SpinBox]:
	return [%MobBurstRadiusSpin, %MobBurstDamageSpin, %MobBurstDelaySpin]


func _get_mob_death_burst_step_buttons() -> Array[Button]:
	return [
		%MobBurstRadiusDecButton,
		%MobBurstRadiusIncButton,
		%MobBurstDamageDecButton,
		%MobBurstDamageIncButton,
		%MobBurstDelayDecButton,
		%MobBurstDelayIncButton,
	]


func _setup_mob_combat_tuning_ui() -> void:
	var spins := _get_mob_combat_spins()
	for spin_index in spins.size():
		var spin: SpinBox = spins[spin_index]
		spin.add_theme_constant_override("updown_width", 0)
		spin.value_changed.connect(_on_mob_combat_spin_changed.bind(spin_index))
		spin.tree_entered.connect(
			_on_mob_combat_spin_tree_entered.bind(spin_index, spin),
			CONNECT_ONE_SHOT
		)
	%MobDamageDecButton.pressed.connect(_on_mob_combat_step_pressed.bind(0, -1))
	%MobDamageIncButton.pressed.connect(_on_mob_combat_step_pressed.bind(0, 1))
	%MobRangeDecButton.pressed.connect(_on_mob_combat_step_pressed.bind(1, -1))
	%MobRangeIncButton.pressed.connect(_on_mob_combat_step_pressed.bind(1, 1))
	%MobIntervalDecButton.pressed.connect(_on_mob_combat_step_pressed.bind(2, -1))
	%MobIntervalIncButton.pressed.connect(_on_mob_combat_step_pressed.bind(2, 1))
	var burst_spins := _get_mob_death_burst_spins()
	for burst_index in burst_spins.size():
		var burst_spin: SpinBox = burst_spins[burst_index]
		burst_spin.add_theme_constant_override("updown_width", 0)
		burst_spin.value_changed.connect(_on_mob_death_burst_spin_changed.bind(burst_index))
		burst_spin.tree_entered.connect(
			_on_mob_death_burst_spin_tree_entered.bind(burst_index, burst_spin),
			CONNECT_ONE_SHOT
		)
	%MobBurstRadiusDecButton.pressed.connect(_on_mob_death_burst_step_pressed.bind(0, -1))
	%MobBurstRadiusIncButton.pressed.connect(_on_mob_death_burst_step_pressed.bind(0, 1))
	%MobBurstDamageDecButton.pressed.connect(_on_mob_death_burst_step_pressed.bind(1, -1))
	%MobBurstDamageIncButton.pressed.connect(_on_mob_death_burst_step_pressed.bind(1, 1))
	%MobBurstDelayDecButton.pressed.connect(_on_mob_death_burst_step_pressed.bind(2, -1))
	%MobBurstDelayIncButton.pressed.connect(_on_mob_death_burst_step_pressed.bind(2, 1))
	%MobChargeDistanceSpin.add_theme_constant_override("updown_width", 0)
	%MobChargeDistanceSpin.value_changed.connect(_on_mob_charge_spin_changed.bind(0))
	%MobChargeDistanceSpin.tree_entered.connect(
		_on_mob_charge_spin_tree_entered.bind(0, %MobChargeDistanceSpin),
		CONNECT_ONE_SHOT
	)
	%MobChargeDistanceDecButton.pressed.connect(_on_mob_charge_step_pressed.bind(0, -1))
	%MobChargeDistanceIncButton.pressed.connect(_on_mob_charge_step_pressed.bind(0, 1))
	_refresh_mob_combat_tuning_ui()


func _set_mob_combat_tuning_enabled(enabled: bool) -> void:
	for spin in _get_mob_combat_spins():
		spin.editable = enabled
	for button in _get_mob_combat_step_buttons():
		button.disabled = not enabled
	%ApplyMobCombatTuningButton.disabled = not enabled
	%SaveMobCombatTuningButton.disabled = not enabled
	%ResetMobCombatTuningButton.disabled = not enabled


func _set_mob_death_burst_tuning_enabled(enabled: bool) -> void:
	%MobDeathBurstSection.visible = enabled
	for spin in _get_mob_death_burst_spins():
		spin.editable = enabled
	for button in _get_mob_death_burst_step_buttons():
		button.disabled = not enabled


func _get_mob_charge_spins() -> Array[SpinBox]:
	return [%MobChargeDistanceSpin]


func _get_mob_charge_step_buttons() -> Array[Button]:
	return [%MobChargeDistanceDecButton, %MobChargeDistanceIncButton]


func _set_mob_charge_tuning_enabled(enabled: bool) -> void:
	%MobChargeSection.visible = enabled
	for spin in _get_mob_charge_spins():
		spin.editable = enabled
	for button in _get_mob_charge_step_buttons():
		button.disabled = not enabled


func _configure_mob_combat_spin(spin: SpinBox, field_def: Dictionary) -> void:
	spin.min_value = float(field_def.get("min", 0.0))
	spin.max_value = float(field_def.get("max", 9999.0))
	spin.step = float(field_def.get("step", 1.0))
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.rounded = spin.step >= 1.0


func _apply_mob_tuning_field_style(
	label: Label,
	spin: SpinBox,
	scene: PackedScene,
	field_def: Dictionary
) -> void:
	var property: String = field_def["property"]
	var base_label: String = str(field_def.get("label", property))
	var state := _mob_snapshots.get_property_tuning_state(scene, property)
	var color := MOB_TUNING_COLOR_DEFAULT
	var suffix := ""
	if state == TestArenaMobSnapshot.TUNING_STATE_SAVED:
		color = MOB_TUNING_COLOR_SAVED
	elif state == TestArenaMobSnapshot.TUNING_STATE_SESSION:
		color = MOB_TUNING_COLOR_SESSION
		suffix = " *"
	label.text = base_label + suffix
	label.add_theme_color_override("font_color", color)
	spin.add_theme_color_override("font_color", color)
	var line_edit := spin.get_line_edit()
	if line_edit:
		line_edit.add_theme_color_override("font_color", color)


func _refresh_mob_tuning_field_styles(scene: PackedScene) -> void:
	var labels := _get_mob_combat_field_labels()
	var spins := _get_mob_combat_spins()
	for i in mini(labels.size(), _mob_combat_field_defs.size()):
		_apply_mob_tuning_field_style(labels[i], spins[i], scene, _mob_combat_field_defs[i])
	labels = _get_mob_death_burst_field_labels()
	spins = _get_mob_death_burst_spins()
	for i in mini(labels.size(), _mob_death_burst_field_defs.size()):
		_apply_mob_tuning_field_style(labels[i], spins[i], scene, _mob_death_burst_field_defs[i])
	labels = _get_mob_charge_field_labels()
	spins = _get_mob_charge_spins()
	for i in mini(labels.size(), _mob_charge_field_defs.size()):
		_apply_mob_tuning_field_style(labels[i], spins[i], scene, _mob_charge_field_defs[i])


func _refresh_mob_combat_tuning_ui() -> void:
	var scene := _get_selected_mob_scene()
	if scene == null or not _mob_snapshots.supports_combat_tuning(scene):
		_mob_combat_field_defs.clear()
		_mob_death_burst_field_defs.clear()
		_mob_charge_field_defs.clear()
		%MobCombatTuningStatusLabel.text = "몹 정보를 불러올 수 없습니다."
		_set_mob_combat_tuning_enabled(false)
		_set_mob_death_burst_tuning_enabled(false)
		_set_mob_charge_tuning_enabled(false)
		return

	_mob_combat_field_defs = _mob_snapshots.get_field_defs(scene)
	var spins := _get_mob_combat_spins()
	_mob_tuning_ui_refreshing = true
	for spin_index in spins.size():
		var field_def: Dictionary = _mob_combat_field_defs[spin_index]
		var spin: SpinBox = spins[spin_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_refresh_mob_death_burst_tuning_ui(scene)
	_refresh_mob_charge_tuning_ui(scene)
	_refresh_mob_tuning_field_styles(scene)
	_refresh_mob_combat_tuning_status_only(scene)
	_set_mob_combat_tuning_enabled(true)


func _refresh_mob_death_burst_tuning_ui(scene: PackedScene) -> void:
	if not _mob_snapshots.supports_death_burst_tuning(scene):
		_mob_death_burst_field_defs.clear()
		_set_mob_death_burst_tuning_enabled(false)
		return

	_mob_death_burst_field_defs = _mob_snapshots.get_death_burst_field_defs(scene)
	var burst_spins := _get_mob_death_burst_spins()
	_mob_tuning_ui_refreshing = true
	for burst_index in burst_spins.size():
		var field_def: Dictionary = _mob_death_burst_field_defs[burst_index]
		var spin: SpinBox = burst_spins[burst_index]
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
	var charge_spins := _get_mob_charge_spins()
	_mob_tuning_ui_refreshing = true
	for charge_index in charge_spins.size():
		var field_def: Dictionary = _mob_charge_field_defs[charge_index]
		var spin: SpinBox = charge_spins[charge_index]
		_configure_mob_combat_spin(spin, field_def)
		spin.value = _mob_snapshots.get_tuned_value(scene, field_def["property"])
	_mob_tuning_ui_refreshing = false
	_refresh_mob_tuning_field_styles(scene)
	_set_mob_charge_tuning_enabled(true)


func _on_mob_combat_spin_tree_entered(spin_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered(spin)
	_wire_spin_box_text_commit(
		spin,
		func(new_value: float) -> void:
			_on_mob_combat_spin_changed(spin_index, new_value)
	)


func _on_mob_death_burst_spin_tree_entered(burst_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered(spin)
	_wire_spin_box_text_commit(
		spin,
		func(new_value: float) -> void:
			_on_mob_death_burst_spin_changed(burst_index, new_value)
	)


func _on_mob_charge_spin_tree_entered(charge_index: int, spin: SpinBox) -> void:
	_on_tuning_spin_tree_entered(spin)
	_wire_spin_box_text_commit(
		spin,
		func(new_value: float) -> void:
			_on_mob_charge_spin_changed(charge_index, new_value)
	)


func _commit_and_apply_mob_tuning_from_spins() -> void:
	var scene := _get_selected_mob_scene()
	if scene == null:
		return
	for spin_index in _mob_combat_field_defs.size():
		var spin: SpinBox = _get_mob_combat_spins()[spin_index]
		_commit_spin_box_pending(spin)
		_on_mob_combat_spin_changed(spin_index, spin.value)
	for burst_index in _mob_death_burst_field_defs.size():
		var burst_spin: SpinBox = _get_mob_death_burst_spins()[burst_index]
		_commit_spin_box_pending(burst_spin)
		_on_mob_death_burst_spin_changed(burst_index, burst_spin.value)
	for charge_index in _mob_charge_field_defs.size():
		var charge_spin: SpinBox = _get_mob_charge_spins()[charge_index]
		_commit_spin_box_pending(charge_spin)
		_on_mob_charge_spin_changed(charge_index, charge_spin.value)


func _on_apply_mob_combat_tuning_pressed() -> void:
	var scene := _get_selected_mob_scene()
	if scene == null:
		return
	_commit_and_apply_mob_tuning_from_spins()
	var label: String = MOB_OPTIONS[%MobTypeOption.selected]["label"]
	_update_status("몹 전투 튜닝 적용: %s" % label)


func _on_mob_combat_step_pressed(spin_index: int, direction: int) -> void:
	var spins := _get_mob_combat_spins()
	if spin_index < 0 or spin_index >= spins.size():
		return
	var spin: SpinBox = spins[spin_index]
	_on_mob_combat_spin_changed(spin_index, spin.value + spin.step * float(direction))


func _on_mob_combat_spin_changed(spin_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := _get_selected_mob_scene()
	if scene == null or spin_index < 0 or spin_index >= _mob_combat_field_defs.size():
		return
	var property: String = _mob_combat_field_defs[spin_index]["property"]
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.set_session_value(scene_id, property, new_value)
	_apply_mob_tuning_live(scene)
	_sync_mob_combat_spin_display(spin_index, scene)
	_apply_mob_tuning_field_style(
		_get_mob_combat_field_labels()[spin_index],
		_get_mob_combat_spins()[spin_index],
		scene,
		_mob_combat_field_defs[spin_index]
	)
	_update_mob_description()
	_refresh_mob_combat_tuning_status_only(scene)


func _on_mob_death_burst_step_pressed(burst_index: int, direction: int) -> void:
	var burst_spins := _get_mob_death_burst_spins()
	if burst_index < 0 or burst_index >= burst_spins.size():
		return
	var spin: SpinBox = burst_spins[burst_index]
	_on_mob_death_burst_spin_changed(burst_index, spin.value + spin.step * float(direction))


func _on_mob_death_burst_spin_changed(burst_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := _get_selected_mob_scene()
	if scene == null or burst_index < 0 or burst_index >= _mob_death_burst_field_defs.size():
		return
	var property: String = _mob_death_burst_field_defs[burst_index]["property"]
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.set_session_value(scene_id, property, new_value)
	_apply_mob_tuning_live(scene)
	_sync_mob_death_burst_spin_display(burst_index, scene)
	_apply_mob_tuning_field_style(
		_get_mob_death_burst_field_labels()[burst_index],
		_get_mob_death_burst_spins()[burst_index],
		scene,
		_mob_death_burst_field_defs[burst_index]
	)
	_update_mob_description()
	_refresh_mob_combat_tuning_status_only(scene)


func _sync_mob_death_burst_spin_display(burst_index: int, scene: PackedScene) -> void:
	var burst_spins := _get_mob_death_burst_spins()
	if burst_index < 0 or burst_index >= burst_spins.size() or burst_index >= _mob_death_burst_field_defs.size():
		return
	var property: String = _mob_death_burst_field_defs[burst_index]["property"]
	_mob_tuning_ui_refreshing = true
	burst_spins[burst_index].value = _mob_snapshots.get_tuned_value(scene, property)
	_mob_tuning_ui_refreshing = false


func _on_mob_charge_step_pressed(charge_index: int, direction: int) -> void:
	var charge_spins := _get_mob_charge_spins()
	if charge_index < 0 or charge_index >= charge_spins.size():
		return
	var spin: SpinBox = charge_spins[charge_index]
	_on_mob_charge_spin_changed(charge_index, spin.value + spin.step * float(direction))


func _on_mob_charge_spin_changed(charge_index: int, new_value: float) -> void:
	if _mob_tuning_ui_refreshing:
		return
	var scene := _get_selected_mob_scene()
	if scene == null or charge_index < 0 or charge_index >= _mob_charge_field_defs.size():
		return
	var property: String = _mob_charge_field_defs[charge_index]["property"]
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.set_session_value(scene_id, property, new_value)
	_apply_mob_tuning_live(scene)
	_sync_mob_charge_spin_display(charge_index, scene)
	_apply_mob_tuning_field_style(
		_get_mob_charge_field_labels()[charge_index],
		_get_mob_charge_spins()[charge_index],
		scene,
		_mob_charge_field_defs[charge_index]
	)
	_update_mob_description()
	_refresh_mob_combat_tuning_status_only(scene)


func _sync_mob_charge_spin_display(charge_index: int, scene: PackedScene) -> void:
	var charge_spins := _get_mob_charge_spins()
	if charge_index < 0 or charge_index >= charge_spins.size() or charge_index >= _mob_charge_field_defs.size():
		return
	var property: String = _mob_charge_field_defs[charge_index]["property"]
	_mob_tuning_ui_refreshing = true
	charge_spins[charge_index].value = _mob_snapshots.get_tuned_value(scene, property)
	_mob_tuning_ui_refreshing = false


func _apply_mob_tuning_live(scene: PackedScene) -> void:
	if (
		_active_mob == null
		or not is_instance_valid(_active_mob)
		or _last_mob_scene != scene
	):
		return
	_mob_snapshots.apply_to_mob(_active_mob, scene)
	if _active_mob.is_node_ready():
		_active_mob.refresh_attack_range_ring()


func _sync_mob_combat_spin_display(spin_index: int, scene: PackedScene) -> void:
	var spins := _get_mob_combat_spins()
	if spin_index < 0 or spin_index >= spins.size() or spin_index >= _mob_combat_field_defs.size():
		return
	var property: String = _mob_combat_field_defs[spin_index]["property"]
	_mob_tuning_ui_refreshing = true
	spins[spin_index].value = _mob_snapshots.get_tuned_value(scene, property)
	_mob_tuning_ui_refreshing = false


func _refresh_mob_combat_tuning_status_only(scene: PackedScene) -> void:
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	var status_parts: PackedStringArray = []
	if _mob_snapshots.has_saved_snapshot(scene_id):
		status_parts.append("저장된 스냅샷 적용 중")
	if not _mob_snapshots.get_session_overrides(scene_id).is_empty():
		status_parts.append("미저장 변경 있음")
	if (
		_active_mob != null
		and is_instance_valid(_active_mob)
		and _last_mob_scene == scene
	):
		status_parts.append("스폰 중 — 값 변경 시 즉시 반영")
	var legend := "색: 기본 · 저장 · 미저장*"
	if status_parts.is_empty():
		%MobCombatTuningStatusLabel.text = "프리팹 기본값 — %s" % legend
	else:
		%MobCombatTuningStatusLabel.text = "%s — %s" % [" · ".join(status_parts), legend]


func _on_save_mob_combat_tuning_pressed() -> void:
	var scene := _get_selected_mob_scene()
	if scene == null:
		return
	_commit_and_apply_mob_tuning_from_spins()
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.save_mob(scene_id)
	var label: String = MOB_OPTIONS[%MobTypeOption.selected]["label"]
	_update_status("몹 전투 스냅샷 저장: %s" % label)
	_apply_mob_tuning_live(scene)
	_refresh_mob_combat_tuning_ui()


func _on_reset_mob_combat_tuning_pressed() -> void:
	var scene := _get_selected_mob_scene()
	if scene == null:
		return
	var scene_id := TestArenaMobSnapshot.get_scene_id(scene)
	_mob_snapshots.reset_mob(scene_id)
	var label: String = MOB_OPTIONS[%MobTypeOption.selected]["label"]
	_update_status("몹 전투 스냅샷 초기화: %s" % label)
	_apply_mob_tuning_live(scene)
	_refresh_mob_combat_tuning_ui()
	_update_mob_description()


# 선택한 몹 프리팹을 스폰 포인트에 배치합니다.
func spawn_test_mob(scene: PackedScene) -> void:
	if scene == null:
		push_error("TestArena.spawn_test_mob: scene is null.")
		return
	_cancel_pending_mob_respawn()
	_clear_active_mob()
	var spawn_pos: Vector2 = _get_test_mob_spawn_position()
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
	_mob_snapshots.apply_to_mob(mob, scene)
	if mob.is_node_ready():
		mob.refresh_attack_range_ring()
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
	if use_inventory_loadout and %Player.has_method(&"apply_loadout_on_kill"):
		%Player.apply_loadout_on_kill()
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


# F6 튜닝 GUI에서 수정 가능한 무기 속성 목록을 반환합니다.
func _get_weapon_omit_properties(catalog_weapon: WeaponData) -> Array[String]:
	var omit: Array[String] = []
	if catalog_weapon == null or not _weapon_snapshots.supports_projectile_tuning(catalog_weapon):
		return omit
	for field_def in _weapon_snapshots.get_field_defs(catalog_weapon):
		omit.append(field_def["property"])
	if _weapon_snapshots.supports_projectile_movement_tuning(catalog_weapon):
		omit.append("projectile_movement")
	return omit


# 드롭다운에서 선택 중인 무기 설명을 표시합니다.
func _update_weapon_description() -> void:
	var weapon := _get_selected_weapon()
	if weapon:
		var tuned := _weapon_snapshots.build_tuned_weapon(weapon)
		%WeaponDescLabel.text = tuned.build_test_arena_info_bbcode(_get_weapon_omit_properties(weapon))
	else:
		%WeaponDescLabel.text = "조건에 맞는 무기가 없습니다."


# 드롭다운에서 선택 중인 보조손 설명을 표시합니다.
func _update_offhand_description() -> void:
	if not %OffhandDescLabel.visible:
		return
	var gear := _get_selected_offhand()
	if gear:
		var tuned := _gear_snapshots.build_tuned_gear(gear)
		var slot_label := UiLocale.t(&"slot.offhand")
		%OffhandDescLabel.text = GearStatDisplay.build_gear_tooltip(tuned, slot_label)
	else:
		%OffhandDescLabel.text = "보조손 목록이 비어 있습니다."


# 보조손 grant_on_hit 상태이상 정보를 장비 탭에 읽기 전용으로 표시합니다.
func _refresh_offhand_status_hint() -> void:
	if not %OffhandStatusRow.visible:
		return
	var status_ids := _get_selected_offhand_status_ids()
	if status_ids.is_empty():
		%OffhandStatusHintLabel.text = "적중 상태이상: 없음"
		%OffhandStatusOption.clear()
		%EditOffhandStatusButton.disabled = true
		var empty_status_ids: Array[StringName] = []
		_refresh_status_tab_options(empty_status_ids, &"")
		return
	%OffhandStatusHintLabel.text = "적중 상태이상:"
	%OffhandStatusOption.clear()
	for status_id in status_ids:
		%OffhandStatusOption.add_item(StatusEffectCatalog.get_display_name(status_id))
		%OffhandStatusOption.set_item_metadata(%OffhandStatusOption.get_item_count() - 1, status_id)
	%EditOffhandStatusButton.disabled = false
	var selected_id := status_ids[0]
	if %StatusEffectOption.get_item_count() > 0 and %StatusEffectOption.selected >= 0:
		var current_id := StringName(%StatusEffectOption.get_item_metadata(%StatusEffectOption.selected))
		if current_id != &"":
			selected_id = current_id
	var selected_index := 0
	for i in status_ids.size():
		if status_ids[i] == selected_id:
			selected_index = i
			break
	%OffhandStatusOption.select(selected_index)
	_refresh_status_tab_options(status_ids, selected_id)


# 장비 탭의 상태이상 수정 버튼으로 상태이상 탭을 열고 대상을 자동 선택합니다.
func _on_edit_offhand_status_button_pressed() -> void:
	var status_ids := _get_selected_offhand_status_ids()
	if status_ids.is_empty():
		_update_status("수정할 상태이상이 없습니다.")
		return
	var selected_id := status_ids[0]
	if %OffhandStatusOption.get_item_count() > 0 and %OffhandStatusOption.selected >= 0:
		selected_id = StringName(%OffhandStatusOption.get_item_metadata(%OffhandStatusOption.selected))
	_open_status_tab_with_status(selected_id)


func _open_status_tab_with_status(status_id: StringName) -> void:
	var status_ids := _get_selected_offhand_status_ids()
	_refresh_status_tab_options(status_ids, status_id)
	var tabs: TabContainer = %TestPanelsTab
	tabs.current_tab = TEST_TAB_INDEX_STATUS_EFFECT
	var selected_label := StatusEffectCatalog.get_display_name(status_id)
	%StatusEffectNavLabel.text = "선택됨: %s" % selected_label


func _refresh_status_tab_options(status_ids: Array[StringName], preferred_status_id: StringName) -> void:
	var option: OptionButton = %StatusEffectOption
	_status_effect_tuning_ui_refreshing = true
	option.clear()
	if status_ids.is_empty():
		%StatusEffectNavLabel.text = "장비 탭에서 상태이상 수정을 선택하세요."
		%StatusEffectRuleHintLabel.text = ""
		_status_effect_tuning_ui_refreshing = false
		_refresh_status_effect_tuning_ui()
		return
	var selected_index := 0
	for i in status_ids.size():
		var status_id := status_ids[i]
		option.add_item(StatusEffectCatalog.get_display_name(status_id))
		option.set_item_metadata(i, status_id)
		if preferred_status_id != &"" and status_id == preferred_status_id:
			selected_index = i
	option.select(selected_index)
	var selected_id := StringName(option.get_item_metadata(selected_index))
	%StatusEffectNavLabel.text = "선택됨: %s" % StatusEffectCatalog.get_display_name(selected_id)
	%StatusEffectRuleHintLabel.text = _build_status_rule_hint(selected_id)
	_status_effect_tuning_ui_refreshing = false
	_refresh_status_effect_tuning_ui()


func _get_selected_offhand_status_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var gear := _get_selected_offhand()
	if gear == null:
		return result
	var stats := GearStatMerge.normalize_modifiers(gear.stat_modifiers)
	if not stats.has("grant_on_hit"):
		return result
	var raw_tags: Variant = stats["grant_on_hit"]
	if raw_tags is Array:
		for raw_tag in raw_tags:
			var status_id := StringName(String(raw_tag).strip_edges())
			if status_id == &"" or status_id in result:
				continue
			if not StatusEffectCatalog.has_status(status_id):
				continue
			result.append(status_id)
		return result
	var status_id := StringName(String(raw_tags).strip_edges())
	if status_id != &"" and StatusEffectCatalog.has_status(status_id):
		result.append(status_id)
	return result


func _setup_status_effect_tuning_ui() -> void:
	_clear_status_effect_tuning_fields()
	%ApplyStatusEffectTuningButton.disabled = true
	%SaveStatusEffectTuningButton.disabled = true
	%ResetStatusEffectTuningButton.disabled = true
	%StatusEffectTuningStatusLabel.text = "장비 탭에서 상태이상을 선택하세요."


func _clear_status_effect_tuning_fields() -> void:
	for child in %StatusEffectTuningFields.get_children():
		%StatusEffectTuningFields.remove_child(child)
		child.free()
	_status_effect_tuning_spin_rows.clear()


func _on_status_effect_option_selected(_index: int) -> void:
	if _status_effect_tuning_ui_refreshing:
		return
	_refresh_status_effect_tuning_ui()


func _refresh_status_effect_tuning_ui() -> void:
	_clear_status_effect_tuning_fields()
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		%StatusEffectTuningStatusLabel.text = "장비 탭에서 상태이상을 선택하세요."
		%ApplyStatusEffectTuningButton.disabled = true
		%SaveStatusEffectTuningButton.disabled = true
		%ResetStatusEffectTuningButton.disabled = true
		return
	if not _status_effect_snapshots.supports_status_tuning(status_id):
		%StatusEffectTuningStatusLabel.text = "이 상태이상은 튜닝을 지원하지 않습니다."
		%ApplyStatusEffectTuningButton.disabled = true
		%SaveStatusEffectTuningButton.disabled = true
		%ResetStatusEffectTuningButton.disabled = true
		return
	var tuned := _status_effect_snapshots.build_tuned_values(status_id)
	var field_defs := _status_effect_snapshots.get_field_defs(status_id)
	_status_effect_tuning_ui_refreshing = true
	for field_def in field_defs:
		_add_status_effect_tuning_row(status_id, field_def, tuned)
	_status_effect_tuning_ui_refreshing = false
	_refresh_status_effect_tuning_status_only(status_id)
	%ApplyStatusEffectTuningButton.disabled = false
	%SaveStatusEffectTuningButton.disabled = false
	%ResetStatusEffectTuningButton.disabled = false


func _add_status_effect_tuning_row(status_id: StringName, field_def: Dictionary, tuned: Dictionary) -> void:
	var property: String = field_def["property"]
	var initial_value := float(tuned.get(property, 0.0))
	var row := TestArenaTuningUiUtil.create_tuning_row(
		%StatusEffectTuningFields,
		field_def,
		initial_value,
		_on_status_effect_tuning_value_changed.bind(status_id, property),
		_on_status_effect_tuning_spin_tree_entered.bind(status_id, property),
		func(spin: SpinBox, direction: int) -> void:
			_on_status_effect_tuning_step_pressed(spin, status_id, property, direction),
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		TUNING_SPIN_MIN_HEIGHT
	)
	_apply_status_effect_tuning_row_lock_state(status_id, property, row)
	_status_effect_tuning_spin_rows.append(row)


func _on_status_effect_tuning_spin_tree_entered(
	spin: SpinBox,
	status_id: StringName,
	property: String
) -> void:
	_on_tuning_spin_tree_entered(spin)
	_wire_spin_box_text_commit(
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
	if _active_mob != null and is_instance_valid(_active_mob):
		# 수치 변경 시 활성 효과의 남은 지속시간은 유지합니다.
		_active_mob.refresh_status_effect_profiles(status_id, false)


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
	%StatusEffectTuningStatusLabel.text = (
		" · ".join(status_parts)
		if not status_parts.is_empty()
		else "카탈로그 기본값"
	)
	%StatusEffectRuleHintLabel.text = _build_status_rule_hint(status_id)


func _commit_and_apply_status_effect_tuning_from_spins() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	for row in _status_effect_tuning_spin_rows:
		var spin: SpinBox = row.get("spin")
		if not is_instance_valid(spin):
			continue
		_commit_spin_box_pending(spin)
		var property: String = row.get("property", "")
		if property.is_empty():
			continue
		_store_status_effect_tuning_value(status_id, property, spin.value)
	_apply_status_effect_tuning_live(status_id)


func _on_apply_status_effect_tuning_pressed() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	_commit_and_apply_status_effect_tuning_from_spins()
	_refresh_status_effect_tuning_ui()
	_update_status("상태이상 튜닝 적용: %s" % StatusEffectCatalog.get_display_name(status_id))


func _on_save_status_effect_tuning_pressed() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	_commit_and_apply_status_effect_tuning_from_spins()
	_status_effect_snapshots.save_status(status_id)
	_refresh_status_effect_tuning_ui()
	_update_status("상태이상 스냅샷 저장: %s" % StatusEffectCatalog.get_display_name(status_id))


func _on_reset_status_effect_tuning_pressed() -> void:
	var status_id := _get_selected_status_effect_id()
	if status_id == &"":
		return
	_status_effect_snapshots.reset_status(status_id)
	_refresh_status_effect_tuning_ui()
	_update_status("상태이상 스냅샷 초기화: %s" % StatusEffectCatalog.get_display_name(status_id))


func _get_selected_status_effect_id() -> StringName:
	var option: OptionButton = %StatusEffectOption
	if option.get_item_count() <= 0 or option.selected < 0:
		return &""
	return StringName(option.get_item_metadata(option.selected))


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


# 드롭다운에서 선택 중인 몹 스탯·역할을 표시합니다.
func _update_mob_description() -> void:
	%MobDescLabel.text = _build_mob_info_bbcode(_get_selected_mob_scene())


func _build_mob_info_bbcode(scene: PackedScene) -> String:
	if scene == null:
		return "몹 정보를 불러올 수 없습니다."
	var mob := scene.instantiate() as Mob
	if mob == null:
		return "몹 정보를 불러올 수 없습니다."

	_mob_snapshots.apply_to_mob(mob, scene)

	var hp_mult := _get_test_mob_hp_multiplier(scene, mob)
	var test_hp := maxi(1, roundi(float(mob.base_max_health) * maxf(hp_mult, 0.01)))
	var kind_label: String = MOB_KIND_LABELS_KO.get(mob.mob_kind, str(mob.mob_kind))
	var role_hint: String = MOB_ROLE_HINTS_KO.get(mob.mob_kind, "")
	var rewards := KillRewards.compute(mob.mob_kind, null)

	var lines: PackedStringArray = []
	lines.append("[color=#ffdd55]%s[/color] · %s" % [kind_label, mob.mob_kind])
	if not role_hint.is_empty():
		lines.append(role_hint)
	lines.append(
		"체력: %d (프리팹) → %d (F6 스폰)" % [mob.base_max_health, test_hp]
	)
	lines.append("이동 속도: %.0f~%.0f" % [mob.speed_min, mob.speed_max])
	if not mob.movement_enabled:
		lines.append("[color=#a9a9b0]이동 없음[/color]")
	if not mob.combat_enabled:
		lines.append("[color=#a9a9b0]전투 없음[/color]")
	elif mob.ranged_attack_enabled:
		lines.append("예고: %.1fs" % mob.ranged_telegraph_delay)
	if (
		mob.death_burst_enabled
		and not _mob_snapshots.supports_death_burst_tuning(scene)
		and not _mob_snapshots.supports_charge_tuning(scene)
	):
		var burst_line := "사망 폭발: 반경 %.0f · %d 피해" % [
			mob.death_burst_radius,
			mob.death_burst_damage,
		]
		if mob.death_burst_delay > 0.0:
			burst_line += " · %.1fs 후" % mob.death_burst_delay
		lines.append(burst_line)
	if mob.charge_attack_enabled:
		lines.append("돌진 발동 거리: %.0f" % mob.charge_trigger_distance)
		if not _mob_snapshots.supports_charge_tuning(scene):
			var travel := mob.speed * mob.charge_speed_mult * mob.charge_duration
			lines.append(
				"돌진 거리(참고): %.0f · ×%.1f 속도 · %.2fs"
				% [travel, mob.charge_speed_mult, mob.charge_duration]
			)
		if mob.charge_end_burst_radius > 0.0:
			lines.append(
				"돌진 종료 폭발: 반경 %.0f · %d 피해"
				% [mob.charge_end_burst_radius, mob.charge_end_burst_damage]
			)
	if mob.self_destruct_enabled:
		lines.append("자폭: 체력 %.0f%% 이하" % (mob.self_destruct_health_ratio * 100.0))
	if int(rewards.get("xp", 0)) > 0:
		lines.append("처치 보상(기본): XP %d · 골드 %d" % [rewards["xp"], rewards["gold"]])
	else:
		lines.append("[color=#a9a9b0]처치 보상 없음[/color]")

	mob.free()
	return "\n".join(lines)


# 플레이어 초기 스폰 기준 고정 몹 스폰 좌표(%MobSpawnPoint)를 반환합니다.
func _get_test_mob_spawn_position() -> Vector2:
	return %MobSpawnPoint.global_position


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
