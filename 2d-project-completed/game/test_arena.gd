extends Node2D

## 몹·무기 전투를 빠르게 검증하는 테스트 아레나(메인 루프·밸런스 스폰 없음).

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")
const GearCatalog = preload("res://inventory/gear_catalog.gd")
const TestArenaTuningUiUtil = preload("res://game/test_arena_tuning_ui.gd")
const TestArenaStatusEffectSnapshotScript = preload("res://game/test_arena_status_effect_snapshot.gd")
const TestArenaStatusEffectControllerScript = preload("res://game/test_arena_status_effect_controller.gd")
const TestArenaWeaponPanelControllerScript = preload("res://game/test_arena_weapon_panel_controller.gd")
const TestArenaGearPanelControllerScript = preload("res://game/test_arena_gear_panel_controller.gd")
const TestArenaMobPanelControllerScript = preload("res://game/test_arena_mob_panel_controller.gd")
const TestArenaPlayerPanelControllerScript = preload("res://game/test_arena_player_panel_controller.gd")
const TestArenaPlayerSnapshotScript = preload("res://game/test_arena_player_snapshot.gd")
const EQUIPMENT_DROP_SCENE := preload("res://effects/equipment_drop/equipment_drop.tscn")
const RelicCombatBridgeScript = preload("res://inventory/relic_combat_bridge.gd")

const START_WEAPON := preload("res://weapons/data/katana.tres")
const PLAYER_RESPAWN_DELAY := 3.0
const TUNING_SPIN_BUTTON_SIZE := Vector2(52, 52)
const TUNING_SPIN_MIN_HEIGHT := 48
const TUNING_SPIN_BUTTON_FONT_SIZE := 24
const TUNING_SPIN_VALUE_FONT_SIZE := 17
const TEST_TAB_INDEX_PLAYER := 0
const TEST_TAB_INDEX_MOB := 1
const TEST_TAB_INDEX_WEAPON := 2
const TEST_TAB_INDEX_GEAR := 3
const TEST_TAB_INDEX_STATUS_EFFECT := 4
const WEAPON_SUB_TAB_INDEX_PRIMARY := 0
const WEAPON_SUB_TAB_INDEX_OFFHAND := 1

const ARMOR_SLOT_LABELS_KO: Dictionary = {
	EquipSlots.HELMET: "헬멧",
	EquipSlots.ARMOR: "갑옷",
	EquipSlots.GLOVES: "장갑",
	EquipSlots.BOOTS: "부츠",
	EquipSlots.ACCESSORY: "악세",
}
const DUMMY_BASE_MAX_HEALTH := 500
const NON_DUMMY_HP_VS_DUMMY_MULTIPLIER := 10.0
## F6 QA — 1.0이면 affix 몹 처치 시 유물 100% 드랍(E4). F5에는 노출하지 않습니다.
@export_range(0.0, 1.0, 0.0001) var relic_drop_debug_rate := 0.0
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
var _available_rarities: Array[String] = []
var _active_mob: Mob = null
var _last_mob_scene: PackedScene = null
var _player_is_dead := false
var _saved_player_collision_layer := 0
var _saved_player_collision_mask := 0
var _saved_auto_attack_enabled := true
var _mob_respawn_token := 0
var _weapon_damage := WeaponDamageTracker.new()
var _weapon_snapshots: TestArenaWeaponSnapshot
var _gear_snapshots := TestArenaGearSnapshot.new()
var _mob_snapshots := TestArenaMobSnapshot.new()
var _status_effect_snapshots := TestArenaStatusEffectSnapshotScript.new()
var _status_effect_controller := TestArenaStatusEffectControllerScript.new()
var _weapon_panel_controller := TestArenaWeaponPanelControllerScript.new()
var _gear_panel_controller := TestArenaGearPanelControllerScript.new()
var _mob_panel_controller := TestArenaMobPanelControllerScript.new()
var _player_panel_controller := TestArenaPlayerPanelControllerScript.new()
var _player_snapshot := TestArenaPlayerSnapshotScript.new()
var _equipped_weapon_id := ""
var _equipped_offhand_id := ""
var _pending_offhand_context_restore := false
var _pending_offhand_gear_id := ""
var _pending_offhand_status_id: StringName = &""

var _pause_menu: CanvasLayer
var _inventory_menu: CanvasLayer


