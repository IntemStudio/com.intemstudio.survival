class_name GearStatMerge
extends RefCounted

## 장비 stat_modifiers 합산 규칙 — 배율은 곱, min/max·flat은 합, 불리언은 OR.

const _PAIR_BASES: Array[String] = [
	"block",
	"armor",
	"suppression",
	"defy_death",
	"heart",
	"mana",
	"flask",
	"revive",
	"dart_damage",
]

const _ADD_KEYS: Array[String] = [
	"power",
	"stamina",
	"curse",
	"strength",
	"dexterity",
	"intelligence",
	"weapon_upgrade_level",
	"sword_crit_chance_bonus",
	"damage_mult_per_level",
]

const _MAX_KEYS: Array[String] = [
	"invincibility_after_damage_sec",
	"invincibility_after_dash_sec",
]

const _BOOL_OR_KEYS: Array[String] = ["prevent_curse"]

const _TAG_LIST_KEYS: Array[String] = [
	"grant_orbital",
	"grant_on_dash",
	"grant_on_kill",
	"grant_on_wave_start",
	"grant_on_hit",
]


# 레거시 flat armor 등을 min/max 쌍으로 정규화합니다.
static func normalize_modifiers(modifiers: Dictionary) -> Dictionary:
	var out := modifiers.duplicate(true)
	if out.has("armor") and not out.has("armor_min"):
		var flat := int(out["armor"])
		out["armor_min"] = flat
		out["armor_max"] = flat
		out.erase("armor")
	return out


static func merge_into(totals: Dictionary, modifiers: Dictionary) -> void:
	var stats := normalize_modifiers(modifiers)
	var consumed: Dictionary = {}
	for base in _PAIR_BASES:
		var min_key := "%s_min" % base
		var max_key := "%s_max" % base
		if not stats.has(min_key) or not stats.has(max_key):
			continue
		_merge_add(totals, min_key, float(stats[min_key]))
		_merge_add(totals, max_key, float(stats[max_key]))
		consumed[min_key] = true
		consumed[max_key] = true
	for key in stats:
		if consumed.has(key):
			continue
		var value: Variant = stats[key]
		if _is_mult_key(key):
			_merge_multiply(totals, key, float(value))
		elif key in _ADD_KEYS:
			_merge_add(totals, key, float(value))
		elif key in _MAX_KEYS:
			_merge_max(totals, key, float(value))
		elif key in _BOOL_OR_KEYS:
			_merge_bool_or(totals, key, bool(value))
		elif key in _TAG_LIST_KEYS:
			_merge_tag_list(totals, key, String(value))
		else:
			push_warning("GearStatMerge: unknown stat key '%s' — last-wins" % key)
			totals[key] = value


static func _is_mult_key(key: String) -> bool:
	return key.ends_with("_mult") or key == "damage_mult"


static func _merge_add(totals: Dictionary, key: String, amount: float) -> void:
	totals[key] = float(totals.get(key, 0.0)) + amount


static func _merge_multiply(totals: Dictionary, key: String, mult: float) -> void:
	if totals.has(key):
		totals[key] = float(totals[key]) * mult
	else:
		totals[key] = mult


static func _merge_max(totals: Dictionary, key: String, value: float) -> void:
	if totals.has(key):
		totals[key] = maxf(float(totals[key]), value)
	else:
		totals[key] = value


static func _merge_bool_or(totals: Dictionary, key: String, value: bool) -> void:
	totals[key] = bool(totals.get(key, false)) or value


static func _merge_tag_list(totals: Dictionary, key: String, tag: String) -> void:
	if tag.is_empty():
		return
	var list: Array = totals.get(key, [])
	if tag not in list:
		list.append(tag)
	totals[key] = list
