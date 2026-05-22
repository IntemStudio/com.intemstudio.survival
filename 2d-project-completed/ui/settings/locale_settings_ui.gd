extends VBoxContainer

## 일시정지 설정 — 언어 선택.

@onready var _language_option: OptionButton = %LanguageOption

var _locale_ids: PackedStringArray = []
var _syncing := false


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_build_language_options()
	_language_option.item_selected.connect(_on_language_selected)
	sync_from_locale()
	refresh_locale()


func sync_from_locale() -> void:
	_syncing = true
	var locale := String(LocaleSettings.read_current()[LocaleSettings.KEY_LOCALE])
	var index := _locale_ids.find(locale)
	if index < 0:
		index = 0
	_language_option.select(index)
	_syncing = false


func refresh_locale() -> void:
	if not is_node_ready():
		return
	%LanguageTitle.text = UiLocale.t(&"settings.language")
	if has_node("LanguageRow/LanguageRowLabel"):
		get_node("LanguageRow/LanguageRowLabel").text = UiLocale.t(&"settings.language")


func _build_language_options() -> void:
	_language_option.clear()
	_locale_ids = UiLocale.get_available_locales()
	for locale_id in _locale_ids:
		_language_option.add_item(UiLocale.get_language_display_name(locale_id))


func _on_language_selected(index: int) -> void:
	if _syncing or index < 0 or index >= _locale_ids.size():
		return
	LocaleSettings.apply(_locale_ids[index])