func _ready() -> void:
	# Step0 경계 고정: 로드 → 옵션빌드 → 탭세팅 → UI세팅 → signal connect
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
	# 1) load: 스냅샷 복원/카탈로그 반영 (F5와 동일 인스턴스 공유)
	_weapon_snapshots = DevWeaponTuning.get_snapshot()
	_weapon_snapshots.clear_session()
	_weapon_snapshots.load_from_disk()
	_gear_snapshots.load_from_disk()
	_player_snapshot.load_from_disk()
	DevTuningStore.reload_mob_authoring()
	DevTuningStore.reload_weapon_authoring()
	EliteFeatureFlags.affix_roll_enabled = false
	_status_effect_snapshots.load_from_disk()
	# 컨트롤러는 옵션 빌드 전에 의존성 주입이 필요합니다.
	_configure_player_panel_controller()
	_configure_weapon_panel_controller()
	_configure_gear_panel_controller()
	_configure_mob_panel_controller()
	_configure_status_effect_controller()
	# 2) 옵션 빌드: 무기/장비/몹 데이터 준비
	_build_weapon_options()
	_build_offhand_options()
	_build_armor_gear_options()
	_status_effect_snapshots.register_all_catalog_statuses()
	_status_effect_snapshots.apply_saved_to_catalog()
	_register_mob_scenes()
	# 3) 탭 세팅: TestPanels 탭 타이틀/탭바 구성
	_setup_test_panels_tab()
	_setup_weapon_sub_tabs()
	_setup_player_class_option()
	# 4) UI 세팅: 탭별 Option/튜닝/가시성 초기화
	_setup_mob_type_option()
	_setup_weapon_filters()
	_setup_offhand_picker()
	_setup_offhand_section_visibility()
	_setup_armor_gear_picker()
	_setup_armor_gear_section_visibility()
	_gear_panel_controller.setup_offhand_gear_tuning_ui()
	_gear_panel_controller.setup_armor_gear_tuning_ui()
	_setup_status_effect_tuning_ui()
	call_deferred("_wire_gear_snapshot_to_registry")
	_weapon_panel_controller.setup_projectile_tuning_ui()
	_setup_mob_combat_tuning_ui()
	_setup_mob_affix_option()
	if not use_inventory_loadout:
		_equip_weapon(START_WEAPON)
	else:
		call_deferred("apply_inventory_loadout_to_player")
	# 5) signal connect: UI 이벤트 및 런타임 브리지 연결
	%PlayerClassOption.item_selected.connect(_on_player_class_option_selected)
	%PlayerDefaultWeaponOption.item_selected.connect(_on_player_default_weapon_option_selected)
	%HealPlayerButton.pressed.connect(_player_panel_controller.on_heal_player_pressed)
	%SavePlayerMoveSpeedButton.pressed.connect(_player_panel_controller.on_save_player_tuning_pressed)
	%ResetPlayerMoveSpeedButton.pressed.connect(_player_panel_controller.on_reset_player_tuning_pressed)
	%CreatePlayerButton.pressed.connect(_on_create_player_button_pressed)
	%SpawnMobButton.pressed.connect(_on_spawn_mob_button_pressed)
	%MobTypeOption.item_selected.connect(_on_mob_type_option_selected)
	%EquipWeaponButton.pressed.connect(_weapon_panel_controller.on_equip_weapon_button_pressed)
	%EquipOffhandButton.pressed.connect(_gear_panel_controller.on_equip_offhand_button_pressed)
	%EquipArmorButton.pressed.connect(_gear_panel_controller.on_equip_armor_button_pressed)
	%WeaponOption.item_selected.connect(_on_weapon_option_selected)
	%OffhandOption.item_selected.connect(_on_offhand_option_selected)
	%ArmorSlotFilter.item_selected.connect(_on_armor_slot_filter_selected)
	%ArmorGearOption.item_selected.connect(_on_armor_gear_option_selected)
	%ApplyOffhandTuningButton.pressed.connect(_gear_panel_controller.on_apply_offhand_tuning_pressed)
	%SaveOffhandTuningButton.pressed.connect(_gear_panel_controller.on_save_offhand_tuning_pressed)
	%ResetOffhandTuningButton.pressed.connect(_gear_panel_controller.on_reset_offhand_tuning_pressed)
	%ApplyArmorGearTuningButton.pressed.connect(_gear_panel_controller.on_apply_armor_gear_tuning_pressed)
	%SaveArmorGearTuningButton.pressed.connect(_gear_panel_controller.on_save_armor_gear_tuning_pressed)
	%ResetArmorGearTuningButton.pressed.connect(_gear_panel_controller.on_reset_armor_gear_tuning_pressed)
	%ApplyProjectileTuningButton.pressed.connect(_weapon_panel_controller.on_apply_projectile_tuning_pressed)
	%SaveProjectileTuningButton.pressed.connect(_weapon_panel_controller.on_save_projectile_tuning_pressed)
	%ResetProjectileTuningButton.pressed.connect(_weapon_panel_controller.on_reset_projectile_tuning_pressed)
	%ApplyMobCombatTuningButton.pressed.connect(_on_apply_mob_combat_tuning_pressed)
	%SaveMobCombatTuningButton.pressed.connect(_on_save_mob_combat_tuning_pressed)
	%ResetMobCombatTuningButton.pressed.connect(_on_reset_mob_combat_tuning_pressed)
	%ProjectileMovementOption.item_selected.connect(_on_projectile_movement_selected)
	%WeaponTypeFilter.item_selected.connect(_on_weapon_filters_changed)
	%WeaponRarityFilter.item_selected.connect(_on_weapon_filters_changed)
	%WeaponLockFilter.item_selected.connect(_on_weapon_filters_changed)
	%OffhandLockFilter.item_selected.connect(_on_offhand_lock_filter_selected)
	%ArmorGearLockFilter.item_selected.connect(_on_armor_gear_lock_filter_selected)
	%StatusEffectOption.item_selected.connect(_on_status_effect_option_selected)
	%ApplyStatusEffectTuningButton.pressed.connect(_on_apply_status_effect_tuning_pressed)
	%SaveStatusEffectTuningButton.pressed.connect(_on_save_status_effect_tuning_pressed)
	%ResetStatusEffectTuningButton.pressed.connect(_on_reset_status_effect_tuning_pressed)
	%Player.health_depleted.connect(_on_player_health_depleted)
	%MobRespawnCheck.toggled.connect(_on_mob_respawn_toggled)
	%MobAffixOption.item_selected.connect(_on_mob_affix_option_selected)
	%EditOffhandStatusButton.pressed.connect(_on_edit_offhand_status_button_pressed)
	_on_mob_respawn_toggled(%MobRespawnCheck.button_pressed)


