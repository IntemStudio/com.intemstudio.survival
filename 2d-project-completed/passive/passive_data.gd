extends Resource
class_name PassiveData

## 런 한정 패시브 정의. Phase B는 flat 경로(stat·grant_by_level)만 사용합니다.

@export var passive_id := ""
@export var display_name := ""
@export var display_name_ko := ""
@export var max_level := 3
@export var evolves_into_id := ""
@export var tags: Array[StringName] = []
@export var stat_modifiers_by_level: Array[Dictionary] = []
@export var grant_tags_by_level: Array[Dictionary] = []
@export var trigger_id: StringName = &""
@export var conditions: Array[Resource] = []
@export var effects: Array[Resource] = []


func get_unique_key() -> String:
	return passive_id if not passive_id.is_empty() else resource_path


func is_evolved_only() -> bool:
	return tags.has(&"evolved")


func get_display_name_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not display_name.is_empty():
		return display_name
	return display_name_ko if not display_name_ko.is_empty() else display_name


func get_select_label(target_level: int) -> String:
	var level := maxi(target_level, 1)
	return "%s  Lv.%d" % [get_display_name_localized(), level]


# 획득 UI용 — 현재→다음 레벨 효과 요약.
func build_select_tooltip_bbcode(current_level: int, target_level: int) -> String:
	var lines: PackedStringArray = []
	if target_level <= current_level:
		lines.append(get_display_name_localized())
		lines.append("MAX")
		return "\n".join(lines)
	if current_level <= 0:
		lines.append("[b]%s[/b]" % get_display_name_localized())
	else:
		lines.append(
			"[b]%s[/b]  Lv.%d → Lv.%d" % [
				get_display_name_localized(),
				current_level,
				target_level,
			]
		)
	var stat_line := _format_level_stat_line(target_level - 1)
	if not stat_line.is_empty():
		lines.append(stat_line)
	var grant_line := _format_level_grant_line(target_level - 1)
	if not grant_line.is_empty():
		lines.append(grant_line)
	if target_level >= max_level and not evolves_into_id.is_empty():
		var evolved := PassiveCatalog.get_passive(evolves_into_id)
		if evolved != null:
			if UiLocale.get_locale() == UiLocale.LOCALE_EN:
				lines.append("Evolves into: %s" % evolved.get_display_name_localized())
			else:
				lines.append("진화 → %s" % evolved.get_display_name_localized())
	return "\n".join(lines)


func get_cumulative_stat_modifiers(level: int) -> Dictionary:
	var totals: Dictionary = {}
	if level <= 0:
		return totals
	var count := mini(level, stat_modifiers_by_level.size())
	for index in count:
		GearStatMerge.merge_into(totals, stat_modifiers_by_level[index])
	return totals


func get_cumulative_grant_modifiers(level: int) -> Dictionary:
	var totals: Dictionary = {}
	if level <= 0:
		return totals
	var count := mini(level, grant_tags_by_level.size())
	for index in count:
		GearStatMerge.merge_into(totals, grant_tags_by_level[index])
	return totals


func _format_level_stat_line(level_index: int) -> String:
	if level_index < 0 or level_index >= stat_modifiers_by_level.size():
		return ""
	var lines := GearStatDisplay.format_stat_lines(stat_modifiers_by_level[level_index])
	return "\n".join(lines)


func _format_level_grant_line(level_index: int) -> String:
	if level_index < 0 or level_index >= grant_tags_by_level.size():
		return ""
	var grants: Dictionary = grant_tags_by_level[level_index]
	var parts: PackedStringArray = []
	for key in grants:
		var value: Variant = grants[key]
		if value is Array:
			for tag in value:
				parts.append("%s: %s" % [key, String(tag)])
		else:
			parts.append("%s: %s" % [key, String(value)])
	return ", ".join(parts)
