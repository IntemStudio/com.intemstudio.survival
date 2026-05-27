class_name AttackContext
extends RefCounted

## 공격 발동 시점 스냅샷 — 독립체는 읽기만 하고 피해를 재계산하지 않습니다.

var owner: Node = null
var weapon: WeaponData = null
var spawn_transform: Transform2D = Transform2D.IDENTITY
var origin: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var locked_target: Node = null
var rolled_damage: int = 0
var runtime_flags: Dictionary = {}


static func from_gun(
	weapon_data: WeaponData,
	spawn_transform: Transform2D,
	direction: Vector2,
	owner_node: Node = null,
	target: Node = null,
	pre_rolled_damage: int = -1
) -> AttackContext:
	var context := AttackContext.new()
	context.weapon = weapon_data
	context.spawn_transform = spawn_transform
	context.origin = spawn_transform.origin
	context.direction = direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT
	context.owner = owner_node
	context.locked_target = target
	if pre_rolled_damage >= 0:
		context.rolled_damage = pre_rolled_damage
	elif weapon_data:
		context.rolled_damage = LoadoutStatApply.roll_combat_damage(weapon_data)
	return context
