# Architecture — Pool (오브젝트 풀)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 작업 규칙: [`.cursor/rules/godot-pool.mdc`](../../.cursor/rules/godot-pool.mdc) · 연동: [`Architecture_Mobs.md`](Architecture_Mobs.md), [`Architecture_Projectiles.md`](Architecture_Projectiles.md), [`Architecture_PhysicsLayers.md`](Architecture_PhysicsLayers.md), [`Architecture_GameLoop_Balance.md`](Architecture_GameLoop_Balance.md), [`Architecture_AttackSystem.md`](Architecture_AttackSystem.md)

`ScenePool`은 몹, 경험치·골드, 플레이어 발사체·영역 존, 몹 원거리·예고·돌진 레인, 엘리트 잔불 등 고빈도 씬의 acquire/release를 단일 서비스로 처리한다. 타입별 풀 클래스는 없고 `PackedScene.resource_path`로 버킷을 나눈다.

## Overview

메인 플레이 씬(`survivors_game.tscn`, `test_arena.tscn`)의 `Game/ObjectPools` 노드가 `ScenePool`을 실행한다. 호출자는 `acquire(scene, parent, spawn_global_position?)`로 노드를 빌려 쓰고, 수명이 끝나면 `PoolUtil.release_node(node)`로 반환한다. 풀에 등록되지 않은 노드는 `PoolUtil`이 `queue_free()`로 처리한다.

재사용 노드는 `_ready()`가 최초 prewarm/instantiate 때 한 번만 실행된다. 스폰마다 필요한 상태는 `pool_on_acquire()` 또는 호출자 setup(`initialize_spawn_health`, `setup()`, `setup_weapon()` 등)에서 설정한다. 반환 시 `pool_reset()`으로 게임플레이 그룹·충돌·타이머·시각 상태를 비운다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 풀 인프라 | `ScenePool` acquire/release, inactive 저장, prewarm, `default_max_per_scene` 상한 |
| 반환 헬퍼 | `PoolUtil.release_node()` — 풀 등록 여부에 따라 release 또는 free |
| pooled 노드 계약 | `pool_reset()`, `pool_on_acquire()` 구현, `queue_free()` 대신 `PoolUtil` 사용 |
| 스폰 진입점 | `Game.spawn_mob()`, `AttackFactory`, `mob.gd` 사망·공격, `loadout_grant_passive`, `elite_ember_spawner` |
| prewarm 설정 | `ObjectPools` `@export` 카운트, `MOB_PREWARM_SCENE_PATHS`, `_ready()` prewarm 목록 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 발사체 movement·피해 공식 | [`Architecture_Projectiles.md`](Architecture_Projectiles.md) |
| 몹 AI·사망 보상 규칙 | [`Architecture_Mobs.md`](Architecture_Mobs.md) |
| 물리 레이어 표·상수·apply | [`Architecture_PhysicsLayers.md`](Architecture_PhysicsLayers.md) |
| 저빈도 instantiate 대상 | `magnet_pickup`, `health_pickup`, `smoke_explosion`, `equipment_drop` 등 |
| Attack Entity 장기 목표 | [`Architecture_AttackSystem.md`](Architecture_AttackSystem.md) — 풀 계약은 여기서 유지 |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `game/pool/scene_pool.gd` | `class_name ScenePool` — 버킷, prewarm, acquire/release, activate/deactivate |
| `game/pool/pool_util.gd` | `class_name PoolUtil` — `release_node()` |
| `game/game.gd` | `$ObjectPools` — `spawn_mob()` acquire |
| `game/attack/attack_factory.gd` | 플레이어 발사체·영역 존 acquire (`_acquire` → `ObjectPools`) |
| `game/attack/attack_services.gd` | `ObjectPools`와 대칭인 `Game` 직계 자식 |
| `entities/mob/mob.gd` | 몹 pool_reset/on_acquire, exp/gold spawn, attack mark/projectile/charge lane |
| `weapons/core/gun.gd` | `AttackFactory` 경유 spawn, orbit companion release |
| `inventory/loadout_grant_passive.gd` | 패시브 orbital·dash dart acquire |
| `elite/elite_ember_spawner.gd` | blazing affix 잔불 hazard acquire |
| `effects/exp_orb/exp_orb.gd`, `effects/gold_coin/gold_coin.gd` | 픽업 풀 계약 |

관계:

```text
Game/ObjectPools (ScenePool)
  <- acquire(scene, parent, pos?)
  -> pool_reset → reparent → position → activate → pool_on_acquire
  <- PoolUtil.release_node
  -> pool_reset → deactivate → deferred storage under ObjectPools
```

### Prewarm 대상 (현행)

