class_name PassiveResolver
extends RefCounted

## grant 트리거 진입점 — LoadoutPassive·버프 위임을 한곳에서 호출합니다.


# grant_on_kill 태그를 처치 시 반영합니다.
static func on_kill(
	player: Node,
	registry: ItemRegistry,
	grant_modifiers: Dictionary
) -> void:
	if player == null or grant_modifiers.is_empty():
		return
	LoadoutGrantPassive.apply_on_kill(player, registry, grant_modifiers)


# grant_on_wave_start 태그를 웨이브 시작 시 반영합니다.
static func on_wave_start(
	player: Node,
	registry: ItemRegistry,
	grant_modifiers: Dictionary,
	wave_number: int = 0
) -> void:
	if player == null or grant_modifiers.is_empty():
		return
	LoadoutGrantPassive.apply_on_wave_start(player, registry, grant_modifiers, wave_number)


# grant_on_dash 태그를 대시 시 반영합니다.
static func on_dash(
	player: Node,
	registry: ItemRegistry,
	grant_modifiers: Dictionary
) -> void:
	if player == null or grant_modifiers.is_empty():
		return
	LoadoutGrantPassive.apply_on_dash(player, registry, grant_modifiers)
