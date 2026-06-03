# Architecture — Physics Layers (2D 물리 레이어)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 실행 must: [`.cursor/rules/godot-core.mdc`](../../.cursor/rules/godot-core.mdc) · 연동: [`Architecture_Pool.md`](Architecture_Pool.md), [`Architecture_Projectiles.md`](Architecture_Projectiles.md), [`Architecture_Player.md`](Architecture_Player.md), [`Architecture_Mobs.md`](Architecture_Mobs.md)

Godot 2D `collision_layer` / `collision_mask`는 비트 플래그다. 슬롯 번호(1–4), 비트 값, `project.godot` 이름, `PhysicsLayers` 상수·`apply_*()`가 한 세트로 맞아야 한다. 새 스크립트에서 레이어 정수를 직접 쓰지 않고 `PhysicsLayers` API로 적용한다.

## Overview

- **코드 SSOT:** `game/physics_layers.gd` (`class_name PhysicsLayers`)
- **에디터 이름 SSOT:** `project.godot` → `[layer_names]` → `2d_physics/layer_*`
- **적용 시점:** 노드 `_ready()`, 풀 `pool_on_acquire()`, 스폰 직후 setup (`map_arena` 장애물, `Game.spawn_mob` 경로의 몹 등)
- **검증 헬퍼:** `PhysicsLayers.layer_matches(mask, layer)` — 마스크가 특정 레이어 비트를 포함하는지 확인

몹 본체는 몹끼리만 충돌하고 환경·플레이어 CharacterBody와는 통과한다. 플레이어 본체는 환경만 막는다. 플레이어 HurtBox·발사체·장판·Gun 조준은 Area2D로 `collision_layer = 0`, `monitorable = false`이며 마스크만 역할별로 다르다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 레이어·마스크 상수 | `ENVIRONMENT`, `MOBS`, `PICKUP`, `PLAYER`, `MASK_*` 조합 |
| 역할별 apply | `apply_player_body`, `apply_mob_body`, `apply_player_projectile` 등 |
| 슬롯·이름·비트 표 | 아래 표 — `project.godot`와 동기 |
| 변경 시 동기 대상 | `physics_layers.gd`, `project.godot`, 관련 `.tscn`, 풀 `pool_on_acquire` |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 발사체 movement·피해 | [`Architecture_Projectiles.md`](Architecture_Projectiles.md) |
| 풀 acquire/release 순서 | [`Architecture_Pool.md`](Architecture_Pool.md) |
| 맵 스폰·장애물 배치 알고리즘 | [`Docs/Agents/AGENTS_MapArena.md`](../Agents/AGENTS_MapArena.md) — 스폰 겹침 재시도는 layer 1(environment) 기준 |
| 몹 전용 투사체 레이어 분리 | [`BACKLOG.md`](../../BACKLOG.md) 후속 |

## Key Types & Relationships

| 파일 | 역할 |
|------|------|
| `game/physics_layers.gd` | 레이어·마스크 상수, `apply_*()`, `layer_matches()` |
| `project.godot` | `2d_physics/layer_1` … `layer_4` 표시 이름 |
| `entities/player/player.gd` | `_ready`에서 `apply_player_body` / `apply_player_hurtbox` / `apply_player_pickup_range` |
| `entities/mob/mob.gd` | `pool_on_acquire` → `apply_mob_body` |
| `world/map_arena/map_arena.gd` | 소나무·장애물 `apply_environment_body` |
| 무기·이펙트 pooled Area2D | `pool_on_acquire` 또는 `_ready`에서 `apply_player_projectile` / `apply_player_area_zone` / `apply_mob_projectile` 등 |

### Godot 슬롯 ↔ 비트 ↔ 이름 (`collision_layer`)

| Slot | Value (bit) | `project.godot` name | Typical node | Typical `collision_mask` |
|------|-------------|----------------------|--------------|--------------------------|
| 1 | 1 | environment | 장애물 `StaticBody2D` | 0 |
| 2 | 2 | mobs | 몹 `CharacterBody2D` | 2 (mobs only) |
| 3 | 4 | pickup | 경험치·드롭 `Area2D` | 0 (`monitorable`로 픽업 감지) |
| 4 | 8 | player | 플레이어 `CharacterBody2D` | 1 (environment only) |

### 마스크 상수 (`collision_mask` / 조합)

| Role | Constant | Value | Detects (layers) |
|------|----------|-------|------------------|
| Player body | `MASK_PLAYER_BODY` | 1 | environment |
| Mob body | `MASK_MOB_BODY` | 2 | mobs |
| Player HurtBox | `MASK_PLAYER_HURTBOX` | 2 | mobs |
| Player PickupRange | `MASK_PLAYER_PICKUP` | 4 | pickup |
| Player projectiles | `MASK_PLAYER_PROJECTILE` | 3 | environment + mobs |
| Mob projectiles | `MASK_MOB_PROJECTILE` | 9 | environment + player |
| Player area zones | `MASK_PLAYER_AREA_ZONE` | 2 | mobs |
| Gun targeting | `MASK_PLAYER_TARGETING` | 2 | mobs |

비트 합산 예: `MASK_PLAYER_PROJECTILE` = `ENVIRONMENT | MOBS` = 1 | 2 = **3**. `MASK_MOB_PROJECTILE` = `ENVIRONMENT | PLAYER` = 1 | 8 = **9**.

### `apply_*()` 매핑

