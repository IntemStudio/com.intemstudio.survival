class_name LoadoutGrantPassive
extends RefCounted

## loadout grant_* 태그를 전투에 반영합니다.

const KING_BIBLE_ORB_SCENE := preload("res://weapons/magic/king_bible_orb.tscn")
const THROWING_PROJECTILE_SCENE := preload("res://weapons/throwing/throwing_projectile.tscn")

const DASH_DART_COUNT := 3
const DASH_DART_SPREAD_DEG := 22.0

const ORBITAL_WEAPON_BY_TAG: Dictionary = {
	"sticky_orbital": "sticky_orbital",
	"pyromancy_orbital": "pyromancy_orbital",
}

const _ON_DASH_HANDLERS: Dictionary = {
	"haste": Callable(LoadoutGrantPassive, "_grant_dash_haste"),
	"darts": Callable(LoadoutGrantPassive, "_grant_dash_darts"),
}

const _ON_KILL_HANDLERS: Dictionary = {
	"magnet_pulse": Callable(LoadoutGrantPassive, "_grant_kill_magnet_pulse"),
	"momentum": Callable(LoadoutGrantPassive, "_grant_kill_momentum"),
}

const _ON_WAVE_START_HANDLERS: Dictionary = {
	"vigor": Callable(LoadoutGrantPassive, "_grant_wave_vigor"),
}


# grant_orbital 태그마다 궤도 동료를 스폰합니다.
static func refresh_orbitals(
	player: Node2D,
	registry: ItemRegistry,
	modifiers: Dictionary,
	tracked: Array
) -> void:
	clear_orbitals(tracked)
	if player == null or registry == null or modifiers.is_empty():
		return
	var tags: Variant = modifiers.get("grant_orbital", [])
	if not tags is Array:
		return
	for tag_variant in tags:
		var tag := String(tag_variant)
		var weapon_id := String(ORBITAL_WEAPON_BY_TAG.get(tag, ""))
		if weapon_id.is_empty():
			push_warning("LoadoutGrantPassive: unknown grant_orbital '%s'" % tag)
			continue
		var weapon := registry.resolve_weapon(weapon_id)
		if weapon == null:
			continue
		var orb := _spawn_orbital(player, weapon)
		if orb != null:
			tracked.append(orb)


static func clear_orbitals(tracked: Array) -> void:
	for node in tracked:
		if is_instance_valid(node):
			PoolUtil.release_node(node)
	tracked.clear()


# 대시 시 grant_on_dash 태그를 적용합니다.
static func apply_on_dash(
	player: Node2D,
	registry: ItemRegistry,
	modifiers: Dictionary
) -> void:
	_dispatch_grant_tags(player, registry, modifiers, "grant_on_dash", _ON_DASH_HANDLERS)


# 처치 시 grant_on_kill 태그를 적용합니다.
static func apply_on_kill(
	player: Node2D,
	registry: ItemRegistry,
	modifiers: Dictionary
) -> void:
	_dispatch_grant_tags(player, registry, modifiers, "grant_on_kill", _ON_KILL_HANDLERS)


# 웨이브 시작 시 grant_on_wave_start 태그를 적용합니다.
static func apply_on_wave_start(
	player: Node2D,
	registry: ItemRegistry,
	modifiers: Dictionary,
	_wave_number: int = 0
) -> void:
	_dispatch_grant_tags(player, registry, modifiers, "grant_on_wave_start", _ON_WAVE_START_HANDLERS)


# 무기 적중 시 grant_on_hit 태그를 상태이상으로 적용합니다.
static func apply_on_hit(
	player: Node2D,
	_registry: ItemRegistry,
	modifiers: Dictionary,
	target_mob: Node,
	source_weapon: WeaponData
) -> void:
	if player == null or target_mob == null or modifiers.is_empty():
		return
	if not target_mob.has_method(&"apply_status"):
		return
	var tags: Variant = modifiers.get("grant_on_hit", [])
	if not tags is Array:
		return
	for tag_variant in tags:
		var status_id := StringName(String(tag_variant))
		if status_id == &"":
			continue
		if not StatusEffectCatalog.has_status(status_id):
			push_warning("LoadoutGrantPassive: unknown grant_on_hit '%s'" % String(status_id))
			continue
		target_mob.call(&"apply_status", status_id, source_weapon)


# 활성 세트 offhand 장비 스프라이트를 표시합니다(양손 무기 시 숨김).
static func refresh_offhand_visual(
	player: Node2D,
	registry: ItemRegistry,
	loadout: PlayerLoadoutState
) -> void:
	var pivot := player.get_node_or_null("%OffhandPivot") as Node2D
	var sprite := player.get_node_or_null("%OffhandSprite") as Sprite2D
	if pivot == null or sprite == null:
		return
	if registry == null or loadout == null:
		pivot.visible = false
		return
	var set_index := loadout.active_set_index
	var weapon_id := loadout.get_set_item_id(set_index, EquipSlots.WEAPON)
	if registry.is_offhand_blocked_by_weapon(weapon_id):
		pivot.visible = false
		return
	var offhand_id := loadout.get_set_item_id(set_index, EquipSlots.OFFHAND)
	if offhand_id.is_empty():
		pivot.visible = false
		return
	var gear := registry.resolve_gear(offhand_id)
	if gear == null or gear.texture == null:
		pivot.visible = false
		return
	sprite.texture = gear.texture
	sprite.scale = Vector2(0.32, 0.32)
	sprite.modulate = Color(0.82, 0.88, 1.0, 0.95)
	pivot.visible = true


