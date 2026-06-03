extends RefCounted

## 직업 카탈로그 엔트리 — PlayerClassCatalog._build_cache에서 호출합니다.

const VISUAL_KNIGHT := preload("res://characters/classes/knight/knight.tscn")
const VISUAL_ROGUE := preload("res://characters/classes/rogue/rogue.tscn")
const VISUAL_ELEMENTALIST := preload("res://characters/classes/elementalist/elementalist.tscn")

const SHARED_BASE_MAX_HEALTH := 110.0
const SHARED_MAX_HEALTH_PER_LEVEL := 33.0
const SHARED_BASE_ATTACK := 12.0
const SHARED_ATTACK_PER_LEVEL := 2.4
const SHARED_BASE_HEALTH_REGEN := 1.0
const SHARED_HEALTH_REGEN_PER_LEVEL := 0.2
const SHARED_MOVE_SPEED_MULT := 1.0


static func append_all(target: Array, create_class: Callable) -> void:
	_append(
		target,
		create_class,
		"knight",
		"Knight",
		"검사",
		"Balanced melee fighter with strong defense.",
		"균형 잡힌 근접 전투형. 높은 방어력.",
		VISUAL_KNIGHT,
		SHARED_BASE_MAX_HEALTH,
		SHARED_MAX_HEALTH_PER_LEVEL,
		SHARED_BASE_ATTACK,
		SHARED_ATTACK_PER_LEVEL,
		SHARED_BASE_HEALTH_REGEN,
		SHARED_HEALTH_REGEN_PER_LEVEL,
		SHARED_MOVE_SPEED_MULT,
		20
	)
	_append(
		target,
		create_class,
		"rogue",
		"Rogue",
		"도적",
		"Fast and agile. Excels at ranged hit-and-run.",
		"빠르고 기민한 원거리·기동전 특화.",
		VISUAL_ROGUE,
		SHARED_BASE_MAX_HEALTH,
		SHARED_MAX_HEALTH_PER_LEVEL,
		SHARED_BASE_ATTACK,
		SHARED_ATTACK_PER_LEVEL,
		SHARED_BASE_HEALTH_REGEN,
		SHARED_HEALTH_REGEN_PER_LEVEL,
		SHARED_MOVE_SPEED_MULT,
		0
	)
	_append(
		target,
		create_class,
		"elementalist",
		"Elementalist",
		"원소술사",
		"Channels elemental magic for sustained damage.",
		"원소 마법으로 지속 피해를 내는 술사.",
		VISUAL_ELEMENTALIST,
		SHARED_BASE_MAX_HEALTH,
		SHARED_MAX_HEALTH_PER_LEVEL,
		SHARED_BASE_ATTACK,
		SHARED_ATTACK_PER_LEVEL,
		SHARED_BASE_HEALTH_REGEN,
		SHARED_HEALTH_REGEN_PER_LEVEL,
		SHARED_MOVE_SPEED_MULT,
		0
	)


static func _append(
	target: Array,
	create_class: Callable,
	id: String,
	name_en: String,
	name_ko: String,
	description_en: String,
	description_ko: String,
	visual_scene: PackedScene,
	base_max_health: float,
	max_health_per_level: float,
	base_attack: float,
	attack_per_level: float,
	base_health_regen: float,
	health_regen_per_level: float,
	move_speed_mult: float,
	base_defense: int
) -> void:
	target.append(
		create_class.call(
			id,
			name_en,
			name_ko,
			description_en,
			description_ko,
			visual_scene,
			base_max_health,
			max_health_per_level,
			base_attack,
			attack_per_level,
			base_health_regen,
			health_regen_per_level,
			move_speed_mult,
			base_defense
		)
	)
