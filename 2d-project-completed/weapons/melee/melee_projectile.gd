extends Area2D

const REPEAT_HIT_INTERVAL := 0.07
const RETURN_ARRIVE_DISTANCE := 36.0
const CURVED_RETURN_WIDTH_RATIO := 0.45
const DECELERATE_DRAG := 6.0
const DECELERATE_RELEASE_SPEED := 12.0
const DECELERATE_RELEASE_DELAY_RANGE := Vector2(0.5, 0.75)
const DEFAULT_COLLISION_RADIUS := 12.0
const CLUB_WEAPON_ID := "club"
const CLUB_COLLISION_SIZE := Vector2(84.0, 32.0)
const CLUB_COLLISION_OFFSET := Vector2(28.0, 0.0)
const BULLET_SPRITE_SCALE := Vector2.ONE
const BULLET_SPRITE_OFFSET := Vector2(-11.0, -1.0)
const CLUB_SPRITE_SCALE := Vector2(2.8, 1.35)
const CLUB_SPRITE_OFFSET := Vector2(8.0, -1.0)

var _weapon: WeaponData
var _owner: Node2D
var _direction := Vector2.RIGHT
var _origin_position := Vector2.ZERO
var _curve_perpendicular := Vector2.DOWN
var _travelled := 0.0
var _current_speed := 0.0
var _decelerate_release_delay := -1.0
var _returning := false
var _setup_generation := 0
var _mob_hit_chains_started: Dictionary = {}
var _distinct_mob_hits := 0


func pool_reset() -> void:
	_setup_generation += 1
	_weapon = null
	_owner = null
	_direction = Vector2.RIGHT
	_origin_position = Vector2.ZERO
	_curve_perpendicular = Vector2.DOWN
	_travelled = 0.0
	_current_speed = 0.0
	_decelerate_release_delay = -1.0
	_returning = false
	_mob_hit_chains_started.clear()
	_distinct_mob_hits = 0


func pool_on_acquire() -> void:
	PhysicsLayers.apply_player_projectile(self)


func setup(weapon_data: WeaponData, spawn_transform: Transform2D, projectile_owner: Node2D = null) -> void:
	if not WeaponData.is_valid_projectile_pierce_count(weapon_data.projectile_pierce_count):
		push_error(
			"MeleeProjectile: projectile_pierce_count가 0입니다 (무기=%s)." % weapon_data.get_unique_key()
		)
		PoolUtil.release_node(self)
		return

	_setup_generation += 1
	_weapon = weapon_data
	_owner = projectile_owner
	global_transform = spawn_transform
	_direction = Vector2.RIGHT.rotated(rotation)
	_origin_position = global_position
	_curve_perpendicular = _direction.orthogonal()
	_travelled = 0.0
	_current_speed = weapon_data.get_melee_projectile_speed()
	_decelerate_release_delay = -1.0
	_returning = false
	_mob_hit_chains_started.clear()
	_distinct_mob_hits = 0

	_apply_visual_tint(weapon_data)
	_apply_projectile_shape(weapon_data)


func _physics_process(delta: float) -> void:
	if not _weapon:
		PoolUtil.release_node(self)
		return
	if _weapon.should_projectile_return() and not is_instance_valid(_owner):
		PoolUtil.release_node(self)
		return

	var speed := _weapon.get_melee_projectile_speed()
	var max_range := _weapon.get_melee_range() * LoadoutStatApply.get_combat_power_radius_mult()
	if _weapon.should_projectile_decelerate():
		_move_decelerating(delta)
		return
	if _weapon.should_projectile_curve_return():
		_move_curved_return(delta, speed, max_range)
		return

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


