extends Node2D

const RunConfigScript = preload("res://game/run_config.gd")
const ArenaWaveDirectorScript = preload("res://game/arena/arena_wave_director.gd")
const ARENA_TELEPORTER_SCENE := preload("res://game/arena/arena_teleporter.tscn")
const GOLD_CHEST_SCENE := preload("res://game/rewards/gold_chest.tscn")
const CHEST_PURCHASE_MENU_SCENE := preload("res://ui/chest_purchase_menu.tscn")
const EQUIPMENT_DROP_SCENE := preload("res://effects/equipment_drop/equipment_drop.tscn")
const DEFAULT_BALANCE_TABLE := preload("res://game/balance/default_balance_table.tres")
const DEFAULT_BALANCE_TIMELINE := preload("res://game/balance/default_balance_timeline.tres")
const RUN_CLEAR_CURVE_MINUTES := 30.0
const ARENA_CHEST_RADIUS := 240.0
const ARENA_CHEST_SPECIFIC_PRICE := 120
const ARENA_CHEST_ALL_PRICE := 90
const ARENA_CHEST_PRICE_PER_WAVE := 10
const ARENA_CHEST_CONFIGS := [
	{"id": "all", "title_key": &"chest.type.all", "slot_filter": ItemRewardPicker.SLOT_ALL, "price": ARENA_CHEST_ALL_PRICE},
	{"id": "weapon", "title_key": &"chest.type.weapon", "slot_filter": EquipSlots.WEAPON, "price": ARENA_CHEST_SPECIFIC_PRICE},
	{"id": "helmet", "title_key": &"chest.type.helmet", "slot_filter": EquipSlots.HELMET, "price": ARENA_CHEST_SPECIFIC_PRICE},
	{"id": "armor", "title_key": &"chest.type.armor", "slot_filter": EquipSlots.ARMOR, "price": ARENA_CHEST_SPECIFIC_PRICE},
	{"id": "gloves", "title_key": &"chest.type.gloves", "slot_filter": EquipSlots.GLOVES, "price": ARENA_CHEST_SPECIFIC_PRICE},
	{"id": "boots", "title_key": &"chest.type.boots", "slot_filter": EquipSlots.BOOTS, "price": ARENA_CHEST_SPECIFIC_PRICE},
	{"id": "offhand", "title_key": &"chest.type.offhand", "slot_filter": EquipSlots.OFFHAND, "price": ARENA_CHEST_SPECIFIC_PRICE},
	{"id": "accessory", "title_key": &"chest.type.accessory", "slot_filter": EquipSlots.ACCESSORY, "price": ARENA_CHEST_SPECIFIC_PRICE},
]

@export var balance_table: BalanceTable
@export var balance_timeline: BalanceTimeline
@export_range(0.05, 2.0, 0.01, "or_greater") var base_spawn_interval := 0.3
@export_range(1, 500, 1) var max_alive_mobs := 100
## true면 획득 보상이 인벤토리에 자동 배치되고 활성 세트 weapon만 Player에 반영됩니다.
@export var use_inventory_loadout := true

var _elapsed_seconds := 0.0
var _last_spawn_density := -1.0
var kill_count := 0
var _game_started := false
var _run_cleared := false
var _run_failed := false
var _pending_weapon_selects := 0
var _passive_run_state := PassiveRunState.new()
var _weapon_run_state := WeaponRunState.new()
var _last_reward_title_key: StringName = &"weapon_select.level_up"
var _weapon_damage := WeaponDamageTracker.new()
var _timeline_fired_keys: Dictionary = {}
var _density_event_mult := 1.0
var _density_event_remaining := 0.0
var _game_mode: StringName = RunConfigScript.MODE_SURVIVAL
var _arena_director: ArenaWaveDirector
var _arena_teleporter: ArenaTeleporter
var _arena_waiting_for_teleporter := false
var _arena_enable_teleporter_after_weapon_select := false
var _arena_pending_teleporter_message := ""

var _pause_menu: CanvasLayer
var _weapon_select_menu: CanvasLayer
var _inventory_menu: CanvasLayer
var _chest_purchase_menu: ChestPurchaseMenu
var _active_gold_chests: Array[GoldChest] = []
var _pending_arena_chest_reward_wave := 0
var _chest_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_bind_ui_nodes()
	_chest_rng.randomize()
	_game_mode = RunConfigScript.get_game_mode()
	if _is_arena_mode():
		_setup_arena_director()
		_setup_arena_teleporter()
	ActionManager.initialize()
	LocaleSettings.load_and_apply()
	DisplaySettings.load_and_apply()
	AudioSettings.load_and_apply()
	GameplaySettings.load_and_apply()
	add_to_group(UiLocale.GROUP_REFRESH)
	if not balance_table:
		balance_table = DEFAULT_BALANCE_TABLE
	if not balance_timeline:
		balance_timeline = DEFAULT_BALANCE_TIMELINE
	_update_kill_count_hud()
	$Timer.stop()
	if %Player.has_method(&"set_weapon_run_state"):
		%Player.set_weapon_run_state(_weapon_run_state)
	%Player.leveled_up.connect(_on_player_leveled_up)
	if not show_reward_select(&"weapon_select.title"):
		_ensure_game_started()
	refresh_locale()


func is_game_started() -> bool:
	return _game_started


func _is_survival_mode() -> bool:
	return _game_mode == RunConfigScript.MODE_SURVIVAL


func _is_arena_mode() -> bool:
	return _game_mode == RunConfigScript.MODE_ARENA


func is_weapon_select_open() -> bool:
	return _weapon_select_menu != null and _weapon_select_menu.visible


