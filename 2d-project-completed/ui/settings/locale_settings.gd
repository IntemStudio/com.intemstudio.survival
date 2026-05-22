class_name LocaleSettings
extends RefCounted

## UI 언어(ko/en) 저장·적용.

const SAVE_PATH := "user://locale_settings.cfg"
const KEY_LOCALE := "locale"
const DEFAULT_LOCALE := UiLocale.LOCALE_KO


# 저장 파일 없음 → DEFAULT_LOCALE 적용(항상 apply).
static func load_and_apply() -> void:
	var data := _load_file()
	apply(String(data.get(KEY_LOCALE, DEFAULT_LOCALE)))


static func apply(locale: String) -> void:
	UiLocale.set_locale(locale)
	_save(locale)
	UiLocale.notify_refresh()


static func read_current() -> Dictionary:
	return {KEY_LOCALE: UiLocale.get_locale()}


static func _save(locale: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("locale", KEY_LOCALE, locale)
	SettingsSaveUtil.save_config(cfg, SAVE_PATH)


static func _load_file() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return {KEY_LOCALE: cfg.get_value("locale", KEY_LOCALE, DEFAULT_LOCALE)}
