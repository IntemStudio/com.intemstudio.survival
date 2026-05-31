class_name EliteAffixRuntimeOverloading
extends EliteAffixRuntime

## overloading affix — 방어막 50%, 7초 무피해 후 1초 재충전, 피격 bomb debuff.

const SHIELD_MAX_RATIO := 0.5
const RECHARGE_DELAY_SEC := 7.0
const RECHARGE_DURATION_SEC := 1.0

var _shield_max_hp := 0
var _seconds_since_damage := 0.0
var _is_recharging := false
var _recharge_timer := 0.0
var _recharge_start_shield := 0


func begin(mob: Node2D) -> void:
	if mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	_shield_max_hp = maxi(1, roundi(float(mob_node.max_health) * SHIELD_MAX_RATIO))
	mob_node.elite_shield_hp = _shield_max_hp
	_reset_recharge_state()


func reset() -> void:
	_shield_max_hp = 0
	_reset_recharge_state()


func tick(delta: float, mob: Node2D) -> void:
	if delta <= 0.0 or mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	if _shield_max_hp <= 0:
		return
	if mob_node.elite_shield_hp >= _shield_max_hp:
		_reset_recharge_state()
		return
	if _is_recharging:
		_recharge_timer += delta
		var progress := clampf(_recharge_timer / RECHARGE_DURATION_SEC, 0.0, 1.0)
		mob_node.elite_shield_hp = roundi(
			lerpf(float(_recharge_start_shield), float(_shield_max_hp), progress)
		)
		if progress >= 1.0:
			mob_node.elite_shield_hp = _shield_max_hp
			_reset_recharge_state()
		return
	_seconds_since_damage += delta
	if _seconds_since_damage >= RECHARGE_DELAY_SEC:
		_is_recharging = true
		_recharge_timer = 0.0
		_recharge_start_shield = mob_node.elite_shield_hp


func on_hit_player(raw_damage: int, mob: Node2D) -> void:
	if mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	if not is_instance_valid(mob_node.player):
		return
	if mob_node.player.has_method(&"apply_elite_debuff"):
		mob_node.player.call(
			&"apply_elite_debuff",
			&"elite_bomb",
			{"snapshot_damage": raw_damage}
		)


func on_took_damage(_amount: int, mob: Node2D) -> void:
	if mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	if mob_node.elite_shield_hp >= _shield_max_hp:
		return
	_seconds_since_damage = 0.0
	_is_recharging = false
	_recharge_timer = 0.0


func _reset_recharge_state() -> void:
	_seconds_since_damage = 0.0
	_is_recharging = false
	_recharge_timer = 0.0
	_recharge_start_shield = 0
