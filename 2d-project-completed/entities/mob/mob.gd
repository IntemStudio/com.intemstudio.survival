extends CharacterBody2D
class_name Mob

signal died

@export var attack_distance := 85.0
@export var base_max_health := 200
@export var mob_kind: StringName = &"basic"
@export var speed_min := 160.0
@export var speed_max := 240.0
@export var slime_tint := Color(1.0, 1.0, 1.0, 1.0)
@export var ranged_attack_enabled := false
@export var ranged_cooldown := 1.4
@export var ranged_damage_min := 6
@export var ranged_damage_max := 10
@export var ranged_projectile_speed := 520.0
@export var ranged_max_distance := 900.0
@export var ranged_spawn_offset := Vector2(0, -40)
@export var ranged_telegraph_delay := 0.5
@export var ranged_attack_mark_offset := Vector2(0, -72)

var speed := 200.0
var max_health := base_max_health
var health := base_max_health

var _poison_stacks: Array[Dictionary] = []
var _nettles_timer := 0.0
var _is_targeted := false
var _target_pulse := 0.0
var _is_dying := false
var _ranged_cooldown_remaining := 0.0
var _ranged_windup_active := false
var _pending_ranged_direction := Vector2.RIGHT
var _active_attack_mark: Node2D = null

const TARGET_INDICATOR_BASE_SCALE := Vector2(2.4, 2.4)
const EXP_ORB_SCENE := preload("res://effects/exp_orb/exp_orb.tscn")
const MOB_PROJECTILE_SCENE := preload("res://entities/mob/mob_projectile.tscn")
const MOB_ATTACK_MARK_SCENE := preload("res://entities/mob/mob_attack_mark.tscn")
const MOB_COLLISION_LAYER := 2
const MOB_COLLISION_MASK := 3

@onready var player: Node2D = get_node("/root/Game/Player")
@onready var _target_indicator: Sprite2D = %TargetIndicator
@onready var _attack_range_ring: Sprite2D = get_node_or_null("AttackRangeRing")


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
	_ranged_cooldown_remaining = 0.0
	_cancel_ranged_telegraph()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if is_node_ready():
		_target_indicator.visible = false
		_target_indicator.scale = TARGET_INDICATOR_BASE_SCALE
		_set_attack_range_ring_visible(false)


func pool_on_acquire() -> void:
	collision_layer = MOB_COLLISION_LAYER
	collision_mask = MOB_COLLISION_MASK
	speed = randf_range(speed_min, speed_max)
	add_to_group("mobs")
	%Slime.modulate = slime_tint
	%Slime.play_walk()
	if ranged_attack_enabled:
		_ranged_cooldown_remaining = randf_range(0.0, ranged_cooldown * 0.5)
		_sync_attack_range_ring()
	else:
		_set_attack_range_ring_visible(false)
	set_physics_process(true)


func _sync_health_bar() -> void:
	if not is_node_ready():
		return
	%HealthBar.max_value = max_health
	%HealthBar.value = health


# 원거리 몹 전용 AttackRangeRing — attack_distance(중심 간 거리) 반경으로 맞춥니다.
func _sync_attack_range_ring() -> void:
	if not _attack_range_ring:
		return
	var tex := _attack_range_ring.texture
	if not tex:
		_set_attack_range_ring_visible(false)
		return
	var tex_radius := maxf(tex.get_width(), tex.get_height()) * 0.5
	if tex_radius <= 0.0:
		return
	var ring_scale := attack_distance / tex_radius
	_attack_range_ring.scale = Vector2(ring_scale, ring_scale)
	_set_attack_range_ring_visible(true)


func _set_attack_range_ring_visible(visible_state: bool) -> void:
	if _attack_range_ring:
		_attack_range_ring.visible = visible_state


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
	if ranged_attack_enabled and _ranged_cooldown_remaining > 0.0:
		_ranged_cooldown_remaining = maxf(_ranged_cooldown_remaining - delta, 0.0)

	var offset: Vector2 = player.global_position - global_position
	var distance: float = offset.length()

	if distance > attack_distance:
		velocity = offset / distance * speed
	else:
		velocity = Vector2.ZERO
		if (
			ranged_attack_enabled
			and not _ranged_windup_active
			and _ranged_cooldown_remaining <= 0.0
			and offset.length_squared() > 0.01
		):
			_begin_ranged_telegraph(offset)

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