| Function | Target | `collision_layer` | `collision_mask` | Notes |
|----------|--------|-------------------|------------------|-------|
| `apply_environment_body` | `StaticBody2D` | `ENVIRONMENT` (1) | 0 | |
| `apply_player_body` | `CharacterBody2D` | `PLAYER` (8) | `MASK_PLAYER_BODY` (1) | 이동·대시 동일 본체 |
| `apply_player_hurtbox` | `Area2D` | 0 | `MASK_PLAYER_HURTBOX` (2) | `monitorable = false` |
| `apply_player_pickup_range` | `Area2D` | 0 | `MASK_PLAYER_PICKUP` (4) | `monitorable = false` |
| `apply_player_projectile` | `Area2D` | 0 | `MASK_PLAYER_PROJECTILE` (3) | 탄환·투척·부메랑·궤도 등 |
| `apply_player_area_zone` | `Area2D` | 0 | `MASK_PLAYER_AREA_ZONE` (2) | 연금 장판 등 |
| `apply_mob_body` | `CharacterBody2D` | `MOBS` (2) | `MASK_MOB_BODY` (2) | 풀 재획득 시 복원 |
| `apply_mob_projectile` | `Area2D` | 0 | `MASK_MOB_PROJECTILE` (9) | |
| `apply_pickup` | `Area2D` | `PICKUP` (4) | 0 | `monitorable = true` |
| `apply_elite_ember_hazard` | `Area2D` | 0 | `MASK_PLAYER` (8) | 엘리트 잔불 — 플레이어 본체만 |

Gun 조준 `Area2D`(`gun.tscn`)는 씬에 `collision_mask = 2`로 두며 `MASK_PLAYER_TARGETING`과 동일하다. 별도 `apply_*`는 없다.

## Flow

### 플레이어 (씬 로드 1회)

1. `player.gd` `_ready()` → `apply_player_body(self)`, `apply_player_hurtbox(%HurtBox)`, `apply_player_pickup_range(%PickupRange)`.
2. 대시는 별도 physics layer 없이 동일 `CharacterBody2D` 이동으로 처리한다.

### 몹 (풀)

1. `pool_reset()` → `collision_layer` / `collision_mask` = 0.
2. `pool_on_acquire()` → `apply_mob_body(self)` + `add_to_group("mobs")`.

### 플레이어 공격 오브젝트 (풀)

1. `ScenePool.acquire` → `pool_on_acquire()`에서 `apply_player_projectile` 또는 `apply_player_area_zone`.
2. `.tscn` 기본 mask(2 또는 3)는 prewarm·에디터 미리보기용; 런타임 계약은 `apply_*`가 우선한다.

### 몹 원거리

1. `mob_projectile` `pool_on_acquire()` → `apply_mob_projectile`.

### 맵 장애물

1. `map_arena`가 소나무 등 `StaticBody2D` 생성 시 `apply_environment_body`.

### 픽업

- `equipment_drop`: `apply_pickup` + 수집 시 플레이어 감지용 `collision_mask = MASK_PLAYER` 오버라이드.
- `exp_orb` / `gold_coin`: 현재 `.tscn`에 `collision_layer = 4` 고정 — `pool_on_acquire`에서 `apply_pickup` 미호출. 레이어 변경 시 `.tscn`과 PickupRange 마스크를 함께 맞출 것.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 새 코드에서 레이어 비트(1, 2, 4, 8, 3, 9 등)를 직접 대입하지 않는다. | `physics_layers.gd`와 드리프트 방지. |
| Area2D 공격·피격·픽업 범위는 `collision_layer = 0`, `monitorable = false`가 기본이다. | 역할은 mask로만 구분. |
| 몹 본체 mask는 mobs(2)만 — environment·player와 CharacterBody 충돌 없음. | 서바이버 이동·벽 통과 UX. |
| 플레이어 발사체 mask 3 = 벽 + 몹; 장판 mask 2 = 몹만. | 환경에 막히는 탄환 vs 바닥 AoE 분리. |
| 몹 투사체 mask 9 — player(8) 포함 필수. | mask를 environment(1)만 쓰면 플레이어 미적중. |
| `mobs` 그룹 이름 변경 금지. | 타겟팅·스폰·밸런스가 그룹에 의존. |
| 레이어 슬롯 추가·순서 변경은 Godot 프로젝트 전역 영향. | `physics_layers.gd`, 모든 `.tscn`, 문서·`.mdc` 동시 갱신. |

## Change Guidelines

| 변경 | 같이 확인할 것 |
|------|----------------|
| 슬롯·이름·비트 | `physics_layers.gd`, `project.godot` `[layer_names]`, 이 문서, `godot-core.mdc`, `godot-mobs.mdc`, `godot-weapons.mdc` |
| 새 Area2D 역할 | 적절한 `MASK_*` + `apply_*` 추가 여부, pooled면 `pool_on_acquire` |
| 플레이어·몹·발사체 `.tscn` | 에디터 기본값과 `apply_*` 일치 — 풀 경로는 acquire 시 apply가 SSOT |
| Gun·타겟팅 | `gun.tscn` mask = `MASK_PLAYER_TARGETING` |
| 스폰 겹침·장애물 | `AGENTS_MapArena.md` — environment layer(1) 기준 |
| F6 테스트 플레이어 | `test_arena.gd`의 `apply_player_body` |

최소 검증: F5/F6에서 플레이어·몹 이동(벽/몹 통과), HurtBox 접촉 피해, 발사체 벽·몹 충돌, 장판 몹만, 몹 탄 플레이어 적중, 경험치·장비 드롭 수집.
