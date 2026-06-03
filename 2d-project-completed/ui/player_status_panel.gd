extends Control

## 플레이어 경험치·체력을 화면 왼쪽 하단에 표시합니다. (경험치 위, 체력 아래)

const PlayerDebuffCatalogScript = preload("res://elite/player_debuff_catalog.gd")
const EliteBlazingConstantsScript = preload("res://elite/elite_blazing_constants.gd")

const BASE_HEIGHT := 78.0
const BURN_ROW_EXTRA := 28.0


func _ready() -> void:
	%BurnNameLabel.text = PlayerDebuffCatalogScript.get_display_name(
		EliteBlazingConstantsScript.PLAYER_DEBUFF_ID
	)
	_sync_panel_height()


func set_health(current: float, maximum: float) -> void:
	var max_value: float = maxf(maximum, 1.0)
	%HealthBar.max_value = max_value
	%HealthBar.value = clampf(current, 0.0, max_value)
	%HealthLabel.text = "%d / %d" % [int(round(current)), int(round(max_value))]


func get_health_max() -> float:
	return %HealthBar.max_value


func set_experience(current: int, to_level: int, current_level: int) -> void:
	var cap: int = maxi(to_level, 1)
	%ExperienceBar.max_value = cap
	%ExperienceBar.value = clampi(current, 0, cap)
	%LevelLabel.text = "Lv. %d" % current_level
	%ExpLabel.text = "%d / %d" % [current, cap]


func set_burn_active(active: bool, remaining_sec: float = 0.0) -> void:
	%BurnRow.visible = active
	if active and remaining_sec > 0.0:
		%BurnTimerLabel.text = "%.1fs" % remaining_sec
	else:
		%BurnTimerLabel.text = ""
	_sync_panel_height()


func _sync_panel_height() -> void:
	var height: float = BASE_HEIGHT
	if %BurnRow.visible:
		height += BURN_ROW_EXTRA
	custom_minimum_size.y = height
	if anchor_top == 1.0 and is_equal_approx(anchor_bottom, 1.0):
		offset_top = offset_bottom - height