func is_pause_menu_open() -> bool:
	return _pause_menu != null and _pause_menu.visible


func is_inventory_open() -> bool:
	return InventoryGameBridge.is_inventory_open(_inventory_menu)


func is_chest_purchase_open() -> bool:
	return _chest_purchase_menu != null and _chest_purchase_menu.visible


func show_weapon_select(title_key: StringName = &"weapon_select.level_up") -> bool:
	return show_reward_select(title_key)


func show_reward_select(title_key: StringName = &"weapon_select.level_up") -> bool:
	if _weapon_select_menu == null:
		push_error("Game: WeaponSelectMenu node missing.")
		return false
	_last_reward_title_key = title_key
	var wave_number := _get_current_wave_number_for_rewards()
	var choices := _roll_reward_choices(wave_number)
	if choices.is_empty():
		_consume_pending_weapon_select()
		return false
	if not _weapon_select_menu.present_reward_choices(
		title_key,
		choices,
		_get_weapon_choice_owned_weapons(),
		_passive_run_state,
		_weapon_run_state
	):
		_consume_pending_weapon_select()
		return false

	_weapon_select_menu.show()
	_weapon_select_menu.on_menu_opened()
	get_tree().paused = true
	return true


func reroll_reward_choices() -> void:
	if _weapon_select_menu == null:
		return
	var choices := _roll_reward_choices(_get_current_wave_number_for_rewards())
	if choices.is_empty():
		return
	_weapon_select_menu.present_reward_choices(
		_last_reward_title_key,
		choices,
		_get_weapon_choice_owned_weapons(),
		_passive_run_state,
		_weapon_run_state
	)


func get_passive_run_state() -> PassiveRunState:
	return _passive_run_state


func get_weapon_run_state() -> WeaponRunState:
	return _weapon_run_state


func on_reward_chosen(choice: RewardChoice) -> void:
	if choice == null:
		return
	if choice.is_weapon():
		on_weapon_chosen(choice.weapon)
	elif choice.is_weapon_upgrade():
		on_weapon_upgrade_chosen(choice.weapon)
	elif choice.is_passive():
		on_passive_chosen(choice.passive)


func on_passive_chosen(passive: PassiveData) -> void:
	if passive == null:
		return
	var new_level := _passive_run_state.add_level(passive.passive_id, passive.max_level)
	if new_level <= 0:
		if show_reward_select(_last_reward_title_key):
			return
		_finish_reward_flow(false)
		return
	if new_level >= passive.max_level:
		_passive_run_state.try_evolve(passive)
	_refresh_passive_stats()
	_finish_reward_flow(false)


func on_weapon_upgrade_chosen(weapon: WeaponData) -> void:
	if weapon == null:
		return
	var bonus := _get_weapon_upgrade_bonus_levels()
	var new_level := _weapon_run_state.add_level(weapon, bonus)
	if new_level <= 0:
		if show_reward_select(_last_reward_title_key):
			return
		_finish_reward_flow(false)
		return
	_finish_reward_flow(false)


func _refresh_passive_stats() -> void:
	%Player.refresh_stats_from_passives(_passive_run_state, _get_equipped_accessory_ids())


func _roll_reward_choices(wave_number: int) -> Array:
	const MAX_EMPTY_REROLLS := 3
	_sync_weapon_run_state_from_owned()
	var owned := _get_weapon_choice_owned_weapons()
	var upgrade_pool := _get_upgrade_eligible_weapons()
	var upgrade_bonus := _get_weapon_upgrade_bonus_levels()
	for _attempt in MAX_EMPTY_REROLLS:
		var choices := RewardPool.roll_choices(
			owned,
			upgrade_pool,
			_passive_run_state,
			_weapon_run_state,
			%Player.level,
			wave_number,
			_chest_rng,
			upgrade_bonus,
			use_inventory_loadout
		)
		if not choices.is_empty():
			return choices
	return []


func _get_upgrade_eligible_weapons() -> Array[WeaponData]:
	if not use_inventory_loadout:
		return %Player.get_owned_weapons()
	var service := _get_inventory_service()
	if service == null:
		return %Player.get_owned_weapons()
	var weapon_id := InventoryCombatBridge.get_active_weapon_id(service.loadout)
	if weapon_id.is_empty():
		return []
	var weapon := service.registry.resolve_weapon(weapon_id)
	if weapon == null:
		return []
	return [weapon]


func _sync_weapon_run_state_from_owned() -> void:
	for weapon in _get_weapon_choice_owned_weapons():
		_weapon_run_state.ensure_registered(weapon)


func _get_equipped_accessory_ids() -> Array[String]:
	var ids: Array[String] = []
	if not use_inventory_loadout:
		return ids
	var service := _get_inventory_service()
	if service == null:
		return ids
	var accessory_id := service.loadout.get_set_item_id(
		service.loadout.active_set_index,
		EquipSlots.ACCESSORY
	)
	if not accessory_id.is_empty():
		ids.append(accessory_id)
	return ids


func _get_weapon_upgrade_bonus_levels() -> int:
	if not %Player.has_method(&"get_persistent_stat_modifiers"):
		return 0
	var mods: Dictionary = %Player.get_persistent_stat_modifiers()
	return maxi(int(mods.get("weapon_upgrade_level", 0)), 0)