func _exit_tree() -> void:
	EliteFeatureFlags.force_affix_id = &""


# ===== Lifecycle/Pause/Inventory Bridge (Step0 boundary freeze) =====
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


# F6 affix 유물 드랍 QA — relic_drop_debug_rate export.
func get_relic_drop_rate() -> float:
	return relic_drop_debug_rate


# 몹 처치 XP·골드 — TestArena는 XP 0, affix 배율만 반영.
func get_kill_rewards_for_mob(mob_kind: StringName, elite_affix_id: StringName = &"") -> Dictionary:
	var has_elite_affix := not elite_affix_id.is_empty()
	var rewards := KillRewards.compute(mob_kind, BalancePhase.new(), has_elite_affix)
	rewards["xp"] = 0
	return rewards


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
		RelicCombatBridgeScript.clear()
		InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)
		return
	var menu_service: InventoryService = _inventory_menu.get_service()
	if menu_service == null:
		InventoryCombatBridge.clear_loadout_from_player(%Player)
		RelicCombatBridgeScript.clear()
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
	RelicCombatBridgeScript.refresh_from_bag(menu_service.loadout)
	InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)
	if %ArmorGearRow.visible:
		var selected_before := _gear_panel_controller.get_selected_armor_gear()
		var selected_before_id := ""
		if selected_before != null:
			selected_before_id = selected_before.get_unique_key()
		var armor_slot_key := _gear_panel_controller.get_selected_armor_slot_key()
		var equipped_armor_id := menu_service.loadout.get_set_item_id(
			EquipSlots.SHARED_ARMOR_SET_INDEX,
			armor_slot_key
		)
		_gear_panel_controller.refresh_armor_gear_option_list(equipped_armor_id, false)
		var selected_after := _gear_panel_controller.get_selected_armor_gear()
		var selected_after_id := ""
		if selected_after != null:
			selected_after_id = selected_after.get_unique_key()
		# 장비 선택이 바뀐 경우에만 튜닝 UI를 재구성합니다.
		if selected_before_id != selected_after_id:
			_refresh_armor_gear_tuning_ui()


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


# ===== Weapon/Gear/Mob 옵션 빌드·기본 UI (Step0 boundary freeze) =====
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
	_gear_panel_controller.build_offhand_options()


func _build_armor_gear_options() -> void:
	_gear_panel_controller.build_armor_gear_options()


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
	tabs.set_tab_title(TEST_TAB_INDEX_PLAYER, "플레이어")
	tabs.set_tab_title(TEST_TAB_INDEX_MOB, "몹")
	tabs.set_tab_title(TEST_TAB_INDEX_WEAPON, "무기")
	tabs.set_tab_title(TEST_TAB_INDEX_GEAR, "장비")
	tabs.set_tab_title(TEST_TAB_INDEX_STATUS_EFFECT, "상태이상")
	var tab_bar: VBoxContainer = %TabBarHost
	if tab_bar.has_method("rebuild_tabs"):
		tab_bar.rebuild_tabs()


func _setup_weapon_sub_tabs() -> void:
	var weapon_sub_tabs: TabContainer = %WeaponSubTab
	weapon_sub_tabs.set_tab_title(WEAPON_SUB_TAB_INDEX_PRIMARY, "주무기")
	weapon_sub_tabs.set_tab_title(WEAPON_SUB_TAB_INDEX_OFFHAND, "보조무기")
	weapon_sub_tabs.current_tab = WEAPON_SUB_TAB_INDEX_PRIMARY
	_refresh_weapon_sub_tab_lock_state()


func _refresh_weapon_sub_tab_lock_state() -> void:
	var weapon_sub_tabs: TabContainer = %WeaponSubTab
	var offhand_enabled: bool = use_inventory_loadout and _inventory_menu != null
	weapon_sub_tabs.set_tab_title(
		WEAPON_SUB_TAB_INDEX_OFFHAND,
		"보조무기" if offhand_enabled else "보조무기(잠금)"
	)


func _setup_player_class_option() -> void:
	_player_panel_controller.setup_class_option()


func _on_player_class_option_selected(index: int) -> void:
	_player_panel_controller.on_class_option_selected(index)


func _on_player_default_weapon_option_selected(index: int) -> void:
	_player_panel_controller.on_default_weapon_option_selected(index)


func _on_create_player_button_pressed() -> void:
	if _player_is_dead:
		_restore_player_from_death_state()
	_player_panel_controller.on_create_player_pressed()


