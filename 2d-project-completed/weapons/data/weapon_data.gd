extends Resource
class_name WeaponData

const MELEE_RANGE_BY_TYPE := {
	"Very Short": 70.0,
	"Short": 110.0,
	"Medium": 160.0,
	"Far": 220.0,
}

const PROJECTILE_RANGE_BY_TYPE := {
	"Very Short": 300.0,
	"Short": 400.0,
	"Medium": 700.0,
	"Far": 1000.0,
	"Very Far": 1400.0,
}

@export var weapon_id := ""
@export var display_name := ""
@export var display_name_ko := ""
@export var weapon_type := ""
@export var weapon_subtype := ""
@export var rarity := ""
@export var hand := ""
@export var range_type := ""
@export var effect := ""
@export var texture: Texture2D = null
@export var sprite_modulate := Color.WHITE
@export var projectile_scene: PackedScene = null
@export var throw_range := 600.0
@export var throw_speed := 700.0
@export var aoe_radius := 100.0
@export var returns_to_owner := false
@export var poison_damage_min := 10
@export var poison_damage_max := 20
@export var poison_duration := 4.0
@export var poison_ticks_per_second := 2.0
@export var min_damage := 1
@export var max_damage := 1
@export var attacks_per_second := 1.0
@export var burst_count := 1
@export var burst_interval := 0.08
@export var hit_count := 1
@export var magic_attack_style := "Projectile"
@export var damage_element := ""
@export var projectile_speed := 900.0
@export var homing_strength := 0.0
@export var applies_nettles := false
@export var nettles_duration := 8.0
@export var explosion_radius := 0.0
@export var ranged_attack_style := "Bullet"
@export var uses_arc_throw := false


func get_unique_key() -> String:
	if not weapon_id.is_empty():
		return weapon_id
	if not resource_path.is_empty():
		return resource_path
	return display_name


func get_select_label() -> String:
	return "%s (%d-%d)" % [get_display_name_localized(), min_damage, max_damage]


func get_display_name_localized() -> String:
	return display_name_ko if not display_name_ko.is_empty() else display_name


func build_select_tooltip_bbcode() -> String:
	var lines: PackedStringArray = []
	var hand_tag := ""
	if hand == "One-Handed":
		hand_tag = " [1손]"
	elif hand == "Two-Handed":
		hand_tag = " [2손]"
	lines.append("[color=#ffdd55]%s%s[/color]" % [get_display_name_localized(), hand_tag])
	lines.append("%s / %s" % [_weapon_type_ko(), weapon_subtype])
	if not damage_element.is_empty():
		lines.append("[color=#c9a87a]피해 속성: %s[/color]" % _damage_element_ko())
	lines.append("데미지: %d-%d" % [min_damage, max_damage])
	lines.append("공격 속도: %.2g APS" % attacks_per_second)
	if has_burst():
		lines.append("연사: %d발" % burst_count)
	if hit_count > 1:
		lines.append("타격 횟수: %d회" % hit_count)
	lines.append("사거리: %s (%d)" % [_range_type_ko(), int(_get_attack_range())])
	if is_explosion_ranged() and explosion_radius > 0.0:
		lines.append("폭발 반경: %d" % int(explosion_radius))
	if damage_element == "poison":
		lines.append("독 피해: %d-%d (%.1f초)" % [poison_damage_min, poison_damage_max, poison_duration])
	if applies_nettles:
		lines.append("쐐기: %.1f초" % nettles_duration)
	if returns_to_owner:
		lines.append("투척 후 복귀")
	if is_orbit_magic():
		lines.append("공격 방식: 궤도")
	if homing_strength > 0.0:
		lines.append("유도 탄")
	var effect_ko := _effect_ko()
	if not effect_ko.is_empty():
		lines.append("")
		lines.append(effect_ko)
	return "\n".join(lines)


func _weapon_type_ko() -> String:
	match weapon_type:
		"Ranged":
			return "원거리"
		"Melee":
			return "근접"
		"Magic":
			return "마법"
		_:
			return weapon_type


