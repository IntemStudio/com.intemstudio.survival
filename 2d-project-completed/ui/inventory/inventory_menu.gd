extends CanvasLayer

const SLOT_SCENE := preload("res://ui/inventory/inventory_slot.tscn")
const _LoadoutSeed := preload("res://inventory/inventory_loadout_seed.gd")

const ARMOR_SLOT_KEYS: Array[StringName] = [
	EquipSlots.HELMET,
	EquipSlots.ARMOR,
	EquipSlots.GLOVES,
	EquipSlots.BOOTS,
]

## 방어구·악세는 세트와 무관하게 sets[0]만 사용(탭 전환 시 UI·데이터 불변).

# 레퍼런스 UI 3×3
# 행0: 무기2 | 헬멧 | 보조2  ·  행1: 무기1 | 갑옷 | 보조1  ·  행2: 장갑 | 악세 | 부츠
const _GRID_ORIGIN := Vector2(24, 28)
const _GRID_CELL := Vector2(100, 100)


static func _grid_pos(col: int, row: int) -> Vector2:
	return _GRID_ORIGIN + Vector2(col * _GRID_CELL.x, row * _GRID_CELL.y)


const WEAPON_LAYOUT: Dictionary = {
	1: Vector2(24, 28),
	0: Vector2(24, 128),
}
const OFFHAND_LAYOUT: Dictionary = {
	1: Vector2(224, 28),
	0: Vector2(224, 128),
}
const ARMOR_LAYOUT: Dictionary = {
	EquipSlots.HELMET: Vector2(124, 28),
	EquipSlots.ARMOR: Vector2(124, 128),
	EquipSlots.GLOVES: Vector2(24, 228),
	EquipSlots.BOOTS: Vector2(224, 228),
}
const ACCESSORY_LAYOUT := Vector2(124, 228)

const EQUIP_LABELS: Dictionary = {
	EquipSlots.HELMET: "헬멧",
	EquipSlots.ARMOR: "갑옷",
	EquipSlots.GLOVES: "장갑",
	EquipSlots.BOOTS: "부츠",
	EquipSlots.WEAPON: "무기",
	EquipSlots.OFFHAND: "보조",
	EquipSlots.ACCESSORY: "악세",
}

var service: InventoryService

var _edit_set_index := 0
var _weapon_slots: Array[InventorySlot] = []
var _offhand_slots: Array[InventorySlot] = []
var _armor_slots: Dictionary = {}
var _accessory_slot: InventorySlot
var _bag_slots: Array[InventorySlot] = []
var _status_clear_timer: float = 0.0

@onready var _equip_panel: Control = %EquipPanel
@onready var _equip_armor_title: Label = %EquipArmorTitle
@onready var _detail_label: RichTextLabel = %DetailLabel
@onready var _active_set_label: Label = %ActiveSetLabel
@onready var _status_label: Label = %StatusLabel
@onready var _title_label: Label = %TitleLabel
@onready var _bag_title_label: Label = %BagTitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _tab_set0: Button = %EditSetTab0
@onready var _tab_set1: Button = %EditSetTab1
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	hide()
	_build_equip_slots()
	_build_bag_slots()
	_tab_set0.pressed.connect(_on_tab_set0_pressed)
	_tab_set1.pressed.connect(_on_tab_set1_pressed)
	_close_button.pressed.connect(_on_close_pressed)
	refresh_locale()


func _process(delta: float) -> void:
	if _status_clear_timer > 0.0:
		_status_clear_timer -= delta
		if _status_clear_timer <= 0.0 and _status_label:
			_status_label.text = ""


func refresh_locale() -> void:
	if not is_node_ready():
		return
	_title_label.text = UiLocale.t(&"inventory.title")
	_bag_title_label.text = UiLocale.t(&"inventory.bag_title")
	_hint_label.text = UiLocale.t(&"inventory.hint")
	_close_button.text = UiLocale.t(&"inventory.close")
	_tab_set0.text = UiLocale.t(&"inventory.set_tab") % 1
	_tab_set1.text = UiLocale.t(&"inventory.set_tab") % 2
	_update_armor_title()
	_refresh_combat_slot_labels()
	_update_active_set_label()


func get_service() -> InventoryService:
	_ensure_service()
	return service


func on_menu_opened() -> void:
	_ensure_service()
	service.set_edit_set_index(_edit_set_index)
	refresh_all_slots()
	refresh_locale()
	_sync_combat_loadout()


