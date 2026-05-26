class_name InteractableArea
extends Area2D

## 플레이어 범위 진입, 프롬프트 표시, interact 입력 처리를 공통화합니다.

@export var prompt_label_path: NodePath = ^"PromptLabel"

var _interaction_player: Node2D = null
var _player_in_range := false
var _interacting := false

@onready var _interaction_prompt_label := get_node_or_null(prompt_label_path) as Label


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	body_entered.connect(_on_interaction_body_entered)
	body_exited.connect(_on_interaction_body_exited)
	refresh_interaction_prompt()
	call_deferred("refresh_interaction_overlap")


func _unhandled_input(event: InputEvent) -> void:
	if _interacting or not _player_in_range or not _can_interact():
		return
	if not InteractionInput.is_interact_pressed(event):
		return

	_interacting = true
	_on_interact(_interaction_player)
	_interacting = false
	get_viewport().set_input_as_handled()
	_sync_interaction_prompt()


func refresh_interaction_prompt() -> void:
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = _format_interaction_prompt(_get_interaction_text())
	_sync_interaction_prompt()


func refresh_locale() -> void:
	refresh_interaction_prompt()


func refresh_interaction_overlap() -> void:
	_player_in_range = false
	_interaction_player = null
	if not monitoring:
		_sync_interaction_prompt()
		return
	for body in get_overlapping_bodies():
		if _is_interaction_player(body):
			_player_in_range = true
			_interaction_player = body
			break
	_sync_interaction_prompt()


func clear_interaction_state() -> void:
	_player_in_range = false
	_interaction_player = null
	_sync_interaction_prompt()


func get_interaction_prompt_label() -> Label:
	return _interaction_prompt_label


func _can_interact() -> bool:
	return true


func _get_interaction_text() -> String:
	return ""


func _on_interact(_player: Node2D) -> void:
	pass


func _should_show_interaction_prompt() -> bool:
	return _player_in_range and _can_interact()


func _format_interaction_prompt(text: String) -> String:
	if text.is_empty():
		return InteractionInput.get_interact_label()
	return UiLocale.t(&"interaction.prompt") % [InteractionInput.get_interact_label(), text]


func _sync_interaction_prompt() -> void:
	if _interaction_prompt_label == null:
		return
	_interaction_prompt_label.visible = _should_show_interaction_prompt()


func _on_interaction_body_entered(body: Node2D) -> void:
	if not _is_interaction_player(body):
		return
	_player_in_range = true
	_interaction_player = body
	_sync_interaction_prompt()


func _on_interaction_body_exited(body: Node2D) -> void:
	if body != _interaction_player and not _is_interaction_player(body):
		return
	_player_in_range = false
	_interaction_player = null
	_sync_interaction_prompt()


func _is_interaction_player(body: Node2D) -> bool:
	return body.name == "Player"
