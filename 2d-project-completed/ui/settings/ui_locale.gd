class_name UiLocale
extends RefCounted

## UI 문자열 로케일(ko/en). `LocaleSettings.apply` 후 `ui_locale_refresh` 그룹이 `refresh_locale()` 호출.

const GROUP_REFRESH := &"ui_locale_refresh"

const LOCALE_KO := "ko"
const LOCALE_EN := "en"

const TABLE: Dictionary = {
	LOCALE_KO: {
		"pause.title": "일시정지",
		"pause.owned_weapons": "보유 무기 · 피해량",
		"pause.no_weapons": "보유 무기 없음",
		"pause.continue": "계속하기",
		"pause.settings": "설정",
		"pause.restart": "다시하기",
		"pause.quit": "게임 종료",
		"pause.back": "돌아가기",
		"settings.title": "설정",
		"settings.language": "언어",
		"settings.video": "화면 / 비디오",
		"settings.resolution": "해상도",
		"settings.window_mode": "화면 모드",
		"settings.vsync": "VSync",
		"window.windowed": "윈도우",
		"window.borderless": "테두리 없는 전체화면",
		"window.fullscreen": "전체 화면",
		"vsync.off": "끔",
		"vsync.on": "켜짐",
		"settings.audio": "오디오",
		"settings.master": "전체 (Master)",
		"settings.bgm": "BGM",
		"settings.sfx": "SFX",
		"settings.gameplay": "게임 플레이",
		"settings.ranged_range": "원거리 몬스터 공격 범위 표시",
		"settings.floating_damage": "플로팅 데미지 표시",
		"settings.mob_health_bar": "몬스터 체력 게이지 표시",
		"settings.tree_density": "소나무 밀도",
		"tree.sparse": "적음",
		"tree.dense": "많음",
		"tree.density_value": "밀도 %d%% · 간격 %.0f",
		"language.korean": "한국어",
		"language.english": "English",
		"gameover.fail": "Game Over",
		"gameover.clear": "클리어!",
		"gameover.weapon_damage": "무기별 피해량",
		"gameover.no_damage": "기록된 피해 없음",
		"gameover.restart": "다시시작",
		"hud.kills": "처치: %d",
		"hud.time": "%02d분 %02d초",
		"hud.balance_phase": "밸런스 구간",
		"hud.balance_notice": "%d분 · %s",
		"hud.balance_segment_final": "%.0f분 · 최종 구간",
		"hud.balance_segment_progress": "%.1f / %.0f분",
		"hud.auto_attack_on": "자동 공격: ON (F)",
		"hud.auto_attack_off": "자동 공격: OFF (F)",
		"weapon_select.title": "무기 선택",
		"weapon_select.level_up": "레벨 업! 무기 선택",
		"weapon_select.auto_toggle": "자동 무기 선택",
		"weapon_select.auto_priority_title": "자동 선택 우선순위 (위일수록 먼저)",
		"weapon_select.detail_hint": "버튼에 마우스를 올리면 설명이 표시됩니다.",
		"weapon_select.discarded_title": "버린 무기",
		"weapon_select.discarded_none": "(없음)",
		"weapon_select.discard": "버리기",
		"weapon_select.reroll_remaining": "리롤 (%d회 남음)",
		"weapon_select.auto_countdown": "자동 선택까지 %.1f초",
		"weapon_type.ranged": "원거리",
		"weapon_type.magic": "마법",
		"weapon_type.melee": "근접",
	},
	LOCALE_EN: {
		"pause.title": "Paused",
		"pause.owned_weapons": "Owned Weapons · Damage",
		"pause.no_weapons": "No owned weapons",
		"pause.continue": "Continue",
		"pause.settings": "Settings",
		"pause.restart": "Restart",
		"pause.quit": "Quit Game",
		"pause.back": "Back",
		"settings.title": "Settings",
		"settings.language": "Language",
		"settings.video": "Video",
		"settings.resolution": "Resolution",
		"settings.window_mode": "Window Mode",
		"settings.vsync": "VSync",
		"window.windowed": "Windowed",
		"window.borderless": "Borderless Fullscreen",
		"window.fullscreen": "Fullscreen",
		"vsync.off": "Off",
		"vsync.on": "On",
		"settings.audio": "Audio",
		"settings.master": "Master",
		"settings.bgm": "BGM",
		"settings.sfx": "SFX",
		"settings.gameplay": "Gameplay",
		"settings.ranged_range": "Show ranged mob attack range",
		"settings.floating_damage": "Show floating damage numbers",
		"settings.mob_health_bar": "Show mob health bars",
		"settings.tree_density": "Tree Density",
		"tree.sparse": "Sparse",
		"tree.dense": "Dense",
		"tree.density_value": "Density %d%% · spacing %.0f",
		"language.korean": "한국어",
		"language.english": "English",
		"gameover.fail": "Game Over",
		"gameover.clear": "Stage Clear!",
		"gameover.weapon_damage": "Damage by Weapon",
		"gameover.no_damage": "No damage recorded",
		"gameover.restart": "Restart",
		"hud.kills": "Kills: %d",
		"hud.time": "%02d:%02d",
		"hud.balance_phase": "Balance phase",
		"hud.balance_notice": "Min %d · %s",
		"hud.balance_segment_final": "%.0f min · Final segment",
		"hud.balance_segment_progress": "%.1f / %.0f min",
		"hud.auto_attack_on": "Auto Attack: ON (F)",
		"hud.auto_attack_off": "Auto Attack: OFF (F)",
		"weapon_select.title": "Weapon Select",
		"weapon_select.level_up": "Level Up! Choose a Weapon",
		"weapon_select.auto_toggle": "Auto Weapon Select",
		"weapon_select.auto_priority_title": "Auto-select priority (top first)",
		"weapon_select.detail_hint": "Hover a weapon button for details.",
		"weapon_select.discarded_title": "Discarded Weapons",
		"weapon_select.discarded_none": "(none)",
		"weapon_select.discard": "Discard",
		"weapon_select.reroll_remaining": "Reroll (%d left)",
		"weapon_select.auto_countdown": "Auto-select in %.1fs",
		"weapon_type.ranged": "Ranged",
		"weapon_type.magic": "Magic",
		"weapon_type.melee": "Melee",
	},
}

