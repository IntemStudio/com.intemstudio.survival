# Architecture — Effects & Pickups (`effects/`)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 풀: [`Architecture_Pool.md`](Architecture_Pool.md) · 물리: [`Architecture_PhysicsLayers.md`](Architecture_PhysicsLayers.md) · 몹 사망·보상: [`Architecture_Mobs.md`](Architecture_Mobs.md) · 플레이어 수집: [`Architecture_Player.md`](Architecture_Player.md) · 엘리트: [`Architecture_EliteForms.md`](Architecture_EliteForms.md) · 밸런스 보상: [`Architecture_GameLoop_Balance.md`](Architecture_GameLoop_Balance.md)

`effects/`는 월드에 떨어지는 **픽업**, **짧은 연출**, **전투 피드백 유틸**을 모은 폴더다. 몹 스킬 전용 연출(`entities/mob/chase/skills/effects/`)과 발사체·장판(`weapons/projectiles/`)은 여기 범위가 아니다.

## Overview

픽업(exp/gold/magnet/health/equipment)은 몹 사망·인벤 드롭·엘리트 유물 드랍 경로에서 스폰되고, 플레이어 `%PickupRange` 또는 자석 이동으로 수집된다. 경험치·골드는 고빈도라 `ScenePool`로 재사용하고, 자석·체력·장비 드롭·1회 연출은 `instantiate` + `queue_free`다.

피드백 계층은 노드 씬이 아닌 static API 위주다. `HitFlash`는 `CanvasItem.modulate` 깜박임, `FloatingText` 계열은 `Game` 자식으로 짧게 떠오르는 라벨을 생성한다. 사망 폭발 예고(`death_burst_warning`)와 연기(`smoke_explosion`)는 몹 `_die()`·`AttackFactory`에서 1회 스폰한다. 엘리트 blazing affix 잔불(`elite_ember_hazard`)만 hazard이면서 풀링 대상이다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 픽업 스폰·수집 | exp/gold/magnet/health/equipment 월드 노드와 플레이어 `gain_*` / `collect()` / 상호작용 획득 |
| 자석 이동 | exp/gold가 `start_magnet()`으로 플레이어를 추적, 접근 시 보상·풀 반환 |
| 픽업 물리 | pickup layer(4) + 플레이어 `%PickupRange` mask(4) 계약 |
| 전투 피드백 | 피격 깜박임, 플로팅 데미지·상태이상·안내 문구 |
| 사망·폭발 연출 | smoke, death burst warning, poison explosion visual(AttackFactory) |
| 엘리트 지면 hazard | blazing affix 잔불 — 접촉 시 `apply_elite_debuff` |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 처치 보상 수치·페이즈 곡선 | `KillRewards`, `BalanceTable`, `game.gd` |
| 레벨업·골드 소비 UI | `Player`, `Game`, HUD |
| 몹 스킬 landing burst | `entities/mob/chase/skills/effects/` |
| 발사체·장판 movement·피해 | [`Architecture_Projectiles.md`](Architecture_Projectiles.md) |
| 상태이상 정의·tick | [`Architecture_StatusEffects.md`](Architecture_StatusEffects.md) — 표시만 `FloatingStatusEffectText` |
| `InteractableArea` 베이스 계약 전체 | `game/interaction/interactable_area.gd` — equipment_drop이 상속 |

## Key Types & Relationships — `effects/` 폴더 지도

| 경로 | 타입 | 풀링 | 역할 |
|------|------|------|------|
| `exp_orb/` | `Area2D` | ✅ | XP 오브. 그룹 `exp_orbs`. `experience_value` 설정 후 자석·`gain_experience` |
| `gold_coin/` | `Area2D` | ✅ | 골드. 그룹 `gold_coins`. `gold_value` 설정 후 `gain_gold` |
| `magnet_pickup/` | `Area2D` | ❌ | `collect()` 시 필드 exp/gold 전부 `start_magnet`. 드랍률 ~1% |
| `health_pickup/` | `Area2D` | ❌ | `collect()` → `heal_health`. 드랍률 ~1% |
| `equipment_drop/` | `EquipmentDrop` (`InteractableArea`) | ❌ | 월드 장비·유물. E 상호작용 → `Game.try_acquire_dropped_equipment_item` |
| `hit_flash/` | `HitFlash` (`RefCounted`) | — | static `play` / `cancel` on `CanvasItem` |
| `floating_text/` | `FloatingText` + 파생 static API | ❌ | 공통 떠오르는 라벨 씬. 용도별 래퍼 3종 |
| `death_burst/` | `Node2D` | ❌ | 폭발 전 반경 링 예고. delay 후 `AttackFactory` 콜백 |
| `smoke_explosion/` | `Node2D` + shader | ❌ | 몹 사망 연기. AnimationPlayer 종료 후 free |
| `elite_ember/` | `EliteEmberHazard` (`Area2D`) | ✅ | blazing affix 잔불 hazard |

