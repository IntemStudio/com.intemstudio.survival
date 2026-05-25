class_name ArenaTeleporter
extends Area2D

signal activated

const INTERACT_KEY := KEY_E

var _player_in_range := false
var _activated := false
var _pulse_time := 0.0
var _base_sprite_scale := Vector2.ONE

@onready var _sprite: Sprite2D = %TeleporterSprite
@onready var _prompt_label: Label = %PromptLabel


func _ready() -> void:
	_base_sprite_scale = _sprite.scale
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_available(true)


func _process(delta: float) -> void:
	if _activated:
		return
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 4.0) * 0.08
	_sprite.scale = _base_sprite_scale * pulse


# 아레나 시작 전 대기 상태에서만 상호작용을 허용합니다.
func set_available(available: bool) -> void:
	if available:
		_activated = false
	visible = available
	monitoring = available
	set_process(available)
	set_process_unhandled_input(available)
	if not available:
		_player_in_range = false
	else:
		call_deferred("_refresh_player_overlap")
	_sync_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _activated or not _player_in_range:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event.echo or not key_event.pressed:
		return
	if key_event.physical_keycode != INTERACT_KEY:
		return

	_activated = true
	set_available(false)
	activated.emit()
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if body.name != "Player":
		return
	_player_in_range = true
	_sync_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = false
	_sync_prompt()


# 재활성화 순간 플레이어가 이미 범위 안에 있어도 프롬프트와 입력 상태를 복구합니다.
func _refresh_player_overlap() -> void:
	if not visible or _activated:
		return
	_player_in_range = false
	for body in get_overlapping_bodies():
		if body.name == "Player":
			_player_in_range = true
			break
	_sync_prompt()


func _sync_prompt() -> void:
	if _prompt_label == null:
		return
	_prompt_label.visible = visible and _player_in_range and not _activated
