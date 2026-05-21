extends Area2D

var _collected := false


func _ready() -> void:
	add_to_group("magnet_pickups")


# 픽업 범위에 들어오면 모든 경험치 오브를 플레이어에게 끌어옵니다.
func collect(player: Node2D) -> void:
	if _collected:
		return
	_collected = true

	for orb in get_tree().get_nodes_in_group("exp_orbs"):
		if is_instance_valid(orb) and orb.has_method("start_magnet"):
			orb.start_magnet(player)

	queue_free()
