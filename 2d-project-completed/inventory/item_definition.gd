extends Resource
class_name ItemDefinition

## 카탈로그 아이템 공통 정의 — 무기(WeaponData)·장비(GearData)가 공유하는 필드.

@export var item_id := ""
@export var display_name := ""
@export var display_name_ko := ""
@export var rarity := "Common"
@export var texture: Texture2D = null
## 착용 가능 슬롯 키(EquipSlots.*). GearData는 gear_slot과 함께 사용.
@export var equip_slots: PackedStringArray = []
## 예: {"armor": 12, "move_speed_mult": 1.05}
@export var stat_modifiers: Dictionary = {}
## false면 해금(기본). true면 잠금 — F6 필터·보상 풀 등에서 제외 가능.
@export var is_locked := false


func get_unique_key() -> String:
	if not item_id.is_empty():
		return item_id
	if not resource_path.is_empty():
		return resource_path
	return display_name


func get_display_name_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not display_name.is_empty():
		return display_name
	return display_name_ko if not display_name_ko.is_empty() else display_name


# 지정 착용 슬롯에 들어갈 수 있는지 확인합니다.
func fits_slot(slot_key: StringName) -> bool:
	var slot_str := EquipSlots.slot_key_to_string(slot_key)
	for entry in equip_slots:
		if String(entry) == slot_str:
			return true
	return false