func on_weapon_chosen(weapon: WeaponData) -> void:
	if _weapon_select_menu == null:
		return
	var acquire_err := _try_acquire_weapon_reward(weapon)
	if not acquire_err.is_empty():
		if acquire_err == InventoryService.ERROR_BAG_FULL:
			_drop_equipment_item(weapon.get_unique_key())
			_finish_weapon_reward_flow(weapon, false)
			_show_weapon_reward_error(&"weapon_select.reward_dropped_bag_full")
			return
		_show_weapon_reward_error(acquire_err)
		return
	_finish_reward_flow(true, weapon)


# 보상 선택 UI를 닫고 게임 흐름을 재개합니다.
func _finish_reward_flow(weapon_acquired: bool, weapon: WeaponData = null) -> void:
	_weapon_select_menu.on_menu_closed()
	_weapon_select_menu.hide()
	get_tree().paused = false
	if weapon_acquired and weapon != null:
		_weapon_run_state.ensure_registered(weapon)
		if use_inventory_loadout:
			apply_inventory_loadout_to_player()
		else:
			%Player.add_weapon.call_deferred(weapon)

	_ensure_game_started()
	_consume_pending_weapon_select()
	if _arena_enable_teleporter_after_weapon_select:
		_show_pending_arena_chest_reward()
		_enable_pending_arena_teleporter()


# 무기 획득 선택을 끝내고 게임 흐름을 재개합니다.
func _finish_weapon_reward_flow(weapon: WeaponData, acquired: bool) -> void:
	_finish_reward_flow(acquired, weapon)


# 무기 획득 UI 필터용 — 인벤토리 안의 무기까지 보유로 봅니다.
func _get_current_wave_number_for_rewards() -> int:
	if _is_arena_mode() and _arena_director != null:
		return _arena_director.current_wave
	return 0


func _get_weapon_choice_owned_weapons() -> Array[WeaponData]:
	if not use_inventory_loadout:
		return %Player.get_owned_weapons()
	var service := _get_inventory_service()
	if service == null:
		return %Player.get_owned_weapons()
	var owned: Array[WeaponData] = []
	var seen: Dictionary = {}
	for set_index in EquipSlots.SET_COUNT:
		for slot_key in EquipSlots.ALL:
			_append_owned_weapon_id(
				owned,
				seen,
				service,
				service.loadout.get_set_item_id(set_index, slot_key)
			)
	for item_id in service.loadout.bag_ids:
		_append_owned_weapon_id(owned, seen, service, item_id)
	return owned


func _append_owned_weapon_id(
	owned: Array[WeaponData],
	seen: Dictionary,
	service: InventoryService,
	item_id: String
) -> void:
	if item_id.is_empty():
		return
	var weapon := service.registry.resolve_weapon(item_id)
	if weapon == null:
		return
	var key := weapon.get_unique_key()
	if seen.has(key):
		return
	seen[key] = true
	owned.append(weapon)


func _try_acquire_weapon_reward(weapon: WeaponData) -> StringName:
	if weapon == null:
		return InventoryService.ERROR_UNKNOWN_ITEM
	if not use_inventory_loadout:
		return &""
	var service := _get_inventory_service()
	if service == null:
		push_error("Game: InventoryMenu service missing for weapon reward.")
		return InventoryService.ERROR_UNKNOWN_ITEM
	var err := service.acquire_item(weapon.get_unique_key())
	if err.is_empty():
		_refresh_inventory_after_reward()
	return err


func try_acquire_dropped_equipment_item(item_id: String) -> StringName:
	if not use_inventory_loadout:
		return InventoryService.ERROR_INVALID_SLOT
	var service := _get_inventory_service()
	if service == null:
		return InventoryService.ERROR_UNKNOWN_ITEM
	var err := service.acquire_item(item_id)
	if not err.is_empty():
		return err
	_refresh_inventory_after_reward()
	apply_inventory_loadout_to_player()
	return &""


# 인벤토리에서 버린 장비를 플레이어 앞에 월드 드롭으로 생성합니다.
func can_drop_equipment_item(item_id: String) -> bool:
	return not item_id.strip_edges().is_empty() and EQUIPMENT_DROP_SCENE != null


func drop_equipment_item(item_id: String) -> bool:
	return _drop_equipment_item(item_id)


