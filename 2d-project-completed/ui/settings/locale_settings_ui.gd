extends VBoxContainer

## 일시정지 설정 — 언어 선택.

var _language_option: OptionButton
var _language_title: Label
var _row_label: Label

var _locale_ids: PackedStringArray = []
var _syncing := false


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	if not _bind_nodes():
		return
	_build_language_options()
	_language_option.item_selected.connect(_on_language_selected)
	sync_from_locale()
	refresh_locale()


# class_name LocaleSettings(RefCounted)와 노드명 충돌·프리팹 인스턴스에서 % 실패를 피하기 위해 자식을 이름으로 탐색합니다.
func _bind_nodes() -> bool:
	_language_option = find_child("LanguageOption", true, false) as OptionButton
	_language_title = find_child("LanguageTitle", true, false) as Label
	_row_label = find_child("LanguageRowLabel", true, false) as Label
	if _language_option == null:
		push_error("LocaleSettingsUi: LanguageOption not found under %s" % get_path())
		return false
	return true


func sync_from_locale() -> void:
	if _language_option == null:
		return
	_syncing = true
	var locale := String(LocaleSettings.read_current()[LocaleSettings.KEY_LOCALE])
	var index := _locale_ids.find(locale)
	if index < 0:
		index = 0
	_language_option.select(index)
	_syncing = false


func refresh_locale() -> void:
	if not is_node_ready() or _language_option == null:
		return
	if _language_title:
		_language_title.text = UiLocale.t(&"settings.language")
	if _row_label:
		_row_label.text = UiLocale.t(&"settings.language")


func _build_language_options() -> void:
	if _language_option == null:
		return
	_language_option.clear()
	_locale_ids = UiLocale.get_available_locales()
	for locale_id in _locale_ids:
		_language_option.add_item(UiLocale.get_language_display_name(locale_id))


func _on_language_selected(index: int) -> void:
	if _syncing or index < 0 or index >= _locale_ids.size():
		return
	LocaleSettings.apply(_locale_ids[index])
