class_name InventoryGameBridge
extends RefCounted

## F5/F6 공통 — 인벤 열기·닫기·입력·전투 세트 스왑.


static func is_inventory_open(inventory_menu: CanvasLayer) -> bool:
	return inventory_menu != null and inventory_menu.visible


static func is_inventory_blocked(game: Node) -> bool:
	if game.has_method("is_weapon_select_open") and game.call("is_weapon_select_open"):
		return true
	if game.has_method("is_pause_menu_open") and game.call("is_pause_menu_open"):
		return true
	if game.has_method("is_game_over") and game.call("is_game_over"):
		return true
	return false


static func can_unpause_after_inventory_close(game: Node) -> bool:
	return not is_inventory_blocked(game)


static func show_inventory(game: Node, inventory_menu: CanvasLayer) -> void:
	if inventory_menu == null or is_inventory_blocked(game):
		return
	if inventory_menu.has_method("on_menu_opened"):
		inventory_menu.on_menu_opened()
	inventory_menu.show()
	game.get_tree().paused = true


static func hide_inventory(game: Node, inventory_menu: CanvasLayer) -> void:
	if inventory_menu == null:
		return
	if inventory_menu.has_method("on_menu_closed"):
		inventory_menu.on_menu_closed()
	inventory_menu.hide()
	if can_unpause_after_inventory_close(game):
		game.get_tree().paused = false


static func toggle_inventory(game: Node, inventory_menu: CanvasLayer) -> void:
	if is_inventory_open(inventory_menu):
		hide_inventory(game, inventory_menu)
	else:
		show_inventory(game, inventory_menu)


static func can_swap_active_combat_set(game: Node, inventory_menu: CanvasLayer) -> bool:
	if is_inventory_open(inventory_menu):
		return false
	if is_inventory_blocked(game):
		return false
	if game.has_method("is_game_started") and not game.call("is_game_started"):
		return false
	if game.get("use_inventory_loadout") == false:
		return false
	return inventory_menu != null and inventory_menu.has_method("get_service")


static func swap_equip_sets(game: Node, inventory_menu: CanvasLayer) -> void:
	if not can_swap_active_combat_set(game, inventory_menu):
		return
	var menu_service: InventoryService = inventory_menu.get_service()
	if menu_service == null:
		return
	menu_service.swap_equip_sets()
	if inventory_menu.has_method("persist_loadout_if_enabled"):
		inventory_menu.call("persist_loadout_if_enabled")
	if game.has_method("apply_inventory_loadout_to_player"):
		game.call("apply_inventory_loadout_to_player")
	if inventory_menu.visible:
		if inventory_menu.has_method("refresh_all_slots"):
			inventory_menu.refresh_all_slots()
	var set_num := menu_service.loadout.active_set_index + 1
	var message := UiLocale.t(&"inventory.set_swapped") % set_num
	if inventory_menu.visible and inventory_menu.has_method("show_status_message"):
		inventory_menu.show_status_message(message)
	elif game.has_method("show_inventory_swap_toast"):
		game.call("show_inventory_swap_toast", message)


static func handle_inventory_input(game: Node, inventory_menu: CanvasLayer, event: InputEvent) -> bool:
	if ActionManager.event_is_pressed(event, ActionManager.ACTION_TOGGLE_INVENTORY):
		toggle_inventory(game, inventory_menu)
		return true
	if (
		ActionManager.event_is_pressed(event, ActionManager.ACTION_SWAP_COMBAT_SET)
		and can_swap_active_combat_set(game, inventory_menu)
	):
		swap_equip_sets(game, inventory_menu)
		return true
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
		and can_swap_active_combat_set(game, inventory_menu)
	):
		swap_equip_sets(game, inventory_menu)
		return true
	return false


# HUD 전투 세트 칩 — use_inventory_loadout 일 때만 표시.
static func refresh_combat_set_hud(game: Node, inventory_menu: CanvasLayer) -> void:
	if game == null or game.get("use_inventory_loadout") != true:
		var hidden := _find_combat_set_label(game)
		if hidden:
			hidden.visible = false
		return
	var label := _find_combat_set_label(game)
	if label == null:
		return
	if inventory_menu == null or not inventory_menu.has_method("get_service"):
		label.visible = false
		return
	var menu_service: InventoryService = inventory_menu.get_service()
	if menu_service == null:
		label.visible = false
		return
	label.visible = true
	var set_num := menu_service.loadout.active_set_index + 1
	label.text = UiLocale.t(&"inventory.hud_combat_set") % set_num


static func _find_combat_set_label(game: Node) -> Label:
	if game == null:
		return null
	if game.has_node("%CombatSetLabel"):
		return game.get_node("%CombatSetLabel") as Label
	return null
