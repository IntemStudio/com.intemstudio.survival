class_name GameplaySettings
extends RefCounted

## 게임플레이 옵션 저장·적용. 몹 AttackRangeRing·첫 무기 사거리 링·플로팅 데미지 텍스트 등.

const SAVE_PATH := "user://gameplay_settings.cfg"
const KEY_SHOW_RANGED_ATTACK_RANGE := "show_ranged_attack_range"
const KEY_SHOW_MELEE_ATTACK_RANGE := "show_melee_attack_range"
const KEY_SHOW_CHASE_SKILL_RANGE := "show_chase_skill_range"
const KEY_SHOW_PRIMARY_WEAPON_RANGE := "show_primary_weapon_range"
const KEY_SHOW_FLOATING_DAMAGE := "show_floating_damage"
const KEY_SHOW_MOB_HEALTH_BAR := "show_mob_health_bar"
const KEY_DEFAULT_AUTO_TARGET := "default_auto_target"
const KEY_DEFAULT_AUTO_ATTACK := "default_auto_attack"
const DEFAULT_SHOW_RANGED_ATTACK_RANGE := true
const DEFAULT_SHOW_MELEE_ATTACK_RANGE := true
const DEFAULT_SHOW_CHASE_SKILL_RANGE := true
const DEFAULT_SHOW_PRIMARY_WEAPON_RANGE := true
const DEFAULT_SHOW_FLOATING_DAMAGE := true
const DEFAULT_SHOW_MOB_HEALTH_BAR := true
const DEFAULT_AUTO_TARGET := true
const DEFAULT_AUTO_ATTACK := true

static var _show_ranged_attack_range := DEFAULT_SHOW_RANGED_ATTACK_RANGE
static var _show_melee_attack_range := DEFAULT_SHOW_MELEE_ATTACK_RANGE
static var _show_chase_skill_range := DEFAULT_SHOW_CHASE_SKILL_RANGE
static var _show_primary_weapon_range := DEFAULT_SHOW_PRIMARY_WEAPON_RANGE
static var _show_floating_damage := DEFAULT_SHOW_FLOATING_DAMAGE
static var _show_mob_health_bar := DEFAULT_SHOW_MOB_HEALTH_BAR
static var _default_auto_target := DEFAULT_AUTO_TARGET
static var _default_auto_attack := DEFAULT_AUTO_ATTACK


# 저장 파일 없음 → 기본값(true)으로 apply.
static func load_and_apply() -> void:
	var data := _load_file()
	apply(
		bool(data.get(KEY_SHOW_RANGED_ATTACK_RANGE, DEFAULT_SHOW_RANGED_ATTACK_RANGE)),
		bool(data.get(KEY_SHOW_MELEE_ATTACK_RANGE, DEFAULT_SHOW_MELEE_ATTACK_RANGE)),
		bool(data.get(KEY_SHOW_CHASE_SKILL_RANGE, DEFAULT_SHOW_CHASE_SKILL_RANGE)),
		bool(data.get(KEY_SHOW_PRIMARY_WEAPON_RANGE, DEFAULT_SHOW_PRIMARY_WEAPON_RANGE)),
		bool(data.get(KEY_SHOW_FLOATING_DAMAGE, DEFAULT_SHOW_FLOATING_DAMAGE)),
		bool(data.get(KEY_SHOW_MOB_HEALTH_BAR, DEFAULT_SHOW_MOB_HEALTH_BAR)),
		bool(data.get(KEY_DEFAULT_AUTO_TARGET, DEFAULT_AUTO_TARGET)),
		bool(data.get(KEY_DEFAULT_AUTO_ATTACK, DEFAULT_AUTO_ATTACK))
	)


static func apply(
	show_ranged_attack_range: bool,
	show_melee_attack_range: bool,
	show_chase_skill_range: bool,
	show_primary_weapon_range: bool,
	show_floating_damage: bool,
	show_mob_health_bar: bool,
	default_auto_target: bool,
	default_auto_attack: bool
) -> void:
	_show_ranged_attack_range = show_ranged_attack_range
	_show_melee_attack_range = show_melee_attack_range
	_show_chase_skill_range = show_chase_skill_range
	_show_primary_weapon_range = show_primary_weapon_range
	_show_floating_damage = show_floating_damage
	_show_mob_health_bar = show_mob_health_bar
	_default_auto_target = default_auto_target
	_default_auto_attack = default_auto_attack
	_save(
		show_ranged_attack_range,
		show_melee_attack_range,
		show_chase_skill_range,
		show_primary_weapon_range,
		show_floating_damage,
		show_mob_health_bar,
		default_auto_target,
		default_auto_attack
	)
	_refresh_mob_visuals()
	_refresh_player_weapon_visuals()


