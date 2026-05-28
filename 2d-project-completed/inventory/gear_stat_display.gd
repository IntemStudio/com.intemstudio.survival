class_name GearStatDisplay
extends RefCounted

## GearData stat_modifiers → 인벤 툴팁 문자열 (표시 전용).

const _STAT_SKIP_KEYS: Array[String] = [
	"block_min",
	"block_max",
	"armor_min",
	"armor_max",
	"suppression_min",
	"suppression_max",
	"defy_death_min",
	"defy_death_max",
	"heart_min",
	"heart_max",
	"mana_min",
	"mana_max",
	"flask_min",
	"flask_max",
	"revive_min",
	"revive_max",
	"power",
	"stamina",
	"curse",
	"weapon_damage_mult",
	"debuff_effect_mult",
	"move_speed_mult",
	"melee_attack_speed_mult",
	"attack_speed_mult",
	"companion_attack_speed_mult",
	"melee_damage_mult",
	"ranged_damage_mult",
	"ranged_attack_speed_mult",
	"magic_attack_speed_mult",
	"magic_damage_mult",
	"energy_damage_mult",
	"physical_damage_mult",
	"nature_damage_mult",
	"fire_damage_mult",
	"lightning_damage_mult",
	"cold_damage_mult",
	"poison_damage_mult",
	"throwing_damage_mult",
	"companion_damage_mult",
	"mana_recovery_mult",
	"stamina_recovery_mult",
	"sword_crit_chance_bonus",
	"weapon_upgrade_level",
	"invincibility_after_damage_sec",
	"invincibility_after_dash_sec",
	"damage_mult",
	"damage_mult_per_level",
	"wall_near_move_speed_mult",
	"grant_orbital",
	"grant_on_dash",
	"grant_on_hit",
	"dart_damage_min",
	"dart_damage_max",
	"intelligence_stat_mult",
	"dexterity_stat_mult",
	"strength_stat_mult",
	"strength",
	"dexterity",
	"intelligence",
	"fiend_undead_damage_mult",
	"prevent_curse",
	"armor",
]


static func format_attunement_line(attunement: int) -> String:
	if attunement <= 0:
		return ""
	var en := UiLocale.get_locale() == UiLocale.LOCALE_EN
	if en:
		return "Attunement: %d" % attunement
	return "조율: %d" % attunement


