extends VBoxContainer

## 일시정지 설정 — 게임플레이 옵션.

@onready var _ranged_range_toggle: CheckButton = $RangedRangeRow/ShowRangedAttackRangeToggle
@onready var _floating_damage_toggle: CheckButton = $FloatingDamageRow/ShowFloatingDamageToggle
@onready var _mob_health_bar_toggle: CheckButton = $MobHealthBarRow/ShowMobHealthBarToggle
@onready var _gameplay_title: Label = get_node_or_null("../GameplaySettingsTitle") as Label

var _syncing := false


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_ranged_range_toggle.toggled.connect(_on_option_toggled)
	_floating_damage_toggle.toggled.connect(_on_option_toggled)
	_mob_health_bar_toggle.toggled.connect(_on_option_toggled)
	sync_from_gameplay()
	refresh_locale()


func refresh_locale() -> void:
	if _gameplay_title:
		_gameplay_title.text = UiLocale.t(&"settings.gameplay")
	_ranged_range_toggle.text = UiLocale.t(&"settings.ranged_range")
	_floating_damage_toggle.text = UiLocale.t(&"settings.floating_damage")
	_mob_health_bar_toggle.text = UiLocale.t(&"settings.mob_health_bar")


# 저장·적용된 게임플레이 옵션으로 UI를 맞춥니다.
func sync_from_gameplay() -> void:
	_syncing = true
	var state := GameplaySettings.read_current()
	_ranged_range_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_RANGED_ATTACK_RANGE])
	)
	_floating_damage_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_FLOATING_DAMAGE])
	)
	_mob_health_bar_toggle.set_pressed_no_signal(
		bool(state[GameplaySettings.KEY_SHOW_MOB_HEALTH_BAR])
	)
	_syncing = false


func _on_option_toggled(_pressed: bool) -> void:
	if _syncing:
		return
	_apply_from_ui()


func _apply_from_ui() -> void:
	GameplaySettings.apply(
		_ranged_range_toggle.button_pressed,
		_floating_damage_toggle.button_pressed,
		_mob_health_bar_toggle.button_pressed
	)
