class_name GameplaySettings
extends RefCounted

## 게임플레이 옵션 저장·적용. 원거리 몹 AttackRangeRing·플로팅 데미지 텍스트 등.

const SAVE_PATH := "user://gameplay_settings.cfg"
const KEY_SHOW_RANGED_ATTACK_RANGE := "show_ranged_attack_range"
const KEY_SHOW_FLOATING_DAMAGE := "show_floating_damage"
const KEY_SHOW_MOB_HEALTH_BAR := "show_mob_health_bar"
const DEFAULT_SHOW_RANGED_ATTACK_RANGE := true
const DEFAULT_SHOW_FLOATING_DAMAGE := true
const DEFAULT_SHOW_MOB_HEALTH_BAR := true

static var _show_ranged_attack_range := DEFAULT_SHOW_RANGED_ATTACK_RANGE
static var _show_floating_damage := DEFAULT_SHOW_FLOATING_DAMAGE
static var _show_mob_health_bar := DEFAULT_SHOW_MOB_HEALTH_BAR


# 저장 파일 없음 → 기본값(true)으로 apply.
static func load_and_apply() -> void:
	var data := _load_file()
	apply(
		bool(data.get(KEY_SHOW_RANGED_ATTACK_RANGE, DEFAULT_SHOW_RANGED_ATTACK_RANGE)),
		bool(data.get(KEY_SHOW_FLOATING_DAMAGE, DEFAULT_SHOW_FLOATING_DAMAGE)),
		bool(data.get(KEY_SHOW_MOB_HEALTH_BAR, DEFAULT_SHOW_MOB_HEALTH_BAR))
	)


static func apply(
	show_ranged_attack_range: bool,
	show_floating_damage: bool,
	show_mob_health_bar: bool
) -> void:
	_show_ranged_attack_range = show_ranged_attack_range
	_show_floating_damage = show_floating_damage
	_show_mob_health_bar = show_mob_health_bar
	_save(show_ranged_attack_range, show_floating_damage, show_mob_health_bar)
	_refresh_mob_visuals()


static func is_ranged_attack_range_visible() -> bool:
	return _show_ranged_attack_range


static func is_floating_damage_visible() -> bool:
	return _show_floating_damage


static func is_mob_health_bar_visible() -> bool:
	return _show_mob_health_bar


static func read_current() -> Dictionary:
	return {
		KEY_SHOW_RANGED_ATTACK_RANGE: _show_ranged_attack_range,
		KEY_SHOW_FLOATING_DAMAGE: _show_floating_damage,
		KEY_SHOW_MOB_HEALTH_BAR: _show_mob_health_bar,
	}


static func _refresh_mob_visuals() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("mobs"):
		if node is Mob:
			var mob := node as Mob
			mob.refresh_attack_range_ring()
			mob.refresh_health_bar_visibility()


static func _save(
	show_ranged_attack_range: bool,
	show_floating_damage: bool,
	show_mob_health_bar: bool
) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gameplay", KEY_SHOW_RANGED_ATTACK_RANGE, show_ranged_attack_range)
	cfg.set_value("gameplay", KEY_SHOW_FLOATING_DAMAGE, show_floating_damage)
	cfg.set_value("gameplay", KEY_SHOW_MOB_HEALTH_BAR, show_mob_health_bar)
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


static func _load_file() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return {
		KEY_SHOW_RANGED_ATTACK_RANGE: cfg.get_value(
			"gameplay",
			KEY_SHOW_RANGED_ATTACK_RANGE,
			DEFAULT_SHOW_RANGED_ATTACK_RANGE
		),
		KEY_SHOW_FLOATING_DAMAGE: cfg.get_value(
			"gameplay",
			KEY_SHOW_FLOATING_DAMAGE,
			DEFAULT_SHOW_FLOATING_DAMAGE
		),
		KEY_SHOW_MOB_HEALTH_BAR: cfg.get_value(
			"gameplay",
			KEY_SHOW_MOB_HEALTH_BAR,
			DEFAULT_SHOW_MOB_HEALTH_BAR
		),
	}
