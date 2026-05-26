extends Node2D
class_name FloatingText

const SCENE_PATH := "res://effects/floating_text/floating_text.tscn"
const DEFAULT_FLOAT_DISTANCE := 48.0
const DEFAULT_FLOAT_DURATION := 0.65
const DEFAULT_START_OFFSET := Vector2(0.0, -48.0)
const RANDOM_X_RANGE := 14.0


# 월드 좌표에 짧게 떠오르는 공통 텍스트를 생성합니다.
static func spawn(
	world_position: Vector2,
	text: String,
	color: Color,
	randomize_x: bool = false
) -> void:
	spawn_with_offset(world_position, text, color, DEFAULT_START_OFFSET, randomize_x)


# 용도별 API가 필요할 때 시작 위치와 애니메이션 값을 조정해 생성합니다.
static func spawn_with_offset(
	world_position: Vector2,
	text: String,
	color: Color,
	start_offset: Vector2 = DEFAULT_START_OFFSET,
	randomize_x: bool = false,
	float_distance: float = DEFAULT_FLOAT_DISTANCE,
	duration: float = DEFAULT_FLOAT_DURATION
) -> void:
	if text.is_empty():
		return

	var parent := _get_spawn_parent()
	if parent == null:
		return
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		return
	var instance := scene.instantiate() as FloatingText
	if instance == null:
		return

	parent.add_child(instance)
	var offset := start_offset
	if randomize_x:
		offset.x += randf_range(-RANDOM_X_RANGE, RANDOM_X_RANGE)
	instance.global_position = world_position + offset
	instance.setup(text, color, float_distance, duration)


static func _get_spawn_parent() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var game: Node = tree.root.get_node_or_null("Game")
	if game != null:
		return game
	return tree.current_scene


# 생성된 텍스트의 내용과 사라지는 애니메이션을 설정합니다.
func setup(
	text: String,
	color: Color,
	float_distance: float = DEFAULT_FLOAT_DISTANCE,
	duration: float = DEFAULT_FLOAT_DURATION
) -> void:
	%Label.text = text
	%Label.modulate = color
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_distance, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration)\
		.set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
