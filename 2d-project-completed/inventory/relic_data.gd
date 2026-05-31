extends ItemDefinition
class_name RelicData

## 엘리트 유물 — 가방 보유만 전투 효과, 장착 슬롯 불가.

enum HeldEffectKind {
	ON_HIT_MOB_STATUS,
	ON_HIT_DELAYED_BURST,
	PERIODIC_SELF_HEAL,
	GOLD_MULTIPLIER,
}

@export var held_effect_kind: HeldEffectKind = HeldEffectKind.ON_HIT_MOB_STATUS
@export var effect_status_id: StringName = &""
@export var burst_delay_sec := 0.75
@export var burst_radius := 80.0
@export var burst_damage_ratio := 0.25
@export var heal_interval_sec := 3.0
@export var heal_percent_max_hp := 1.0
@export var gold_reward_mult := 1.0
@export var tint := Color(0.85, 0.75, 1.0, 1.0)
