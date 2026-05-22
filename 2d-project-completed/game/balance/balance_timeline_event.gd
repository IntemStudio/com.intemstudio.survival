extends Resource
class_name BalanceTimelineEvent

## 표 축(분) 시각에 한 번 발동하는 스폰·밀도 스파이크 이벤트.

@export var event_id: String = ""
@export_range(0.0, 60.0, 0.1, "or_greater") var at_minute: float = 11.0
@export var banner_message: String = ""
@export_range(1.0, 3.0, 0.05) var density_mult: float = 1.0
@export_range(0.0, 180.0, 0.1) var density_duration_seconds: float = 0.0
@export_range(0, 20, 1) var forced_spawn_count: int = 0
@export var forced_mob_scene: PackedScene