func _drop_equipment_item(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var drop := EQUIPMENT_DROP_SCENE.instantiate() as EquipmentDrop
	if drop == null:
		push_error("Game: EquipmentDrop scene must instantiate EquipmentDrop.")
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


func _get_inventory_service() -> InventoryService:
	if _inventory_menu == null or not _inventory_menu.has_method("get_service"):
		return null
	return _inventory_menu.get_service()


func _refresh_inventory_after_reward() -> void:
	if _inventory_menu == null:
		return
	if _inventory_menu.has_method("refresh_all_slots"):
		_inventory_menu.refresh_all_slots()
	if _inventory_menu.has_method("persist_loadout_if_enabled"):
		_inventory_menu.call("persist_loadout_if_enabled")


func _show_weapon_reward_error(err: StringName) -> void:
	if err.is_empty():
		return
	if has_node("%BalanceNoticeBanner"):
		%BalanceNoticeBanner.show_timeline_alert(UiLocale.t(err), 2.5)


# F5 씬 UI 노드 — 프리팹 인스턴스 실패 시 null 방지.
func _bind_ui_nodes() -> void:
	_pause_menu = get_node_or_null("PauseMenu") as CanvasLayer
	_weapon_select_menu = get_node_or_null("WeaponSelectMenu") as CanvasLayer
	_inventory_menu = get_node_or_null("InventoryMenu") as CanvasLayer
	_chest_purchase_menu = get_node_or_null("ChestPurchaseMenu") as ChestPurchaseMenu
	if _chest_purchase_menu == null:
		_chest_purchase_menu = CHEST_PURCHASE_MENU_SCENE.instantiate() as ChestPurchaseMenu
		if _chest_purchase_menu != null:
			_chest_purchase_menu.name = "ChestPurchaseMenu"
			add_child(_chest_purchase_menu)
	if _chest_purchase_menu != null:
		_chest_purchase_menu.purchase_requested.connect(_on_chest_purchase_requested)
		_chest_purchase_menu.close_requested.connect(_on_chest_purchase_close_requested)
	if _pause_menu == null:
		push_error("Game: PauseMenu missing — check res://ui/pause_menu_overlay.tscn loads in survivors_game.tscn.")
	if _inventory_menu == null:
		push_error("Game: InventoryMenu missing — check res://ui/inventory/inventory_overlay.tscn.")


# 아레나 웨이브 디렉터 신호를 메인 게임 흐름에 연결합니다.
func _setup_arena_director() -> void:
	_arena_director = ArenaWaveDirectorScript.new()
	_arena_director.wave_started.connect(_on_arena_wave_started)
	_arena_director.wave_completed.connect(_on_arena_wave_completed)
	_arena_director.arena_completed.connect(_on_arena_completed)


# 아레나 시작 장치를 맵 중앙에 배치합니다.
func _setup_arena_teleporter() -> void:
	if _arena_teleporter != null:
		return
	_arena_teleporter = ARENA_TELEPORTER_SCENE.instantiate() as ArenaTeleporter
	if _arena_teleporter == null:
		push_error("Game: ArenaTeleporter scene must instantiate ArenaTeleporter.")
		return
	add_child(_arena_teleporter)
	_arena_teleporter.global_position = Vector2.ZERO
	_arena_teleporter.set_available(false)
	_arena_teleporter.activated.connect(_on_arena_teleporter_activated)


func _ensure_game_started() -> void:
	if _game_started:
		return
	_game_started = true
	%Player.set_contact_damage_enabled(true)
	if _is_arena_mode():
		_prepare_arena_run()
	else:
		_apply_spawn_interval_from_phase(true)
		$Timer.start()


func _prepare_arena_run() -> void:
	if _arena_director == null:
		_setup_arena_director()
	if _arena_teleporter == null:
		_setup_arena_teleporter()
	_arena_director.start()
	$Timer.stop()
	_enable_arena_teleporter(
		UiLocale.t(&"arena_teleporter.start_notice") % InteractionInput.get_interact_label(),
		4.0
	)
	_update_time_hud()
	_update_balance_phase_hud()


# 웨이브 사이 대기 상태에서만 텔레포터를 다시 열어 다음 웨이브 시작을 플레이어에게 맡깁니다.
func _enable_arena_teleporter(message: String, duration: float) -> void:
	_arena_waiting_for_teleporter = true
	if _arena_teleporter != null:
		_arena_teleporter.global_position = Vector2.ZERO
		_arena_teleporter.set_available(true)
	%BalanceNoticeBanner.show_timeline_alert(message, duration)


# 웨이브 보상 무기 획득이 끝난 뒤 다음 웨이브 시작 장치를 엽니다.
func _queue_arena_teleporter_after_weapon_select(message: String) -> void:
	_arena_enable_teleporter_after_weapon_select = true
	_arena_pending_teleporter_message = message


func _enable_pending_arena_teleporter() -> void:
	var message := _arena_pending_teleporter_message
	_arena_enable_teleporter_after_weapon_select = false
	_arena_pending_teleporter_message = ""
	if message.is_empty():
		message = "텔레포터로 다음 웨이브 시작"
	_enable_arena_teleporter(message, 4.0)


func _show_pending_arena_chest_reward() -> void:
	if _pending_arena_chest_reward_wave <= 0:
		return
	_spawn_arena_gold_chests(_pending_arena_chest_reward_wave)
	_pending_arena_chest_reward_wave = 0


# 웨이브 클리어 후 중앙 주변에 선택형 골드 상자를 배치합니다.
func _spawn_arena_gold_chests(wave_number: int) -> void:
	_clear_arena_gold_chests()
	if not use_inventory_loadout or GOLD_CHEST_SCENE == null:
		return
	var count := ARENA_CHEST_CONFIGS.size()
	for i in count:
		var chest := GOLD_CHEST_SCENE.instantiate() as GoldChest
		if chest == null:
			continue
		add_child(chest)
		var angle := TAU * float(i) / float(count) - PI * 0.5
		chest.global_position = Vector2(cos(angle), sin(angle)) * ARENA_CHEST_RADIUS
		chest.setup(_build_arena_chest_config(ARENA_CHEST_CONFIGS[i], wave_number))
		chest.purchase_requested.connect(_on_gold_chest_purchase_requested)
		_active_gold_chests.append(chest)


func _build_arena_chest_config(base_config: Dictionary, wave_number: int) -> Dictionary:
	var config := base_config.duplicate()
	config["price"] = int(config.get("price", ARENA_CHEST_SPECIFIC_PRICE)) + wave_number * ARENA_CHEST_PRICE_PER_WAVE
	config["wave_number"] = wave_number
	return config


func _clear_arena_gold_chests() -> void:
	for chest in _active_gold_chests:
		if is_instance_valid(chest):
			chest.queue_free()
	_active_gold_chests.clear()


func _start_next_arena_wave() -> void:
	if _arena_director == null or _run_cleared or _run_failed:
		return
	_arena_director.begin_next_wave()
	if _arena_director.has_pending_spawns():
		$Timer.wait_time = ArenaWaveDirectorScript.SPAWN_INTERVAL
		$Timer.start()


func _spawn_next_arena_mob() -> void:
	if _arena_director == null:
		return
	if _arena_director.has_pending_spawns():
		_arena_director.spawn_next(self)
	if not _arena_director.has_pending_spawns():
		$Timer.stop()
		_check_arena_wave_completion()


func _check_arena_wave_completion() -> void:
	if _arena_director == null or not _is_arena_mode():
		return
	if is_weapon_select_open():
		return
	_arena_director.check_wave_completion(_count_alive_mobs())


func _consume_pending_weapon_select() -> void:
	_pending_weapon_selects = maxi(_pending_weapon_selects - 1, 0)
	while _pending_weapon_selects > 0:
		if show_weapon_select():
			return
		_pending_weapon_selects -= 1
	_ensure_game_started()


func _on_player_leveled_up(_new_level: int) -> void:
	_pending_weapon_selects += 1
	if _pending_weapon_selects == 1 and not is_weapon_select_open():
		show_weapon_select()


func register_kill() -> void:
	kill_count += 1
	_update_kill_count_hud()
	if %Player.has_method(&"apply_loadout_on_kill"):
		%Player.apply_loadout_on_kill()
	if _is_arena_mode():
		call_deferred("_check_arena_wave_completion")


# 몹 피해 적용 시 무기별 누적 피해량을 기록합니다.
func register_weapon_damage(weapon: WeaponData, amount: int) -> void:
	_weapon_damage.register(weapon, amount)


# UI 표시용 — 보유 무기 포함, 피해량 내림차순 행 목록.
func get_weapon_damage_display_rows() -> Array[Dictionary]:
	return _weapon_damage.build_display_rows(%Player.get_owned_weapons())


func refresh_locale() -> void:
	_update_kill_count_hud()
	_update_time_hud()
	InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)
	%WeaponDamageTitle.text = UiLocale.t(&"gameover.weapon_damage")
	%GameOverRestartButton.text = UiLocale.t(&"gameover.restart")
	%GameOverQuitButton.text = UiLocale.t(&"pause.quit")
	_refresh_game_over_title()


