class_name InventoryCombatBridge
extends RefCounted

## 활성 장비 세트 weapon → Player 단일 Gun (서바이버 궤도 스택과 분리).


static func get_active_weapon_id(loadout: PlayerLoadoutState) -> String:
	return loadout.get_set_item_id(loadout.active_set_index, EquipSlots.WEAPON)


# 활성 세트 무기만 플레이어에 반영합니다. weapon_id 없으면 무기 슬롯 비움.
static func apply_active_weapon_to_player(
	player: Node,
	registry: ItemRegistry,
	loadout: PlayerLoadoutState
) -> void:
	if player == null or registry == null or loadout == null:
		return
	if not player.has_method("clear_weapons") or not player.has_method("add_weapon"):
		push_warning("InventoryCombatBridge: player missing clear_weapons/add_weapon")
		return

	var weapon_id := get_active_weapon_id(loadout)
	player.clear_weapons()
	if weapon_id.is_empty():
		if player.has_method("refresh_primary_weapon_range_ring"):
			player.refresh_primary_weapon_range_ring()
		return

	var weapon := registry.resolve_weapon(weapon_id)
	if weapon == null:
		push_warning("InventoryCombatBridge: unknown weapon id '%s'" % weapon_id)
		return
	player.add_weapon(weapon)


# 활성 weapon + loadout 스탯을 Player에 한 번에 반영합니다.
static func apply_loadout_to_player(
	player: Node,
	registry: ItemRegistry,
	loadout: PlayerLoadoutState
) -> void:
	apply_active_weapon_to_player(player, registry, loadout)
	if player == null:
		return
	if player.has_method(&"refresh_stats_from_loadout"):
		player.call("refresh_stats_from_loadout", registry, loadout)


# use_inventory_loadout off 시 loadout 스탯을 초기화합니다.
static func clear_loadout_from_player(player: Node) -> void:
	if player != null and player.has_method(&"clear_loadout_stats"):
		player.call("clear_loadout_stats")
