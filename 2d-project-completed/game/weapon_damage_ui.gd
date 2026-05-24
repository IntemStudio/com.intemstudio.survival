class_name WeaponDamageUi

## 게임오버·일시정지 무기별 피해 목록 UI 공통 헬퍼.


# 천 단위 콤마 포맷.
static func format_amount(amount: int) -> String:
	var text := str(amount)
	if amount < 1000:
		return text
	var parts: PackedStringArray = []
	while text.length() > 3:
		parts.insert(0, text.substr(text.length() - 3, 3))
		text = text.substr(0, text.length() - 3)
	if not text.is_empty():
		parts.insert(0, text)
	return ",".join(parts)


# VBoxContainer에 무기별 피해 행(및 선택적 합계)을 채웁니다.
static func populate_list(
	list: VBoxContainer,
	rows: Array[Dictionary],
	empty_text: String,
	include_grand_total: bool,
	weapon_type_font_colors: Dictionary = {}
) -> void:
	for child in list.get_children():
		child.queue_free()

	if rows.is_empty():
		var empty_label := Label.new()
		empty_label.text = empty_text
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty_label)
		return

	var grand_total := 0
	for row in rows:
		grand_total += int(row["total"])

	for row in rows:
		var weapon: WeaponData = row["weapon"]
		var total: int = int(row["total"])
		var label := Label.new()
		label.text = "%s  %s" % [weapon.get_display_name_localized(), format_amount(total)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		if not weapon_type_font_colors.is_empty():
			label.add_theme_color_override(
				"font_color",
				weapon_type_font_colors.get(weapon.weapon_type, Color(0.92, 0.92, 0.95, 1))
			)
		list.add_child(label)

	if not include_grand_total:
		return

	var total_label := Label.new()
	total_label.text = "합계  %s" % format_amount(grand_total)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 24)
	list.add_child(total_label)
