class_name RewardChoice
extends RefCounted

## 무기·무기 강화·패시브 보상 선택지 1개.

enum Kind { WEAPON, WEAPON_UPGRADE, PASSIVE }

var kind: Kind = Kind.WEAPON
var weapon: WeaponData = null
var passive: PassiveData = null
var passive_target_level: int = 1
var weapon_from_level: int = 1
var weapon_target_level: int = 1


static func from_weapon(weapon_data: WeaponData) -> RewardChoice:
	var choice := RewardChoice.new()
	choice.kind = Kind.WEAPON
	choice.weapon = weapon_data
	return choice


static func from_weapon_upgrade(
	weapon_data: WeaponData,
	from_level: int,
	target_level: int
) -> RewardChoice:
	var choice := RewardChoice.new()
	choice.kind = Kind.WEAPON_UPGRADE
	choice.weapon = weapon_data
	choice.weapon_from_level = maxi(from_level, 1)
	choice.weapon_target_level = maxi(target_level, choice.weapon_from_level + 1)
	return choice


static func from_passive(passive_data: PassiveData, target_level: int) -> RewardChoice:
	var choice := RewardChoice.new()
	choice.kind = Kind.PASSIVE
	choice.passive = passive_data
	choice.passive_target_level = maxi(target_level, 1)
	return choice


func is_weapon() -> bool:
	return kind == Kind.WEAPON and weapon != null


func is_weapon_upgrade() -> bool:
	return kind == Kind.WEAPON_UPGRADE and weapon != null


func is_passive() -> bool:
	return kind == Kind.PASSIVE and passive != null


func get_choice_label() -> String:
	if is_weapon():
		return weapon.get_select_label()
	if is_weapon_upgrade():
		return _format_weapon_level_label(weapon_from_level, weapon_target_level)
	if is_passive():
		return passive.get_select_label(passive_target_level)
	return "?"


func get_detail_bbcode(current_passive_level: int = 0, current_weapon_level: int = 1) -> String:
	if is_weapon():
		return weapon.build_select_tooltip_bbcode()
	if is_weapon_upgrade():
		return _build_weapon_upgrade_tooltip(current_weapon_level)
	if is_passive():
		return passive.build_select_tooltip_bbcode(current_passive_level, passive_target_level)
	return ""


func _format_weapon_level_label(from_level: int, to_level: int) -> String:
	var to_label := "MAX" if to_level >= WeaponRunState.MAX_LEVEL else str(to_level)
	return "%s  Lv.%d → %s" % [
		weapon.get_display_name_localized(),
		maxi(from_level, 1),
		to_label,
	]


func _build_weapon_upgrade_tooltip(current_level: int) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % _format_weapon_level_label(current_level, weapon_target_level))
	var from_mult := WeaponRunState.compute_damage_mult(maxi(current_level, 1))
	var to_mult := WeaponRunState.compute_damage_mult(weapon_target_level)
	var pct_from := roundi((from_mult - 1.0) * 100.0)
	var pct_to := roundi((to_mult - 1.0) * 100.0)
	if UiLocale.get_locale() == UiLocale.LOCALE_EN:
		lines.append("Weapon damage bonus +%d%% → +%d%%" % [pct_from, pct_to])
	else:
		lines.append("무기 피해 보너스 +%d%% → +%d%%" % [pct_from, pct_to])
	if weapon_target_level >= WeaponRunState.MAX_LEVEL:
		if UiLocale.get_locale() == UiLocale.LOCALE_EN:
			lines.append("Reaches MAX weapon level")
		else:
			lines.append("무기 강화 최대 레벨")
	return "\n".join(lines)
