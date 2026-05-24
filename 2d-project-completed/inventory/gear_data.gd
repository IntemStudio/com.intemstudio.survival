extends ItemDefinition
class_name GearData

## 방어구·방패·악세사리 등 — Gun 없이 스탯·패시브만 기여.

## 단일 주 슬롯. equip_slots와 겹치면 gear_slot이 우선됩니다.
@export var gear_slot: StringName = &""
## 궤도·상태이상 등 stat_modifiers만으로 표현하기 어려운 효과 설명(툴팁용).
@export var effect := ""
@export var effect_ko := ""
## 조율 슬롯 비용(0이면 조율 없음).
@export var attunement := 1


func get_effect_localized() -> String:
	if UiLocale.get_locale() == UiLocale.LOCALE_EN and not effect.is_empty():
		return effect
	return effect_ko if not effect_ko.is_empty() else effect


func fits_slot(slot_key: StringName) -> bool:
	if not gear_slot.is_empty() and gear_slot == slot_key:
		return true
	return super.fits_slot(slot_key)
