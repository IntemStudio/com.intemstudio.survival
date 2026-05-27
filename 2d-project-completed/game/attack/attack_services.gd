extends Node
class_name AttackServices

## Game 직계 자식 — ObjectPools와 대칭. AttackFactory·DamageResolver 진입점.

var _factory: AttackFactory
static var _warned_missing_on_game := false


func _ready() -> void:
	_factory = AttackFactory.new(self)


func get_factory() -> AttackFactory:
	return _factory


static func find_factory(game: Node = null, warn_if_missing: bool = true) -> AttackFactory:
	var services := find_services(game)
	if services:
		return services.get_factory()
	if warn_if_missing:
		warn_missing_factory(game)
	return null


static func warn_missing_factory(game: Node = null) -> void:
	if _warned_missing_on_game:
		return
	_warned_missing_on_game = true
	var path := game.get_path() if game else NodePath("/root/Game")
	push_warning(
		"AttackServices not found under %s — player attacks will not spawn. Add AttackServices node." % path
	)


static func find_services(game: Node = null) -> AttackServices:
	var root_game := game
	if root_game == null:
		root_game = Engine.get_main_loop().root.get_node_or_null("Game")
	if root_game == null:
		return null
	return root_game.get_node_or_null("AttackServices") as AttackServices
