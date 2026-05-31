class_name MobChaseSkillJump
extends MobChaseSkill

## 점프 추격 — windup(느낌표) 후 발밑 중심 lerp 이동, 완료 context에 착지 burst 스냅샷.

const MOB_ATTACK_MARK_SCENE := preload("res://entities/mob/mob_attack_mark.tscn")

var windup_delay := 0.4
var travel_distance := 140.0
var duration := 0.28
var cooldown := 1.6
var landing_burst_radius := 68.0
var landing_burst_damage := 10
var arc_height := 48.0

var _mob_ref: Mob = null
var _windup_remaining := 0.0
var _move_elapsed := 0.0
var _start_footprint := Vector2.ZERO
var _end_footprint := Vector2.ZERO
var _landing_direction := Vector2.RIGHT
var _foot_to_body_offset := Vector2.ZERO
var _active_mark: Node2D = null
var _slime_base_position := Vector2.ZERO
var _slime_arc_active := false


func reset() -> void:
	_restore_arc_visual(_mob_ref)
	_release_windup_mark()
	_mob_ref = null
	_windup_remaining = 0.0
	_move_elapsed = 0.0
	_start_footprint = Vector2.ZERO
	_end_footprint = Vector2.ZERO
	_landing_direction = Vector2.RIGHT
	_foot_to_body_offset = Vector2.ZERO
	_slime_base_position = Vector2.ZERO
	_slime_arc_active = false
	super.reset()


func begin(mob: Mob, target_offset: Vector2) -> void:
	reset()
	if mob == null:
		return
	_mob_ref = mob
	_foot_to_body_offset = mob.global_position - mob.get_footprint_global_center()
	_start_footprint = mob.get_footprint_global_center()
	var direction := Vector2.RIGHT
	if target_offset.length_squared() > 0.01:
		direction = target_offset.normalized()
	_landing_direction = direction
	_end_footprint = _start_footprint + direction * maxf(travel_distance, 0.0)
	_windup_remaining = maxf(windup_delay, 0.0)
	if _windup_remaining > 0.0:
		_phase = Phase.WINDUP
		_spawn_windup_mark(mob)
	else:
		_begin_move(mob)


func tick(mob: Mob, delta: float) -> MobChaseSkillContext:
	if not is_active() or mob == null:
		return null
	_mob_ref = mob
	if _phase == Phase.WINDUP:
		mob.velocity = Vector2.ZERO
		_windup_remaining -= delta
		if _windup_remaining > 0.0:
			return null
		_windup_remaining = 0.0
		_release_windup_mark()
		_begin_move(mob)
		return null
	if _phase == Phase.MOVING:
		mob.velocity = Vector2.ZERO
		_move_elapsed += delta
		var progress: float = clampf(_move_elapsed / maxf(duration, 0.001), 0.0, 1.0)
		_apply_move_position(mob, progress)
		_apply_arc_visual(mob, progress)
		if progress < 1.0:
			return null
		var context: MobChaseSkillContext = complete(mob)
		reset()
		return context
	return null


func complete(mob: Mob) -> MobChaseSkillContext:
	_restore_arc_visual(mob)
	_release_windup_mark()
	var context := MobChaseSkillContext.new()
	context.mob = mob
	context.landing_position = _end_footprint
	context.landing_direction = _landing_direction
	context.landing_burst_radius = landing_burst_radius
	context.landing_burst_damage = landing_burst_damage
	return context


func get_cooldown() -> float:
	return maxf(cooldown, 0.0)


func get_landing_footprint_global() -> Vector2:
	return _end_footprint


func get_landing_burst_radius() -> float:
	return landing_burst_radius


func _begin_move(mob: Mob) -> void:
	_phase = Phase.MOVING
	_move_elapsed = 0.0
	var slime := _get_slime_node(mob)
	if slime != null:
		_slime_base_position = slime.position
		_slime_arc_active = true


func _apply_move_position(mob: Mob, progress: float) -> void:
	var foot_center := _start_footprint.lerp(_end_footprint, progress)
	mob.global_position = foot_center + _foot_to_body_offset


func _apply_arc_visual(mob: Mob, progress: float) -> void:
	if not _slime_arc_active:
		return
	var slime := _get_slime_node(mob)
	if slime == null:
		return
	var arc_offset_y: float = -arc_height * sin(progress * PI)
	slime.position = _slime_base_position + Vector2(0.0, arc_offset_y)


func _restore_arc_visual(mob: Mob) -> void:
	if not _slime_arc_active or mob == null or not is_instance_valid(mob):
		return
	var slime := _get_slime_node(mob)
	if slime != null:
		slime.position = _slime_base_position
	_slime_arc_active = false


func _get_slime_node(mob: Mob) -> Node2D:
	if mob == null or not mob.is_node_ready():
		return null
	return mob.get_node_or_null("%Slime") as Node2D


func _spawn_windup_mark(mob: Mob) -> void:
	_release_windup_mark()
	if mob == null or not mob.is_inside_tree():
		return
	var mark_offset: Vector2 = mob.ranged_attack_mark_offset
	var tint: Color = mob.slime_tint
	var pool := _get_object_pools(mob)
	if pool != null and pool.has_method(&"acquire"):
		_active_mark = pool.acquire(MOB_ATTACK_MARK_SCENE, mob) as Node2D
	else:
		_active_mark = MOB_ATTACK_MARK_SCENE.instantiate() as Node2D
		mob.add_child(_active_mark)
	if _active_mark != null and _active_mark.has_method(&"setup"):
		_active_mark.setup(mark_offset, tint)


func _release_windup_mark() -> void:
	if is_instance_valid(_active_mark):
		PoolUtil.release_node(_active_mark)
	_active_mark = null


func _get_object_pools(mob: Mob) -> Node:
	var game := mob.get_node_or_null("/root/Game")
	if game == null:
		return null
	return game.get_node_or_null("ObjectPools")
