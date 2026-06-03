# GdUnit generated TestSuite
class_name EliteEmberHazardTest
extends GdUnitTestSuite

const EMBER_SCENE: PackedScene = preload("res://effects/elite_ember/elite_ember_hazard.tscn")


class MockBurnPlayer extends Node2D:
	var applied_debuffs: Array[StringName] = []

	func apply_elite_debuff(debuff_id: StringName, _payload: Dictionary = {}) -> void:
		applied_debuffs.append(debuff_id)

	func is_damage_immune() -> bool:
		return false


func test_body_entered_applies_elite_burn() -> void:
	var player := MockBurnPlayer.new()
	add_child(player)
	player.global_position = Vector2(40.0, 40.0)
	var hazard: EliteEmberHazard = auto_free(EMBER_SCENE.instantiate()) as EliteEmberHazard
	add_child(hazard)
	hazard.global_position = player.global_position
	await await_idle_frame()
	hazard.setup(2.0, 32.0)
	hazard._on_body_entered(player)
	assert_int(player.applied_debuffs.size()).is_equal(1)
	assert_str(String(player.applied_debuffs[0])).is_equal("elite_burn")