func _ensure_service() -> void:
	if service != null:
		service.registry.register_all_catalogs()
		return
	var state := InventorySave.load_state()
	if _LoadoutSeed.is_loadout_empty(state):
		var seed_registry := ItemRegistry.new()
		seed_registry.register_all_catalogs()
		_LoadoutSeed.apply_random_starter(state, seed_registry)
		InventorySave.save_state(state)
	service = InventoryService.new(null, state)
	service.registry.register_all_catalogs()


func on_menu_closed() -> void:
	if service != null:
		InventorySave.save_state(service.loadout)


func refresh_all_slots() -> void:
	if service == null:
		return
	var active_set: int = service.loadout.active_set_index
	_refresh_combat_slots(active_set)

	for slot_key in _armor_slots:
		var slot: InventorySlot = _armor_slots[slot_key]
		var item_id := service.loadout.get_set_item_id(EquipSlots.SHARED_ARMOR_SET_INDEX, slot_key)
		slot.set_item(item_id, _resolve_texture(item_id), false)

	if _accessory_slot:
		var accessory_id := service.loadout.get_set_item_id(
			EquipSlots.SHARED_ARMOR_SET_INDEX,
			EquipSlots.ACCESSORY
		)
		_accessory_slot.set_item(accessory_id, _resolve_texture(accessory_id), false)

	for i in _bag_slots.size():
		var bag_id := service.loadout.get_bag_item_id(i)
		_bag_slots[i].set_item(bag_id, _resolve_texture(bag_id), false)

	_update_tab_styles()
	_update_active_set_label()


func _refresh_combat_slots(active_set: int) -> void:
	for set_index in EquipSlots.SET_COUNT:
		var weapon_id := service.loadout.get_set_item_id(set_index, EquipSlots.WEAPON)
		var offhand_id := service.loadout.get_set_item_id(set_index, EquipSlots.OFFHAND)
		var offhand_blocked := service.registry.is_offhand_blocked_by_weapon(weapon_id)
		var is_active := set_index == active_set

		var weapon_slot: InventorySlot = _weapon_slots[set_index]
		weapon_slot.set_item(weapon_id, _resolve_texture(weapon_id), false)
		weapon_slot.set_combat_active(is_active)

		var offhand_slot: InventorySlot = _offhand_slots[set_index]
		offhand_slot.set_item(offhand_id, _resolve_texture(offhand_id), offhand_blocked)
		offhand_slot.set_combat_active(is_active)


func _build_equip_slots() -> void:
	_weapon_slots.resize(EquipSlots.SET_COUNT)
	_offhand_slots.resize(EquipSlots.SET_COUNT)
	for set_index in EquipSlots.SET_COUNT:
		_weapon_slots[set_index] = _create_equip_slot(
			WEAPON_LAYOUT[set_index],
			set_index,
			EquipSlots.WEAPON,
			UiLocale.t(&"inventory.combat_weapon") % (set_index + 1)
		)
		_offhand_slots[set_index] = _create_equip_slot(
			OFFHAND_LAYOUT[set_index],
			set_index,
			EquipSlots.OFFHAND,
			UiLocale.t(&"inventory.combat_offhand") % (set_index + 1)
		)

	for slot_key in ARMOR_SLOT_KEYS:
		_armor_slots[slot_key] = _create_equip_slot(
			ARMOR_LAYOUT[slot_key],
			EquipSlots.SHARED_ARMOR_SET_INDEX,
			slot_key,
			String(EQUIP_LABELS.get(slot_key, ""))
		)

	_accessory_slot = _create_equip_slot(
		ACCESSORY_LAYOUT,
		EquipSlots.SHARED_ARMOR_SET_INDEX,
		EquipSlots.ACCESSORY,
		String(EQUIP_LABELS.get(EquipSlots.ACCESSORY, ""))
	)

	_add_column_titles()
	_add_swap_hints()


func _create_equip_slot(
	position: Vector2,
	set_index: int,
	slot_key: StringName,
	label: String
) -> InventorySlot:
	var slot: InventorySlot = SLOT_SCENE.instantiate()
	_equip_panel.add_child(slot)
	slot.position = position
	slot.configure_equip(set_index, slot_key, label)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.slot_pressed.connect(_on_slot_pressed)
	slot.slot_dropped.connect(_on_slot_dropped)
	slot.set_drop_validator(_validate_slot_drop)
	return slot


