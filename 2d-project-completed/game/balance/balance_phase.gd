extends Resource
class_name BalancePhase

## 시간(분) 키프레임 한 구간의 밸런스 값. 인스펙터에서 편집합니다.

@export_range(0.0, 60.0, 0.1, "or_greater") var minute: float = 0.0
@export_range(0.1, 10.0, 0.01, "or_greater") var hp_multiplier: float = 1.0
## 처치 XP·골드 배율(시간 키프레임 보간). HP와 분리해 루트 성장만 튜닝합니다.
@export_range(0.1, 5.0, 0.01, "or_greater") var loot_multiplier: float = 1.0
@export_range(0.1, 5.0, 0.01, "or_greater") var spawn_density: float = 1.0
@export_range(0.0, 5.0, 0.01, "or_greater") var threat: float = 1.0

@export_subgroup("Spawn Composition (0~1)")
@export_range(0.0, 1.0, 0.01) var fast_spawn_ratio: float = 0.0
@export_range(0.0, 1.0, 0.01) var ranged_spawn_ratio: float = 0.0
@export_range(0.0, 1.0, 0.01) var elite_spawn_ratio: float = 0.0
@export_range(0.0, 1.0, 0.01) var special_spawn_ratio: float = 0.0
@export_range(0, 5, 1) var special_mob_count: int = 0
@export_range(0.0, 1.0, 0.01) var boss_spawn_ratio: float = 0.0
@export var boss_spawn_enabled: bool = false

@export_multiline var design_intent: String = ""


func duplicate_phase() -> BalancePhase:
	var copy := duplicate() as BalancePhase
	return copy if copy else BalancePhase.new()
