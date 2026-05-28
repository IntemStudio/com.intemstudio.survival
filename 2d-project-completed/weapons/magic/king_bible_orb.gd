extends Area2D

var _weapon: WeaponData
var _player: Node2D
var _orbit_radius := 100.0
var _angle := 0.0


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func pool_reset() -> void:
	_weapon = null
	_player = null
	_orbit_radius = 100.0
	_angle = 0.0


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)
	# ScenePool._activate는 monitoring을 deferred로 켜므로, 첫 _physics_process 전에 동기화
	monitoring = true


func setup(weapon_data: WeaponData, player: Node2D, initial_angle := -1.0) -> void:
	_weapon = weapon_data
	_player = player
	_orbit_radius = weapon_data.get_orbit_radius() * LoadoutStatApply.get_combat_power_radius_mult()
	_angle = initial_angle if initial_angle >= 0.0 else randf() * TAU
	if $Sprite:
		$Sprite.modulate = weapon_data.get_element_color()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player) or not _weapon:
		PoolUtil.release_node(self)
		return

	_angle += _weapon.orbit_speed * _delta
	var orbit_center := GroundShadowFootprint.get_combat_target_center(_player)
	global_position = orbit_center + Vector2.from_angle(_angle) * _orbit_radius
	rotation = _angle + PI * 0.5


func _on_body_entered(body: Node2D) -> void:
	if not monitoring or not _weapon:
		return
	if is_instance_valid(_player) and _player.has_method("is_auto_attack_enabled"):
		if not _player.is_auto_attack_enabled():
			return
	if not is_instance_valid(body) or not body.is_in_group("mobs"):
		return

	var damage := LoadoutStatApply.roll_combat_damage(_weapon)
	DamageResolver.apply_weapon_to_mob(body, damage, _weapon)