func _update_kill_count_hud() -> void:
	%KillCountLabel.text = UiLocale.t(&"hud.kills") % kill_count


func _update_time_hud() -> void:
	if _is_arena_mode() and _arena_director != null:
		%TimeLabel.text = _arena_director.get_hud_text()
		return
	%TimeLabel.text = UiLocale.format_hud_time(_elapsed_seconds)


func _process(delta: float) -> void:
	if _is_balance_clock_running():
		_elapsed_seconds += delta
		_tick_density_event(delta)
		_tick_balance_timeline()
		_apply_spawn_interval_from_phase()
		_try_trigger_stage_clear()
	elif _is_arena_clock_running():
		_check_arena_wave_completion()
	_update_time_hud()
	_update_balance_phase_hud()


func _is_balance_clock_running() -> bool:
	return _is_survival_mode() and _game_started and not get_tree().paused


func _is_arena_clock_running() -> bool:
	return _is_arena_mode() and _game_started and not get_tree().paused and not is_game_over()


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func get_current_balance_phase() -> BalancePhase:
	return _query_balance_phase()


# 몹 처치 XP·골드(예정) — KillRewards 단일 계산 경로.
func get_kill_rewards_for_mob(mob_kind: StringName) -> Dictionary:
	var rewards := KillRewards.compute(mob_kind, get_current_balance_phase())
	if _is_arena_mode():
		rewards["xp"] = 0
	return rewards


func _query_balance_phase() -> BalancePhase:
	if not balance_table:
		return BalancePhase.new()
	return balance_table.get_phase_for_time(_elapsed_seconds)


# balance_table 표 축(분) — 타임라인·키프레임과 동일 축.
func _get_curve_minutes() -> float:
	if not balance_table:
		return maxf(_elapsed_seconds, 0.0) / 60.0
	return balance_table.get_curve_minutes(_elapsed_seconds)


func _tick_density_event(delta: float) -> void:
	if _density_event_remaining <= 0.0:
		return
	_density_event_remaining = maxf(_density_event_remaining - delta, 0.0)
	if _density_event_remaining <= 0.0:
		_density_event_mult = 1.0
		_apply_spawn_interval_from_phase(true)


func _tick_balance_timeline() -> void:
	if not _game_started or not balance_timeline or _run_cleared or _run_failed:
		return
	var curve_minutes := _get_curve_minutes()
	for index in range(balance_timeline.events.size()):
		var event: BalanceTimelineEvent = balance_timeline.events[index]
		if not event:
			continue
		var key := _timeline_event_key(event, index)
		if _timeline_fired_keys.has(key):
			continue
		if curve_minutes + 0.0001 < event.at_minute:
			continue
		_fire_timeline_event(event)
		_timeline_fired_keys[key] = true


func _timeline_event_key(event: BalanceTimelineEvent, index: int) -> String:
	var id := event.event_id.strip_edges()
	if not id.is_empty():
		return id
	return "%s@%d" % [str(event.at_minute), index]


func _fire_timeline_event(event: BalanceTimelineEvent) -> void:
	if not event.banner_message.is_empty():
		%BalanceNoticeBanner.show_timeline_alert(event.banner_message, 4.0)
	if event.density_duration_seconds > 0.0 and event.density_mult > 1.0:
		# 겹칠 때 더 강한 배율·더 긴 잔여 시간을 유지합니다.
		_density_event_mult = maxf(_density_event_mult, event.density_mult)
		_density_event_remaining = maxf(_density_event_remaining, event.density_duration_seconds)
		_apply_spawn_interval_from_phase(true)
	if event.forced_spawn_count > 0 and event.forced_mob_scene:
		for _i in range(event.forced_spawn_count):
			spawn_mob(event.forced_mob_scene, true)


