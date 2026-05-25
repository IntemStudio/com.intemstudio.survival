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
		"lobby.title": "Survival",
		"lobby.start": "게임 시작",
		"lobby.start_survival": "서바이벌 시작",
		"lobby.start_arena": "아레나 시작",
		"lobby.quit": "게임 종료",
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
		"settings.melee_range": "근거리 몬스터 공격 범위 표시",
		"settings.primary_weapon_range": "첫 번째 무기 사거리 표시",
		"settings.floating_damage": "플로팅 데미지 표시",
		"settings.mob_health_bar": "몬스터 체력 게이지 표시",
		"settings.default_auto_target": "자동 타겟 (게임 시작 시)",
		"settings.default_auto_attack": "자동 공격 (게임 시작 시)",
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
		"hud.auto_target_on": "자동 타겟: ON (F)",
		"hud.auto_target_off": "자동 타겟: OFF (F)",
		"hud.auto_attack_on": "자동 공격: ON (G)",
		"hud.auto_attack_off": "자동 공격: OFF (G)",
		"weapon_select.title": "무기 선택",
		"weapon_select.level_up": "레벨 업! 무기 선택",
		"weapon_select.arena_wave_clear": "웨이브 클리어! 무기 선택",
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
		"inventory.title": "인벤토리",
		"inventory.bag_title": "소지품",
		"inventory.close": "닫기",
		"inventory.set_tab": "편집 %d",
		"inventory.col_weapon": "무기",
		"inventory.col_armor": "방어구",
		"inventory.col_offhand": "보조",
		"inventory.combat_weapon": "무기 %d",
		"inventory.combat_offhand": "보조 %d",
		"inventory.armor_edit": "방어구 · 세트 %d",
		"inventory.active_set": "● 전투 세트: %d",
		"inventory.hud_combat_set": "전투 세트 %d",
		"inventory.set_swapped": "전투 세트 %d",
		"inventory.hint": "I: 인벤 · W: 전투 세트 전환(↑는 방향키) · 가방 우클릭/더블클릭: 장착 · 장비 우클릭: 해제 · 드래그: 이동 · 비활성 무기/보조 좌클릭: 세트 편집",
		"inventory.detail_empty": "아이템에 마우스를 올리세요.",
		"inventory.gear_slot": "슬롯: %s",
		"inventory.error.empty": "빈 칸입니다.",
		"inventory.error.invalid_slot": "이 슬롯에 장착할 수 없습니다.",
		"inventory.error.bag_full": "가방이 가득 찼습니다.",
		"inventory.error.two_hand_bag_full": "양손 무기로 바꾸려면 가방에 빈 칸이 더 필요합니다. (무기·보조가 모두 찬 상태)",
		"inventory.error.offhand_blocked": "양손 무기를 들고 있어 보조손을 쓸 수 없습니다.",
		"inventory.error.unknown_item": "알 수 없는 아이템입니다.",
		"inventory.error.cross_set": "다른 전투 세트 슬롯과는 바꿀 수 없습니다.",
		"inventory.combat_active_slot": "현재 전투 세트 슬롯입니다.",
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
		"lobby.title": "Survival",
		"lobby.start": "Start Game",
		"lobby.start_survival": "Start Survival",
		"lobby.start_arena": "Start Arena",
		"lobby.quit": "Quit Game",
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
		"settings.melee_range": "Show melee mob attack range",
		"settings.primary_weapon_range": "Show primary weapon attack range",
		"settings.floating_damage": "Show floating damage numbers",
		"settings.mob_health_bar": "Show mob health bars",
		"settings.default_auto_target": "Auto target (on game start)",
		"settings.default_auto_attack": "Auto attack (on game start)",
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
		"hud.auto_target_on": "Auto Target: ON (F)",
		"hud.auto_target_off": "Auto Target: OFF (F)",
		"hud.auto_attack_on": "Auto Attack: ON (G)",
		"hud.auto_attack_off": "Auto Attack: OFF (G)",
		"weapon_select.title": "Weapon Select",
		"weapon_select.level_up": "Level Up! Choose a Weapon",
		"weapon_select.arena_wave_clear": "Wave Clear! Choose a Weapon",
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
		"inventory.title": "Inventory",
		"inventory.bag_title": "Bag",
		"inventory.close": "Close",
		"inventory.set_tab": "Edit %d",
		"inventory.col_weapon": "Weapon",
		"inventory.col_armor": "Armor",
		"inventory.col_offhand": "Offhand",
		"inventory.combat_weapon": "Weapon %d",
		"inventory.combat_offhand": "Off %d",
		"inventory.armor_edit": "Armor · Set %d",
		"inventory.active_set": "● Active set: %d",
		"inventory.hud_combat_set": "Combat set %d",
		"inventory.set_swapped": "Combat set %d",
		"inventory.hint": "I: inventory · W: swap combat set (↑ = arrow keys) · Bag RMB/double-click: equip · Gear RMB: unequip · Drag: move · Click inactive weapon/off: edit set",
		"inventory.detail_empty": "Hover an item for details.",
		"inventory.gear_slot": "Slot: %s",
		"inventory.error.empty": "Empty slot.",
		"inventory.error.invalid_slot": "Cannot equip in this slot.",
		"inventory.error.bag_full": "Bag is full.",
		"inventory.error.two_hand_bag_full": "Not enough bag space to swap for a two-handed weapon (weapon and offhand are full).",
		"inventory.error.offhand_blocked": "Two-handed weapon blocks offhand.",
		"inventory.error.unknown_item": "Unknown item.",
		"inventory.error.cross_set": "Cannot swap with another combat set slot.",
		"inventory.combat_active_slot": "Current combat set slot.",
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
