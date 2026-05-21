extends CharacterBody2D

signal health_depleted
signal leveled_up(new_level: int)

const GUN_SCENE := preload("res://weapons/core/gun.tscn")

@export var pickup_range := 150.0
@export var base_exp_to_level := 5
const DAMAGE_FLOAT_INTERVAL := 0.2

var health = 100.0
var level := 1
var experience := 0
var _owned_weapons: Array[WeaponData] = []
var _damage_float_accumulator := 0.0
var _damage_float_timer := 0.0


func _ready() -> void:
	var pickup_shape := %PickupRange.get_node("CollisionShape2D").shape as CircleShape2D
	pickup_shape.radius = pickup_range
	%PickupRange.area_entered.connect(_on_pickup_range_area_entered)
	_update_experience_hud()


func get_owned_weapons() -> Array[WeaponData]:
	return _owned_weapons.duplicate()


func has_weapon(weapon_data: WeaponData) -> bool:
	var key := weapon_data.get_unique_key()
	for owned in _owned_weapons:
		if owned.get_unique_key() == key:
			return true
	return false


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


# 체력 회복 아이템 등에서 호출합니다.
func heal_health(amount: float) -> void:
	var max_hp := %HealthBar.max_value
	health = minf(health + amount, max_hp)
	%HealthBar.value = health


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


func _on_pickup_range_area_entered(area: Area2D) -> void:
	if area.has_method("collect"):
		area.collect(self)
	elif area.has_method("start_magnet"):
		area.start_magnet(self)


func _physics_process(delta):
	const SPEED = 600.0
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()
	
	# Taking damage
	const DAMAGE_RATE = 6.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		var damage_this_frame: float = DAMAGE_RATE * overlapping_mobs.size() * delta
		health -= damage_this_frame
		%HealthBar.value = health
		_damage_float_accumulator += damage_this_frame
		if health <= 0.0:
			health_depleted.emit()

	_damage_float_timer -= delta
	if _damage_float_accumulator > 0.0 and _damage_float_timer <= 0.0:
		FloatingDamageText.spawn_player_damage(
			global_position,
			maxi(int(_damage_float_accumulator), 1)
		)
		_damage_float_accumulator = 0.0
		_damage_float_timer = DAMAGE_FLOAT_INTERVAL
