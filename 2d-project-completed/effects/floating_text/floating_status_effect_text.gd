extends RefCounted
class_name FloatingStatusEffectText

const POISON_COLOR := Color(0.45, 0.95, 0.35)
const SLOW_COLOR := Color(0.45, 0.8, 1.0)
const STUN_COLOR := Color(1.0, 0.85, 0.25)
const RESISTED_COLOR := Color(0.8, 0.8, 0.85)


# 상태이상 적용 결과를 피해 숫자와 분리된 문구로 표시합니다.
static func spawn_status(world_position: Vector2, text: String, color: Color) -> void:
	FloatingText.spawn(world_position, text, color, false)


static func spawn_status_applied(world_position: Vector2, data: StatusEffectData) -> void:
	if data == null:
		return
	spawn_status(world_position, data.get_display_name_localized(), data.effect_color)


static func spawn_bleed_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"bleed"), Color(0.95, 0.18, 0.18))


static func spawn_burn_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"burn"), Color(1.0, 0.45, 0.2))


static func spawn_poison_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"poison"), POISON_COLOR)


static func spawn_scorch_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"scorch"), Color(1.0, 0.32, 0.12))


static func spawn_toxic_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"toxic"), Color(0.35, 0.85, 0.2))


static func spawn_zap_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"zap"), Color(0.55, 0.85, 1.0))


static func spawn_slow_applied(world_position: Vector2) -> void:
	spawn_status(world_position, "Slow", SLOW_COLOR)


static func spawn_chill_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"chill"), SLOW_COLOR)


static func spawn_frostbite_applied(world_position: Vector2) -> void:
	spawn_status(world_position, StatusEffectCatalog.get_display_name(&"frostbite"), Color(0.65, 0.95, 1.0))


static func spawn_stun_applied(world_position: Vector2) -> void:
	spawn_status(world_position, "Stun", STUN_COLOR)


static func spawn_status_resisted(world_position: Vector2) -> void:
	spawn_status(world_position, "Resisted", RESISTED_COLOR)
