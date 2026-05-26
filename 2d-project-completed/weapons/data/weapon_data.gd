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

const PROJECTILE_MOVEMENT_STRAIGHT := "Straight"
const PROJECTILE_MOVEMENT_STRAIGHT_PIERCE := "StraightPierce"
const PROJECTILE_MOVEMENT_RETURN := "Return"
const PROJECTILE_MOVEMENT_CURVED_RETURN := "CurvedReturn"
const PROJECTILE_MOVEMENT_DECELERATE := "Decelerate"
const PROJECTILE_MOVEMENT_HOMING := "Homing"
const PROJECTILE_MOVEMENT_ARC := "Arc"
const PROJECTILE_MOVEMENT_ORBIT := "Orbit"

const PROJECTILE_MOVEMENT_LABELS_KO := {
	"Straight": "직선",
	"StraightPierce": "직선 관통",
	"Return": "왕복",
	"CurvedReturn": "곡선 왕복",
	"Decelerate": "감속",
	"Homing": "유도",
	"Arc": "포물선",
	"Orbit": "궤도",
}

const PROJECTILE_MOVEMENT_OPTIONS_BY_TYPE := {
	"Melee": ["StraightPierce", "Return", "CurvedReturn", "Decelerate", "Orbit"],
	"Ranged": ["Straight", "Return", "Arc"],
	"Magic": ["Straight", "Homing", "Orbit"],
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
## 서로 다른 몹 관통 수. 1=기본, -1=무제한, 0=설정 불가
@export var projectile_pierce_count := 1
@export var magic_attack_style := "Projectile"
@export var damage_element := ""
@export var projectile_speed := 900.0
@export var melee_projectile_speed := 1000.0
## 근접 관통탄 1회 공격당 동시 발사 수 (1이면 단발)
@export var melee_spread_count := 1
## 부채꼴 전체 각도(도). 조준 방향을 중심으로 좌우 분배
@export var melee_spread_angle_deg := 0.0
## 병렬 근접탄이 중심선에서 좌우로 떨어지는 거리
@export var melee_parallel_offset := 0.0
@export var homing_strength := 0.0
@export var applies_nettles := false
@export var nettles_duration := 8.0
@export var explosion_radius := 0.0
@export var ranged_attack_style := "Bullet"
@export var uses_arc_throw := false
## Projectile = 탄·비행체, AreaZone = 짧은 고정 히트존(연금 착지 등)
@export var attack_delivery := "Projectile"
## 발사체 비행 패턴 — Straight / StraightPierce / Return / CurvedReturn / Decelerate / Homing / Arc / Orbit
@export var projectile_movement := "Straight"
## 궤도 마법(왕의 성경 등) 회전 속도(라디안/초)
@export var orbit_speed := 2.8
## 궤도 반경 = get_melee_range() + orbit_radius_extra
@export var orbit_radius_extra := 30.0


func get_unique_key() -> String:
	if not weapon_id.is_empty():
		return weapon_id
	if not resource_path.is_empty():
		return resource_path
	return display_name


func get_select_label() -> String:
	return "%s (%d-%d)" % [get_display_name_localized(), min_damage, max_damage]


func get_display_name_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not display_name.is_empty():
		return display_name
	return display_name_ko if not display_name_ko.is_empty() else display_name


func build_select_tooltip_bbcode() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN:
		return _build_select_tooltip_bbcode_en()
	return _build_select_tooltip_bbcode_ko()


func _build_select_tooltip_bbcode_ko() -> String:
	var lines: PackedStringArray = []
	var hand_tag := ""
	if hand == "One-Handed":
		hand_tag = " [한손 무기]"
	elif hand == "Two-Handed":
		hand_tag = " [양손 무기]"
	lines.append("[color=#ffdd55]%s%s[/color]" % [get_display_name_localized(), hand_tag])
	lines.append("%s / %s" % [_weapon_type_ko(), weapon_subtype])
	if not damage_element.is_empty():
		lines.append("[color=#c9a87a]피해 속성: %s[/color]" % _damage_element_ko())
	lines.append("데미지: %d-%d" % [min_damage, max_damage])
	lines.append("공격 속도: %.2f APS" % attacks_per_second)
	if has_burst():
		lines.append("연사: %d발" % burst_count)
	if hit_count > 1:
		lines.append("타격 횟수: %d회" % hit_count)
	var pierce_label := get_projectile_pierce_label_ko()
	if not pierce_label.is_empty():
		lines.append(pierce_label)
	lines.append("사거리: %s (%d)" % [_range_type_ko(), int(_get_attack_range())])
	if is_area_zone_attack() and aoe_radius > 0.0:
		lines.append("영역 반경: %d" % int(aoe_radius))
	if is_explosion_ranged() and explosion_radius > 0.0:
		lines.append("폭발 반경: %d" % int(explosion_radius))
	if damage_element == "poison":
		lines.append("독 피해: %d-%d (%.1f초)" % [poison_damage_min, poison_damage_max, poison_duration])
	if applies_nettles:
		lines.append("쐐기: %.1f초" % nettles_duration)
	if not get_projectile_movement_label_ko().is_empty():
		lines.append("움직임: %s" % get_projectile_movement_label_ko())
	if is_melee() and not is_orbit_attack():
		lines.append("공격 방식: 관통 탄")
	if has_melee_parallel_spawn():
		lines.append("병렬 탄막: %d발 (좌우 %d)" % [get_melee_spread_count(), int(melee_parallel_offset)])
	elif has_melee_spread():
		lines.append("탄막: %d발 (부채꼴 %.0f°)" % [get_melee_spread_count(), melee_spread_angle_deg])
	if is_area_zone_attack():
		lines.append("공격 방식: 영역")
	if is_orbit_attack():
		lines.append("공격 방식: 궤도")
	if homing_strength > 0.0:
		lines.append("유도 탄")
	var effect_ko := _effect_ko()
	if not effect_ko.is_empty():
		lines.append("")
		lines.append(effect_ko)
	return "\n".join(lines)


func _build_select_tooltip_bbcode_en() -> String:
	var lines: PackedStringArray = []
	var hand_tag := ""
	if hand == "One-Handed":
		hand_tag = " [One-Handed]"
	elif hand == "Two-Handed":
		hand_tag = " [Two-Handed]"
	lines.append("[color=#ffdd55]%s%s[/color]" % [get_display_name_localized(), hand_tag])
	lines.append("%s / %s" % [UiLocale.weapon_type_label(weapon_type), weapon_subtype])
	if not damage_element.is_empty():
		lines.append("[color=#c9a87a]Damage type: %s[/color]" % _damage_element_en())
	lines.append("Damage: %d-%d" % [min_damage, max_damage])
	lines.append("Attack speed: %.2f APS" % attacks_per_second)
	if has_burst():
		lines.append("Burst: %d shots" % burst_count)
	if hit_count > 1:
		lines.append("Hits: %d" % hit_count)
	var pierce_label_en := get_projectile_pierce_label_en()
	if not pierce_label_en.is_empty():
		lines.append(pierce_label_en)
	lines.append("Range: %s (%d)" % [_range_type_en(), int(_get_attack_range())])
	if is_area_zone_attack() and aoe_radius > 0.0:
		lines.append("Area radius: %d" % int(aoe_radius))
	if is_explosion_ranged() and explosion_radius > 0.0:
		lines.append("Explosion radius: %d" % int(explosion_radius))
	if damage_element == "poison":
		lines.append("Poison: %d-%d (%.1fs)" % [poison_damage_min, poison_damage_max, poison_duration])
	if applies_nettles:
		lines.append("Nettles: %.1fs" % nettles_duration)
	if not get_projectile_movement_label_ko().is_empty():
		var movement_label_en := PROJECTILE_MOVEMENT_ORBIT if is_orbit_attack() else projectile_movement
		lines.append("Movement: %s" % movement_label_en)
	if is_melee() and not is_orbit_attack():
		lines.append("Delivery: piercing projectile")
	if has_melee_parallel_spawn():
		lines.append("Parallel volley: %d projectiles (%d each side)" % [get_melee_spread_count(), int(melee_parallel_offset)])
	elif has_melee_spread():
		lines.append("Volley: %d projectiles (%.0f° fan)" % [get_melee_spread_count(), melee_spread_angle_deg])
	if is_area_zone_attack():
		lines.append("Delivery: area zone")
	if is_orbit_attack():
		lines.append("Delivery: orbit")
	if homing_strength > 0.0:
		lines.append("Homing")
	if not effect.is_empty():
		lines.append("")
		lines.append("Effect: %s" % effect)
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


func _damage_element_en() -> String:
	return damage_element


func _range_type_en() -> String:
	return range_type


func _get_attack_range() -> float:
	if is_orbit_attack():
		return get_orbit_radius()
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
	return is_magic() and is_orbit_attack()


func is_orbit_attack() -> bool:
	return magic_attack_style == "Orbit" or projectile_movement == PROJECTILE_MOVEMENT_ORBIT


func is_ranged() -> bool:
	return weapon_type == "Ranged"


func is_throwing() -> bool:
	return weapon_subtype == "Throwing"


func is_area_zone_attack() -> bool:
	return attack_delivery == "AreaZone"


func is_explosion_ranged() -> bool:
	return is_ranged() and ranged_attack_style == "Explosion"


func has_burst() -> bool:
	return burst_count > 1


func get_burst_cooldown() -> float:
	return 1.0 / attacks_per_second


func get_melee_range() -> float:
	return MELEE_RANGE_BY_TYPE.get(range_type, MELEE_RANGE_BY_TYPE["Medium"])


func get_melee_projectile_speed() -> float:
	if melee_projectile_speed > 0.0:
		return melee_projectile_speed
	return 1000.0


func get_orbit_radius() -> float:
	return get_melee_range() + orbit_radius_extra


func has_melee_spread() -> bool:
	return is_melee() and melee_spread_count > 1


func has_melee_parallel_spawn() -> bool:
	return is_melee() and melee_spread_count > 1 and melee_parallel_offset > 0.0


func get_melee_spread_count() -> int:
	return maxi(melee_spread_count, 1)


static func is_valid_projectile_pierce_count(value: int) -> bool:
	return value != 0


func has_unlimited_projectile_pierce() -> bool:
	return projectile_pierce_count < 0


func get_projectile_pierce_count_safe() -> int:
	if projectile_pierce_count == 0:
		push_error(
			"WeaponData '%s': projectile_pierce_count는 0일 수 없습니다 (1 이상 또는 -1)." % get_unique_key()
		)
		return 1
	return projectile_pierce_count


func get_projectile_pierce_label_ko() -> String:
	if projectile_pierce_count == -1:
		return "관통: 무제한"
	if projectile_pierce_count == 1:
		return ""
	return "관통: %d체" % projectile_pierce_count


func get_projectile_pierce_label_en() -> String:
	if projectile_pierce_count == -1:
		return "Pierce: unlimited"
	if projectile_pierce_count == 1:
		return ""
	return "Pierce: %d" % projectile_pierce_count


func get_projectile_movement_options() -> Array[String]:
	var result: Array[String] = []

	if is_area_zone_attack():
		result.append(PROJECTILE_MOVEMENT_ARC)
	elif is_melee():
		result.append(PROJECTILE_MOVEMENT_STRAIGHT_PIERCE)
		result.append(PROJECTILE_MOVEMENT_RETURN)
		result.append(PROJECTILE_MOVEMENT_CURVED_RETURN)
		result.append(PROJECTILE_MOVEMENT_DECELERATE)
		result.append(PROJECTILE_MOVEMENT_ORBIT)
	elif is_ranged():
		if is_throwing():
			if projectile_scene == null:
				result.append(PROJECTILE_MOVEMENT_STRAIGHT)
				result.append(PROJECTILE_MOVEMENT_RETURN)
			elif uses_arc_throw:
				result.append(PROJECTILE_MOVEMENT_ARC)
			elif returns_to_owner:
				result.append(PROJECTILE_MOVEMENT_RETURN)
			else:
				result.append(PROJECTILE_MOVEMENT_STRAIGHT)
		else:
			result.append(PROJECTILE_MOVEMENT_STRAIGHT)
	elif is_magic():
		if is_orbit_attack():
			result.append(PROJECTILE_MOVEMENT_ORBIT)
		else:
			result.append(PROJECTILE_MOVEMENT_STRAIGHT)
			result.append(PROJECTILE_MOVEMENT_HOMING)
			result.append(PROJECTILE_MOVEMENT_ORBIT)
	else:
		result.append(PROJECTILE_MOVEMENT_STRAIGHT)

	return result


func get_projectile_movement_label_ko() -> String:
	if is_orbit_attack():
		return PROJECTILE_MOVEMENT_LABELS_KO[PROJECTILE_MOVEMENT_ORBIT]
	return PROJECTILE_MOVEMENT_LABELS_KO.get(projectile_movement, projectile_movement)


func should_projectile_return() -> bool:
	return (
		projectile_movement == PROJECTILE_MOVEMENT_RETURN
		or projectile_movement == PROJECTILE_MOVEMENT_CURVED_RETURN
		or returns_to_owner
	)


func should_projectile_curve_return() -> bool:
	return projectile_movement == PROJECTILE_MOVEMENT_CURVED_RETURN


func should_projectile_decelerate() -> bool:
	return projectile_movement == PROJECTILE_MOVEMENT_DECELERATE


# projectile_movement에 맞춰 returns_to_owner·uses_arc_throw 등 레거시 플래그를 맞춥니다.
func apply_projectile_movement_side_effects() -> void:
	match projectile_movement:
		PROJECTILE_MOVEMENT_RETURN, PROJECTILE_MOVEMENT_CURVED_RETURN:
			returns_to_owner = true
		PROJECTILE_MOVEMENT_ARC:
			returns_to_owner = false
			uses_arc_throw = true
		PROJECTILE_MOVEMENT_ORBIT:
			returns_to_owner = false
			magic_attack_style = "Orbit"
		PROJECTILE_MOVEMENT_HOMING:
			returns_to_owner = false
			magic_attack_style = "Projectile"
			if homing_strength <= 0.0:
				homing_strength = 6.0
		_:
			returns_to_owner = false
			if is_magic() and projectile_movement == PROJECTILE_MOVEMENT_STRAIGHT:
				magic_attack_style = "Projectile"


func normalize_projectile_movement_from_legacy() -> void:
	if projectile_movement != PROJECTILE_MOVEMENT_STRAIGHT:
		return
	if returns_to_owner:
		projectile_movement = PROJECTILE_MOVEMENT_RETURN
	elif is_melee():
		projectile_movement = PROJECTILE_MOVEMENT_STRAIGHT_PIERCE
	elif uses_arc_throw:
		projectile_movement = PROJECTILE_MOVEMENT_ARC
	elif is_orbit_attack():
		projectile_movement = PROJECTILE_MOVEMENT_ORBIT
	elif homing_strength > 0.0:
		projectile_movement = PROJECTILE_MOVEMENT_HOMING


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
