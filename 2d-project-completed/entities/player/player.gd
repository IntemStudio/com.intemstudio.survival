extends CharacterBody2D

signal health_depleted
signal leveled_up(new_level: int)

const GUN_SCENE := preload("res://weapons/core/gun.tscn")
const DASH_SPEED := 1400.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.5

@export var pickup_range := 150.0
@export var base_exp_to_level := 5
const DAMAGE_FLOAT_INTERVAL := 0.2

var health = 100.0
var level := 1
var experience := 0
var _owned_weapons: Array[WeaponData] = []
var _damage_float_accumulator := 0.0
var _damage_float_timer := 0.0
var _last_move_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _dash_time_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var auto_attack_enabled := true
var _health_depleted_emitted := false
var _hit_flash_target: CanvasItem
var _hit_flash_base_modulate := Color.WHITE


func _ready() -> void:
	_hit_flash_target = %HappyBoo.get_node("Colorizer") as CanvasItem
	_hit_flash_base_modulate = _hit_flash_target.modulate
	var pickup_shape := %PickupRange.get_node("CollisionShape2D").shape as CircleShape2D
	pickup_shape.radius = pickup_range
	%PickupRange.area_entered.connect(_on_pickup_range_area_entered)
	%DashCooldownBar.visible = false
	_update_experience_hud()
	_update_auto_attack_hud()


func is_auto_attack_enabled() -> bool:
	return auto_attack_enabled


# F키 등으로 자동 공격 on/off를 전환합니다.
func set_auto_attack_enabled(enabled: bool) -> void:
	if auto_attack_enabled == enabled:
		return
	auto_attack_enabled = enabled
	_apply_auto_attack_to_weapons()
	_update_auto_attack_hud()


func toggle_auto_attack() -> void:
	set_auto_attack_enabled(not auto_attack_enabled)


func _apply_auto_attack_to_weapons() -> void:
	for gun in %Weapons.get_children():
		if gun.has_method("refresh_auto_attack"):
			gun.refresh_auto_attack()


func get_owned_weapons() -> Array[WeaponData]:
	return _owned_weapons.duplicate()


func has_weapon(weapon_data: WeaponData) -> bool:
	var key := weapon_data.get_unique_key()
	for owned in _owned_weapons:
		if owned.get_unique_key() == key:
			return true
	return false


# 테스트 아레나 등에서 무기 슬롯을 비울 때 사용합니다.
func clear_weapons() -> void:
	for gun in %Weapons.get_children():
		gun.free()
	_owned_weapons.clear()


func add_weapon(weapon_data: WeaponData) -> void:
	if has_weapon(weapon_data):
		return

	_owned_weapons.append(weapon_data)

	var gun: Area2D = GUN_SCENE.instantiate()
	%Weapons.add_child(gun)
	gun.equip_weapon(weapon_data)
	_rearrange_weapons()


func _rearrange_weapons() -> void:
	var guns := %Weapons.get_children()
	for i in guns.size():
		var gun := guns[i]
		if gun.has_method("arrange_slot"):
			gun.arrange_slot(i, guns.size())


func get_exp_to_level() -> int:
	return base_exp_to_level * level


# 사망 시그널 중복 방지 상태를 초기화합니다(테스트 아레나 리스폰 등).
func reset_health_depleted_state() -> void:
	_health_depleted_emitted = false


func _play_hit_flash() -> void:
	if _hit_flash_target:
		HitFlash.play(_hit_flash_target, _hit_flash_base_modulate)


# 몹 원거리 투사체 1발 피해 (접촉 DPS와 별도).
func apply_mob_projectile_damage(amount: int) -> void:
	if amount <= 0 or _health_depleted_emitted:
		return
	_play_hit_flash()
	health -= float(amount)
	%HealthBar.value = health
	FloatingDamageText.spawn_player_damage(global_position, amount)
	_try_emit_health_depleted()


# 체력 회복 아이템 등에서 호출합니다.
func heal_health(amount: float) -> void:
	var max_hp: float = %HealthBar.max_value
	health = minf(health + amount, max_hp)
	%HealthBar.value = health
	if health > 0.0:
		_health_depleted_emitted = false


