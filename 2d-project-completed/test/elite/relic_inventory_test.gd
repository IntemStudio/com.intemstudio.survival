# GdUnit generated TestSuite
class_name RelicInventoryTest
extends GdUnitTestSuite

const RelicCatalogScript = preload("res://inventory/relic_catalog.gd")
const RelicCombatBridgeScript = preload("res://inventory/relic_combat_bridge.gd")


func _make_service() -> InventoryService:
	var registry := ItemRegistry.new()
	registry.register_all_catalogs()
	var loadout := PlayerLoadoutState.create_empty()
	return InventoryService.new(registry, loadout)


func test_acquire_relic_places_in_bag_only() -> void:
	var service := _make_service()
	var err := service.acquire_relic("relic_glacial")
	assert_str(String(err)).is_empty()
	assert_str(service.loadout.get_bag_item_id(0)).is_equal("relic_glacial")


func test_relic_cannot_equip_from_bag() -> void:
	var service := _make_service()
	service.acquire_relic("relic_glacial")
	var err := service.try_equip_from_bag(0, 0, EquipSlots.WEAPON)
	assert_str(String(err)).is_equal(String(InventoryService.ERROR_INVALID_SLOT))


func test_relic_combat_bridge_dedupes_same_id() -> void:
	var loadout := PlayerLoadoutState.create_empty()
	loadout.set_bag_item_id(0, "relic_glacial")
	loadout.set_bag_item_id(1, "relic_glacial")
	RelicCombatBridgeScript.refresh_from_bag(loadout)
	assert_bool(RelicCombatBridgeScript.get_held_relic_count(&"relic_glacial")).is_true()
	var seen := 0
	for relic_id in RelicCatalogScript.get_all_relic_ids():
		if RelicCombatBridgeScript.get_held_relic_count(relic_id):
			seen += 1
	assert_int(seen).is_equal(1)
	RelicCombatBridgeScript.clear()