### Floating text 계층

| 스크립트 | 용도 |
|----------|------|
| `floating_text.gd` | `FloatingText.spawn` / `spawn_with_offset` — 부모 `Game`, tween 후 `queue_free` |
| `floating_damage_text.gd` | 무기/몹/플레이어/독 피해 숫자. `GameplaySettings.is_floating_damage_visible()` 게이트 |
| `floating_status_effect_text.gd` | 상태이상 적용·Resisted 문구 |
| `floating_info_text.gd` | 장비 획득 실패, 부활 등 안내 |

### Pickup 수집 계약 (duck typing)

| 메서드 | 대상 | 호출자 |
|--------|------|--------|
| `collect(player)` | magnet, health | `Player._on_pickup_range_area_entered` |
| `start_magnet(player)` | exp_orb, gold_coin | PickupRange 진입, magnet_pickup, `Player.magnetize_field_pickups`, orb/coin `pool_on_acquire` deferred |
| `gain_experience` / `gain_gold` | Player | exp_orb / gold_coin magnet 도착 시 |
| `_on_interact` → `_try_acquire` | EquipmentDrop | `InteractableArea` 입력 |

관계:

```text
mob.gd _die() / game.gd drop / elite relic
  -> spawn effects/* (pool or instantiate)
Player %PickupRange (mask pickup)
  -> area_entered -> collect() | start_magnet()
exp_orb / gold_coin _physics_process
  -> gain_experience | gain_gold -> PoolUtil.release_node

mob/player damage paths
  -> HitFlash.play | FloatingDamageText | FloatingStatusEffectText
AttackFactory.schedule_mob_death_burst
  -> death_burst_warning.setup -> spawn_mob_death_burst
elite_ember_spawner
  -> ScenePool.acquire(ELITE_EMBER_HAZARD) -> setup -> lifetime release
```

## Flow

### Runtime — 몹 사망 픽업

1. `Mob._die()`가 `register_kill()` 후 `_compute_kill_rewards()`로 xp/gold를 계산한다.
2. xp > 0이면 `ObjectPools.acquire(EXP_ORB_SCENE, spawn_parent)` (fallback: instantiate), `global_position`·`experience_value` 설정.
3. gold > 0이면 동일하게 `GOLD_COIN_SCENE`, `GOLD_DROP_OFFSET`으로 위치 분리.
4. 각각 `randf() < 0.01`로 magnet·health 픽업을 instantiate (오프셋 랜덤, exp와 겹침 완화).
5. smoke_explosion instantiate 후 몹 `PoolUtil.release_node(self)`.
6. exp/gold는 `pool_on_acquire`에서 그룹 등록 + deferred `_try_auto_magnet` — 이미 `pickup_range` 안이면 즉시 자석.

### Runtime — 플레이어 수집

1. `%PickupRange`는 `PhysicsLayers.apply_player_pickup_range` (`mask = MASK_PLAYER_PICKUP = 4`).
2. pickup layer(4) `Area2D`가 범위에 들어오면 `_on_pickup_range_area_entered`.
3. `collect` 있으면 즉시 처리(magnet/health → `queue_free`).
4. `start_magnet` 있으면 exp/gold 자석 시작; 도착(`collect_distance` 24px) 시 Player API 호출 후 풀 반환.
5. 패시브 `magnet_pulse` 등은 `Player.magnetize_field_pickups()`로 그룹 전체 `start_magnet`.

### Runtime — 장비 월드 드롭

1. **인벤 버리기:** `Game.drop_equipment_item` → `EquipmentDrop.setup(item_id)` → 플레이어 전방 96px.
2. **엘리트 유물:** `Mob._try_drop_elite_relic()` — affix `drops_relic`, `get_relic_drop_rate()` 통과 시 몹 위치 spawn.
3. **F6 테스트:** `test_arena.gd`에서 동일 씬으로 드롭 테스트.
4. 상호작용 성공 시 `queue_free`; 실패 시 `FloatingInfoText.spawn_equipment_status`.

### Runtime — 연출·피드백