func gain_experience(amount: int) -> void:
	experience += amount
	while experience >= get_exp_to_level():
		experience -= get_exp_to_level()
		level += 1
		leveled_up.emit(level)
	_update_experience_hud()


func _update_experience_hud() -> void:
	var hud := get_node_or_null("/root/Game/HUD")
	if not hud:
		return
	var hud_root: Control = hud.get_node("HUDRoot")
	var exp_bar: ProgressBar = hud_root.get_node("ExperienceBar")
	var exp_to_level := get_exp_to_level()
	exp_bar.max_value = exp_to_level
	exp_bar.value = experience
	hud_root.get_node("LevelLabel").text = "Lv. %d" % level
	hud_root.get_node("ExpLabel").text = "%d / %d" % [experience, exp_to_level]


func _update_auto_attack_hud() -> void:
	var label := get_node_or_null("%AutoAttackLabel") as Label
	if not label:
		return
	if auto_attack_enabled:
		label.text = "자동 공격: ON (F)"
		label.add_theme_color_override("font_color", Color(0.1, 0.45, 0.15))
	else:
		label.text = "자동 공격: OFF (F)"
		label.add_theme_color_override("font_color", Color(0.55, 0.12, 0.12))


func _is_auto_attack_input_blocked() -> bool:
	var game := get_node_or_null("/root/Game")
	if not game:
		return false
	if game.is_weapon_select_open() or game.is_pause_menu_open() or game.is_game_over():
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _is_auto_attack_input_blocked():
		return
	if not event.is_action_pressed("toggle_auto_attack") or event.echo:
		return
	toggle_auto_attack()
	get_viewport().set_input_as_handled()


# 대시 쿨다운 중에만 발밑 게이지를 표시합니다.
func _update_dash_cooldown_gauge() -> void:
	var bar := %DashCooldownBar
	if _dash_cooldown_remaining <= 0.0:
		bar.visible = false
		return

	bar.visible = true
	bar.max_value = DASH_COOLDOWN
	bar.value = DASH_COOLDOWN - _dash_cooldown_remaining


func _on_pickup_range_area_entered(area: Area2D) -> void:
	if area.has_method("collect"):
		area.collect(self)
	elif area.has_method("start_magnet"):
		area.start_magnet(self)


func _physics_process(delta: float) -> void:
	const SPEED := 600.0
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.01:
		_last_move_direction = direction.normalized()

	_dash_cooldown_remaining = maxf(_dash_cooldown_remaining - delta, 0.0)
	_update_dash_cooldown_gauge()

	if _dash_time_remaining > 0.0:
		_dash_time_remaining -= delta
		velocity = _dash_direction * DASH_SPEED
	elif Input.is_action_just_pressed("dash") and _dash_cooldown_remaining <= 0.0:
		var dash_dir := direction
		if dash_dir.length_squared() < 0.01:
			dash_dir = _last_move_direction
		if dash_dir.length_squared() > 0.01:
			_dash_direction = dash_dir.normalized()
			_dash_time_remaining = DASH_DURATION
			_dash_cooldown_remaining = DASH_COOLDOWN
			velocity = _dash_direction * DASH_SPEED
		else:
			velocity = direction * SPEED
	else:
		velocity = direction * SPEED

	move_and_slide()

	if velocity.length_squared() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()
	
	# Taking damage
	if not _health_depleted_emitted:
		const DAMAGE_RATE = 6.0
		var overlapping_mobs = %HurtBox.get_overlapping_bodies()
		if overlapping_mobs:
			var damage_this_frame: float = DAMAGE_RATE * overlapping_mobs.size() * delta
			health -= damage_this_frame
			%HealthBar.value = health
			_damage_float_accumulator += damage_this_frame
			_try_emit_health_depleted()

	_damage_float_timer -= delta
	if _damage_float_accumulator > 0.0 and _damage_float_timer <= 0.0:
		_play_hit_flash()
		FloatingDamageText.spawn_player_damage(
			global_position,
			maxi(int(_damage_float_accumulator), 1)
		)
		_damage_float_accumulator = 0.0
		_damage_float_timer = DAMAGE_FLOAT_INTERVAL


func _try_emit_health_depleted() -> void:
	if health > 0.0 or _health_depleted_emitted:
		return
	_health_depleted_emitted = true
	health_depleted.emit()