static func _dispatch_grant_tags(
	player: Node2D,
	registry: ItemRegistry,
	modifiers: Dictionary,
	modifier_key: String,
	handlers: Dictionary
) -> void:
	if player == null or modifiers.is_empty():
		return
	var tags: Variant = modifiers.get(modifier_key, [])
	if not tags is Array:
		return
	for tag_variant in tags:
		var tag := String(tag_variant)
		var handler: Variant = handlers.get(tag)
		if handler is Callable:
			handler.call(player, registry, modifiers)
		else:
			push_warning(
				"LoadoutGrantPassive: unknown %s '%s'" % [modifier_key, tag]
			)


static func _grant_dash_haste(player: Node2D, _registry: ItemRegistry, _modifiers: Dictionary) -> void:
	if player.has_method(&"apply_loadout_dash_haste"):
		player.call("apply_loadout_dash_haste")


static func _grant_dash_darts(
	player: Node2D, registry: ItemRegistry, modifiers: Dictionary
) -> void:
	_spawn_dash_darts(player, registry, modifiers)


static func _grant_kill_magnet_pulse(
	player: Node2D, _registry: ItemRegistry, _modifiers: Dictionary
) -> void:
	if player.has_method(&"magnetize_field_pickups"):
		player.call("magnetize_field_pickups")


static func _grant_kill_momentum(
	player: Node2D, _registry: ItemRegistry, _modifiers: Dictionary
) -> void:
	BuffTriggerRouter.apply_loadout_kill_momentum(player)


static func _grant_wave_vigor(
	player: Node2D, _registry: ItemRegistry, _modifiers: Dictionary
) -> void:
	BuffTriggerRouter.apply_loadout_wave_vigor(player)


static func _spawn_orbital(player: Node2D, weapon: WeaponData) -> Node:
	var game := _find_game_root(player)
	if game == null:
		return null
	var pool := game.get_node_or_null("ObjectPools") as ScenePool
	var orb: Area2D
	if pool:
		orb = pool.acquire(KING_BIBLE_ORB_SCENE, game) as Area2D
	else:
		orb = KING_BIBLE_ORB_SCENE.instantiate() as Area2D
		game.add_child(orb)
	if orb == null:
		return null
	orb.setup(weapon, player)
	return orb


static func _spawn_dash_darts(player: Node2D, registry: ItemRegistry, modifiers: Dictionary) -> void:
	var game := _find_game_root(player)
	if game == null:
		return
	var template := registry.resolve_weapon("throwing_javelins")
	if template == null:
		return
	var dart_weapon := template.duplicate(true) as WeaponData
	dart_weapon.damage_coefficient = _resolve_dart_damage_coefficient(modifiers, template)
	var dash_dir := Vector2.RIGHT
	if player.has_method(&"get_last_move_direction"):
		dash_dir = player.call("get_last_move_direction") as Vector2
	if dash_dir.length_squared() < 0.01:
		dash_dir = Vector2.RIGHT
	dash_dir = dash_dir.normalized()
	var pool := game.get_node_or_null("ObjectPools") as ScenePool
	var spread_rad := deg_to_rad(DASH_DART_SPREAD_DEG)
	var center_index := (DASH_DART_COUNT - 1) * 0.5
	for i in DASH_DART_COUNT:
		var angle_offset := (float(i) - center_index) * spread_rad
		var dir := dash_dir.rotated(angle_offset)
		var projectile: Node
		if pool:
			projectile = pool.acquire(THROWING_PROJECTILE_SCENE, game)
		else:
			projectile = THROWING_PROJECTILE_SCENE.instantiate()
			game.add_child(projectile)
		if projectile == null:
			continue
		projectile.global_position = player.global_position
		if projectile.has_method(&"setup_weapon"):
			projectile.call("setup_weapon", player, dir, dart_weapon)


static func _find_game_root(player: Node) -> Node:
	if player == null:
		return null
	var tree := player.get_tree()
	if tree == null or tree.current_scene == null:
		return null
	var scene := tree.current_scene
	if scene.get_node_or_null("ObjectPools") != null:
		return scene
	return scene.get_parent()


static func _resolve_dart_damage_coefficient(modifiers: Dictionary, template: WeaponData) -> float:
	if modifiers.has("dart_damage_coeff"):
		return float(modifiers["dart_damage_coeff"])
	if modifiers.has("dart_damage_min") and modifiers.has("dart_damage_max"):
		return WeaponData.legacy_mid_to_coeff(
			int(modifiers["dart_damage_min"]),
			int(modifiers["dart_damage_max"])
		)
	return template.damage_coefficient