static var _locale: String = LOCALE_KO


static func get_locale() -> String:
	return _locale


static func get_available_locales() -> PackedStringArray:
	return PackedStringArray([LOCALE_KO, LOCALE_EN])


# 언어 선택 목록에 표시할 고유 이름(각 로케일 고정 라벨).
static func get_language_display_name(locale: String) -> String:
	var key := "language.korean" if locale == LOCALE_KO else "language.english"
	var bucket: Dictionary = TABLE.get(locale, TABLE[LOCALE_KO])
	return String(bucket.get(key, locale))


static func set_locale(locale: String) -> void:
	if not TABLE.has(locale):
		locale = LOCALE_KO
	_locale = locale
	TranslationServer.set_locale(locale)


static func t(key: StringName) -> String:
	var bucket: Dictionary = TABLE.get(_locale, TABLE[LOCALE_KO])
	return String(bucket.get(String(key), key))


static func weapon_type_label(weapon_type: String) -> String:
	match weapon_type:
		"Ranged":
			return t(&"weapon_type.ranged")
		"Magic":
			return t(&"weapon_type.magic")
		"Melee":
			return t(&"weapon_type.melee")
		_:
			return weapon_type


static func format_hud_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var secs := total % 60
	return t(&"hud.time") % [minutes, secs]


static func format_balance_notice(minute_int: int, intent: String) -> String:
	if minute_int <= 0:
		return intent
	return t(&"hud.balance_notice") % [minute_int, intent]


static func format_balance_segment_final(elapsed_minutes: float) -> String:
	return t(&"hud.balance_segment_final") % elapsed_minutes


static func format_balance_segment_progress(elapsed_minutes: float, next_minute: float) -> String:
	return t(&"hud.balance_segment_progress") % [elapsed_minutes, next_minute]


static func notify_refresh() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.call_group(GROUP_REFRESH, &"refresh_locale")