func _damage_element_ko() -> String:
	match damage_element:
		"thrusting":
			return "관통"
		"slashing":
			return "베기"
		"striking":
			return "타격"
		"poison":
			return "독"
		"explosion":
			return "폭발"
		"fire":
			return "화염"
		"nature":
			return "자연"
		"radiant":
			return "광휘"
		"sound":
			return "음파"
		"magic":
			return "마법"
		_:
			return damage_element


func _range_type_ko() -> String:
	match range_type:
		"Very Short":
			return "극근"
		"Short":
			return "근거리"
		"Medium":
			return "중거리"
		"Far":
			return "원거리"
		"Very Far":
			return "극원거리"
		_:
			return range_type


func _get_attack_range() -> float:
	if is_melee():
		return get_melee_range()
	if is_throwing():
		return throw_range
	return get_projectile_range()


func _effect_ko() -> String:
	if effect.is_empty():
		return ""
	if effect == "On combat start, grants En Garde.":
		return "효과: 전투 시작 시 En Garde 부여"
	var text := effect
	text = text.replace("Primary attack deals ", "")
	text = text.replace("Primary attacks deal ", "")
	text = text.replace("Primary attack ", "")
	if not applies_nettles:
		text = text.replace(" and inflicts Nettles.", " · 쐐기 부여")
	if hit_count <= 1:
		text = text.replace(" and can hit multiple times.", " · 다중 타격")
	text = text.replace("thrusting damage", "관통 피해")
	text = text.replace("slashing damage", "베기 피해")
	text = text.replace("striking damage", "타격 피해")
	text = text.replace("poison damage", "독 피해")
	text = text.replace("explosion damage", "폭발 피해")
	text = text.replace("fire damage", "화염 피해")
	text = text.replace("magical damage", "마법 피해")
	text = text.replace("nature damage", "자연 피해")
	text = text.replace("radiant damage", "광휘 피해")
	text = text.replace("sound damage", "음파 피해")
	text = text.replace("spins a flail that deals ", "철퇴 회전 · ")
	text = text.trim_suffix(".")
	return "효과: %s" % text


func is_melee() -> bool:
	return weapon_type == "Melee"


func is_magic() -> bool:
	return weapon_type == "Magic"


func is_orbit_magic() -> bool:
	return is_magic() and magic_attack_style == "Orbit"


func is_ranged() -> bool:
	return weapon_type == "Ranged"


func is_throwing() -> bool:
	return weapon_subtype == "Throwing"


func is_explosion_ranged() -> bool:
	return is_ranged() and ranged_attack_style == "Explosion"


func has_burst() -> bool:
	return burst_count > 1


func get_burst_cooldown() -> float:
	return 1.0 / attacks_per_second


func get_melee_range() -> float:
	return MELEE_RANGE_BY_TYPE.get(range_type, MELEE_RANGE_BY_TYPE["Medium"])


func get_projectile_range() -> float:
	return PROJECTILE_RANGE_BY_TYPE.get(range_type, PROJECTILE_RANGE_BY_TYPE["Medium"])


func roll_damage() -> int:
	return randi_range(min_damage, max_damage)


func get_element_color() -> Color:
	match damage_element:
		"fire":
			return Color(1.0, 0.45, 0.2)
		"nature":
			return Color(0.45, 0.95, 0.35)
		"radiant":
			return Color(1.0, 0.95, 0.55)
		"sound":
			return Color(0.75, 0.55, 1.0)
		"magic":
			return Color(0.55, 0.75, 1.0)
		"thrusting":
			return Color(0.7, 0.85, 1.0)
		"striking":
			return Color(0.9, 0.9, 0.95)
		"slashing":
			return Color(0.95, 0.82, 0.65)
		"poison":
			return Color(0.5, 0.92, 0.35)
		"explosion":
			return Color(1.0, 0.5, 0.25)
		_:
			return Color(0.8, 0.65, 1.0)
