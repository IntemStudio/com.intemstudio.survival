# GdUnit generated TestSuite
class_name PhysicsLayersTest
extends GdUnitTestSuite


func test_player_projectile_mask_includes_environment_and_mobs() -> void:
	assert_int(PhysicsLayers.MASK_PLAYER_PROJECTILE).is_equal(
		PhysicsLayers.ENVIRONMENT | PhysicsLayers.MOBS
	)


func test_mob_projectile_mask_includes_environment_and_player() -> void:
	assert_int(PhysicsLayers.MASK_MOB_PROJECTILE).is_equal(
		PhysicsLayers.ENVIRONMENT | PhysicsLayers.PLAYER
	)


func test_layer_matches() -> void:
	assert_bool(PhysicsLayers.layer_matches(PhysicsLayers.MASK_PLAYER_BODY, PhysicsLayers.ENVIRONMENT)).is_true()
	assert_bool(PhysicsLayers.layer_matches(PhysicsLayers.MASK_PLAYER_BODY, PhysicsLayers.MOBS)).is_false()