func _add_column_titles() -> void:
	_add_hint_label(Vector2(_GRID_ORIGIN.x, 4), UiLocale.t(&"inventory.col_weapon"))
	_add_hint_label(Vector2(_GRID_ORIGIN.x + _GRID_CELL.x, 4), UiLocale.t(&"inventory.col_armor"))
	_add_hint_label(Vector2(_GRID_ORIGIN.x + _GRID_CELL.x * 2.0, 4), UiLocale.t(&"inventory.col_offhand"))


func _add_swap_hints() -> void:
	var weapon_mid := _grid_pos(0, 0) + Vector2(44, _GRID_CELL.y - 4)
	var offhand_mid := _grid_pos(2, 0) + Vector2(44, _GRID_CELL.y - 4)
	_add_hint_label(weapon_mid, "↕", 20)
	_add_hint_label(offhand_mid, "↕", 20)


func _add_hint_label(position: Vector2, text: String, font_size: int = 14) -> void:
	var label := Label.new()
	label.position = position
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 1))
	_equip_panel.add_child(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_bag_slots() -> void:
	var grid: GridContainer = %BagGrid
	for i in EquipSlots.BAG_SIZE:
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.configure_bag(i)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.slot_dropped.connect(_on_slot_dropped)
		slot.set_drop_validator(_validate_slot_drop)
		_bag_slots.append(slot)


func _resolve_texture(item_id: String) -> Texture2D:
	if item_id.is_empty() or service == null:
		return null
	var resource := service.registry.resolve_gear_or_weapon(item_id)
	if resource is WeaponData:
		return (resource as WeaponData).texture
	if resource is GearData:
		return (resource as GearData).texture
	return null


func _validate_slot_drop(source: Dictionary, target: Dictionary) -> bool:
	if service == null or target.is_empty():
		return false
	return service.can_drop(source, target)


func _on_slot_hovered(slot: InventorySlot) -> void:
	_show_detail_for_item(slot.item_id)


func _on_slot_unhovered(_slot: InventorySlot) -> void:
	pass


func _on_slot_pressed(slot: InventorySlot, mouse_button: int) -> void:
	if service == null:
		return
	var desc := slot.get_slot_descriptor()
	if mouse_button == MOUSE_BUTTON_LEFT and desc.get("kind") == &"set":
		if _try_select_combat_set(desc):
			return
		if _try_acknowledge_active_combat_slot(slot, desc):
			return
	var should_sync := false
	if mouse_button == MOUSE_BUTTON_LEFT and desc.get("kind") == &"bag":
		should_sync = _try_equip_from_bag_slot(desc["bag_index"])
	elif mouse_button == MOUSE_BUTTON_RIGHT and desc.get("kind") == &"bag":
		should_sync = _try_equip_from_bag_slot(desc["bag_index"])
	elif mouse_button == MOUSE_BUTTON_RIGHT and desc.get("kind") == &"set":
		var unequip_err := service.try_unequip(desc["set_index"], desc["slot_key"])
		_show_error(unequip_err)
		should_sync = unequip_err.is_empty()
	if should_sync:
		refresh_all_slots()
		_sync_combat_loadout()


func _try_select_combat_set(desc: Dictionary) -> bool:
	var slot_key: StringName = desc.get("slot_key", &"")
	if slot_key != EquipSlots.WEAPON and slot_key != EquipSlots.OFFHAND:
		return false
	var set_index: int = desc.get("set_index", -1)
	if set_index < 0 or set_index == service.loadout.active_set_index:
		return false
	service.set_active_combat_set(set_index)
	InventorySave.save_state(service.loadout)
	var set_num := service.loadout.active_set_index + 1
	show_status_message(UiLocale.t(&"inventory.set_swapped") % set_num)
	refresh_all_slots()
	_sync_combat_loadout()
	return true


func _on_slot_dropped(source: Dictionary, target: InventorySlot) -> void:
	if service == null:
		return
	var target_desc := target.get_slot_descriptor()
	if target_desc.is_empty():
		return
	var err := service.try_drop(source, target_desc)
	_show_drop_error(err, source, target_desc)
	refresh_all_slots()
	_sync_combat_loadout()


func _show_detail_for_item(item_id: String) -> void:
	if item_id.is_empty():
		_detail_label.text = UiLocale.t(&"inventory.detail_empty")
		return
	var weapon := service.registry.resolve_weapon(item_id) if service else null
	if weapon:
		_detail_label.text = weapon.build_select_tooltip_bbcode()
		return
	var gear := service.registry.resolve_gear(item_id) if service else null
	if gear:
		_detail_label.text = _build_gear_tooltip(gear)
		return
	_detail_label.text = item_id


func _build_gear_tooltip(gear: GearData) -> String:
	var slot_label := String(EQUIP_LABELS.get(gear.gear_slot, gear.gear_slot))
	return GearStatDisplay.build_gear_tooltip(gear, slot_label)


func _show_error(err: StringName) -> void:
	if err.is_empty():
		return
	_status_label.text = UiLocale.t(err)
	_status_clear_timer = 2.5


func _show_drop_error(err: StringName, source: Dictionary, target: Dictionary) -> void:
	if err.is_empty():
		return
	if err == InventoryService.ERROR_CROSS_SET:
		_show_error(err)
		return
	if (
		err == InventoryService.ERROR_INVALID_SLOT
		and source.get("kind") == &"set"
		and target.get("kind") == &"set"
		and int(source.get("set_index", -1)) != int(target.get("set_index", -1))
	):
		_show_error(InventoryService.ERROR_CROSS_SET)
		return
	_show_error(err)


func _try_equip_from_bag_slot(bag_index: int) -> bool:
	if service == null:
		return false
	var err := service.try_equip_from_bag_smart(bag_index, EquipSlots.SHARED_ARMOR_SET_INDEX)
	_show_error(err)
	return err.is_empty()


func _try_acknowledge_active_combat_slot(slot: InventorySlot, desc: Dictionary) -> bool:
	var slot_key: StringName = desc.get("slot_key", &"")
	if slot_key != EquipSlots.WEAPON and slot_key != EquipSlots.OFFHAND:
		return false
	var set_index: int = desc.get("set_index", -1)
	if set_index != service.loadout.active_set_index:
		return false
	if slot.item_id.is_empty():
		return false
	_show_detail_for_item(slot.item_id)
	show_status_message(UiLocale.t(&"inventory.combat_active_slot"))
	return true


func _sync_combat_loadout() -> void:
	var game := _get_game()
	if game and game.has_method("apply_inventory_loadout_to_player"):
		game.call("apply_inventory_loadout_to_player")


func _on_tab_set0_pressed() -> void:
	_set_edit_set(0)


func _on_tab_set1_pressed() -> void:
	_set_edit_set(1)


func _set_edit_set(index: int) -> void:
	_edit_set_index = index
	if service == null:
		return
	service.set_edit_set_index(index)
	_update_tab_styles()


func _refresh_combat_slot_labels() -> void:
	for set_index in EquipSlots.SET_COUNT:
		if set_index < _weapon_slots.size() and _weapon_slots[set_index]:
			var weapon_hint: Label = _weapon_slots[set_index].get_node_or_null("VBox/HintLabel")
			if weapon_hint:
				weapon_hint.text = UiLocale.t(&"inventory.combat_weapon") % (set_index + 1)
		if set_index < _offhand_slots.size() and _offhand_slots[set_index]:
			var offhand_hint: Label = _offhand_slots[set_index].get_node_or_null("VBox/HintLabel")
			if offhand_hint:
				offhand_hint.text = UiLocale.t(&"inventory.combat_offhand") % (set_index + 1)


func _update_armor_title() -> void:
	if _equip_armor_title:
		_equip_armor_title.text = UiLocale.t(&"inventory.col_armor")


func _update_tab_styles() -> void:
	_style_tab(_tab_set0, _edit_set_index == 0)
	_style_tab(_tab_set1, _edit_set_index == 1)


func _style_tab(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
	else:
		button.remove_theme_color_override("font_color")


func _update_active_set_label() -> void:
	if service == null:
		return
	var active := service.loadout.active_set_index + 1
	_active_set_label.text = UiLocale.t(&"inventory.active_set") % active


func _on_close_pressed() -> void:
	var game := _get_game()
	if game:
		InventoryGameBridge.hide_inventory(game, self)


func show_status_message(message: String) -> void:
	_status_label.text = message
	_status_clear_timer = 2.5


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("toggle_inventory"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func _get_game() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var current := tree.current_scene
	if current and current.has_method("apply_inventory_loadout_to_player"):
		return current
	return get_node_or_null("/root/Game")
