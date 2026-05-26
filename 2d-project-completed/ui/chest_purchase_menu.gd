class_name ChestPurchaseMenu
extends CanvasLayer

signal purchase_requested(chest: GoldChest)
signal close_requested

var _chest: GoldChest
var _details: Dictionary = {}
var _purchase_finished := false

@onready var _title_label: Label = %TitleLabel
@onready var _slot_label: Label = %SlotLabel
@onready var _odds_label: Label = %OddsLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _status_label: Label = %StatusLabel
@onready var _buy_button: Button = %BuyButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_buy_button.pressed.connect(_on_buy_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	refresh_locale()
	hide()


func present_chest(chest: GoldChest, details: Dictionary) -> void:
	_chest = chest
	_details = details.duplicate()
	_purchase_finished = false
	_apply_details()


func show_result(message: String) -> void:
	_purchase_finished = true
	_status_label.text = message
	_buy_button.disabled = true
	_cancel_button.text = UiLocale.t(&"chest.purchase.close")


func show_error(message: String, details: Dictionary = {}) -> void:
	if not details.is_empty():
		_details = details.duplicate()
	_apply_details()
	_status_label.text = message


func refresh_locale() -> void:
	if not is_node_ready():
		return
	_buy_button.text = UiLocale.t(&"chest.purchase.buy")
	_cancel_button.text = UiLocale.t(&"chest.purchase.close") if _purchase_finished else UiLocale.t(&"chest.purchase.cancel")
	_apply_details()


func _apply_details() -> void:
	if not is_node_ready():
		return
	var title_text := String(_details.get("title", UiLocale.t(&"chest.purchase.title")))
	_title_label.text = title_text
	_slot_label.text = String(_details.get("slot_text", ""))
	_odds_label.text = String(_details.get("odds_text", ""))
	_gold_label.text = String(_details.get("gold_text", ""))
	_status_label.text = String(_details.get("status_text", ""))
	_buy_button.disabled = _purchase_finished or not bool(_details.get("can_purchase", false))
	_cancel_button.text = UiLocale.t(&"chest.purchase.close") if _purchase_finished else UiLocale.t(&"chest.purchase.cancel")


func _on_buy_button_pressed() -> void:
	if _chest == null or _purchase_finished:
		return
	purchase_requested.emit(_chest)


func _on_cancel_button_pressed() -> void:
	close_requested.emit()
