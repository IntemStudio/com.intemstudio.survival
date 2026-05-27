extends VBoxContainer

## 테스트 아레나 탭 바 — 행당 최대 4칸 고정 너비, 5개부터 다음 줄.

const MAX_TABS_PER_ROW := 4
const TAB_BAR_ROW_HEIGHT := 36.0

@export var tab_container: NodePath = ^"../TestPanelsTab"

var _tab_container: TabContainer
var _row0: HBoxContainer
var _row1: HBoxContainer
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	_tab_container = get_node(tab_container) as TabContainer
	if _tab_container == null:
		push_error("TestArenaTabBar: TabContainer not found.")
		return
	_tab_container.tabs_visible = false
	_build_row_hosts()
	rebuild_tabs()
	resized.connect(_update_tab_button_widths)
	_tab_container.tab_changed.connect(_on_tab_container_changed)


func rebuild_tabs() -> void:
	if _tab_container == null:
		return
	_clear_tab_buttons()
	_tab_buttons.clear()

	var tab_count := _tab_container.get_tab_count()
	for tab_index in tab_count:
		var button := _create_tab_button(tab_index)
		_tab_buttons.append(button)
		if tab_index < MAX_TABS_PER_ROW:
			_row0.add_child(button)
		else:
			_row1.add_child(button)

	_row1.visible = tab_count > MAX_TABS_PER_ROW
	_update_tab_button_widths()
	_sync_selected_tab_visual()


func _build_row_hosts() -> void:
	_row0 = HBoxContainer.new()
	_row0.add_theme_constant_override("separation", 4)
	_row0.custom_minimum_size.y = TAB_BAR_ROW_HEIGHT
	add_child(_row0)

	_row1 = HBoxContainer.new()
	_row1.add_theme_constant_override("separation", 4)
	_row1.custom_minimum_size.y = TAB_BAR_ROW_HEIGHT
	_row1.visible = false
	add_child(_row1)


func _create_tab_button(tab_index: int) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = _tab_container.get_tab_title(tab_index)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_on_tab_button_pressed.bind(tab_index))
	return button


func _on_tab_button_pressed(tab_index: int) -> void:
	if _tab_container == null:
		return
	_tab_container.current_tab = tab_index
	_sync_selected_tab_visual()


func _on_tab_container_changed(_tab: int) -> void:
	_sync_selected_tab_visual()


func _sync_selected_tab_visual() -> void:
	if _tab_container == null:
		return
	var current := _tab_container.current_tab
	for tab_index in _tab_buttons.size():
		_tab_buttons[tab_index].button_pressed = tab_index == current


func _update_tab_button_widths() -> void:
	var host_width := size.x
	if host_width <= 0.0:
		return
	var tab_width := host_width / float(MAX_TABS_PER_ROW)
	for button in _tab_buttons:
		button.custom_minimum_size = Vector2(tab_width, TAB_BAR_ROW_HEIGHT)


func _clear_tab_buttons() -> void:
	for row in [_row0, _row1]:
		if row == null:
			continue
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
