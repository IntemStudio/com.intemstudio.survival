extends Area2D

var _weapon: WeaponData
var _player: Node2D
var _orbit_radius := 100.0
var _angle := 0.0
var _mob_hit_cooldowns: Dictionary = {}


func pool_reset() -> void:
	_weapon = null
	_player = null
	_orbit_radius = 100.0
	_angle = 0.0
	_mob_hit_cooldowns.clear()


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)
	# ScenePool._activate는 monitoring을 deferred로 켜므로, 첫 _physics_process 전에 동기화
	monitoring = true


func setup(weapon_data: WeaponData, player: Node2D) -> void:
	_weapon = weapon_data
	_player = player
	_orbit_radius = weapon_data.get_orbit_radius()
	_angle = randf() * TAU
	_mob_hit_cooldowns.clear()
	if $Sprite:
		$Sprite.modulate = weapon_data.get_element_color()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or not _weapon:
		PoolUtil.release_node(self)
		return

	_angle += _weapon.orbit_speed * delta
	var orbit_center := GroundShadowFootprint.get_combat_target_center(_player)
	global_position = orbit_center + Vector2.from_angle(_angle) * _orbit_radius
	rotation = _angle + PI * 0.5

	_damage_overlapping_mobs(delta)


# 궤도가 빠르게 지나가도 겹침 프레임에서 피해가 들어가도록 매 physics tick마다 overlap을 확인합니다.
func _damage_overlapping_mobs(delta: float) -> void:
	if not monitoring:
		return
	if is_instance_valid(_player) and _player.has_method("is_auto_attack_enabled"):
		if not _player.is_auto_attack_enabled():
			return

	var hit_interval := 1.0 / LoadoutStatApply.get_effective_attacks_per_second(_weapon)
	for body in get_overlapping_bodies():
		if not is_instance_valid(body) or not body.is_in_group("mobs"):
			continue

		var mob_id: int = body.get_instance_id()
		var remaining: float = float(_mob_hit_cooldowns.get(mob_id, 0.0))
		remaining -= delta
		if remaining > 0.0:
			_mob_hit_cooldowns[mob_id] = remaining
			continue

		var damage := LoadoutStatApply.roll_combat_damage(_weapon)
		if body.has_method("apply_weapon_damage"):
			body.apply_weapon_damage(damage, _weapon)
		elif body.has_method("take_damage"):
			body.take_damage(damage)
		_mob_hit_cooldowns[mob_id] = hit_interval
