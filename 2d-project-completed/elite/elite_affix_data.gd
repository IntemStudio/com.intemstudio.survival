extends Resource
class_name EliteAffixData

## 엘리트 affix 한 종의 stat·비주얼·유물 메타데이터입니다.

@export var affix_id: StringName = &""
@export_range(1.0, 10.0, 0.01, "or_greater") var hp_mult: float = 1.0
@export_range(1.0, 10.0, 0.01, "or_greater") var damage_mult: float = 1.0
@export var tint := Color.WHITE
@export var display_prefix_ko := ""
@export_multiline var description_ko := ""
@export var horn_scene: PackedScene
@export var relic_item_id: StringName = &""
@export var drops_relic: bool = true
@export var enabled: bool = true


func get_unique_key() -> StringName:
	return affix_id


# F6·툴팁용 affix 요약 BBCode — stat 배율 + 기획 설명.
func build_gui_description_bbcode() -> String:
	var lines: PackedStringArray = []
	var title_color := tint.to_html(false)
	var title := display_prefix_ko.strip_edges()
	if title.is_empty():
		title = String(affix_id)
	lines.append("[color=#%s]%s[/color]" % [title_color, title])
	lines.append("HP ×%.0f · 공격 ×%.0f" % [hp_mult, damage_mult])
	if not description_ko.strip_edges().is_empty():
		lines.append(description_ko.strip_edges())
	return "\n".join(lines)
