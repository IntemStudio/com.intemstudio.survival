class_name EquipmentDrop
extends InteractableArea

## 월드에 떨어진 장비 item_id를 상호작용으로 런 인벤토리에 획득합니다.

const PROMPT_OFFSET := Vector2(-120.0, -72.0)
const BASE_SCALE := Vector2(0.72, 0.72)

@export var item_id := ""

var _pulse_time := 0.0
var _registry := ItemRegistry.new()
var _item_display_name := ""

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_registry.register_all_catalogs()
	PhysicsLayers.apply_pickup(self)
	collision_mask = PhysicsLayers.MASK_PLAYER
	monitoring = true
	monitorable = true
	_refresh_visuals()
	var prompt_label := get_interaction_prompt_label()
	if prompt_label != null:
		prompt_label.position = PROMPT_OFFSET
	super._ready()


func setup(new_item_id: String) -> void:
	item_id = new_item_id.strip_edges()
	if is_node_ready():
		_refresh_visuals()
		refresh_interaction_prompt()


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 4.0) * 0.08
	_sprite.scale = BASE_SCALE * pulse


func _get_interaction_text() -> String:
	var display_name := _item_display_name if not _item_display_name.is_empty() else item_id
	return UiLocale.t(&"equipment_drop.prompt_label") % display_name


func _on_interact(_player: Node2D) -> void:
	_try_acquire()


func _try_acquire() -> void:
	var game := _find_game_root()
	if game == null or not game.has_method("try_acquire_dropped_equipment_item"):
		_show_floating_status(UiLocale.t(&"equipment_drop.error_unavailable"))
		return
	var err: StringName = game.call("try_acquire_dropped_equipment_item", item_id)
	if err.is_empty():
		queue_free()
		return
	_show_floating_status(UiLocale.t(err))


func _refresh_visuals() -> void:
	var resource := _registry.resolve_gear_or_weapon(item_id)
	if resource is WeaponData:
		var weapon := resource as WeaponData
		_sprite.texture = weapon.texture if weapon.texture != null else _sprite.texture
		_item_display_name = weapon.get_display_name_localized()
	elif resource is GearData:
		var gear := resource as GearData
		_sprite.texture = gear.texture if gear.texture != null else _sprite.texture
		_item_display_name = gear.get_display_name_localized()
	else:
		_item_display_name = item_id
	_sprite.scale = BASE_SCALE


func _show_floating_status(message: String) -> void:
	FloatingInfoText.spawn_equipment_status(global_position, message)


func _find_game_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var current := tree.current_scene
	if current and current.has_method("try_acquire_dropped_equipment_item"):
		return current
	return get_node_or_null("/root/Game")