func _restore_player_from_death_state() -> void:
	var player: CharacterBody2D = %Player
	if _saved_player_collision_layer != 0:
		player.collision_layer = _saved_player_collision_layer
		player.collision_mask = _saved_player_collision_mask
	else:
		PhysicsLayers.apply_player_body(player)
	player.set_physics_process(true)
	player.visible = true
	player.set_auto_attack_enabled(_saved_auto_attack_enabled)
	player.reset_health_depleted_state()
	_player_is_dead = false


func _setup_mob_type_option() -> void:
	_mob_panel_controller.setup_mob_type_option()


func _setup_mob_affix_option() -> void:
	_mob_panel_controller.setup_mob_affix_option()
	_sync_elite_force_affix_from_ui()


func _on_mob_affix_option_selected(_index: int) -> void:
	_sync_elite_force_affix_from_ui()
	_mob_panel_controller.update_mob_affix_description()
	_mob_panel_controller.update_mob_description()


func _sync_elite_force_affix_from_ui() -> void:
	EliteFeatureFlags.force_affix_id = _mob_panel_controller.get_selected_force_affix_id()


func _build_test_elite_roll_context(mob: Mob, mob_scene: PackedScene) -> EliteAffixRollContext:
	var context := EliteAffixRollContext.new()
	context.mob_kind = mob.mob_kind
	context.phase_minute = 0.0
	context.is_boss = mob_scene == MobSpawnSelector.MOB_BOSS_SCENE
	context.force_affix_id = _mob_panel_controller.get_selected_force_affix_id()
	return context


func _on_mob_type_option_selected(_index: int) -> void:
	_mob_panel_controller.on_mob_type_option_selected(_index)


func _register_mob_scenes() -> void:
	for entry in MOB_OPTIONS:
		_mob_snapshots.register_scene(entry["scene"] as PackedScene)


func _setup_weapon_filters() -> void:
	_weapon_panel_controller.setup_weapon_filters()


func _setup_offhand_picker() -> void:
	_gear_panel_controller.setup_offhand_picker()


func _setup_armor_gear_picker() -> void:
	_gear_panel_controller.setup_armor_gear_picker()


func _setup_armor_gear_section_visibility() -> void:
	var enabled := use_inventory_loadout and _inventory_menu != null
	_gear_panel_controller.setup_armor_gear_section_visibility(enabled)


func _setup_offhand_section_visibility() -> void:
	var enabled := use_inventory_loadout and _inventory_menu != null
	_gear_panel_controller.setup_offhand_section_visibility(enabled)
	_refresh_weapon_sub_tab_lock_state()
	%OffhandDisabledHintLabel.visible = not enabled
	%OffhandDisabledHintLabel.text = (
		"보조무기 탭을 사용하려면 인벤 연동(use_inventory_loadout)을 켜세요."
	)
	%EquipOffhandButton.disabled = not enabled
	%ApplyOffhandTuningButton.disabled = not enabled
	%SaveOffhandTuningButton.disabled = not enabled
	%ResetOffhandTuningButton.disabled = not enabled
	if not enabled:
		%WeaponSubTab.current_tab = WEAPON_SUB_TAB_INDEX_PRIMARY


func _wire_gear_snapshot_to_registry() -> void:
	if not use_inventory_loadout or _inventory_menu == null:
		return
	var menu_service: InventoryService = _inventory_menu.get_service()
	if menu_service == null:
		return
	menu_service.registry.set_gear_modifier_resolver(
		Callable(_gear_snapshots, "resolve_modifiers")
	)


func _configure_status_effect_controller() -> void:
	_status_effect_controller.configure(
		_status_effect_snapshots,
		_get_active_mob,
		_get_selected_offhand_status_ids,
		_update_status,
		TEST_TAB_INDEX_STATUS_EFFECT,
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_MIN_HEIGHT,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		TUNING_SPIN_VALUE_FONT_SIZE,
		%TestPanelsTab,
		%StatusEffectOption,
		%StatusEffectNavLabel,
		%StatusEffectRuleHintLabel,
		%StatusEffectTuningFields,
		%StatusEffectTuningStatusLabel,
		%ApplyStatusEffectTuningButton,
		%SaveStatusEffectTuningButton,
		%ResetStatusEffectTuningButton
	)


func _configure_player_panel_controller() -> void:
	_player_panel_controller.configure(
		%Player,
		_update_status,
		apply_inventory_loadout_to_player,
		equip_player_default_weapon,
		_player_snapshot,
		%PlayerClassOption,
		%PlayerDefaultWeaponOption,
		_all_weapon_options,
		%PlayerClassDescLabel,
		%PlayerStatsLabel,
		%HealPlayerButton,
		%CreatePlayerButton,
		%PlayerMoveSpeedFields,
		%PlayerClassMultFields,
		%PlayerMoveSpeedTuningStatusLabel,
		%SavePlayerMoveSpeedButton,
		%ResetPlayerMoveSpeedButton,
		%PlayerSpawnPoint.global_position,
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_MIN_HEIGHT,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		TUNING_SPIN_VALUE_FONT_SIZE,
		MOB_TUNING_COLOR_DEFAULT,
		MOB_TUNING_COLOR_SAVED,
		MOB_TUNING_COLOR_SESSION
	)


