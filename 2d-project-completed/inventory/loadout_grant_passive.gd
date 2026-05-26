class_name LoadoutGrantPassive
extends RefCounted

## loadout grant_orbital · grant_on_dash 태그를 전투에 반영합니다.

const KING_BIBLE_ORB_SCENE := preload("res://weapons/magic/king_bible_orb.tscn")
const THROWING_PROJECTILE_SCENE := preload("res://weapons/throwing/throwing_projectile.tscn")

const DASH_DART_COUNT := 3
const DASH_DART_SPREAD_DEG := 22.0

const ORBITAL_WEAPON_BY_TAG: Dictionary = {
	"sticky_orbital": "sticky_orbital",
	"pyromancy_orbital": "pyromancy_orbital",
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


# 대시 시 grant_on_dash(haste·darts)를 적용합니다.
static func apply_on_dash(
	player: Node2D,
	registry: ItemRegistry,
	modifiers: Dictionary
) -> void:
	if player == null or modifiers.is_empty():
		return
	var tags: Variant = modifiers.get("grant_on_dash", [])
	if not tags is Array:
		return
	for tag_variant in tags:
		match String(tag_variant):
			"haste":
				if player.has_method(&"apply_loadout_dash_haste"):
					player.call("apply_loadout_dash_haste")
			"darts":
				_spawn_dash_darts(player, registry, modifiers)
			_:
				push_warning("LoadoutGrantPassive: unknown grant_on_dash '%s'" % String(tag_variant))


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
	dart_weapon.min_damage = int(modifiers.get("dart_damage_min", template.min_damage))
	dart_weapon.max_damage = int(modifiers.get("dart_damage_max", template.max_damage))
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
