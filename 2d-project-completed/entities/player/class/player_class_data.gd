extends Resource
class_name PlayerClassData

## 플레이어 직업 정의 — 런 시작 시 상시 stat_modifiers를 부여합니다.

@export var class_id := ""
@export var display_name := ""
@export var display_name_ko := ""
@export var description_en := ""
@export var description_ko := ""
@export var stat_modifiers: Dictionary = {}
@export var visual_scene: PackedScene

@export var base_max_health := 110.0
@export var max_health_per_level := 33.0
@export var base_attack := 12.0
@export var attack_per_level := 2.4
@export var base_health_regen := 1.0
@export var health_regen_per_level := 0.2
@export var move_speed_mult := 1.0
@export var base_defense := 0


func get_unique_key() -> String:
	return class_id if not class_id.is_empty() else resource_path


func get_display_name_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not display_name.is_empty():
		return display_name
	return display_name_ko if not display_name_ko.is_empty() else display_name


func get_description_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not description_en.is_empty():
		return description_en
	return description_ko if not description_ko.is_empty() else description_en


# 직업 기본 스탯 + 추가 modifier를 런타임 Dictionary로 변환합니다.
func build_stat_modifiers() -> Dictionary:
	var mods := stat_modifiers.duplicate(true)
	mods["class_base_max_health"] = base_max_health
	mods["class_max_health_per_level"] = max_health_per_level
	mods["class_base_attack"] = base_attack
	mods["class_attack_per_level"] = attack_per_level
	mods["class_base_health_regen"] = base_health_regen
	mods["class_health_regen_per_level"] = health_regen_per_level
	mods["move_speed_mult"] = move_speed_mult
	if base_defense > 0:
		mods["armor_min"] = base_defense
		mods["armor_max"] = base_defense
	else:
		mods.erase("armor_min")
		mods.erase("armor_max")
	return mods


# 로비·툴팁용 — 직업 설명과 스탯 요약.
func build_tooltip_bbcode() -> String:
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % get_display_name_localized())
	var description := get_description_localized()
	if not description.is_empty():
		lines.append(description)
	for stat_line in build_stat_summary_lines():
		lines.append(stat_line)
	return "\n".join(lines)


# 직업 기본 스탯 요약 문자열(한/영).
func build_stat_summary_lines() -> PackedStringArray:
	var en := UiLocale.get_locale() == UiLocale.LOCALE_EN
	var lines: PackedStringArray = []
	if en:
		lines.append(
			"Max HP: %d / +%d per level" % [int(base_max_health), int(max_health_per_level)]
		)
		lines.append(
			"Attack: %d / +%.1f per level" % [int(base_attack), attack_per_level]
		)
		lines.append(
			"HP regen: %.1f/s / +%.1f per level" % [base_health_regen, health_regen_per_level]
		)
		lines.append("Move speed: %d%%" % int(roundf(move_speed_mult * 100.0)))
		lines.append("Defense: %d" % base_defense)
	else:
		lines.append(
			"최대 체력: %d / 레벨당 +%d" % [int(base_max_health), int(max_health_per_level)]
		)
		lines.append(
			"공격력: %d / 레벨당 +%.1f" % [int(base_attack), attack_per_level]
		)
		lines.append(
			"체력 회복: %.1fHP/초 / 레벨당 +%.1f" % [base_health_regen, health_regen_per_level]
		)
		lines.append("속도: %d%%" % int(roundf(move_speed_mult * 100.0)))
		lines.append("방어력: %d" % base_defense)
	return lines
