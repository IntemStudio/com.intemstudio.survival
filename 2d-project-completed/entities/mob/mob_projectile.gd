extends Area2D

var _player: CharacterBody2D
var _direction := Vector2.RIGHT
var _damage := 0
var _speed := 520.0
var _max_range := 900.0
var _travelled := 0.0
var _hit := false


func pool_reset() -> void:
	_player = null
	_direction = Vector2.RIGHT
	_damage = 0
	_speed = 520.0
	_max_range = 900.0
	_travelled = 0.0
	_hit = false


func pool_on_acquire() -> void:
	pass


# 몹 원거리 탄환: 방향·데미지·사거리 설정 (A안 — mask 1, 플레이어만 피해, 나무는 막힘).
func setup(
	target_player: CharacterBody2D,
	direction: Vector2,
	damage: int,
	speed: float,
	max_range: float,
	tint: Color
) -> void:
	_player = target_player
	_direction = direction.normalized()
	_damage = damage
	_speed = speed
	_max_range = max_range
	_travelled = 0.0
	_hit = false
	rotation = _direction.angle()
	if has_node("Sprite"):
		$Sprite.modulate = tint
		$Sprite.scale = Vector2(0.45, 0.45)


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_travelled += _speed * delta
	if _travelled >= _max_range:
		PoolUtil.release_node(self)


func _on_body_entered(body: Node) -> void:
	if _hit:
		return

	if body is StaticBody2D:
		_hit = true
		call_deferred(&"_return_to_pool")
		return

	if not _player or body != _player:
		return

	_hit = true
	if body.has_method(&"apply_mob_projectile_damage"):
		body.apply_mob_projectile_damage(_damage)
	call_deferred(&"_return_to_pool")


func _return_to_pool() -> void:
	PoolUtil.release_node(self)