func _configure_weapon_panel_controller() -> void:
	_weapon_panel_controller.configure(
		_weapon_snapshots,
		_update_status,
		apply_inventory_loadout_to_player,
		func() -> CanvasLayer:
			return _inventory_menu,
		func() -> bool:
			return use_inventory_loadout and _inventory_menu != null,
		func() -> bool:
			return _player_is_dead,
		WEAPON_TYPE_ORDER,
		WEAPON_TYPE_LABELS_KO,
		WEAPON_RARITY_ORDER,
		WEAPON_RARITY_LABELS_KO,
		START_WEAPON,
		_all_weapon_options,
		_available_rarities,
		%Player,
		%WeaponTypeFilter,
		%WeaponRarityFilter,
		%WeaponLockFilter,
		%WeaponOption,
		%WeaponDescLabel,
		%ProjectileTuningFields,
		%ProjectileTuningStatusLabel,
		%ProjectileMovementRow,
		%ProjectileMovementOption,
		%SaveProjectileTuningButton,
		%ResetProjectileTuningButton,
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_MIN_HEIGHT,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		TUNING_SPIN_VALUE_FONT_SIZE
	)


func _configure_gear_panel_controller() -> void:
	_gear_panel_controller.configure(
		_gear_snapshots,
		_update_status,
		apply_inventory_loadout_to_player,
		func() -> CanvasLayer:
			return _inventory_menu,
		func() -> bool:
			return use_inventory_loadout and _inventory_menu != null,
		_status_effect_controller.refresh_status_tab_options,
		func(spin: SpinBox) -> void:
			TestArenaTuningUiUtil.style_spin_line_edit(spin, TUNING_SPIN_MIN_HEIGHT, TUNING_SPIN_VALUE_FONT_SIZE),
		func(spin: SpinBox, on_committed: Callable) -> void:
			TestArenaTuningUiUtil.wire_spin_box_text_commit(spin, on_committed),
		func(spin: SpinBox) -> void:
			TestArenaTuningUiUtil.commit_spin_box_pending(spin),
		ARMOR_SLOT_LABELS_KO,
		TUNING_SPIN_BUTTON_SIZE,
		TUNING_SPIN_MIN_HEIGHT,
		TUNING_SPIN_BUTTON_FONT_SIZE,
		%OffhandOption,
		%OffhandLockFilter,
		%OffhandFilterRow,
		%OffhandDescLabel,
		%OffhandStatusRow,
		%OffhandStatusHintLabel,
		%OffhandStatusOption,
		%EditOffhandStatusButton,
		%OffhandTuningFields,
		%OffhandTuningStatusLabel,
		%SaveOffhandTuningButton,
		%ResetOffhandTuningButton,
		%ArmorSlotFilter,
		%ArmorGearLockFilter,
		%ArmorGearOption,
		%ArmorGearDescLabel,
		%ArmorGearTuningFields,
		%ArmorGearTuningStatusLabel,
		%SaveArmorGearTuningButton,
		%ResetArmorGearTuningButton,
		%GearSectionLabel,
		%ArmorSlotRow,
		%ArmorGearRow,
		%ArmorGearTuningLabel,
		%ArmorGearTuningButtons,
		%OffhandSectionLabel,
		%OffhandRow,
		%OffhandTuningLabel,
		%OffhandTuningButtons,
		%StatusEffectNavLabel,
		%StatusEffectOption
	)


func _configure_mob_panel_controller() -> void:
	_mob_panel_controller.configure(
		_mob_snapshots,
		_update_status,
		_get_test_mob_hp_multiplier,
		_apply_mob_tuning_live,
		_is_selected_mob_scene_active,
		func(spin: SpinBox) -> void:
			TestArenaTuningUiUtil.style_spin_line_edit(spin, TUNING_SPIN_MIN_HEIGHT, TUNING_SPIN_VALUE_FONT_SIZE),
		func(spin: SpinBox, on_committed: Callable) -> void:
			TestArenaTuningUiUtil.wire_spin_box_text_commit(spin, on_committed),
		func(spin: SpinBox) -> void:
			TestArenaTuningUiUtil.commit_spin_box_pending(spin),
		MOB_OPTIONS,
		MOB_KIND_LABELS_KO,
		MOB_ROLE_HINTS_KO,
		MOB_TUNING_COLOR_DEFAULT,
		MOB_TUNING_COLOR_SAVED,
		MOB_TUNING_COLOR_SESSION,
		%MobTypeOption,
		%MobDescLabel,
		%MobCombatTuningStatusLabel,
		_get_mob_combat_spins(),
		_get_mob_combat_step_buttons(),
		_get_mob_combat_field_labels(),
		%ApplyMobCombatTuningButton,
		%SaveMobCombatTuningButton,
		%ResetMobCombatTuningButton,
		%MobDeathBurstSection,
		_get_mob_death_burst_spins(),
		_get_mob_death_burst_step_buttons(),
		_get_mob_death_burst_field_labels(),
		%MobChargeSection,
		_get_mob_charge_spins(),
		_get_mob_charge_step_buttons(),
		_get_mob_charge_field_labels(),
		%MobChaseSkillSection,
		_get_mob_chase_skill_spins(),
		_get_mob_chase_skill_step_buttons(),
		_get_mob_chase_skill_field_labels(),
		%MobChaseModeLabel,
		%MobChaseModeOption,
		%MobChaseSkillLabel,
		%MobChaseSkillOption,
		%MobAffixOption,
		%MobAffixDescLabel
	)


