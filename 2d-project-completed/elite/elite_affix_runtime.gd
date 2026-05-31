class_name EliteAffixRuntime
extends RefCounted

## affix별 몹 런타임 behavior 베이스 — subclass 또는 noop으로 확장합니다.


func begin(_mob: Node2D) -> void:
	pass


func reset() -> void:
	pass


func tick(_delta: float, _mob: Node2D) -> void:
	pass


func on_hit_player(_raw_damage: int, _mob: Node2D) -> void:
	pass


func on_took_damage(_amount: int, _mob: Node2D) -> void:
	pass


func on_death(_mob: Node2D) -> void:
	pass
