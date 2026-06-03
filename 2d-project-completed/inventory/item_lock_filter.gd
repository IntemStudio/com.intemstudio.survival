class_name ItemLockFilter
extends RefCounted

## 카탈로그 아이템 잠금 상태 필터 — 전체/해금/잠금.

const MODE_ALL := 0
const MODE_UNLOCKED := 1
const MODE_LOCKED := 2


static func populate_option_button(option: OptionButton) -> void:
	option.clear()
	option.add_item("전체")
	option.add_item("해금")
	option.add_item("잠금")
	option.select(MODE_ALL)


static func get_mode(option: OptionButton) -> int:
	if option == null:
		return MODE_ALL
	return option.selected


static func matches(is_locked: bool, mode: int) -> bool:
	match mode:
		MODE_UNLOCKED:
			return not is_locked
		MODE_LOCKED:
			return is_locked
		_:
			return true
