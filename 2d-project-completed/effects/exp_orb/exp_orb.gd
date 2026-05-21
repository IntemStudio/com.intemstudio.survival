extends Area2D

@export var experience_value := 1
@export var collect_distance := 24.0

const MAGNET_SPEED := 450.0
const MAGNET_ACCEL_DURATION := 2.0
const MAGNET_MAX_MULTIPLIER := 2.0

var _magnet_target: Node2D = null
var _magnet_time := 0.0


func pool_reset() -> void:
	if is_in_group("exp_orbs"):
		remove_from_group("exp_orbs")
	_magnet_target = null
	_magnet_time = 0.0


func pool_on_acquire() -> void:
	add_to_group("exp_orbs")
	call_deferred(&"_try_auto_magnet")


func _try_auto_magnet() -> void:
	if not is_inside_tree() or not get_meta(&"_pooled_active", false):
		return
	var player := get_node_or_null("/root/Game/Player")
	if player and global_position.distance_to(player.global_position) <= player.pickup_range:
		start_magnet(player)


func start_magnet(target: Node2D) -> void:
	if _magnet_target:
		return
	_magnet_target = target
	_magnet_time = 0.0


func _get_magnet_speed_multiplier() -> float:
	if _magnet_time >= MAGNET_ACCEL_DURATION:
		return MAGNET_MAX_MULTIPLIER
	return lerpf(1.0, MAGNET_MAX_MULTIPLIER, _magnet_time / MAGNET_ACCEL_DURATION)


func _physics_process(delta: float) -> void:
	if not _magnet_target:
		return

	_magnet_time += delta
	var speed := MAGNET_SPEED * _get_magnet_speed_multiplier()
	var direction := global_position.direction_to(_magnet_target.global_position)
	global_position += direction * speed * delta

	if global_position.distance_to(_magnet_target.global_position) < collect_distance:
		if _magnet_target.has_method("gain_experience"):
			_magnet_target.gain_experience(experience_value)
		PoolUtil.release_node(self)