static func format_stat_lines(modifiers: Dictionary) -> PackedStringArray:
	var stats := GearStatMerge.normalize_modifiers(modifiers)
	var lines: PackedStringArray = []
	var en := UiLocale.get_locale() == UiLocale.LOCALE_EN
	_append_min_max_stat(lines, stats, "block_min", "block_max", "Block", "막기")
	_append_min_max_stat(lines, stats, "armor_min", "armor_max", "Armor", "방어구")
	_append_min_max_stat(lines, stats, "suppression_min", "suppression_max", "Suppression", "억제")
	_append_min_max_stat(lines, stats, "defy_death_min", "defy_death_max", "Defy Death", "죽음 거부")
	_append_min_max_stat(lines, stats, "heart_min", "heart_max", "Heart", "심장")
	_append_min_max_stat(lines, stats, "mana_min", "mana_max", "Mana", "마나")
	_append_min_max_stat(lines, stats, "flask_min", "flask_max", "Flask", "플라스크")
	_append_min_max_stat(lines, stats, "revive_min", "revive_max", "Revive", "부활")
	_append_min_max_stat(lines, stats, "dart_damage_min", "dart_damage_max", "Thrusting Damage", "관통 피해")
	if stats.has("power"):
		lines.append("+%d %s" % [int(stats["power"]), "Power" if en else "파워"])
	if stats.has("stamina"):
		lines.append("+%d %s" % [int(stats["stamina"]), "Stamina" if en else "스태미나"])
	if stats.has("curse"):
		lines.append("+%d %s" % [int(stats["curse"]), "Curse" if en else "저주"])
	_append_mult_bonus_line(lines, stats, "weapon_damage_mult", "Weapon Damage", "무기 피해")
	_append_mult_bonus_line(lines, stats, "damage_mult", "Damage", "피해")
	_append_mult_bonus_line(lines, stats, "melee_damage_mult", "Melee Damage", "근접 피해")
	_append_mult_bonus_line(lines, stats, "ranged_damage_mult", "Ranged Damage", "원거리 피해")
	_append_mult_bonus_line(lines, stats, "physical_damage_mult", "Physical Damage", "물리 피해")
	_append_mult_bonus_line(lines, stats, "nature_damage_mult", "Nature Damage", "자연 피해")
	_append_mult_bonus_line(lines, stats, "fire_damage_mult", "Fire Damage", "화염 피해")
	_append_mult_bonus_line(lines, stats, "lightning_damage_mult", "Lightning Damage", "번개 피해")
	_append_mult_bonus_line(lines, stats, "cold_damage_mult", "Cold Damage", "냉기 피해")
	_append_mult_bonus_line(lines, stats, "poison_damage_mult", "Poison Damage", "독 피해")
	_append_mult_bonus_line(lines, stats, "magic_damage_mult", "Magic Damage", "마법 피해")
	_append_mult_bonus_line(lines, stats, "throwing_damage_mult", "Throwing Damage", "투척 피해")
	_append_mult_bonus_line(lines, stats, "companion_damage_mult", "Companion Damage", "동료 피해")
	_append_mult_bonus_line(lines, stats, "companion_attack_speed_mult", "Companion Attack Speed", "동료 공격 속도")
	_append_mult_bonus_line(lines, stats, "attack_speed_mult", "Attack Speed", "공격 속도")
	_append_mult_bonus_line(lines, stats, "debuff_effect_mult", "Effect of Debuffs", "디버프 효과")
	_append_mult_bonus_line(lines, stats, "move_speed_mult", "Movement Speed", "이동 속도")
	_append_mult_bonus_line(
		lines, stats, "wall_near_move_speed_mult", "Movement Speed while near a wall", "벽 근처 이동 속도"
	)
	_append_mult_bonus_line(lines, stats, "melee_attack_speed_mult", "Melee Attack Speed", "근접 공격 속도")
	_append_mult_bonus_line(lines, stats, "ranged_attack_speed_mult", "Ranged Attack Speed", "원거리 공격 속도")
	_append_mult_bonus_line(lines, stats, "magic_attack_speed_mult", "Magic Attack Speed", "마법 공격 속도")
	_append_mult_bonus_line(lines, stats, "energy_damage_mult", "Energy Damage", "에너지 피해")
	_append_mult_bonus_line(lines, stats, "mana_recovery_mult", "Mana Recovery", "마나 회복")
	_append_mult_bonus_line(lines, stats, "stamina_recovery_mult", "Stamina Recovery Speed", "스태미나 회복 속도")
	_append_mult_bonus_line(
		lines, stats, "intelligence_stat_mult", "stats from Intelligence", "지능에서 오는 스탯"
	)
	_append_mult_bonus_line(lines, stats, "dexterity_stat_mult", "stats from Dexterity", "민첩에서 오는 스탯")
	_append_mult_bonus_line(lines, stats, "strength_stat_mult", "stats from Strength", "힘에서 오는 스탯")
	_append_mult_bonus_line(
		lines, stats, "fiend_undead_damage_mult", "Damage against Fiends and Undead", "악마·언데드 대상 피해"
	)
	if stats.has("strength"):
		lines.append("+%d %s" % [int(stats["strength"]), "Strength" if en else "힘"])
	if stats.has("dexterity"):
		lines.append("+%d %s" % [int(stats["dexterity"]), "Dexterity" if en else "민첩"])
	if stats.has("intelligence"):
		lines.append("+%d %s" % [int(stats["intelligence"]), "Intelligence" if en else "지능"])
	if stats.get("prevent_curse", false):
		if en:
			lines.append("Protects you from getting Cursed.")
		else:
			lines.append("저주에 걸리지 않도록 보호합니다.")
	if stats.has("weapon_upgrade_level"):
		if en:
			lines.append("+%d on weapon upgrade picks" % int(stats["weapon_upgrade_level"]))
		else:
			lines.append("무기 강화 선택 시 추가 +%d" % int(stats["weapon_upgrade_level"]))
	if stats.has("invincibility_after_damage_sec"):
		var sec_damage := float(stats["invincibility_after_damage_sec"])
		if en:
			lines.append(
				"+%s seconds of Invincibility after Taking Damage" % _format_seconds(sec_damage)
			)
		else:
			lines.append("피격 후 %s초 무적" % _format_seconds(sec_damage))
	if stats.has("invincibility_after_dash_sec"):
		var sec_dash := float(stats["invincibility_after_dash_sec"])
		if en:
			lines.append("+%s seconds of Invincibility after Dash" % _format_seconds(sec_dash))
		else:
			lines.append("대시 후 %s초 무적" % _format_seconds(sec_dash))
	if stats.has("damage_mult_per_level"):
		var penalty_pct := int(round(abs(float(stats["damage_mult_per_level"])) * 100.0))
		if en:
			lines.append("-%d%% Damage per level" % penalty_pct)
		else:
			lines.append("레벨당 피해 -%d%%" % penalty_pct)
	if stats.has("sword_crit_chance_bonus"):
		var bonus_pct := int(round(float(stats["sword_crit_chance_bonus"]) * 100.0))
		if en:
			lines.append("+%d%% Critical Hit Chance with Swords" % bonus_pct)
		else:
			lines.append("검 장착 시 치명타 확률 +%d%%" % bonus_pct)
	_append_grant_tags(lines, stats)
	for stat_key in stats:
		if stat_key in _STAT_SKIP_KEYS:
			continue
		lines.append("%s: %s" % [stat_key, str(stats[stat_key])])
	return lines


