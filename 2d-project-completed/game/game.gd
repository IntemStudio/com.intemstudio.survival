extends Node2D

const DEFAULT_BALANCE_TABLE := preload("res://game/balance/default_balance_table.tres")

@export var balance_table: BalanceTable
@export_range(0.05, 2.0, 0.01, "or_greater") var base_spawn_interval := 0.3
@export_range(1, 500, 1) var max_alive_mobs := 100

var _elapsed_seconds := 0.0
var _last_spawn_density := -1.0
var kill_count := 0
var _game_started := false
var _pending_weapon_selects := 0
var _weapon_damage := WeaponDamageTracker.new()


func _ready() -> void:
	if not balance_table:
		balance_table = DEFAULT_BALANCE_TABLE
	_update_kill_count_hud()
	$Timer.stop()
	%Player.leveled_up.connect(_on_player_leveled_up)
	if not show_weapon_select("무기 선택"):
		_ensure_game_started()


func is_weapon_select_open() -> bool:
	return %WeaponSelectMenu.visible


func is_pause_menu_open() -> bool:
	return %PauseMenu.visible


func show_weapon_select(title: String = "레벨 업! 무기 선택") -> bool:
	if not %WeaponSelectMenu.present_random_choices(title, %Player.get_owned_weapons()):
		_consume_pending_weapon_select()
		return false

	%WeaponSelectMenu.show()
	%WeaponSelectMenu.on_menu_opened()
	get_tree().paused = true
	return true


func on_weapon_chosen(weapon: WeaponData) -> void:
	%WeaponSelectMenu.on_menu_closed()
	%WeaponSelectMenu.hide()
	get_tree().paused = false
	%Player.add_weapon.call_deferred(weapon)

	_ensure_game_started()
	_consume_pending_weapon_select()


func _ensure_game_started() -> void:
	if _game_started:
		return
	_game_started = true
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


func _update_kill_count_hud() -> void:
	%KillCountLabel.text = "처치: %d" % kill_count


func _process(delta: float) -> void:
	if _is_balance_clock_running():
		_elapsed_seconds += delta
		_apply_spawn_interval_from_phase()
	%TimeLabel.text = _format_time(_elapsed_seconds)
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


func _apply_spawn_interval_from_phase(force: bool = false) -> void:
	var density := _query_balance_phase().spawn_density
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


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var secs := total % 60
	return "%02d:%02d" % [minutes, secs]


func spawn_mob():
	if _count_alive_mobs() >= max_alive_mobs:
		return

	%PathFollow2D.progress_ratio = randf()
	var phase := _query_balance_phase()
	var mob_scene := MobSpawnSelector.pick_scene(phase)
	var pool: ScenePool = $ObjectPools as ScenePool
	var new_mob: Mob
	if pool:
		new_mob = pool.acquire(mob_scene, self) as Mob
	else:
		new_mob = mob_scene.instantiate() as Mob
		add_child(new_mob)
	if not new_mob:
		push_error("Game.spawn_mob: spawn scene must instantiate a Mob.")
		return
	new_mob.global_position = %PathFollow2D.global_position
	new_mob.initialize_spawn_health(phase.hp_multiplier)


func _on_timer_timeout():
	spawn_mob()


func is_game_over() -> bool:
	return %GameOver.visible


func show_pause_menu() -> void:
	if is_weapon_select_open():
		return
	%PauseMenu.show()
	get_tree().paused = true


func resume_game() -> void:
	%PauseMenu.hide()
	if not is_game_over():
		get_tree().paused = false


func _on_player_health_depleted():
	_populate_game_over_weapon_damage()
	%GameOver.show()
	get_tree().paused = true


func _populate_game_over_weapon_damage() -> void:
	var list := %WeaponDamageList
	for child in list.get_children():
		child.queue_free()

	var rows := _weapon_damage.build_display_rows(%Player.get_owned_weapons())
	if rows.is_empty():
		var empty_label := Label.new()
		empty_label.text = "기록된 피해 없음"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty_label)
		return

	var grand_total := 0
	for row in rows:
		grand_total += int(row["total"])

	for row in rows:
		var weapon: WeaponData = row["weapon"]
		var total: int = int(row["total"])
		var label := Label.new()
		label.text = "%s  %s" % [weapon.get_display_name_localized(), _format_damage(total)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		list.add_child(label)

	var total_label := Label.new()
	total_label.text = "합계  %s" % _format_damage(grand_total)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 24)
	list.add_child(total_label)


func _format_damage(amount: int) -> String:
	var text := str(amount)
	if amount < 1000:
		return text
	var parts: PackedStringArray = []
	while text.length() > 3:
		parts.insert(0, text.substr(text.length() - 3, 3))
		text = text.substr(0, text.length() - 3)
	if not text.is_empty():
		parts.insert(0, text)
	return ",".join(parts)


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