1. **Hit flash:** `Mob` `%Slime`, `Player` `_hit_flash_target` — 피격 시 `HitFlash.play`, 풀 반환·tint 복구 시 `HitFlash.cancel`.
2. **Floating damage:** `Mob.apply_weapon_damage` / status tick / `Player` 피격 — `FloatingDamageText.*` (설정 off면 스킵).
3. **Status float:** `StatusEffectController` 신규 적용 시 `FloatingStatusEffectText.spawn_status_applied`.
4. **Death burst:** `Mob._trigger_death_burst` → `AttackFactory.schedule_mob_death_burst` — `delay > 0`이면 `death_burst_warning` → 타이머 후 `spawn_mob_death_burst` (피해 + poison explosion visual).
5. **Smoke:** `_die()` 직후 몹 위치 1회.
6. **Elite ember:** `elite_ember_spawner` → acquire → `setup(lifetime, radius)` → 주기적 burn debuff → lifetime `PoolUtil.release_node`.

### Editor / Data

1. pickup 씬은 `collision_layer = 4`, `monitorable = true` (씬 또는 `apply_pickup`).
2. equipment_drop은 `item_id` 문자열로 `ItemRegistry` 비주얼·프롬프트 갱신.
3. floating damage 표시는 `GameplaySettings` / 설정 UI 토글과 동기.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| exp/gold는 풀 acquire 후 `PoolUtil.release_node`로 끝낸다. | [`Architecture_Pool.md`](Architecture_Pool.md) — `queue_free` 금지. |
| magnet/health/equipment/smoke/warning/floating text는 `queue_free`. | 저빈도·1회 수명. 풀 전환 시 pool 계약 추가 필요. |
| per-spawn 값(`experience_value`, `gold_value`)은 acquire **후** 호출자가 설정. | `_ready()`는 prewarm 시 1회만. |
| gold `pool_reset`은 `gold_value = 0`. | 재사용 시 이전 값 누수 방지. |
| PickupRange는 `collect`를 `start_magnet`보다 먼저 검사. | magnet_pickup은 `collect`만 구현. |
| exp/gold 자석 중복은 `_magnet_target` 가드. | 이중 `gain_*` 방지. |
| `/root/Game/Player` 하드 참조는 exp_orb deferred auto-magnet에 사용. | 씬 계약 변경 시 grep 필수. |
| 새 플로팅 텍스트는 `FloatingText` 파생 static API로. | parallel 시스템 금지 (`.cursor/rules/godot-weapons.mdc`). |
| `HitFlash.cancel`은 mob `pool_reset`·tint 변경 경로에서 호출. | 풀 반환 후 modulate stuck 방지. |
| EquipmentDrop 획득은 `Game.try_acquire_dropped_equipment_item`만. | 인벤 서비스·loadout 갱신 일원화. |
| Elite ember는 pause 중 tick/contact 무시. | 일시정지 중 debuff 방지. |
| `entities/mob/chase/skills/effects/` ≠ `effects/`. | 폴더 이름만 유사; 문서·import 혼동 주의. |

### Prewarm (`ObjectPools`)

| 씬 | export |
|----|--------|
| `exp_orb.tscn` | `prewarm_exp_orbs` |
| `gold_coin.tscn` | `prewarm_gold_coins` |
| `elite_ember_hazard.tscn` | `prewarm_elite_embers` |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 월드 픽업 | pickup layer, `collect` 또는 `start_magnet`+Player API, 드랍 경로(`mob.gd` 또는 `game.gd`), 빈도에 따른 풀 여부 |
| exp/gold magnet 튜닝 | `MAGNET_*` 상수 쌍(exp/gold 동일 구현 — 한쪽 수정 시 다른 쪽 동기) |
| PickupRange 반경 | `Player.pickup_range`, `%PickupRange` shape, 링 비주얼 `_sync_pickup_range_visual` |
| 장비 드롭 UX | `InteractableArea`, `UiLocale` equipment_drop 키, `try_acquire_dropped_equipment_item` 오류 코드 |
| 새 floating 종류 | `floating_text.tscn` 재사용, 색·offset은 static wrapper에만 |
| death burst delay | `mob` export, F6 death burst 튜닝, `AttackFactory.schedule_mob_death_burst` |
| elite ember | `elite_blazing_constants`, `PhysicsLayers.apply_elite_ember_hazard`, spawner prewarm |
| `/root/Game` 경로 변경 | `exp_orb.gd`, `FloatingText._get_spawn_parent`, equipment_drop `_find_game_root` |

최소 검증: F5/F6에서 몹 연속 처치 시 exp/gold 스폰·자석·풀 반환, magnet/health 드랍(확률), 인벤 드롭·엘리트 유물 상호작용, 피격 hit flash·floating damage 토글, death_burst_enabled 몹 지연 폭발 링, blazing 엘리트 잔불 debuff.