func _get_effective_spawn_density() -> float:
	return _query_balance_phase().spawn_density * _density_event_mult


func _apply_spawn_interval_from_phase(force: bool = false) -> void:
	var density := _get_effective_spawn_density()
	if not force and is_equal_approx(density, _last_spawn_density):
		return
	_last_spawn_density = density
	$Timer.wait_time = base_spawn_interval / maxf(density, 0.01)


func _update_balance_phase_hud() -> void:
	if _is_arena_mode():
		if _arena_director != null:
			%BalanceNoticeBanner.update_arena_display(
				_arena_director.get_notice_text(),
				_arena_director.get_wave_progress(),
				_arena_director.get_segment_text()
			)
		return
	if not balance_table:
		return
	var segment := balance_table.get_keyframe_segment_for_time(_elapsed_seconds)
	%BalanceNoticeBanner.update_display(segment)


func get_alive_mob_count() -> int:
	return _count_alive_mobs()


func _count_alive_mobs() -> int:
	return get_tree().get_nodes_in_group("mobs").size()


func spawn_mob(
	forced_scene: PackedScene = null,
	ignore_alive_cap: bool = false,
	health_multiplier: float = -1.0
):
	if _run_cleared or _run_failed:
		return null
	if not ignore_alive_cap and _count_alive_mobs() >= max_alive_mobs:
		return null

	var phase := _query_balance_phase()
	var mob_scene := forced_scene if forced_scene else MobSpawnSelector.pick_scene(phase)
	var spawn_pos: Vector2 = %MapArena.get_random_spawn_position(%Player.global_position)
	var pool: ScenePool = $ObjectPools as ScenePool
	var new_mob: Mob
	if pool:
		new_mob = pool.acquire(mob_scene, self, spawn_pos) as Mob
	else:
		new_mob = mob_scene.instantiate() as Mob
		add_child(new_mob)
		new_mob.global_position = spawn_pos
	if not new_mob:
		push_error("Game.spawn_mob: spawn scene must instantiate a Mob.")
		return null
	var spawn_health_multiplier := phase.hp_multiplier
	if health_multiplier > 0.0:
		spawn_health_multiplier = health_multiplier
	new_mob.initialize_spawn_health(spawn_health_multiplier)
	return new_mob


func _on_timer_timeout():
	if _is_arena_mode():
		_spawn_next_arena_mob()
		return
	spawn_mob()


func _on_arena_teleporter_activated() -> void:
	if not _is_arena_mode() or not _game_started or not _arena_waiting_for_teleporter:
		return
	_arena_waiting_for_teleporter = false
	_hide_chest_purchase_menu()
	_clear_arena_gold_chests()
	%BalanceNoticeBanner.show_timeline_alert("아레나 시작", 2.0)
	_start_next_arena_wave()


func _on_arena_wave_started(_wave_number: int, title: String, _is_boss_wave: bool) -> void:
	BuffTriggerRouter.apply_arena_wave_start(%Player, _wave_number)
	_update_time_hud()
	%BalanceNoticeBanner.show_timeline_alert(title, 3.0)


func _on_arena_wave_completed(wave_number: int) -> void:
	$Timer.stop()
	if %Player.has_method(&"on_wave_completed_for_buffs"):
		%Player.call("on_wave_completed_for_buffs")
	_pending_arena_chest_reward_wave = wave_number
	var next_wave_message := "Wave %d 클리어 · 텔레포터로 다음 웨이브 시작" % wave_number
	_queue_arena_teleporter_after_weapon_select(next_wave_message)
	if not show_reward_select(&"weapon_select.arena_wave_clear"):
		_show_pending_arena_chest_reward()
		_enable_pending_arena_teleporter()


func _on_arena_completed(_wave_number: int) -> void:
	if %Player.has_method(&"on_wave_completed_for_buffs"):
		%Player.call("on_wave_completed_for_buffs")
	_hide_chest_purchase_menu()
	_clear_arena_gold_chests()
	_trigger_stage_clear()


func _on_gold_chest_purchase_requested(chest: GoldChest) -> void:
	_show_chest_purchase_menu(chest)


func _show_chest_purchase_menu(chest: GoldChest) -> void:
	if chest == null or _chest_purchase_menu == null or not is_instance_valid(chest):
		return
	_chest_purchase_menu.present_chest(chest, _build_chest_purchase_details(chest))
	_chest_purchase_menu.show()
	get_tree().paused = true


func _hide_chest_purchase_menu() -> void:
	if _chest_purchase_menu == null:
		return
	_chest_purchase_menu.hide()
	if not is_game_over() and not is_inventory_open() and not is_weapon_select_open() and not is_pause_menu_open():
		get_tree().paused = false


func _on_chest_purchase_close_requested() -> void:
	_hide_chest_purchase_menu()


func _on_chest_purchase_requested(chest: GoldChest) -> void:
	try_purchase_gold_chest(chest)


