class_name AttackFactory
extends RefCounted

const BULLET_SCENE := preload("res://weapons/core/bullet_2d.tscn")
const MELEE_PROJECTILE_SCENE := preload("res://weapons/melee/melee_projectile.tscn")
const MAGIC_BOLT_SCENE := preload("res://weapons/magic/magic_bolt.tscn")
const KING_BIBLE_ORB_SCENE := preload("res://weapons/magic/king_bible_orb.tscn")
const THROWING_PROJECTILE_SCENE := preload("res://weapons/throwing/throwing_projectile.tscn")
const AREA_DAMAGE_ZONE_SCENE := preload("res://weapons/area/area_damage_zone.tscn")
const POISON_EXPLOSION_SCENE := preload("res://weapons/concoction/poison_explosion.tscn")
const DEATH_BURST_WARNING_SCENE := preload("res://effects/death_burst/death_burst_warning.tscn")
const DEATH_BURST_VISUAL_RADIUS_MULT := 1.35

var _services_node: Node


func _init(services_node: Node) -> void:
	_services_node = services_node


func _get_game() -> Node:
	return _services_node.get_parent()


func _acquire(scene: PackedScene) -> Node:
	var game := _get_game()
	if game == null:
		push_error("AttackFactory: Game parent missing on AttackServices.")
		return null
	var pool := game.get_node_or_null("ObjectPools") as ScenePool
	if pool:
		return pool.acquire(scene, game)
	var node := scene.instantiate()
	game.add_child(node)
	return node


func spawn_bullet(context: AttackContext) -> Area2D:
	if context == null or context.weapon == null:
		return null
	var bullet: Area2D = _acquire(BULLET_SCENE) as Area2D
	if bullet == null:
		return null
	if bullet.has_method(&"setup"):
		bullet.setup(context.weapon, context.spawn_transform, context.rolled_damage)
	else:
		bullet.global_transform = context.spawn_transform
		bullet.set("damage", context.rolled_damage)
	return bullet


func spawn_melee_projectile(
	context: AttackContext,
	spawn_transform: Transform2D,
	projectile_owner: Node2D
) -> Area2D:
	if context == null or context.weapon == null:
		return null
	var projectile: Area2D = _acquire(MELEE_PROJECTILE_SCENE) as Area2D
	if projectile == null:
		return null
	projectile.setup(context.weapon, spawn_transform, projectile_owner)
	return projectile


func spawn_magic_bolt(context: AttackContext) -> Area2D:
	if context == null or context.weapon == null:
		return null
	var bolt: Area2D = _acquire(MAGIC_BOLT_SCENE) as Area2D
	if bolt == null:
		return null
	bolt.setup(context.weapon, context.spawn_transform)
	return bolt


func spawn_orbit_orb(weapon: WeaponData, player: Node2D, initial_angle: float) -> Area2D:
	if weapon == null or player == null:
		return null
	var orb: Area2D = _acquire(KING_BIBLE_ORB_SCENE) as Area2D
	if orb == null:
		return null
	orb.setup(weapon, player, initial_angle)
	return orb


func spawn_throwing_from_gun(
	player: Node2D,
	weapon: WeaponData,
	spawn_position: Vector2,
	aim_position: Vector2,
	shoot_direction: Vector2,
	rolled_damage: int
) -> Node:
	if player == null or weapon == null:
		return null

	var projectile: Node = null
	if weapon.uses_arc_throw and weapon.projectile_scene:
		projectile = _acquire(weapon.projectile_scene)
		if projectile == null:
			return null
		projectile.global_position = spawn_position
		projectile.setup_weapon(player, aim_position, weapon)
	elif weapon.projectile_scene:
		projectile = _acquire(weapon.projectile_scene)
		if projectile == null:
			return null
		projectile.global_position = spawn_position
		if projectile.has_method(&"setup_weapon"):
			projectile.setup_weapon(player, shoot_direction, weapon)
		else:
			projectile.setup(
				player,
				shoot_direction,
				rolled_damage,
				weapon.get_projectile_range() * LoadoutStatApply.get_combat_power_radius_mult(),
				weapon.throw_speed
			)
	else:
		projectile = _acquire(THROWING_PROJECTILE_SCENE)
		if projectile == null:
			return null
		projectile.global_position = spawn_position
		projectile.setup_weapon(player, shoot_direction, weapon)
	return projectile


func spawn_area_circle(
	weapon: WeaponData,
	global_position: Vector2,
	radius: float,
	apply_poison: bool = false
) -> AreaDamageZone:
	if weapon == null:
		return null
	var zone: AreaDamageZone = _acquire(AREA_DAMAGE_ZONE_SCENE) as AreaDamageZone
	if zone == null:
		return null
	zone.global_position = global_position
	zone.setup_circle(weapon, radius, apply_poison)
	return zone


# 몹 일반 사망 시 플레이어 범위 피해 + 짧은 연출
func spawn_mob_death_burst(
	burst_position: Vector2,
	radius: float,
	damage: int,
	on_player_hit: Callable = Callable(),
	neutral_burst: bool = false
) -> void:
	if damage <= 0 or radius <= 0.0:
		return
	var game := _get_game()
	if game:
		var visual: Node2D = POISON_EXPLOSION_SCENE.instantiate() as Node2D
		game.add_child(visual)
		visual.global_position = burst_position
		if visual.has_method(&"setup"):
			visual.setup(radius, DEATH_BURST_VISUAL_RADIUS_MULT)
	if neutral_burst:
		DamageResolver.apply_neutral_burst_in_radius(
			burst_position,
			radius,
			damage,
			on_player_hit
		)
	else:
		DamageResolver.apply_burst_damage_to_player_in_radius(
			burst_position,
			radius,
			damage,
			on_player_hit
		)


# 사망 폭발 — delay 초 후 피해·연출(0 이하면 즉시)
func schedule_mob_death_burst(
	burst_position: Vector2,
	radius: float,
	damage: int,
	delay: float,
	on_player_hit: Callable = Callable(),
	neutral_burst: bool = false
) -> void:
	if damage <= 0 or radius <= 0.0:
		return
	if delay <= 0.0:
		spawn_mob_death_burst(burst_position, radius, damage, on_player_hit, neutral_burst)
		return
	var game := _get_game()
	if game == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			tree.create_timer(delay).timeout.connect(
				func() -> void:
					spawn_mob_death_burst(
						burst_position,
						radius,
						damage,
						on_player_hit,
						neutral_burst
					),
				CONNECT_ONE_SHOT
			)
		return
	var warning: Node2D = DEATH_BURST_WARNING_SCENE.instantiate() as Node2D
	game.add_child(warning)
	warning.global_position = burst_position
	if warning.has_method(&"setup"):
		warning.setup(
			radius,
			delay,
			func() -> void:
				spawn_mob_death_burst(
					burst_position,
					radius,
					damage,
					on_player_hit,
					neutral_burst
				)
		)
	else:
		game.get_tree().create_timer(delay).timeout.connect(
			func() -> void:
				spawn_mob_death_burst(
					burst_position,
					radius,
					damage,
					on_player_hit,
					neutral_burst
				),
			CONNECT_ONE_SHOT
		)