| 카테고리 | 씬 / 상수 | export |
|----------|-----------|--------|
| 원거리 탄 | `BULLET_SCENE` | `prewarm_bullets` |
| 마법 탄 | `MAGIC_BOLT_SCENE` | `prewarm_magic_bolts` |
| 근접 관통 | `MELEE_PROJECTILE_SCENE` | `prewarm_melee_projectiles` |
| 영역 존 | `AREA_DAMAGE_ZONE_SCENE` | `prewarm_area_damage_zones` |
| 투척 | `THROWING_PROJECTILE_SCENE` | `prewarm_throwing` |
| 부메랑 | `BOOMERANG_SCENE` | `prewarm_boomerangs` |
| 궤도 | `KING_BIBLE_ORB_SCENE` | `prewarm_king_bible_orbs` |
| 경험치 | `EXP_ORB_SCENE` | `prewarm_exp_orbs` |
| 골드 | `GOLD_COIN_SCENE` | `prewarm_gold_coins` |
| 몹 변종 | `MOB_PREWARM_SCENE_PATHS` | `prewarm_mobs_per_type` |
| 몹 투사체 | `MOB_PROJECTILE_SCENE` | `prewarm_mob_projectiles` |
| 몹 예고 | `MOB_ATTACK_MARK_SCENE` | `prewarm_mob_attack_marks` |
| 돌진 레인 | `MOB_CHARGE_LANE_SCENE` | `prewarm_mob_charge_lanes` |
| 엘리트 잔불 | `ELITE_EMBER_HAZARD_SCENE` | `prewarm_elite_embers` |

몹 prewarm 경로는 `MobSpawnSelector`와 compile-time preload 순환 참조를 피하기 위해 `MOB_PREWARM_SCENE_PATHS` 문자열 배열 + `_ready()`에서 `load()`한다.

## Flow

### acquire 순서 (`ScenePool.acquire`)

1. inactive 버킷에서 pop; 없으면 `scene.instantiate()` + 등록
2. `pool_reset()` (있으면)
3. `_pool_return_pending` 메타 제거
4. `parent`로 reparent (`parent.add_child`)
5. `spawn_global_position`이 유한하면 `Node2D.global_position` 설정
6. `_activate()` — `process_mode`, `visible`, `Area2D.monitoring/monitorable`
7. `_pooled_active = true`
8. **`pool_on_acquire()` 마지막** — 트리·process·Area 활성 이후

호출자는 acquire 반환 후에도 위치·`setup()`·`initialize_spawn_health()` 등을 추가로 호출할 수 있다.

### release 순서 (`ScenePool.release` / `PoolUtil.release_node`)

1. `_pool_return_pending`으로 중복 반환 방지
2. 활성 노드가 아니면 경고 후 `queue_free` (비정상 경로)
3. `_pooled_active = false`
4. `pool_reset()`
5. `_deactivate()` — process off, hidden, Area monitoring off
6. `default_max_per_scene` 초과 시 discard + `queue_free`
7. 그 외 `_store_inactive_deferred` — 부모가 자식 추가/제거 중일 때 동기 `remove_child` 실패 방지

### Prewarm (`_prewarm_scene`)

1. `instantiate()` → `_register_node`
2. `ObjectPools`에 `add_child`
3. `pool_reset()`
4. `_deactivate()`
5. inactive 버킷에 push

### Runtime — 주요 호출 경로

| 대상 | 경로 |
|------|------|
| 몹 | `Game.spawn_mob()` → `%MapArena.get_random_spawn_position(%Player.global_position)` → `acquire(mob_scene, Game, spawn_pos)` → `initialize_spawn_health()` |
| 경험치·골드 | `mob.gd` `_die()` → `acquire(EXP_ORB_SCENE` / `GOLD_COIN_SCENE`, spawn_parent) → position·value 설정 → 몹 `PoolUtil.release_node(self)` |
| 플레이어 발사체·영역 | `Gun.shoot()` → `AttackFactory.spawn_*` → `_acquire(scene)` → `setup` / `setup_weapon` → 종료 시 `PoolUtil.release_node` |
| 연금 착지 영역 | `concoction.gd` → `AttackFactory.spawn_area_circle` 또는 직접 acquire → zone lifetime 종료 시 release |
| 몹 원거리 | `mob.gd` windup → `acquire(MOB_ATTACK_MARK_SCENE, mob)` → timer → mark release → `acquire(MOB_PROJECTILE_SCENE, spawn_layer)` → projectile 종료 시 release |
| 돌진 레인 | `mob.gd` charge → `acquire(MOB_CHARGE_LANE_SCENE, spawn_parent)` → `setup_world` → lane 자체 lifetime release |
| 패시브 orbital/dash | `loadout_grant_passive.gd` → `acquire(KING_BIBLE_ORB_SCENE` / throwing scene, game) |
| 엘리트 잔불 | `elite_ember_spawner.gd` → `acquire(ELITE_EMBER_HAZARD_SCENE, ...)` |
| F6 단일 몹 | `test_arena.gd` — acquire/release로 테스트 몹 재사용 |

