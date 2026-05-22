extends Area2D

const REPEAT_HIT_INTERVAL := 0.07

var _weapon: WeaponData
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _setup_generation := 0
var _mob_hit_chains_started: Dictionary = {}


func pool_reset() -> void:
	_setup_generation += 1
	_weapon = null
	_direction = Vector2.RIGHT
	_travelled = 0.0
	_mob_hit_chains_started.clear()


func pool_on_acquire() -> void:
	pass


func setup(weapon_data: WeaponData, spawn_transform: Transform2D) -> void:
	_setup_generation += 1
	_weapon = weapon_data
	global_transform = spawn_transform
	_direction = Vector2.RIGHT.rotated(rotation)
	_travelled = 0.0
	_mob_hit_chains_started.clear()

	if $Sprite2D:
		$Sprite2D.modulate = weapon_data.get_element_color()
		$Sprite2D.scale = Vector2(0.65, 0.65)


func _physics_process(delta: float) -> void:
	if not _weapon:
		PoolUtil.release_node(self)
		return

	var speed := _weapon.get_melee_projectile_speed()
	var max_range := _weapon.get_melee_range()
	global_position += _direction * speed * delta
	_travelled += speed * delta
	if _travelled >= max_range:
		PoolUtil.release_node(self)


func _on_body_entered(body: Node2D) -> void:
	if not _weapon or not body.is_in_group("mobs"):
		return

	var mob_id: int = body.get_instance_id()
	if _mob_hit_chains_started.get(mob_id, false):
		return
	_mob_hit_chains_started[mob_id] = true

	var generation := _setup_generation
	for hit_index in range(_weapon.hit_count):
		if hit_index == 0:
			if is_instance_valid(body):
				_deal_damage(body)
		else:
			get_tree().create_timer(REPEAT_HIT_INTERVAL * hit_index).timeout.connect(
				_on_scheduled_hit.bind(generation, mob_id)
			)


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
