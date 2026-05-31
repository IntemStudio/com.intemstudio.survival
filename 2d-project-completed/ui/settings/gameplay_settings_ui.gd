extends VBoxContainer

## 일시정지 설정 — 게임플레이 옵션.

@onready var _ranged_range_toggle: CheckButton = $RangedRangeRow/ShowRangedAttackRangeToggle
@onready var _melee_range_toggle: CheckButton = $MeleeRangeRow/ShowMeleeAttackRangeToggle
@onready var _chase_skill_range_toggle: CheckButton = (
	$ChaseSkillRangeRow/ShowChaseSkillRangeToggle
)
@onready var _primary_weapon_range_toggle: CheckButton = (
	$PrimaryWeaponRangeRow/ShowPrimaryWeaponRangeToggle
)
@onready var _floating_damage_toggle: CheckButton = $FloatingDamageRow/ShowFloatingDamageToggle
@onready var _mob_health_bar_toggle: CheckButton = $MobHealthBarRow/ShowMobHealthBarToggle
@onready var _default_auto_target_toggle: CheckButton = (
	$DefaultAutoTargetRow/ShowDefaultAutoTargetToggle
)
@onready var _default_auto_attack_toggle: CheckButton = (
	$DefaultAutoAttackRow/ShowDefaultAutoAttackToggle
)
@onready var _gameplay_title: Label = get_node_or_null("../GameplaySettingsTitle") as Label

var _syncing := false


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_ranged_range_toggle.toggled.connect(_on_option_toggled)
	_melee_range_toggle.toggled.connect(_on_option_toggled)
	_chase_skill_range_toggle.toggled.connect(_on_option_toggled)
	_primary_weapon_range_toggle.toggled.connect(_on_option_toggled)
	_floating_damage_toggle.toggled.connect(_on_option_toggled)
	_mob_health_bar_toggle.toggled.connect(_on_option_toggled)
	_default_auto_target_toggle.toggled.connect(_on_option_toggled)
	_default_auto_attack_toggle.toggled.connect(_on_option_toggled)
	sync_from_gameplay()
	refresh_locale()


func refresh_locale() -> void:
	if _gameplay_title:
		_gameplay_title.text = UiLocale.t(&"settings.gameplay")
	_ranged_range_toggle.text = UiLocale.t(&"settings.ranged_range")
	_melee_range_toggle.text = UiLocale.t(&"settings.melee_range")
	_chase_skill_range_toggle.text = UiLocale.t(&"settings.chase_skill_range")
	_primary_weapon_range_toggle.text = UiLocale.t(&"settings.primary_weapon_range")
	_floating_damage_toggle.text = UiLocale.t(&"settings.floating_damage")
	_mob_health_bar_toggle.text = UiLocale.t(&"settings.mob_health_bar")
	_default_auto_target_toggle.text = UiLocale.t(&"settings.default_auto_target")
	_default_auto_attack_toggle.text = UiLocale.t(&"settings.default_auto_attack")


# 저장·적용된 게임플레이 옵션으로 UI를 맞춥니다.
func sync_from_gameplay() -> void:
	_syncing = true
	var state := GameplaySettings.read_current()
	_ranged_range_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_RANGED_ATTACK_RANGE])
	)
	_melee_range_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_MELEE_ATTACK_RANGE])
	)
	_chase_skill_range_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_CHASE_SKILL_RANGE])
	)
	_primary_weapon_range_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_PRIMARY_WEAPON_RANGE])
	)
	_floating_damage_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_FLOATING_DAMAGE])
	)
	_mob_health_bar_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_MOB_HEALTH_BAR])
	)
	_default_auto_target_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_DEFAULT_AUTO_TARGET])
	)
	_default_auto_attack_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_DEFAULT_AUTO_ATTACK])
	)
	_syncing = false


func _on_option_toggled(_pressed: bool) -> void:
	if _syncing:
		return
	_apply_from_ui()


func _apply_from_ui() -> void:
	GameplaySettings.apply(
		_ranged_range_toggle.button_pressed,
		_melee_range_toggle.button_pressed,
		_chase_skill_range_toggle.button_pressed,
		_primary_weapon_range_toggle.button_pressed,
		_floating_damage_toggle.button_pressed,
		_mob_health_bar_toggle.button_pressed,
		_default_auto_target_toggle.button_pressed,
		_default_auto_attack_toggle.button_pressed
	)