static func build_gear_tooltip(gear: GearData, slot_label: String) -> String:
	var lines: PackedStringArray = []
	lines.append("[color=#ffdd55]%s[/color]" % gear.get_display_name_localized())
	lines.append(UiLocale.t(&"inventory.gear_slot") % slot_label)
	var attunement_line := format_attunement_line(gear.attunement)
	if not attunement_line.is_empty():
		lines.append(attunement_line)
	lines.append_array(format_stat_lines(gear.stat_modifiers))
	var effect_text := gear.get_effect_localized()
	if not effect_text.is_empty():
		lines.append(effect_text)
	return "\n".join(lines)


static func _append_grant_tags(lines: PackedStringArray, stats: Dictionary) -> void:
	var en := UiLocale.get_locale() == UiLocale.LOCALE_EN
	if stats.has("grant_orbital"):
		if en:
			lines.append("Grants orbital: %s" % String(stats["grant_orbital"]))
		else:
			lines.append("궤도 부여: %s" % String(stats["grant_orbital"]))
	if stats.has("grant_on_dash"):
		if en:
			lines.append("On Dash: %s" % String(stats["grant_on_dash"]))
		else:
			lines.append("대시 시: %s" % String(stats["grant_on_dash"]))
	if stats.has("grant_on_hit"):
		if en:
			lines.append("On Hit: %s" % String(stats["grant_on_hit"]))
		else:
			lines.append("적중 시: %s" % String(stats["grant_on_hit"]))


static func _append_min_max_stat(
	lines: PackedStringArray,
	stats: Dictionary,
	min_key: String,
	max_key: String,
	label_en: String,
	label_ko: String
) -> void:
	if not stats.has(min_key) or not stats.has(max_key):
		return
	var en := UiLocale.get_locale() == UiLocale.LOCALE_EN
	lines.append(
		"+%d/%d %s" % [int(stats[min_key]), int(stats[max_key]), label_en if en else label_ko]
	)


static func _append_mult_bonus_line(
	lines: PackedStringArray,
	stats: Dictionary,
	key: String,
	label_en: String,
	label_ko: String
) -> void:
	if not stats.has(key):
		return
	var mult: float = float(stats[key])
	var bonus_pct := int(round((mult - 1.0) * 100.0))
	var en := UiLocale.get_locale() == UiLocale.LOCALE_EN
	lines.append("+%d%% %s" % [bonus_pct, label_en if en else label_ko])


static func _format_seconds(sec: float) -> String:
	if is_equal_approx(sec, snapped(sec, 1.0)):
		return str(int(sec))
	return "%.2f" % sec
