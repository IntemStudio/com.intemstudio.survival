extends Node2D

const DEFAULT_BALANCE_TABLE := preload("res://game/balance/default_balance_table.tres")
const DEFAULT_BALANCE_TIMELINE := preload("res://game/balance/default_balance_timeline.tres")
const RUN_CLEAR_CURVE_MINUTES := 30.0

@export var balance_table: BalanceTable
@export var balance_timeline: BalanceTimeline
@export_range(0.05, 2.0, 0.01, "or_greater") var base_spawn_interval := 0.3
@export_range(1, 500, 1) var max_alive_mobs := 100

var _elapsed_seconds := 0.0
var _last_spawn_density := -1.0
var kill_count := 0
var _game_started := false
var _run_cleared := false
var _run_failed := false
var _pending_weapon_selects := 0
var _weapon_damage := WeaponDamageTracker.new()
var _timeline_fired_keys: Dictionary = {}
var _density_event_mult := 1.0
var _density_event_remaining := 0.0

var _pause_menu: CanvasLayer
var _weapon_select_menu: CanvasLayer


func _ready() -> void:
	_bind_ui_nodes()
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
	%Player.leveled_up.connect(_on_player_leveled_up)
	if not show_weapon_select(&"weapon_select.title"):
		_ensure_game_started()
	refresh_locale()


func is_game_started() -> bool:
	return _game_started


func is_weapon_select_open() -> bool:
	return _weapon_select_menu != null and _weapon_select_menu.visible


func is_pause_menu_open() -> bool:
	return _pause_menu != null and _pause_menu.visible


func show_weapon_select(title_key: StringName = &"weapon_select.level_up") -> bool:
	if _weapon_select_menu == null:
		push_error("Game: WeaponSelectMenu node missing.")
		return false
	if not _weapon_select_menu.present_random_choices(title_key, %Player.get_owned_weapons()):
		_consume_pending_weapon_select()
		return false

	_weapon_select_menu.show()
	_weapon_select_menu.on_menu_opened()
	get_tree().paused = true
	return true


func on_weapon_chosen(weapon: WeaponData) -> void:
	if _weapon_select_menu == null:
		return
	_weapon_select_menu.on_menu_closed()
	_weapon_select_menu.hide()
	get_tree().paused = false
	%Player.add_weapon.call_deferred(weapon)

	_ensure_game_started()
	_consume_pending_weapon_select()


# F5 씬 UI 노드 — 프리팹 인스턴스 실패 시 null 방지.
func _bind_ui_nodes() -> void:
	_pause_menu = get_node_or_null("PauseMenu") as CanvasLayer
	_weapon_select_menu = get_node_or_null("WeaponSelectMenu") as CanvasLayer
	if _pause_menu == null:
		push_error("Game: PauseMenu missing — check res://ui/pause_menu_overlay.tscn loads in survivors_game.tscn.")


func _ensure_game_started() -> void:
	if _game_started:
		return
	_game_started = true
	%Player.set_contact_damage_enabled(true)
	_apply_spawn_interval_from_phase(true)
	$Timer.start()


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


# 몹 피해 적용 시 무기별 누적 피해량을 기록합니다.
func register_weapon_damage(weapon: WeaponData, amount: int) -> void:
	_weapon_damage.register(weapon, amount)


# UI 표시용 — 보유 무기 포함, 피해량 내림차순 행 목록.
func get_weapon_damage_display_rows() -> Array[Dictionary]:
	return _weapon_damage.build_display_rows(%Player.get_owned_weapons())


func refresh_locale() -> void:
	_update_kill_count_hud()
	_update_time_hud()
	%WeaponDamageTitle.text = UiLocale.t(&"gameover.weapon_damage")
	%GameOverRestartButton.text = UiLocale.t(&"gameover.restart")
	%GameOverQuitButton.text = UiLocale.t(&"pause.quit")
	_refresh_game_over_title()


func _update_kill_count_hud() -> void:
	%KillCountLabel.text = UiLocale.t(&"hud.kills") % kill_count


func _update_time_hud() -> void:
	%TimeLabel.text = UiLocale.format_hud_time(_elapsed_seconds)


func _process(delta: float) -> void:
	if _is_balance_clock_running():
		_elapsed_seconds += delta
		_tick_density_event(delta)
		_tick_balance_timeline()
		_apply_spawn_interval_from_phase()
		_try_trigger_stage_clear()
	_update_time_hud()
	_update_balance_phase_hud()


func _is_balance_clock_running() -> bool:
	return _game_started and not get_tree().paused


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func get_current_balance_phase() -> BalancePhase:
	return _query_balance_phase()


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
	if not balance_table:
		return
	var segment := balance_table.get_keyframe_segment_for_time(_elapsed_seconds)
	%BalanceNoticeBanner.update_display(segment)


func _count_alive_mobs() -> int:
	return get_tree().get_nodes_in_group("mobs").size()


func spawn_mob(forced_scene: PackedScene = null, ignore_alive_cap: bool = false) -> void:
	if _run_cleared or _run_failed:
		return
	if not ignore_alive_cap and _count_alive_mobs() >= max_alive_mobs:
		return

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
		return
	new_mob.initialize_spawn_health(phase.hp_multiplier)


func _on_timer_timeout():
	spawn_mob()


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
	if is_weapon_select_open() or _pause_menu == null:
		return
	_pause_menu.refresh_owned_weapons()
	_pause_menu.show()
	get_tree().paused = true


func resume_game() -> void:
	if _pause_menu == null:
		return
	_pause_menu.hide()
	if not is_game_over():
		get_tree().paused = false


func _on_player_health_depleted():
	_run_failed = true
	$Timer.stop()
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
