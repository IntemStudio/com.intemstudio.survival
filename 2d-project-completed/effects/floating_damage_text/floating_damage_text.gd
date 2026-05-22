extends Node2D
class_name FloatingDamageText

const ENEMY_DAMAGE_COLOR := Color(1.0, 0.88, 0.25)
const PLAYER_DAMAGE_COLOR := Color(1.0, 0.35, 0.35)
const POISON_DAMAGE_COLOR := Color(0.45, 0.95, 0.35)

const FLOAT_DISTANCE := 48.0
const FLOAT_DURATION := 0.65


static func spawn_enemy_damage(world_position: Vector2, amount: int) -> void:
	_spawn(world_position, amount, ENEMY_DAMAGE_COLOR)


static func spawn_player_damage(world_position: Vector2, amount: int) -> void:
	_spawn(world_position, amount, PLAYER_DAMAGE_COLOR)


static func spawn_poison_damage(world_position: Vector2, amount: int) -> void:
	_spawn(world_position, amount, POISON_DAMAGE_COLOR)


static func spawn_magic_damage(world_position: Vector2, amount: int, color: Color) -> void:
	_spawn(world_position, amount, color)


static func _spawn(world_position: Vector2, amount: int, color: Color) -> void:
	if amount <= 0 or not GameplaySettings.is_floating_damage_visible():
		return

	var game: Node = Engine.get_main_loop().root.get_node_or_null("Game")
	if not game:
		return

	var scene: PackedScene = load("res://effects/floating_damage_text/floating_damage_text.tscn")
	var instance: Node2D = scene.instantiate()
	game.add_child(instance)
	instance.global_position = world_position + Vector2(randf_range(-14.0, 14.0), -48.0)
	instance.setup(str(amount), color)


func setup(text: String, color: Color) -> void:
	%Label.text = text
	%Label.modulate = color

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, FLOAT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION)\
		.set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