### Editor / Data

1. prewarm 수량은 `survivors_game.tscn` / `test_arena.tscn`의 `ObjectPools` `@export`로 조정한다.
2. 새 고빈도 씬은 `scene_pool.gd` `_ready()` prewarm + `@export`를 같은 PR에 추가한다.
3. 새 몹 변종은 `MOB_PREWARM_SCENE_PATHS`와 `MobSpawnSelector`를 함께 갱신한다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| pooled 노드는 `pool_reset()` / `pool_on_acquire()`를 구현한다. | 재사용 시 이전 spawn 상태가 섞이지 않게 한다. |
| per-spawn 설정을 `_ready()`에 두지 않는다. | prewarm/instantiate 시 한 번만 실행되기 때문이다. |
| `pool_reset()`에서 게임플레이 그룹(`mobs`, `exp_orbs` 등)을 제거하고 `pool_on_acquire()`에서 복원한다. | 그룹 쿼리 오염을 막는다. |
| 풀에서 acquire한 노드는 `PoolUtil.release_node(self)`로 끝낸다. `queue_free()` 금지. | inactive 버킷·등록 메타가 깨진다. |
| 몹 `pool_reset`: 상태·텔레그래프·충돌 layer/mask 0, `POOL_STORAGE_POSITION`으로 이동. | 비활성 몹이 전투·물리에 개입하지 않게 한다. |
| 몹 `pool_on_acquire`: `PhysicsLayers.apply_mob_body()`, `add_to_group("mobs")`. | layer/mask는 [`Architecture_PhysicsLayers.md`](Architecture_PhysicsLayers.md) SSOT를 따른다. |
| 몹 `_die()`는 `Game.register_kill()` 후 exp/gold spawn, 마지막에 `PoolUtil.release_node(self)`. | 처치 수·보상·풀 반환 순서 계약. |
| `release()`는 `_pool_return_pending`과 deferred storage로 이중 반환·부모 트리 변경 중 crash를 막는다. | hit deferred + 사거리 release 등 동시 종료가 있다. |
| `default_max_per_scene` 초과 시 discard + free. | 메모리 상한. |
| Area2D는 acquire 직후 overlap이 즉시 안 잡힐 수 있다. | 영역 존은 `_collect_hit_bodies()` 패턴 사용 (`Architecture_Projectiles.md`). |
| `ObjectPools` 없으면 instantiate fallback. | 테스트·부분 씬에서도 동작하게 한다. |

### Not pooled (현행)

| 대상 | 방식 | 비고 |
|------|------|------|
| `magnet_pickup`, `health_pickup` | `instantiate` + `collect()` 시 `queue_free` | 낮은 드랍률 (~1%) |
| `smoke_explosion`, `death_burst_warning`, `poison_explosion` | instantiate | 짧은 1회 연출 |
| `equipment_drop` (elite relic) | instantiate | 저빈도 |

나중에 풀링하면 `pool_reset`/`pool_on_acquire` 추가 후 `queue_free`를 `PoolUtil.release_node`로 교체한다.

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 pooled 씬 | `pool_reset()`, `pool_on_acquire()`, 종료 `PoolUtil.release_node`, prewarm export |
| 새 몹 변종 | `MobSpawnSelector`, `MOB_PREWARM_SCENE_PATHS`, `BalanceTable` spawn ratio |
| 새 플레이어 attack 씬 | `AttackFactory.spawn_*` 또는 `Gun` 경로, `PhysicsLayers` apply, prewarm |
| `ObjectPools` 이름/위치 변경 | grep `ObjectPools` / `ScenePool` — `game.gd`, `gun.gd`, `mob.gd`, `attack_factory.gd`, `test_arena.tscn` |
| prewarm 수량 튜닝 | F6/F5 동시 생존 peak, GC spike, inactive discard 로그 |
| 물리 레이어 변경 | [`Architecture_PhysicsLayers.md`](Architecture_PhysicsLayers.md) — `physics_layers.gd` + 각 타입 `pool_on_acquire` |

최소 검증: F5/F6에서 몹 스폰·사망(exp/gold)·원거리 예고·플레이어 다종 발사체·연금 영역·돌진 레인·엘리트 잔불이 반복 spawn/return 후 상태 누수 없이 동작하는지, 몹 연속 처치 시 `register_kill`과 exp orb가 정상인지 확인한다.
