class_name EquipmentDrop
extends Area2D

## 월드에 떨어진 장비 item_id를 상호작용으로 런 인벤토리에 획득합니다.

const INTERACT_ACTION := &"interact"
const PROMPT_OFFSET := Vector2(-120.0, -72.0)
const BASE_SCALE := Vector2(0.72, 0.72)

@export var item_id := ""

var _player_in_range := false
var _interacting := false
var _pulse_time := 0.0
var _registry := ItemRegistry.new()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt_label: Label = $PromptLabel


func _ready() -> void:
	_registry.register_all_catalogs()
	PhysicsLayers.apply_pickup(self)
	collision_mask = PhysicsLayers.MASK_PLAYER
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt_label.position = PROMPT_OFFSET
	_refresh_visuals()
	call_deferred("_refresh_player_overlap")


func setup(new_item_id: String) -> void:
	item_id = new_item_id.strip_edges()
	if is_node_ready():
		_refresh_visuals()


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 4.0) * 0.08
	_sprite.scale = BASE_SCALE * pulse


func _unhandled_input(event: InputEvent) -> void:
	if _interacting or not _player_in_range:
		return
	if not _is_interact_pressed(event):
		return
	_try_acquire()
	get_viewport().set_input_as_handled()


func _is_interact_pressed(event: InputEvent) -> bool:
	return event.is_action_pressed(INTERACT_ACTION)


func _try_acquire() -> void:
	var game := _find_game_root()
	if game == null or not game.has_method("try_acquire_dropped_equipment_item"):
		_show_floating_status(UiLocale.t(&"equipment_drop.error_unavailable"))
		return
	_interacting = true
	var err: StringName = game.call("try_acquire_dropped_equipment_item", item_id)
	_interacting = false
	if err.is_empty():
		queue_free()
		return
	_show_floating_status(UiLocale.t(err))


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = true
	_sync_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = false
	_sync_prompt()


func _refresh_player_overlap() -> void:
	_player_in_range = false
	for body in get_overlapping_bodies():
		if body.name == "Player":
			_player_in_range = true
			break
	_sync_prompt()


func _refresh_visuals() -> void:
	var resource := _registry.resolve_gear_or_weapon(item_id)
	if resource is WeaponData:
		var weapon := resource as WeaponData
		_sprite.texture = weapon.texture if weapon.texture != null else _sprite.texture
		_prompt_label.text = UiLocale.t(&"equipment_drop.prompt") % weapon.get_display_name_localized()
	elif resource is GearData:
		var gear := resource as GearData
		_sprite.texture = gear.texture if gear.texture != null else _sprite.texture
		_prompt_label.text = UiLocale.t(&"equipment_drop.prompt") % gear.get_display_name_localized()
	else:
		_prompt_label.text = UiLocale.t(&"equipment_drop.prompt") % item_id
	_sprite.scale = BASE_SCALE
	_sync_prompt()


func _sync_prompt() -> void:
	if _prompt_label == null:
		return
	_prompt_label.visible = _player_in_range


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
