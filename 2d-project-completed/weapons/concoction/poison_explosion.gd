extends Node2D

@onready var _sprite: Sprite2D = %Sprite


func setup(radius: float, visual_radius_mult: float = 1.0) -> void:
	var texture_size := _sprite.texture.get_size().x
	var display_radius := radius * maxf(visual_radius_mult, 0.01)
	var target_scale := (display_radius * 2.0) / texture_size

	_sprite.scale = Vector2.ZERO
	_sprite.modulate.a = 0.55

	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "scale", Vector2.ONE * target_scale, 0.22)\
		.from(Vector2.ZERO).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4).set_delay(0.12)
	tween.chain().tween_callback(queue_free)