static func is_ranged_attack_range_visible() -> bool:
	return _show_ranged_attack_range


static func is_melee_attack_range_visible() -> bool:
	return _show_melee_attack_range


static func is_chase_skill_range_visible() -> bool:
	return _show_chase_skill_range


static func is_primary_weapon_range_visible() -> bool:
	return _show_primary_weapon_range


static func is_floating_damage_visible() -> bool:
	return _show_floating_damage


static func is_mob_health_bar_visible() -> bool:
	return _show_mob_health_bar


static func is_default_auto_target_enabled() -> bool:
	return _default_auto_target


static func is_default_auto_attack_enabled() -> bool:
	return _default_auto_attack


static func read_current() -> Dictionary:
	return {
		KEY_SHOW_RANGED_ATTACK_RANGE: _show_ranged_attack_range,
		KEY_SHOW_MELEE_ATTACK_RANGE: _show_melee_attack_range,
		KEY_SHOW_CHASE_SKILL_RANGE: _show_chase_skill_range,
		KEY_SHOW_PRIMARY_WEAPON_RANGE: _show_primary_weapon_range,
		KEY_SHOW_FLOATING_DAMAGE: _show_floating_damage,
		KEY_SHOW_MOB_HEALTH_BAR: _show_mob_health_bar,
		KEY_DEFAULT_AUTO_TARGET: _default_auto_target,
		KEY_DEFAULT_AUTO_ATTACK: _default_auto_attack,
	}


static func _refresh_mob_visuals() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("mobs"):
		if node is Mob:
			var mob := node as Mob
			mob.refresh_attack_range_ring()
			mob.refresh_chase_skill_range_rings()
			mob.refresh_health_bar_visibility()


static func _refresh_player_weapon_visuals() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var game := tree.root.get_node_or_null("Game")
	if game == null:
		return
	var player := game.get_node_or_null("Player")
	if player and player.has_method("refresh_primary_weapon_range_ring"):
		player.refresh_primary_weapon_range_ring()


static func _save(
	show_ranged_attack_range: bool,
	show_melee_attack_range: bool,
	show_chase_skill_range: bool,
	show_primary_weapon_range: bool,
	show_floating_damage: bool,
	show_mob_health_bar: bool,
	default_auto_target: bool,
	default_auto_attack: bool
) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gameplay", KEY_SHOW_RANGED_ATTACK_RANGE, show_ranged_attack_range)
	cfg.set_value("gameplay", KEY_SHOW_MELEE_ATTACK_RANGE, show_melee_attack_range)
	cfg.set_value("gameplay", KEY_SHOW_CHASE_SKILL_RANGE, show_chase_skill_range)
	cfg.set_value("gameplay", KEY_SHOW_PRIMARY_WEAPON_RANGE, show_primary_weapon_range)
	cfg.set_value("gameplay", KEY_SHOW_FLOATING_DAMAGE, show_floating_damage)
	cfg.set_value("gameplay", KEY_SHOW_MOB_HEALTH_BAR, show_mob_health_bar)
	cfg.set_value("gameplay", KEY_DEFAULT_AUTO_TARGET, default_auto_target)
	cfg.set_value("gameplay", KEY_DEFAULT_AUTO_ATTACK, default_auto_attack)
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
		KEY_SHOW_MELEE_ATTACK_RANGE: cfg.get_value(
			"gameplay",
			KEY_SHOW_MELEE_ATTACK_RANGE,
			DEFAULT_SHOW_MELEE_ATTACK_RANGE
		),
		KEY_SHOW_CHASE_SKILL_RANGE: cfg.get_value(
			"gameplay",
			KEY_SHOW_CHASE_SKILL_RANGE,
			DEFAULT_SHOW_CHASE_SKILL_RANGE
		),
		KEY_SHOW_PRIMARY_WEAPON_RANGE: cfg.get_value(
			"gameplay",
			KEY_SHOW_PRIMARY_WEAPON_RANGE,
			DEFAULT_SHOW_PRIMARY_WEAPON_RANGE
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
		KEY_DEFAULT_AUTO_TARGET: cfg.get_value(
			"gameplay",
			KEY_DEFAULT_AUTO_TARGET,
			DEFAULT_AUTO_TARGET
		),
		KEY_DEFAULT_AUTO_ATTACK: cfg.get_value(
			"gameplay",
			KEY_DEFAULT_AUTO_ATTACK,
			DEFAULT_AUTO_ATTACK
		),
	}
