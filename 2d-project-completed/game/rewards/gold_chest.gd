class_name GoldChest
extends InteractableArea

signal purchase_requested(chest: GoldChest)

## 웨이브 사이 골드 구매 상자. 가격은 월드 라벨로 항상 표시합니다.

@export var chest_id := "all"
@export var title_key: StringName = &"chest.type.all"
@export var slot_filter: StringName = ItemRewardPicker.SLOT_ALL
@export var price := 100

@onready var _price_label: Label = %PriceLabel
@onready var _sprite: Sprite2D = %ChestSprite

var _base_sprite_scale := Vector2.ONE
var _pulse_time := 0.0


func _ready() -> void:
	_base_sprite_scale = _sprite.scale
	collision_layer = 0
	collision_mask = PhysicsLayers.MASK_PLAYER
	monitorable = false
	monitoring = true
	super._ready()
	_refresh_price_label()


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 3.5) * 0.05
	_sprite.scale = _base_sprite_scale * pulse


func setup(config: Dictionary) -> void:
	chest_id = String(config.get("id", chest_id))
	title_key = StringName(config.get("title_key", title_key))
	slot_filter = StringName(config.get("slot_filter", slot_filter))
	price = int(config.get("price", price))
	if is_node_ready():
		_refresh_price_label()
		refresh_interaction_prompt()


func refresh_locale() -> void:
	super.refresh_locale()
	_refresh_price_label()


func get_config() -> Dictionary:
	return {
		"id": chest_id,
		"title_key": title_key,
		"slot_filter": slot_filter,
		"price": price,
	}


func set_available(available: bool) -> void:
	visible = available
	monitoring = available
	set_process(available)
	set_process_unhandled_input(available)
	if not available:
		clear_interaction_state()
	else:
		call_deferred("refresh_interaction_overlap")
	refresh_interaction_prompt()


func _get_interaction_text() -> String:
	return UiLocale.t(&"chest.interact")


func _on_interact(_player: Node2D) -> void:
	purchase_requested.emit(self)


func _refresh_price_label() -> void:
	if _price_label == null:
		return
	_price_label.text = UiLocale.t(&"chest.price_label") % price
