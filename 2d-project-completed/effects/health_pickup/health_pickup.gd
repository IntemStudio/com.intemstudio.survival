extends Area2D

@export var heal_amount := 30.0

var _collected := false


# 픽업 범위에 들어오면 플레이어 체력을 회복합니다.
func collect(player: Node2D) -> void:
	if _collected:
		return
	_collected = true

	if player.has_method("heal_health"):
		player.heal_health(heal_amount)

	queue_free()
