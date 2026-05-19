extends Area2D

const ORBIT_SPEED := 2.8

var _weapon: WeaponData
var _player: Node2D
var _orbit_radius := 100.0
var _angle := 0.0
var _attack_timer := 0.0


func setup(weapon_data: WeaponData, player: Node2D) -> void:
	_weapon = weapon_data
	_player = player
	_orbit_radius = weapon_data.get_melee_range() + 30.0
	_angle = randf() * TAU
	_attack_timer = 0.0
	if $Sprite:
		$Sprite.modulate = weapon_data.get_element_color()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or not _weapon:
		queue_free()
		return

	_angle += ORBIT_SPEED * delta
	global_position = _player.global_position + Vector2.from_angle(_angle) * _orbit_radius
	rotation = _angle + PI * 0.5

	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_attack_timer = 1.0 / _weapon.attacks_per_second
	_damage_overlapping_mobs()


func _damage_overlapping_mobs() -> void:
	for body in get_overlapping_bodies():
		if not body.is_in_group("mobs"):
			continue
		var damage := _weapon.roll_damage()
		if body.has_method("apply_weapon_damage"):
			body.apply_weapon_damage(damage, _weapon)
		elif body.has_method("take_damage"):
			body.take_damage(damage)