# 골드 상자 결제와 인벤토리 배치를 한 경로에서 처리합니다.
func try_purchase_gold_chest(chest: GoldChest) -> void:
	if chest == null or not is_instance_valid(chest):
		return
	var service := _get_inventory_service()
	if service == null:
		_show_chest_purchase_error(chest, UiLocale.t(InventoryService.ERROR_UNKNOWN_ITEM))
		return
	var config := chest.get_config()
	var price := int(config.get("price", 0))
	if not %Player.can_spend_gold(price):
		_show_chest_purchase_error(chest, UiLocale.t(&"chest.error.not_enough_gold"))
		return
	var pick := _pick_purchasable_chest_item(service, config)
	var pick_error: StringName = pick.get("error", &"")
	if not pick_error.is_empty():
		_show_chest_purchase_error(chest, UiLocale.t(pick_error))
		return
	var item_id := String(pick.get("item_id", ""))
	if not %Player.spend_gold(price):
		_show_chest_purchase_error(chest, UiLocale.t(&"chest.error.not_enough_gold"))
		return
	var err := service.acquire_item(item_id)
	if not err.is_empty():
		%Player.refund_gold(price)
		_show_chest_purchase_error(chest, UiLocale.t(err))
		return
	_refresh_inventory_after_reward()
	apply_inventory_loadout_to_player()
	chest.set_available(false)
	_active_gold_chests.erase(chest)
	chest.queue_free()
	var item_name := _get_item_display_name(service.registry, item_id)
	_chest_purchase_menu.show_result(UiLocale.t(&"chest.result.acquired") % item_name)


func _show_chest_purchase_error(chest: GoldChest, message: String) -> void:
	if _chest_purchase_menu == null:
		return
	_chest_purchase_menu.show_error(message, _build_chest_purchase_details(chest))


func _build_chest_purchase_details(chest: GoldChest) -> Dictionary:
	var config := chest.get_config()
	var price := int(config.get("price", 0))
	var slot_filter := StringName(config.get("slot_filter", ItemRewardPicker.SLOT_ALL))
	var wave_number := int(config.get("wave_number", _get_current_arena_wave_number()))
	var target_rarity := _roll_preview_rarity_for_wave(wave_number)
	var odds_text := _format_rarity_odds_for_wave(wave_number)
	var status_text := UiLocale.t(&"chest.purchase.ready")
	var can_purchase := true
	var service := _get_inventory_service()
	if not %Player.can_spend_gold(price):
		status_text = UiLocale.t(&"chest.error.not_enough_gold")
		can_purchase = false
	elif service == null:
		status_text = UiLocale.t(InventoryService.ERROR_UNKNOWN_ITEM)
		can_purchase = false
	else:
		var blocker := _get_chest_purchase_blocker(service, slot_filter, target_rarity)
		if not blocker.is_empty():
			status_text = UiLocale.t(blocker)
			can_purchase = false
	return {
		"title": UiLocale.t(StringName(config.get("title_key", &"chest.purchase.title"))),
		"slot_text": UiLocale.t(&"chest.purchase.slot") % _get_slot_filter_label(slot_filter),
		"odds_text": UiLocale.t(&"chest.purchase.odds") % odds_text,
		"gold_text": UiLocale.t(&"chest.purchase.gold") % [%Player.gold, price],
		"status_text": status_text,
		"can_purchase": can_purchase,
	}


func _pick_purchasable_chest_item(service: InventoryService, config: Dictionary) -> Dictionary:
	var slot_filter := StringName(config.get("slot_filter", ItemRewardPicker.SLOT_ALL))
	var target_rarity := _roll_rarity_for_wave(int(config.get("wave_number", _get_current_arena_wave_number())))
	var first_blocker: StringName = &""
	for rarity in ItemRewardPicker.get_rarity_fallback_chain(target_rarity):
		var candidates := ItemRewardPicker.collect_candidates(
			service.registry,
			service.loadout,
			slot_filter,
			rarity
		)
		var purchasable: Array[String] = []
		for item_id in candidates:
			var err := service.can_acquire_item(item_id)
			if err.is_empty():
				purchasable.append(item_id)
			elif first_blocker.is_empty():
				first_blocker = err
		if purchasable.is_empty():
			continue
		var index := _chest_rng.randi_range(0, purchasable.size() - 1)
		return {"error": &"", "item_id": purchasable[index], "rarity": rarity}
	if not first_blocker.is_empty():
		return {"error": first_blocker, "item_id": "", "rarity": ""}
	return {"error": ItemRewardPicker.ERROR_NO_CANDIDATE, "item_id": "", "rarity": ""}


func _get_chest_purchase_blocker(
	service: InventoryService,
	slot_filter: StringName,
	target_rarity: String
) -> StringName:
	var first_blocker: StringName = &""
	for rarity in ItemRewardPicker.get_rarity_fallback_chain(target_rarity):
		var candidates := ItemRewardPicker.collect_candidates(
			service.registry,
			service.loadout,
			slot_filter,
			rarity
		)
		for item_id in candidates:
			var err := service.can_acquire_item(item_id)
			if err.is_empty():
				return &""
			if first_blocker.is_empty():
				first_blocker = err
	if not first_blocker.is_empty():
		return first_blocker
	return ItemRewardPicker.ERROR_NO_CANDIDATE


func _roll_rarity_for_wave(wave_number: int) -> String:
	var uncommon_chance := _get_uncommon_chance_for_wave(wave_number)
	return "Uncommon" if _chest_rng.randf() < uncommon_chance else "Common"


func _roll_preview_rarity_for_wave(wave_number: int) -> String:
	var uncommon_chance := _get_uncommon_chance_for_wave(wave_number)
	return "Uncommon" if uncommon_chance > 0.0 else "Common"


func _get_uncommon_chance_for_wave(wave_number: int) -> float:
	if wave_number <= 2:
		return 0.10
	if wave_number <= 4:
		return 0.20
	if wave_number == 5:
		return 0.30
	if wave_number <= 7:
		return 0.40
	if wave_number <= 9:
		return 0.50
	return 0.60


