class_name PhysicsLayers
extends RefCounted

## 2D 물리 레이어·마스크 단일 정의. 값·이름은 project.godot [layer_names]와 반드시 일치.

# region 레이어 (collision_layer 비트)
const ENVIRONMENT := 1  # 슬롯 1 — 소나무·벽 StaticBody2D
const MOBS := 2  # 슬롯 2 — 몹 CharacterBody2D
const PICKUP := 4  # 슬롯 3 — 경험치·아이템 Area2D
const PLAYER := 8  # 슬롯 4 — 플레이어 CharacterBody2D
# endregion

# region 마스크 조합 (collision_mask)
const MASK_ENVIRONMENT := ENVIRONMENT
const MASK_MOBS := MOBS
const MASK_PICKUP := PICKUP
const MASK_PLAYER := PLAYER

## 몹 본체 — 몹끼리만 밀림, 환경·플레이어 통과
const MASK_MOB_BODY := MOBS
## 플레이어 이동 — 벽·나무만 막음
const MASK_PLAYER_BODY := ENVIRONMENT
## 플레이어 HurtBox — 몹 접촉·겹침
const MASK_PLAYER_HURTBOX := MOBS
## 플레이어 PickupRange
const MASK_PLAYER_PICKUP := PICKUP
## 플레이어 발사체·투척·마법 탄 — 환경 + 몹
const MASK_PLAYER_PROJECTILE := ENVIRONMENT | MOBS
## 플레이어 지면 영역(연금 등) — 몹만
const MASK_PLAYER_AREA_ZONE := MOBS
## 플레이어 조준(Gun) — 사거리 내 몹 탐색
const MASK_PLAYER_TARGETING := MOBS
## 몹 원거리 발사체 — 환경 + 플레이어
const MASK_MOB_PROJECTILE := ENVIRONMENT | PLAYER
# endregion


static func layer_matches(mask: int, layer: int) -> bool:
	return (mask & layer) != 0


# 장애물 StaticBody2D
static func apply_environment_body(body: StaticBody2D) -> void:
	body.collision_layer = ENVIRONMENT
	body.collision_mask = 0


# 플레이어 루트 CharacterBody2D
static func apply_player_body(body: CharacterBody2D) -> void:
	body.collision_layer = PLAYER
	body.collision_mask = MASK_PLAYER_BODY


# 플레이어 HurtBox·PickupRange
static func apply_player_hurtbox(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = MASK_PLAYER_HURTBOX
	area.monitorable = false


static func apply_player_pickup_range(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = MASK_PLAYER_PICKUP
	area.monitorable = false


# 플레이어 쪽 Area2D 발사체·탄환
static func apply_player_projectile(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = MASK_PLAYER_PROJECTILE
	area.monitorable = false


# 플레이어 영역 지속 피해
static func apply_player_area_zone(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = MASK_PLAYER_AREA_ZONE
	area.monitorable = false


# 엘리트 불타는 잔불 — 플레이어 CharacterBody2D 감지
static func apply_elite_ember_hazard(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = MASK_PLAYER
	area.monitorable = false


# 몹 원거리 발사체
static func apply_mob_projectile(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = MASK_MOB_PROJECTILE
	area.monitorable = false


# 몹 CharacterBody2D (풀 재사용 시)
static func apply_mob_body(body: CharacterBody2D) -> void:
	body.collision_layer = MOBS
	body.collision_mask = MASK_MOB_BODY


# 픽업 Area2D
static func apply_pickup(area: Area2D) -> void:
	area.collision_layer = PICKUP
	area.collision_mask = 0
	area.monitorable = true
