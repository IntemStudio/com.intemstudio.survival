extends CharacterBody2D
class_name Mob

signal died

@export var attack_distance := 85.0
@export var base_max_health := 200
@export var mob_kind: StringName = &"basic"
@export var speed_min := 160.0
@export var speed_max := 240.0
@export var slime_tint := Color(1.0, 1.0, 1.0, 1.0)

var speed := 200.0
var max_health := base_max_health
var health := base_max_health

var _poison_stacks: Array[Dictionary] = []
var _nettles_timer := 0.0
var _is_targeted := false
var _target_pulse := 0.0
var _is_dying := false

const TARGET_INDICATOR_BASE_SCALE := Vector2(2.4, 2.4)
const EXP_ORB_SCENE := preload("res://effects/exp_orb/exp_orb.tscn")
const MOB_COLLISION_LAYER := 2
const MOB_COLLISION_MASK := 3

@onready var player: Node2D = get_node("/root/Game/Player")
@onready var _target_indicator: Sprite2D = %TargetIndicator


# 스폰 직전 Game에서 호출해 밸런스 HP 배수를 반영합니다.
func initialize_spawn_health(hp_multiplier: float) -> void:
	var scaled := maxi(1, roundi(base_max_health * maxf(hp_multiplier, 0.01)))
	max_health = scaled
	health = scaled
	_sync_health_bar()


func pool_reset() -> void:
	if is_in_group("mobs"):
		remove_from_group("mobs")
	_poison_stacks.clear()
	_nettles_timer = 0.0
	_is_dying = false
	_is_targeted = false
	_target_pulse = 0.0
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if is_node_ready():
		_target_indicator.visible = false
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE


func pool_on_acquire() -> void:
	collision_layer = MOB_COLLISION_LAYER
	collision_mask = MOB_COLLISION_MASK
	speed = randf_range(speed_min, speed_max)
	add_to_group("mobs")
	%Slime.modulate = slime_tint
	%Slime.play_walk()
	set_physics_process(true)


func _sync_health_bar() -> void:
	if not is_node_ready():
		return
	%HealthBar.max_value = max_health
	%HealthBar.value = health


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

	var spawn_parent := get_parent()
	var exp_orb: Node2D
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	if pool and pool.has_method(&"acquire"):
		exp_orb = pool.acquire(EXP_ORB_SCENE, spawn_parent) as Node2D
	else:
		exp_orb = EXP_ORB_SCENE.instantiate()
		spawn_parent.add_child(exp_orb)
	exp_orb.global_position = global_position

	const MAGNET_DROP_CHANCE := 0.01
	if randf() < MAGNET_DROP_CHANCE:
		var magnet_scene = preload("res://effects/magnet_pickup/magnet_pickup.tscn")
		var magnet = magnet_scene.instantiate()
		get_parent().add_child(magnet)
		magnet.global_position = global_position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))

	const HEALTH_DROP_CHANCE := 0.01
	if randf() < HEALTH_DROP_CHANCE:
		var health_scene = preload("res://effects/health_pickup/health_pickup.tscn")
		var health_pickup = health_scene.instantiate()
		get_parent().add_child(health_pickup)
		health_pickup.global_position = global_position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))

	PoolUtil.release_node(self)
