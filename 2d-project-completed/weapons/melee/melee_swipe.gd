extends Area2D

const HIT_INTERVAL := 0.07

var _weapon: WeaponData
var _hit_mobs: Dictionary = {}


func setup(weapon_data: WeaponData, direction: Vector2) -> void:
	_weapon = weapon_data
	rotation = direction.angle()

	var shape := $CollisionShape2D.shape as RectangleShape2D
	var reach := weapon_data.get_melee_range() * 0.9
	shape.size = Vector2(reach, 56.0)
	$CollisionShape2D.position = Vector2(reach * 0.5, 0.0)

	var visual: ColorRect = $Visual
	visual.custom_minimum_size = shape.size
	visual.position = $CollisionShape2D.position - shape.size * 0.5

	_pulse_damage()
	if _weapon.hit_count > 1:
		for hit_index in range(1, _weapon.hit_count):
			get_tree().create_timer(HIT_INTERVAL * hit_index).timeout.connect(_pulse_damage)

	var lifetime := 0.1 + HIT_INTERVAL * maxi(_weapon.hit_count - 1, 0)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _pulse_damage() -> void:
	if not is_inside_tree() or not _weapon:
		return

	for body in get_overlapping_bodies():
		if not is_instance_valid(body) or not body.is_in_group("mobs"):
			continue
		if not body.has_method("apply_weapon_damage"):
			continue

		var mob_id: int = body.get_instance_id()
		var hits_done: int = _hit_mobs.get(mob_id, 0)
		if hits_done >= _weapon.hit_count:
			continue

		body.apply_weapon_damage(_weapon.roll_damage(), _weapon)
		_hit_mobs[mob_id] = hits_done + 1
