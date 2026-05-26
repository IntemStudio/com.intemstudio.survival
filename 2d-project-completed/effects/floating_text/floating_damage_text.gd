extends FloatingText
class_name FloatingDamageText

const ENEMY_DAMAGE_COLOR := Color(1.0, 0.88, 0.25)
const PLAYER_DAMAGE_COLOR := Color(1.0, 0.35, 0.35)
const POISON_DAMAGE_COLOR := Color(0.45, 0.95, 0.35)


static func spawn_enemy_damage(world_position: Vector2, amount: int) -> void:
	_spawn_damage(world_position, amount, ENEMY_DAMAGE_COLOR)


static func spawn_player_damage(world_position: Vector2, amount: int) -> void:
	_spawn_damage(world_position, amount, PLAYER_DAMAGE_COLOR)


static func spawn_poison_damage(world_position: Vector2, amount: int) -> void:
	_spawn_damage(world_position, amount, POISON_DAMAGE_COLOR)


static func spawn_weapon_damage(world_position: Vector2, amount: int, color: Color) -> void:
	_spawn_damage(world_position, amount, color)


# 피해 숫자는 게임플레이 표시 옵션을 따른 뒤 공통 플로팅 텍스트로 출력합니다.
static func _spawn_damage(world_position: Vector2, amount: int, color: Color) -> void:
	if amount <= 0 or not GameplaySettings.is_floating_damage_visible():
		return
	FloatingText.spawn(world_position, str(amount), color, true)