func _on_weapon_filters_changed(_index: int = -1) -> void:
	_weapon_panel_controller.on_weapon_filters_changed()


func _on_weapon_option_selected(_index: int) -> void:
	_weapon_panel_controller.on_weapon_option_selected()


func _get_weapon_filter_type() -> String:
	return _weapon_panel_controller.get_weapon_filter_type()


func _get_weapon_filter_rarity() -> String:
	return _weapon_panel_controller.get_weapon_filter_rarity()


func _weapon_matches_rarity(weapon: WeaponData, rarity_filter: String) -> bool:
	return _weapon_panel_controller.weapon_matches_rarity(weapon, rarity_filter)


func _refresh_weapon_option_list(preserve_key: String = "") -> void:
	_weapon_panel_controller.refresh_weapon_option_list(preserve_key)


func _on_mob_respawn_toggled(enabled: bool) -> void:
	mob_respawn_enabled = enabled


func _on_spawn_mob_button_pressed() -> void:
	spawn_test_mob(_get_selected_mob_scene())


func _on_armor_slot_filter_selected(_index: int) -> void:
	_gear_panel_controller.on_armor_slot_filter_selected()


func _on_offhand_lock_filter_selected(_index: int = -1) -> void:
	_gear_panel_controller.on_offhand_lock_filter_selected()


func _on_armor_gear_lock_filter_selected(_index: int = -1) -> void:
	_gear_panel_controller.on_armor_gear_lock_filter_selected()


func _on_armor_gear_option_selected(_index: int) -> void:
	_gear_panel_controller.on_armor_gear_option_selected()


func _on_offhand_option_selected(_index: int) -> void:
	_gear_panel_controller.on_offhand_option_selected()


# ===== Weapon 장착/발사체 튜닝 (Step0 boundary freeze) =====
func _get_selected_mob_scene() -> PackedScene:
	return _mob_panel_controller.get_selected_mob_scene(MobSpawnSelector.MOB_BASIC_SCENE)


# 플레이어 탭에서 지정한 기본 무기를 인벤(또는 직접) 장착합니다.
func equip_player_default_weapon() -> void:
	var weapon_id := _player_snapshot.get_effective_default_weapon_id()
	if weapon_id.is_empty():
		return
	var weapon := _find_weapon_by_id(weapon_id)
	if weapon == null:
		push_warning("TestArena: default weapon not found (%s)" % weapon_id)
		return
	if use_inventory_loadout and _inventory_menu != null:
		var menu_service: InventoryService = _inventory_menu.get_service()
		if menu_service != null:
			var err := menu_service.try_force_equip_weapon_on_active_set(weapon_id)
			if not err.is_empty():
				_update_status("기본 무기 장착 실패 (%s)" % String(err))
				return
			if _inventory_menu.has_method("refresh_all_slots"):
				_inventory_menu.refresh_all_slots()
			if _inventory_menu.has_method("persist_loadout_if_enabled"):
				_inventory_menu.persist_loadout_if_enabled()
			return
	_equip_weapon(weapon)


func _find_weapon_by_id(weapon_id: String) -> WeaponData:
	for weapon in _all_weapon_options:
		if weapon.get_unique_key() == weapon_id:
			return weapon
	return null


func _get_selected_weapon() -> WeaponData:
	return _weapon_panel_controller.get_selected_weapon()


# 무기 GUI 착용 — 인벤 활성 세트에 반영한 뒤 플레이어에 튜닝 무기를 적용합니다.
func _equip_weapon_from_gui(catalog_weapon: WeaponData) -> void:
	_weapon_panel_controller.equip_weapon_from_gui(catalog_weapon)


# 플레이어에 튜닝된 무기를 장착하고 발사체 튜닝 UI를 갱신합니다.
func _equip_weapon(catalog_weapon: WeaponData) -> void:
	_weapon_panel_controller.equip_weapon(catalog_weapon)


# 스냅샷 값을 장착 중인 Gun에 반영합니다(UI는 갱신하지 않음).
func _apply_tuning_live(catalog_weapon: WeaponData) -> void:
	_weapon_panel_controller.apply_tuning_live(catalog_weapon)


