class_name ArenaTeleporter
extends InteractableArea

signal activated

var _activated := false
var _pulse_time := 0.0
var _base_sprite_scale := Vector2.ONE

@onready var _sprite: Sprite2D = %TeleporterSprite


func _ready() -> void:
	_base_sprite_scale = _sprite.scale
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitorable = false
	monitoring = true
	super._ready()
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
		clear_interaction_state()
	else:
		call_deferred("refresh_interaction_overlap")
	refresh_interaction_prompt()


func _can_interact() -> bool:
	return visible and not _activated


func _get_interaction_text() -> String:
	return UiLocale.t(&"arena_teleporter.prompt_label")


func _on_interact(_player: Node2D) -> void:
	_activated = true
	set_available(false)
	activated.emit()
