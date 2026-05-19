extends CharacterBody2D

signal died

@export var attack_distance := 85.0

var speed = randf_range(200, 300) * 0.8
var max_health := 200
var health := max_health

var _poison_stacks: Array[Dictionary] = []
var _nettles_timer := 0.0
var _is_targeted := false
var _target_pulse := 0.0
var _is_dying := false

const TARGET_INDICATOR_BASE_SCALE := Vector2(2.4, 2.4)

@onready var player: Node2D = get_node("/root/Game/Player")
@onready var _target_indicator: Sprite2D = %TargetIndicator


func _ready() -> void:
	add_to_group("mobs")
	%HealthBar.max_value = max_health
	%HealthBar.value = health
	%Slime.play_walk()


func set_targeted(active: bool) -> void:
	_is_targeted = active
	_target_indicator.visible = active
	if not active:
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE
		_target_pulse = 0.0


func _process(delta: float) -> void:
	if not _is_targeted:
		return
	_target_pulse += delta * 8.0
	var pulse := 1.0 + sin(_target_pulse) * 0.1
	_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE * pulse


func _physics_process(delta: float) -> void:
	var offset: Vector2 = player.global_position - global_position
	var distance: float = offset.length()

	if distance > attack_distance:
		velocity = offset / distance * speed
	else:
		velocity = Vector2.ZERO

	_apply_mob_separation()
	_process_poison(delta)
	_process_nettles(delta)
	move_and_slide()


func _apply_mob_separation() -> void:
	const SEPARATION_RADIUS := 70.0
	const SEPARATION_FORCE := 4.0

	for mob in get_tree().get_nodes_in_group("mobs"):
		if mob == self:
			continue

		var push: Vector2 = global_position - mob.global_position
		var dist: float = push.length()
		if dist > 0.0 and dist < SEPARATION_RADIUS:
			velocity += push.normalized() * (SEPARATION_RADIUS - dist) * SEPARATION_FORCE

	if velocity.length() > speed:
		velocity = velocity.normalized() * speed


func apply_nettles(duration: float) -> void:
	_nettles_timer = maxf(_nettles_timer, duration)


func has_nettles() -> bool:
	return _nettles_timer > 0.0


func _process_nettles(delta: float) -> void:
	if _nettles_timer > 0.0:
		_nettles_timer = maxf(_nettles_timer - delta, 0.0)


func apply_poison(weapon: WeaponData) -> void:
	_poison_stacks.append({
		"damage_min": weapon.poison_damage_min,
		"damage_max": weapon.poison_damage_max,
		"duration": weapon.poison_duration,
		"tick_interval": 1.0 / weapon.poison_ticks_per_second,
		"tick_timer": 0.0,
	})


func _process_poison(delta: float) -> void:
	var index := _poison_stacks.size() - 1
	while index >= 0:
		var stack: Dictionary = _poison_stacks[index]
		stack["duration"] = stack["duration"] - delta
		stack["tick_timer"] = stack["tick_timer"] - delta

		if stack["tick_timer"] <= 0.0:
			var poison_damage := randi_range(stack["damage_min"], stack["damage_max"])
			if has_nettles():
				poison_damage = int(poison_damage * 1.5)
			_apply_poison_tick(poison_damage)
			stack["tick_timer"] = stack["tick_interval"]

		if stack["duration"] <= 0.0:
			_poison_stacks.remove_at(index)

		index -= 1


func _apply_poison_tick(amount: int) -> void:
	if amount <= 0:
		return

	health -= amount
	%HealthBar.value = maxf(health, 0.0)
	FloatingDamageText.spawn_poison_damage(global_position, amount)

	if health <= 0:
		_request_die()


func take_damage(amount: int) -> void:
	if _is_dying or amount <= 0:
		return

	%Slime.play_hurt()
	health -= amount
	%HealthBar.value = maxf(health, 0.0)
	FloatingDamageText.spawn_enemy_damage(global_position, amount)

	if health <= 0:
		_request_die()


func apply_weapon_damage(amount: int, weapon: WeaponData) -> void:
	if _is_dying or amount <= 0 or not weapon:
		return

	%Slime.play_hurt()
	health -= amount
	%HealthBar.value = maxf(health, 0.0)
	FloatingDamageText.spawn_magic_damage(global_position, amount, weapon.get_element_color())

	if weapon.applies_nettles:
		apply_nettles(weapon.nettles_duration)

	if health <= 0:
		_request_die()


func take_magic_damage(amount: int, weapon: WeaponData) -> void:
	apply_weapon_damage(amount, weapon)


func _request_die() -> void:
	if _is_dying:
		return
	_is_dying = true
	set_targeted(false)
	set_physics_process(false)
	call_deferred("_die")


func _die() -> void:
	if not is_inside_tree():
		return

	var game := get_node_or_null("/root/Game")
	if game and game.has_method("register_kill"):
		game.register_kill()

	var smoke_scene = preload("res://effects/smoke_explosion/smoke_explosion.tscn")
	var smoke = smoke_scene.instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = global_position

	var exp_orb_scene = preload("res://effects/exp_orb/exp_orb.tscn")
	var exp_orb = exp_orb_scene.instantiate()
	get_parent().add_child(exp_orb)
	exp_orb.global_position = global_position

	queue_free()