func _move_curved_return(delta: float, speed: float, max_range: float) -> void:
	var previous_position := global_position
	var outbound_end := _origin_position + _direction * max_range
	var curve_width := max_range * CURVED_RETURN_WIDTH_RATIO

	_travelled += speed * delta
	if _travelled >= max_range and not _returning:
		_returning = true
		_mob_hit_chains_started.clear()
		_distinct_mob_hits = 0

	if _returning:
		var return_t := clampf((_travelled - max_range) / max_range, 0.0, 1.0)
		var return_target := _owner.global_position
		var base_position := outbound_end.lerp(return_target, return_t)
		var curve_offset := -sin(return_t * PI) * curve_width
		global_position = base_position + _curve_perpendicular * curve_offset
		if return_t >= 1.0 or global_position.distance_to(return_target) < RETURN_ARRIVE_DISTANCE:
			PoolUtil.release_node(self)
			return
	else:
		var outbound_t := clampf(_travelled / max_range, 0.0, 1.0)
		var base_position := _origin_position.lerp(outbound_end, outbound_t)
		var curve_offset := sin(outbound_t * PI) * curve_width
		global_position = base_position + _curve_perpendicular * curve_offset

	var move_delta := global_position - previous_position
	if move_delta.length_squared() > 0.001:
		rotation = move_delta.angle()


func _move_decelerating(delta: float) -> void:
	if _decelerate_release_delay >= 0.0:
		_decelerate_release_delay -= delta
		if _decelerate_release_delay <= 0.0:
			PoolUtil.release_node(self)
		return

	var previous_position := global_position
	_current_speed = maxf(0.0, _current_speed * exp(-DECELERATE_DRAG * delta))
	global_position += _direction * _current_speed * delta

	var move_delta := global_position - previous_position
	if move_delta.length_squared() > 0.001:
		rotation = move_delta.angle()

	if _current_speed <= DECELERATE_RELEASE_SPEED:
		_decelerate_release_delay = randf_range(
			DECELERATE_RELEASE_DELAY_RANGE.x,
			DECELERATE_RELEASE_DELAY_RANGE.y
		)


func _on_body_entered(body: Node2D) -> void:
	if not _weapon or body == _owner:
		return
	if _is_environment_body(body):
		PoolUtil.release_node(self)
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


func _is_environment_body(body: Node) -> bool:
	return body is CollisionObject2D and PhysicsLayers.layer_matches(
		(body as CollisionObject2D).collision_layer,
		PhysicsLayers.ENVIRONMENT
	)


# bullet_2d와 동일한 총알 스프라이트에 무기 색을 입힙니다.
func _apply_visual_tint(weapon_data: WeaponData) -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if not sprite:
		return
	var base_color := weapon_data.get_element_color()
	if weapon_data.damage_element.is_empty():
		base_color = weapon_data.sprite_modulate
	sprite.modulate = base_color
	if _is_club_weapon(weapon_data):
		sprite.scale = CLUB_SPRITE_SCALE * weapon_data.get_projectile_scale()
		sprite.position = CLUB_SPRITE_OFFSET * weapon_data.get_projectile_scale()
	else:
		sprite.scale = BULLET_SPRITE_SCALE * weapon_data.get_projectile_scale()
		sprite.position = BULLET_SPRITE_OFFSET * weapon_data.get_projectile_scale()


# 곤봉은 보이는 타격 면적과 실제 충돌 판정을 같은 사각형으로 맞춥니다.
func _apply_projectile_shape(weapon_data: WeaponData) -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision:
		return
	if _is_club_weapon(weapon_data):
		ProjectileVisualUtil.apply_rect_collision(
			self,
			weapon_data,
			CLUB_COLLISION_SIZE,
			CLUB_COLLISION_OFFSET
		)
		return

	var mult := weapon_data.get_projectile_scale()
	var circle := CircleShape2D.new()
	circle.radius = DEFAULT_COLLISION_RADIUS * mult
	collision.shape = circle
	collision.position = Vector2.ZERO


func _is_club_weapon(weapon_data: WeaponData) -> bool:
	return weapon_data and weapon_data.get_unique_key() == CLUB_WEAPON_ID


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
	var damage := _roll_weapon_damage()
	DamageResolver.apply_weapon_to_mob(body, damage, _weapon)


func _roll_weapon_damage() -> int:
	if is_instance_valid(_owner) and _owner.has_method("roll_weapon_damage"):
		return _owner.roll_weapon_damage(_weapon)
	return _weapon.compute_damage_from_attack(LoadoutStatApply.FALLBACK_ATTACK_POWER)