func _format_rarity_odds_for_wave(wave_number: int) -> String:
	var uncommon := int(round(_get_uncommon_chance_for_wave(wave_number) * 100.0))
	var common := 100 - uncommon
	return "Common %d%% / Uncommon %d%%" % [common, uncommon]


func _get_current_arena_wave_number() -> int:
	if _arena_director == null:
		return 1
	return maxi(_arena_director.current_wave, 1)


func _get_slot_filter_label(slot_filter: StringName) -> String:
	if slot_filter == ItemRewardPicker.SLOT_ALL:
		return UiLocale.t(&"slot.all")
	return UiLocale.t(StringName("slot.%s" % String(slot_filter)))


func _get_item_display_name(registry: ItemRegistry, item_id: String) -> String:
	var resource := registry.resolve_gear_or_weapon(item_id)
	if resource != null and resource.has_method("get_display_name_localized"):
		return resource.call("get_display_name_localized")
	return item_id


func is_game_over() -> bool:
	return _run_cleared or _run_failed


func is_run_cleared() -> bool:
	return _run_cleared


# 표 축 30분( balance_pace_multiplier 반영)에 도달하면 클리어합니다.
func _get_clear_elapsed_seconds() -> float:
	var pace := 1.0
	if balance_table:
		pace = maxf(balance_table.balance_pace_multiplier, 0.01)
	return RUN_CLEAR_CURVE_MINUTES * 60.0 / pace


func _try_trigger_stage_clear() -> void:
	if not _game_started or _run_cleared or _run_failed:
		return
	if _elapsed_seconds < _get_clear_elapsed_seconds():
		return
	_trigger_stage_clear()


func _trigger_stage_clear() -> void:
	_run_cleared = true
	$Timer.stop()
	_hide_chest_purchase_menu()
	_clear_arena_gold_chests()
	var mobs := get_tree().get_nodes_in_group("mobs").duplicate()
	for node in mobs:
		var mob := node as Mob
		if mob:
			mob.die_from_stage_clear()
	_show_stage_clear()


func _show_stage_clear() -> void:
	_populate_game_over_weapon_damage()
	%GameOver.show()
	_refresh_game_over_title()
	get_tree().paused = true


func show_pause_menu() -> void:
	if is_weapon_select_open() or is_inventory_open() or is_chest_purchase_open() or _pause_menu == null:
		return
	_pause_menu.refresh_owned_weapons()
	_pause_menu.show()
	get_tree().paused = true


func resume_game() -> void:
	if _pause_menu == null:
		return
	_pause_menu.hide()
	if not is_game_over() and not is_inventory_open() and not is_chest_purchase_open():
		get_tree().paused = false


func show_inventory() -> void:
	InventoryGameBridge.show_inventory(self, _inventory_menu)


func hide_inventory() -> void:
	InventoryGameBridge.hide_inventory(self, _inventory_menu)


func toggle_inventory() -> void:
	InventoryGameBridge.toggle_inventory(self, _inventory_menu)


func show_inventory_swap_toast(message: String) -> void:
	%BalanceNoticeBanner.show_timeline_alert(message, 2.0)


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
	InventoryCombatBridge.apply_loadout_to_player(
		%Player,
		menu_service.registry,
		menu_service.loadout
	)
	_sync_weapon_run_state_from_owned()
	_refresh_passive_stats()
	InventoryGameBridge.refresh_combat_set_hud(self, _inventory_menu)


func _unhandled_input(event: InputEvent) -> void:
	if InventoryGameBridge.handle_inventory_input(self, _inventory_menu, event):
		get_viewport().set_input_as_handled()


func _on_player_health_depleted():
	_run_failed = true
	$Timer.stop()
	_hide_chest_purchase_menu()
	_clear_arena_gold_chests()
	_populate_game_over_weapon_damage()
	%GameOver.show()
	_refresh_game_over_title()
	get_tree().paused = true


func _refresh_game_over_title() -> void:
	if not %GameOver.visible:
		return
	if _run_cleared:
		%GameOverTitle.text = UiLocale.t(&"gameover.clear")
	elif _run_failed:
		%GameOverTitle.text = UiLocale.t(&"gameover.fail")
	_refresh_game_over_run_stats()


# 게임오버·클리어 화면에 생존 시간·레벨·처치 수 요약을 갱신합니다.
func _refresh_game_over_run_stats() -> void:
	if not %GameOver.visible:
		return
	var player_level: int = %Player.level
	if _is_arena_mode() and _arena_director != null:
		var time_text := UiLocale.format_hud_time(_elapsed_seconds)
		%RunStatsLabel.text = UiLocale.t(&"gameover.stats_arena") % [
			_arena_director.current_wave,
			ArenaWaveDirectorScript.MAX_WAVE,
			time_text,
			player_level,
			kill_count,
		]
	else:
		%RunStatsLabel.text = UiLocale.t(&"gameover.stats_survival") % [
			UiLocale.format_hud_time(_elapsed_seconds),
			player_level,
			kill_count,
		]


func _populate_game_over_weapon_damage() -> void:
	WeaponDamageUi.populate_list(
		%WeaponDamageList,
		get_weapon_damage_display_rows(),
		UiLocale.t(&"gameover.no_damage"),
		true
	)


func _restart_game() -> void:
	$SpeedCheat.reset_speed()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_restart_button_pressed() -> void:
	_restart_game()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_pause_continue_pressed() -> void:
	resume_game()


func _on_pause_restart_pressed() -> void:
	_restart_game()


func _on_pause_quit_pressed() -> void:
	get_tree().quit()