# 사거리 안에서 공격 마크를 띄운 뒤 ranged_telegraph_delay 후 탄환을 쏩니다.
func _begin_ranged_telegraph(offset: Vector2) -> void:
	if _ranged_windup_active:
		return

	_ranged_windup_active = true
	_pending_ranged_direction = offset.normalized()
	_spawn_attack_mark()

	var tree := get_tree()
	if not tree:
		_complete_ranged_telegraph()
		return

	var timer := tree.create_timer(ranged_telegraph_delay)
	timer.timeout.connect(_on_ranged_telegraph_timeout, CONNECT_ONE_SHOT)


func _on_ranged_telegraph_timeout() -> void:
	if not _ranged_windup_active or _is_dying or not is_inside_tree():
		_cancel_ranged_telegraph()
		return
	_complete_ranged_telegraph()


func _complete_ranged_telegraph() -> void:
	_release_attack_mark()
	_ranged_windup_active = false
	_fire_ranged_projectile(_pending_ranged_direction)


func _cancel_ranged_telegraph() -> void:
	_ranged_windup_active = false
	_release_attack_mark()


func _spawn_attack_mark() -> void:
	_release_attack_mark()

	var game := get_node_or_null("/root/Game")
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	if pool and pool.has_method(&"acquire"):
		_active_attack_mark = pool.acquire(MOB_ATTACK_MARK_SCENE, self) as Node2D
	else:
		_active_attack_mark = MOB_ATTACK_MARK_SCENE.instantiate()
		add_child(_active_attack_mark)

	if _active_attack_mark.has_method(&"setup"):
		_active_attack_mark.setup(ranged_attack_mark_offset, slime_tint)


func _release_attack_mark() -> void:
	if is_instance_valid(_active_attack_mark):
		PoolUtil.release_node(_active_attack_mark)
	_active_attack_mark = null


# 풀링 탄환을 발사합니다(예고 종료 후 호출).
func _fire_ranged_projectile(offset: Vector2) -> void:
	var direction := offset.normalized()
	var damage := randi_range(ranged_damage_min, ranged_damage_max)
	var spawn_pos := global_position + ranged_spawn_offset

	var game := get_node_or_null("/root/Game")
	var spawn_parent := get_parent()
	var pool: Node = game.get_node_or_null("ObjectPools") if game else null
	var projectile: Node2D
	if pool and pool.has_method(&"acquire"):
		projectile = pool.acquire(MOB_PROJECTILE_SCENE, spawn_parent) as Node2D
	else:
		projectile = MOB_PROJECTILE_SCENE.instantiate()
		spawn_parent.add_child(projectile)

	projectile.global_position = spawn_pos
	if projectile.has_method(&"setup"):
		projectile.setup(
			player as CharacterBody2D,
			direction,
			damage,
			ranged_projectile_speed,
			ranged_max_distance,
			slime_tint
		)

	_ranged_cooldown_remaining = ranged_cooldown


func apply_nettles(duration: float) -> void:
	_nettles_timer = maxf(_nettles_timer, duration)


func has_nettles() -> bool:
	return _nettles_timer > 0.0


func _process_nettles(delta: float) -> void:
	if _nettles_timer > 0.0:
		_nettles_timer = maxf(_nettles_timer - delta, 0.0)


func apply_poison(weapon: WeaponData) -> void:
	_poison_stacks.append({
		"weapon": weapon,
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
			var poison_weapon: WeaponData = stack.get("weapon")
			_apply_poison_tick(poison_damage, poison_weapon)
			stack["tick_timer"] = stack["tick_interval"]

		if stack["duration"] <= 0.0:
			_poison_stacks.remove_at(index)

		index -= 1


func _apply_poison_tick(amount: int, weapon: WeaponData = null) -> void:
	if amount <= 0:
		return

	_register_weapon_damage(weapon, amount)
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

	_register_weapon_damage(weapon, amount)
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


func _register_weapon_damage(weapon: WeaponData, amount: int) -> void:
	if amount <= 0 or weapon == null:
		return
	var game := get_node_or_null("/root/Game")
	if game and game.has_method(&"register_weapon_damage"):
		game.register_weapon_damage(weapon, amount)


func _request_die() -> void:
	if _is_dying:
		return
	_cancel_ranged_telegraph()
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
