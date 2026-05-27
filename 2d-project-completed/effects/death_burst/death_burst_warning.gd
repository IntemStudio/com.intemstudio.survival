extends Node2D

## 몹 사망 폭발 전 — 반경 링이 지연 시간에 맞춰 커지는 예고 연출.

const RING_TEXTURE := preload("res://art/shared/fx/circle.png")

@onready var _ring: Sprite2D = %Ring


# burst_radius·delay 후 on_complete를 호출합니다.
func setup(burst_radius: float, delay: float, on_complete: Callable) -> void:
	var safe_delay := maxf(delay, 0.01)
	var tex_radius := maxf(RING_TEXTURE.get_width(), RING_TEXTURE.get_height()) * 0.5
	if tex_radius <= 0.0:
		on_complete.call()
		queue_free()
		return
	var target_scale := burst_radius / tex_radius
	_ring.texture = RING_TEXTURE
	_ring.scale = Vector2.ONE * target_scale * 0.08
	_ring.modulate = Color(1.0, 0.32, 0.18, 0.22)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_ring, "scale", Vector2.ONE * target_scale, safe_delay)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_ring, "modulate:a", 0.72, safe_delay * 0.85)\
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)
