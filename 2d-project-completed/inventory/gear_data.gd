extends ItemDefinition
class_name GearData

## 방어구·방패·악세사리 등 — Gun 없이 스탯·패시브만 기여.

## 단일 주 슬롯. equip_slots와 겹치면 gear_slot이 우선됩니다.
@export var gear_slot: StringName = &""


func fits_slot(slot_key: StringName) -> bool:
	if not gear_slot.is_empty() and gear_slot == slot_key:
		return true
	return super.fits_slot(slot_key)
