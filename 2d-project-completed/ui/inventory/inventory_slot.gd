extends PanelContainer
class_name InventorySlot

## 인벤 슬롯 1칸 — 아이콘·드래그·호버.

signal slot_hovered(slot_ref: InventorySlot)
signal slot_unhovered(slot_ref: InventorySlot)
signal slot_pressed(slot_ref: InventorySlot, mouse_button: int, left_shift_pressed: bool)
signal slot_dropped(source: Dictionary, target: InventorySlot)

const EMPTY_MODULATE := Color(0.45, 0.48, 0.55, 0.35)
const BLOCKED_MODULATE := Color(0.35, 0.35, 0.38, 0.55)
const INACTIVE_COMBAT_ICON := Color(0.55, 0.58, 0.65, 0.42)
const ACTIVE_COMBAT_PANEL := Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_COMBAT_PANEL := Color(0.72, 0.74, 0.78, 0.88)

@export var slot_label_text := ""

var bag_index := -1
var _drop_validator: Callable
var set_index := -1
var slot_key: StringName = &""
var item_id := ""
var blocked := false
var combat_active := true
var _left_shift_down := false

@onready var _icon: TextureRect = %Icon
@onready var _hint: Label = %HintLabel


func _ready() -> void:
	if not slot_label_text.is_empty() and _hint:
		_hint.text = slot_label_text
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	refresh_display()


func configure_bag(index: int) -> void:
	bag_index = index
	set_index = -1
	slot_key = &""
	slot_label_text = ""


func set_drop_validator(validator: Callable) -> void:
	_drop_validator = validator


func configure_equip(edit_set: int, key: StringName, label: String) -> void:
	bag_index = -1
	set_index = edit_set
	slot_key = key
	slot_label_text = label
	if _hint:
		_hint.text = label


func set_item(new_item_id: String, texture: Texture2D, is_blocked: bool = false) -> void:
	item_id = new_item_id if new_item_id else ""
	blocked = is_blocked
	if _icon:
		_icon.texture = texture
	refresh_display()


func set_combat_active(is_active: bool) -> void:
	combat_active = is_active
	refresh_display()


func refresh_display() -> void:
	if _icon:
		var icon_color := Color.WHITE
		if item_id.is_empty():
			icon_color = EMPTY_MODULATE
		elif not combat_active:
			icon_color = INACTIVE_COMBAT_ICON
		if blocked:
			icon_color = icon_color.lerp(BLOCKED_MODULATE, 0.55)
		_icon.modulate = icon_color
	modulate = ACTIVE_COMBAT_PANEL if combat_active else INACTIVE_COMBAT_PANEL
	tooltip_text = item_id


func get_slot_descriptor() -> Dictionary:
	if bag_index >= 0:
		return {"kind": &"bag", "bag_index": bag_index}
	if set_index >= 0 and not slot_key.is_empty():
		return {"kind": &"set", "set_index": set_index, "slot_key": slot_key}
	return {}


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty() or blocked:
		return null
	var preview := duplicate()
	preview.modulate.a = 0.75
	set_drag_preview(preview)
	var data := get_slot_descriptor()
	data["item_id"] = item_id
	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if blocked or not data is Dictionary:
		return false
	if String(data.get("item_id", "")).is_empty():
		return false
	if _drop_validator.is_valid():
		return _drop_validator.call(data, get_slot_descriptor())
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		slot_dropped.emit(data, self)


func _on_mouse_entered() -> void:
	slot_hovered.emit(self)


func _on_mouse_exited() -> void:
	slot_unhovered.emit(self)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		if event.location == KEY_LOCATION_RIGHT:
			return
		if event.location == KEY_LOCATION_LEFT or event.location == KEY_LOCATION_UNSPECIFIED:
			_left_shift_down = event.pressed


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and _left_shift_down:
			slot_pressed.emit(self, MOUSE_BUTTON_LEFT, true)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			slot_pressed.emit(self, MOUSE_BUTTON_LEFT, false)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			slot_pressed.emit(self, MOUSE_BUTTON_RIGHT, false)
			accept_event()
