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
	var name_ko := display_name_ko if not display_name_ko.is_empty() else display_name
	return "%s (%d-%d)" % [name_ko, min_damage, max_damage]


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