func _on_projectile_tuning_spin_tree_entered(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	_weapon_panel_controller.on_projectile_tuning_spin_tree_entered(spin, catalog_weapon, property)


# SpinBox LineEdit 직접 입력을 확정합니다(Godot 4 apply).
func _on_tuning_spin_step_pressed(
	spin: SpinBox,
	catalog_weapon: WeaponData,
	property: String,
	direction: int
) -> void:
	_weapon_panel_controller.on_tuning_spin_step_pressed(spin, catalog_weapon, property, direction)


func _populate_projectile_movement_dropdown(tuned: WeaponData) -> void:
	_weapon_panel_controller.populate_projectile_movement_dropdown(tuned)


func _on_projectile_movement_selected(index: int) -> void:
	_weapon_panel_controller.on_projectile_movement_selected(index)


func _on_projectile_tuning_value_changed(
	new_value: float,
	catalog_weapon: WeaponData,
	property: String
) -> void:
	_weapon_panel_controller.on_projectile_tuning_value_changed(new_value, catalog_weapon, property)


func _sync_tuning_spin_display(property: String, catalog_weapon: WeaponData) -> void:
	_weapon_panel_controller.sync_tuning_spin_display(property, catalog_weapon)


# SpinBox 화살표가 1↔-1 사이에서 0을 거치지 않도록 보정합니다.
func _resolve_projectile_pierce_spin_value(catalog_weapon: WeaponData, new_value: int):
	return _weapon_panel_controller.resolve_projectile_pierce_spin_value(catalog_weapon, new_value)


func _refresh_projectile_tuning_status_only(catalog_weapon: WeaponData) -> void:
	_weapon_panel_controller.refresh_projectile_tuning_status_only(catalog_weapon)


func _commit_and_apply_projectile_tuning_from_spins() -> void:
	_weapon_panel_controller.commit_and_apply_projectile_tuning_from_spins()


# ===== Gear 장착/튜닝 (Step0 boundary freeze) =====
func _refresh_offhand_tuning_ui() -> void:
	_gear_panel_controller.refresh_offhand_tuning_ui()


func _apply_gear_tuning_live(_catalog_gear: GearData) -> void:
	_gear_panel_controller._apply_gear_tuning_live(_catalog_gear)


func _refresh_armor_gear_tuning_ui() -> void:
	_gear_panel_controller.refresh_armor_gear_tuning_ui()


# ===== Mob 패널/설명/전투 튜닝 (Step0 boundary freeze) =====
func _get_mob_combat_field_labels() -> Array[Label]:
	return [
		%MobDamageLabel,
		%MobChaseLabel,
		%MobAttackLabel,
		%MobRangeLabel,
		%MobIntervalLabel,
	]


func _get_mob_death_burst_field_labels() -> Array[Label]:
	return [%MobBurstRadiusLabel, %MobBurstDamageLabel, %MobBurstDelayLabel]


func _get_mob_charge_field_labels() -> Array[Label]:
	return [%MobChargeDistanceLabel]


func _get_mob_chase_skill_field_labels() -> Array[Label]:
	return [
		%MobChaseSkillTriggerLabel,
		%MobChaseSkillWindupLabel,
		%MobChaseSkillTravelLabel,
		%MobChaseSkillArcHeightLabel,
		%MobChaseSkillCooldownLabel,
		%MobChaseSkillBurstRadiusLabel,
		%MobChaseSkillBurstDamageLabel,
	]


func _get_mob_combat_spins() -> Array[SpinBox]:
	return [
		%MobDamageSpin,
		%MobChaseSpin,
		%MobAttackSpin,
		%MobRangeSpin,
		%MobIntervalSpin,
	]


func _get_mob_combat_step_buttons() -> Array[Button]:
	return [
		%MobDamageDecButton,
		%MobDamageIncButton,
		%MobChaseDecButton,
		%MobChaseIncButton,
		%MobAttackDecButton,
		%MobAttackIncButton,
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
	_mob_panel_controller.setup_mob_combat_tuning_ui()


func _get_mob_charge_spins() -> Array[SpinBox]:
	return [%MobChargeDistanceSpin]


func _get_mob_charge_step_buttons() -> Array[Button]:
	return [%MobChargeDistanceDecButton, %MobChargeDistanceIncButton]


func _get_mob_chase_skill_spins() -> Array[SpinBox]:
	return [
		%MobChaseSkillTriggerSpin,
		%MobChaseSkillWindupSpin,
		%MobChaseSkillTravelSpin,
		%MobChaseSkillArcHeightSpin,
		%MobChaseSkillCooldownSpin,
		%MobChaseSkillBurstRadiusSpin,
		%MobChaseSkillBurstDamageSpin,
	]


func _get_mob_chase_skill_step_buttons() -> Array[Button]:
	return [
		%MobChaseSkillTriggerDecButton,
		%MobChaseSkillTriggerIncButton,
		%MobChaseSkillWindupDecButton,
		%MobChaseSkillWindupIncButton,
		%MobChaseSkillTravelDecButton,
		%MobChaseSkillTravelIncButton,
		%MobChaseSkillArcHeightDecButton,
		%MobChaseSkillArcHeightIncButton,
		%MobChaseSkillCooldownDecButton,
		%MobChaseSkillCooldownIncButton,
		%MobChaseSkillBurstRadiusDecButton,
		%MobChaseSkillBurstRadiusIncButton,
		%MobChaseSkillBurstDamageDecButton,
		%MobChaseSkillBurstDamageIncButton,
	]


func _refresh_mob_combat_tuning_ui() -> void:
	_mob_panel_controller.refresh_mob_combat_tuning_ui()


func _on_apply_mob_combat_tuning_pressed() -> void:
	_mob_panel_controller.on_apply_mob_combat_tuning_pressed()


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
		_active_mob.refresh_chase_stop_ring()
		_active_mob.refresh_chase_skill_range_rings()


func _on_save_mob_combat_tuning_pressed() -> void:
	_mob_panel_controller.on_save_mob_combat_tuning_pressed()


func _on_reset_mob_combat_tuning_pressed() -> void:
	_mob_panel_controller.on_reset_mob_combat_tuning_pressed()


# ===== Core Runtime Spawn/Kill/Respawn (Step0 boundary freeze) =====
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
	EliteAffixSpawnHelper.apply_after_mob_ready(mob, _build_test_elite_roll_context(mob, scene))
	if mob.is_node_ready():
		mob.refresh_attack_range_ring()
		mob.refresh_chase_stop_ring()
		mob.refresh_chase_skill_range_rings()
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
	var max_hp: float = player.get_max_health()
	player.health = max_hp
	player.call(&"_sync_health_bar_max")
	player.global_position = %PlayerSpawnPoint.global_position
	player.collision_layer = _saved_player_collision_layer
	player.collision_mask = _saved_player_collision_mask
	player.set_physics_process(true)
	player.visible = true
	player.set_auto_attack_enabled(_saved_auto_attack_enabled)
	player.reset_health_depleted_state()
	if player.has_method(&"_refill_stamina_to_max"):
		player.call(&"_refill_stamina_to_max")
	if player.has_method(&"clear_player_debuffs"):
		player.call(&"clear_player_debuffs")
	_player_is_dead = false
	_player_panel_controller.refresh_panel()
	_update_status("")


func _update_status(text: String) -> void:
	%StatusLabel.text = text


func _get_active_mob() -> Mob:
	return _active_mob


func _is_selected_mob_scene_active(scene: PackedScene) -> bool:
	return _active_mob != null and is_instance_valid(_active_mob) and _last_mob_scene == scene


# ===== Weapon/Gear/Status 설명·탭 브리지 (Step0 boundary freeze) =====
# 보조손 grant_on_hit 상태이상 정보를 장비 탭에 읽기 전용으로 표시합니다.
func _refresh_offhand_status_hint() -> void:
	_gear_panel_controller.refresh_offhand_status_hint()


# 장비 탭의 상태이상 수정 버튼으로 상태이상 탭을 열고 대상을 자동 선택합니다.
func _on_edit_offhand_status_button_pressed() -> void:
	var status_ids := _get_selected_offhand_status_ids()
	if status_ids.is_empty():
		_update_status("수정할 상태이상이 없습니다.")
		return
	_pending_offhand_context_restore = true
	_pending_offhand_gear_id = ""
	if %OffhandOption.get_item_count() > 0 and %OffhandOption.selected >= 0:
		_pending_offhand_gear_id = String(%OffhandOption.get_item_metadata(%OffhandOption.selected))
	%TestPanelsTab.current_tab = TEST_TAB_INDEX_WEAPON
	%WeaponSubTab.current_tab = WEAPON_SUB_TAB_INDEX_OFFHAND
	var selected_id := status_ids[0]
	if %OffhandStatusOption.get_item_count() > 0 and %OffhandStatusOption.selected >= 0:
		selected_id = StringName(%OffhandStatusOption.get_item_metadata(%OffhandStatusOption.selected))
	_pending_offhand_status_id = selected_id
	_status_effect_controller.open_status_tab_with_status(selected_id)


func _get_selected_offhand_status_ids() -> Array[StringName]:
	return _gear_panel_controller.get_selected_offhand_status_ids()


# ===== StatusEffect 패널/튜닝/규칙 (Step0 boundary freeze) =====
func _setup_status_effect_tuning_ui() -> void:
	_status_effect_controller.setup_tuning_ui()


func _on_status_effect_option_selected(_index: int) -> void:
	_status_effect_controller.on_status_effect_option_selected(_index)


func _refresh_status_effect_tuning_ui() -> void:
	_status_effect_controller.refresh_status_effect_tuning_ui()


func _on_apply_status_effect_tuning_pressed() -> void:
	_status_effect_controller.on_apply_status_effect_tuning_pressed()
	_restore_offhand_context_from_status_tab()


func _on_save_status_effect_tuning_pressed() -> void:
	_status_effect_controller.on_save_status_effect_tuning_pressed()
	_restore_offhand_context_from_status_tab()


func _on_reset_status_effect_tuning_pressed() -> void:
	_status_effect_controller.on_reset_status_effect_tuning_pressed()
	_restore_offhand_context_from_status_tab()


func _restore_offhand_context_from_status_tab() -> void:
	if not _pending_offhand_context_restore:
		return
	%TestPanelsTab.current_tab = TEST_TAB_INDEX_WEAPON
	%WeaponSubTab.current_tab = WEAPON_SUB_TAB_INDEX_OFFHAND
	if not _pending_offhand_gear_id.is_empty():
		_select_option_by_metadata(%OffhandOption, _pending_offhand_gear_id)
		_gear_panel_controller.on_offhand_option_selected()
	if _pending_offhand_status_id != &"":
		_select_option_by_metadata(%OffhandStatusOption, _pending_offhand_status_id)
		_refresh_offhand_status_hint()
	_pending_offhand_context_restore = false
	_pending_offhand_gear_id = ""
	_pending_offhand_status_id = &""


func _select_option_by_metadata(option: OptionButton, target_value: Variant) -> void:
	if option == null:
		return
	var target_text := String(target_value)
	if target_text.is_empty():
		return
	var item_count: int = option.get_item_count()
	for index in item_count:
		var metadata_text := String(option.get_item_metadata(index))
		if metadata_text != target_text:
			continue
		option.select(index)
		return


# ===== Mob 설명 보조 + 공용 유틸 (Step0 boundary freeze) =====
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
