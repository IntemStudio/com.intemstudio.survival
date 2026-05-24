extends Area2D

const REPEAT_HIT_INTERVAL := 0.07
const RETURN_ARRIVE_DISTANCE := 36.0

var _weapon: WeaponData
var _owner: Node2D
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _returning := false
var _setup_generation := 0
var _mob_hit_chains_started: Dictionary = {}
var _distinct_mob_hits := 0


func pool_reset() -> void:
	_setup_generation += 1
	_weapon = null
	_owner = null
	_direction = Vector2.RIGHT
	_travelled = 0.0
	_returning = false
	_mob_hit_chains_started.clear()
	_distinct_mob_hits = 0


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)


func setup(weapon_data: WeaponData, spawn_transform: Transform2D, owner: Node2D = null) -> void:
	if not WeaponData.is_valid_projectile_pierce_count(weapon_data.projectile_pierce_count):
		push_error(
			"MeleeProjectile: projectile_pierce_count가 0입니다 (무기=%s)." % weapon_data.get_unique_key()
		)
		PoolUtil.release_node(self)
		return

	_setup_generation += 1
	_weapon = weapon_data
	_owner = owner
	global_transform = spawn_transform
	_direction = Vector2.RIGHT.rotated(rotation)
	_travelled = 0.0
	_returning = false
	_mob_hit_chains_started.clear()
	_distinct_mob_hits = 0

	if $Sprite2D:
		$Sprite2D.modulate = weapon_data.get_element_color()
		$Sprite2D.scale = Vector2(0.65, 0.65)


func _physics_process(delta: float) -> void:
	if not _weapon:
		PoolUtil.release_node(self)
		return
	if _weapon.should_projectile_return() and not is_instance_valid(_owner):
		PoolUtil.release_node(self)
		return

	var speed := _weapon.get_melee_projectile_speed()
	var max_range := _weapon.get_melee_range()
	var move_dir: Vector2

	if _returning:
		move_dir = global_position.direction_to(_owner.global_position)
		if global_position.distance_to(_owner.global_position) < RETURN_ARRIVE_DISTANCE:
			PoolUtil.release_node(self)
			return
	else:
		move_dir = _direction
		_travelled += speed * delta
		if _travelled >= max_range:
			if _weapon.should_projectile_return():
				_returning = true
				_mob_hit_chains_started.clear()
				_distinct_mob_hits = 0
			else:
				PoolUtil.release_node(self)
				return

	global_position += move_dir * speed * delta
	rotation = move_dir.angle()


func _on_body_entered(body: Node2D) -> void:
	if not _weapon or body == _owner:
		return
	if not body.is_in_group("mobs"):
		return

	var mob_id: int = body.get_instance_id()
	if _mob_hit_chains_started.get(mob_id, false):
		return
	_mob_hit_chains_started[mob_id] = true
	_distinct_mob_hits += 1

	var generation := _setup_generation
	for hit_index in range(_weapon.hit_count):
		if hit_index == 0:
			if is_instance_valid(body):
				_deal_damage(body)
		else:
			get_tree().create_timer(REPEAT_HIT_INTERVAL * hit_index).timeout.connect(
				_on_scheduled_hit.bind(generation, mob_id)
			)

	if _is_pierce_limit_reached():
		PoolUtil.release_node(self)


func _is_pierce_limit_reached() -> bool:
	if not _weapon or _weapon.has_unlimited_projectile_pierce():
		return false
	return _distinct_mob_hits >= _weapon.get_projectile_pierce_count_safe()


func _on_scheduled_hit(generation: int, mob_id: int) -> void:
	if generation != _setup_generation or not _weapon:
		return

	var body: Node = instance_from_id(mob_id)
	if not is_instance_valid(body) or not body.is_in_group("mobs"):
		return
	_deal_damage(body)


func _deal_damage(body: Node) -> void:
	if not _weapon:
		return
	var damage := _weapon.roll_damage()
	if body.has_method("apply_weapon_damage"):
		body.apply_weapon_damage(damage, _weapon)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
