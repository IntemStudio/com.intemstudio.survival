# Architecture — Elite Forms (엘리트 형태·유물)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 기획: [`Wiki/EliteForms.md`](../Wiki/EliteForms.md) · 몹: [`Architecture_Mobs.md`](Architecture_Mobs.md) · 인벤: [`Architecture_Inventory.md`](Architecture_Inventory.md) · 플레이어: [`Architecture_Player.md`](Architecture_Player.md) · 몹 상태이상: [`Architecture_StatusEffects.md`](Architecture_StatusEffects.md) · 밸런스: [`Architecture_GameLoop_Balance.md`](Architecture_GameLoop_Balance.md)

**구현 상태:** **스켈레톤 PR-A+B** (affix 데이터·롤·적용·noop runtime, `mob`/`player`/`game`/`test_arena` 훅, F6 affix 드롭다운) · **갱신:** 2026-05-31

affix(엘리트 형태) 롤·적용·런타임 행동, 플레이어 debuff, 유물(relic) 드랍·가방 보유 효과의 코드 경계와 훅 지점을 정리한다. affix별 수치·티어 1 스펙 본문은 Wiki에 두고, 이 문서는 **타입·흐름·불변조건**만 다룬다. **PR-C 이후:** glacial/overloading behavior, relic, `KillRewards` affix XP, F5 `p_normal` 활성화.

## Overview

엘리트 형태는 `Mob` 스폰 직후 **확률적으로 붙는 단일 affix 레이어**다. `mob_kind = elite` 독립 프리팹과 병행하지 않고, 최종적으로 `MobSpawnSelector.elite_spawn_ratio`를 affix 롤로 **대체**하는 것이 목표다. affix는 몹 HP·공격 배율, tint, 머리 장식, affix 전용 tick(실드·오라·잔불 등)을 켠다. 플레이어에게 거는 화상·폭탄·감속·동결은 **`status/`가 아닌** `PlayerDebuffController`에서 처리한다. 처치 시 `KillRewards`에 affix XP 배율을 반영하고, affix 몹만 **0.025%** 확률로 **유물**을 드랍한다. 유물은 `ItemDefinition`과 분리된 `RelicData`이며, **가방 보유만** 전투에 반영된다(인벤의 “장착해야 효과” 규칙의 **유일한 예외**).

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| affix 정의 | `EliteAffixData` — id, HP/ATK 배율, tint, 드롭 relic id, void 여부 |
| affix 카탈로그 | tier 1 (`blazing`/`overloading`/`glacial`/`mending`/`gilded`) 조회 |
| 스폰 롤 | `EliteAffixRoller` — `p_normal`/`p_boss`, 제외 몹 kind, phase 분 |
| affix 적용 | 스폰 파이프라인에서 `initialize_spawn_health()` **이후** stat·비주얼·behavior 부트 |
| affix 런타임 | 몹당 shield, bomb on-hit, death burst, ground hazard, heal aura 등 |
| 플레이어 debuff | `PlayerDebuffController` — `elite_burn`/`elite_bomb`/`elite_chill`/`elite_freeze` |
| 유물 | `RelicData`, 가방 보유 합산, on-hit/주기 heal, 드롭·획득 |
| 보상 | affix 처치 XP ×1.5, relic roll in `Mob._die()` (클리어 사망 제외) |
| F6 | affix 강제 지정 스폰, relic 드롭 치트, QA E1~E9 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| affix 기획 수치·표 | [`Wiki/EliteForms.md`](../Wiki/EliteForms.md) |
| 몹 AI 공통(추격·접촉·원거리) | [`Architecture_Mobs.md`](Architecture_Mobs.md) |
| 몹 대상 weapon status | [`Architecture_StatusEffects.md`](Architecture_StatusEffects.md) — 유물 on-hit은 몹 `StatusEffectController` **재사용 가능** |
| 장착 loadout·버프 | [`Architecture_Inventory.md`](Architecture_Inventory.md), [`Architecture_Buffs.md`](Architecture_Buffs.md) |
| `elite_spawn_ratio` 제거·마이그레이션 일정 | [`BACKLOG.md`](../../BACKLOG.md) Phase 3 |
| 공허(Void) tier 스펙 | Wiki 미정 |
| pity·튜토리얼 보장 드롭 | Wiki 미정 |
| affix HUD·SFX 폴리시 | Wiki 후속 |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `elite/elite_affix_ids.gd` | affix StringName 상수 (`blazing`, `glacial` 등) |
| `elite/elite_affix_data.gd` | affix `Resource` — id, hp_mult, damage_mult, tint, horn_scene, relic_item_id, drops_relic |
| `elite/elite_affix_catalog.gd` | affix id → `EliteAffixData`, tier 1 풀, DLC gate (`gilded`) |
| `elite/elite_affix_roll_context.gd` | 롤 입력 — mob_kind, phase_minute, is_boss, force_affix_id |
| `elite/elite_affix_roller.gd` | phase·mob_kind·is_boss → affix id or empty (`affix_roll_enabled` gate) |
| `elite/elite_affix_applier.gd` | `Mob` + affix id → stat scale, tint, horn child, runtime 등록 |
| `elite/elite_affix_spawn_helper.gd` | `Game`/`TestArena` 공유 진입점 — roll + applier |
| `elite/elite_feature_flags.gd` | F5/F6 — `affix_roll_enabled`(기본 false), `force_affix_id`, `gilded_enabled` |
| `elite/elite_affix_runtime.gd` | affix behavior 베이스 — `begin`, `tick`, `on_hit_player`, `on_death`, `reset` |
| `elite/elite_affix_runtime_registry.gd` | id → runtime Script 조회 |
| `elite/affix/elite_affix_runtime_noop.gd` | MVP 스켈레톤 — 모든 affix에 noop runtime |
| `elite/player_debuff_data.gd` | 플레이어 debuff 정의 (stub) |
| `elite/player_debuff_catalog.gd` | debuff id 등록 (`elite_burn` 등, tick no-op) |
| `elite/player_debuff_controller.gd` | `Player` 소유 — apply/tick/clear API (gate는 stub, ×1.0 / false) |
| `entities/mob/mob.gd` | `_elite_affix_id`, shield HP placeholder, applier/runtime 위임, `pool_reset` clear |
| `entities/player/player.gd` | `_debuff_controller` tick·heal gate hook |
| `game/game.gd` | `spawn_mob()` — health init → tuning → **`EliteAffixSpawnHelper`** |
| `game/test_arena.gd` | F6 `spawn_test_mob()` — 동일 helper, `force_affix_id` 우선 |
| `game/test_arena_mob_panel_controller.gd` | F6 Affix `OptionButton` — `(none)` / tier1 4종 |
| `game/balance/balance_phase.gd` | (후속) `elite_affix_spawn_ratio` 또는 roller 테이블 입력 |
| `game/balance/kill_rewards.gd` | (후속) affix 보유 몹 XP ×1.5 |
| `inventory/relic_data.gd` | (후속) `item_id`, 표시명, `held_effect` kind, 수치 |
| `inventory/relic_catalog.gd` | (후속) `relic_*` 정의 |
| `inventory/relic_combat_bridge.gd` | (후속) 가방 relic 목록 → on-hit hook / periodic heal |
| `inventory/item_registry.gd` | (후속) relic resolve, **장착 슬롯 거부** |
| `inventory/inventory_service.gd` | (후속) relic acquire — 가방만, auto-equip 없음 |
| `effects/equipment_drop/equipment_drop.gd` | (후속) relic 월드 드롭 (기존 경로 재사용) |
| `effects/death_burst/death_burst_warning.gd` | (후속) glacial/overloading telegraph **재사용** |
| `game/attack/damage_resolver.gd` | (후속) bomb/freeze burst → player |
| `test/elite/elite_affix_roller_test.gd` | roller exclude·force·roll-disabled 회귀 |
| `test/elite/elite_affix_applier_test.gd` | glacial HP×4·ATK×2 scale, `pool_reset` affix clear |

관계 요약:

```text
Game.spawn_mob() / TestArena.spawn_test_mob()
  -> Mob.initialize_spawn_health()
  -> DevTuningApplier.apply_mob_scene_tuning()
  -> EliteAffixSpawnHelper.apply_after_mob_ready(mob, context)
  -> EliteAffixRoller.roll(context)
  -> EliteAffixApplier.apply(mob, affix_id)
  -> EliteAffixRuntime (per affix; MVP noop)

Mob contact / projectile hit Player
  -> EliteAffixRuntime.on_hit_player(raw_damage)
  -> PlayerDebuffController.apply(debuff_id)

Player weapon hit Mob
  -> (유물) RelicCombatBridge.on_weapon_hit_mob()
  -> Mob StatusEffectController (relic chill/burn 등)

Mob._die() [not stage_clear]
  -> KillRewards (affix xp mult)
  -> EliteAffixRuntime.on_death()
  -> RelicDropRoll (0.025%, affix.drops_relic)
  -> EquipmentDrop or instant bag (F6 cheat)
```

## Flow

### Runtime — affix 스폰

1. `Game.spawn_mob()` / F6 `spawn_test_mob()`이 기존과 같이 프리팹 acquire, `initialize_spawn_health(hp_multiplier)`, tuning을 적용한다.
2. `EliteAffixSpawnHelper.apply_after_mob_ready()`가 `EliteAffixRoller.roll(context)`를 호출한다. F5 기본값 `affix_roll_enabled = false` → **affix 0%** (F6는 `force_affix_id`만 사용).
3. `EliteAffixRoller`가 `mob_kind`가 dummy/special_a/special_b면 **스킵**한다.
4. boss면 `p_boss`(v0.1: 100%)로 tier1 풀에서 1종 선택; 그 외는 phase별 `p_normal` Bernoulli 후 균등 가중 (F5 활성화는 후속).
5. `EliteAffixApplier`가 HP·공격 export를 affix 배율로 재스케일하고, `slime_tint`·horn child(optional)를 붙인다.
6. affix별 `EliteAffixRuntime`을 registry로 조회해 `begin(mob)` 호출한다 (MVP: 전부 noop).
7. 매 physics tick에서 `Mob`이 runtime `tick(delta)`를 호출한다 (noop).

### Runtime — 플레이어 debuff

1. affix 몹이 플레이어에게 피해를 넣는 경로(접촉 tick, 투사체, bump)에서 runtime이 `PlayerDebuffController.apply()`를 호출한다.
2. `PlayerDebuffController`는 pause 중 tick하지 않는다. 대시 중 tick **정지**, 지속시간만 감소(v0.1).
3. `elite_burn`은 `Player.heal_health` 무효 플래그와 스태미나 regen mult 0을 켠다.
4. `elite_bomb` 만료 시 `DamageResolver`로 snapshot×0.5 burst.
5. `elite_freeze`는 `Player` 이동·대시·자동 공격 입력을 잠근다.

### Runtime — 사망·유물

1. `_request_die()` → `_die()`에서 `_stage_clear_death`면 affix death·relic roll **모두 스킵**한다.
2. runtime `on_death()` — ice bomb schedule, healing core spawn, gilded nuggets 등.
3. affix가 `drops_relic`이고 id≠`void`일 때만 `randf() < 0.00025` relic roll.
4. 성공 시 `relic_item_id`로 `EquipmentDrop` 스폰; 플레이어 상호작용 → `InventoryService.acquire_relic()` → **빈 가방 칸만**.
5. `RelicCombatBridge.refresh_from_bag()`이 가방 relic id 집합을 dedupe(동일 id 1스택) 후 held effect 등록.

### Runtime — 유물 전투

1. `Mob.apply_weapon_damage()` 성공 후 `RelicCombatBridge.on_weapon_hit_mob(mob, weapon, raw_damage)` 호출.
2. relic별: 몹 status apply, delayed mini burst, periodic heal tick( `_process` / Player physics).
3. DoT·burst 피해는 source `WeaponData`로 `Game.register_weapon_damage()` 귀속.

### Editor / Data

1. 새 affix는 `EliteAffixCatalog` + (필요 시) `elite/affix/<id>.gd` behavior 추가.
2. 새 유물은 `RelicCatalog` + `RelicCombatBridge` 분기 + Wiki 카탈로그 동기화.
3. F6: affix 드롭다운 → 스폰 시 roller override; relic drop rate debug export.
4. `.tres` authoring은 Phase 2 이후 검토; MVP는 코드 카탈로그(`StatusEffectCatalog` 패턴).

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| affix stat 배율은 `initialize_spawn_health()` **이후** 적용한다. | phase HP와 affix HP 책임 분리. |
| 한 몹에 affix는 **0 또는 1**개. | Wiki v0.1 중첩 없음. |
| 플레이어 debuff를 `StatusEffectController`(몹)에 넣지 않는다. | tick·pause·무적 규칙이 다르다. |
| 유물은 **가방 보유만** 효과; equip slot API는 **항상 거부**한다. | 인벤 불변조건과의 유일 예외를 코드 한곳에서 강제. |
| 동일 `relic_*` id는 효과 **1스택** (가방 2칸이어도 1회). | exploit·합산 폭주 방지. |
| relic roll·affix death effect는 `_stage_clear_death`에서 **실행하지 않는다. | 클리어 필드 전멸과 동일 계약. |
| `mob.gd`에 affix별 대형 분기를 추가하지 않는다. | `EliteAffixRuntime` subclass 또는 composition으로 분리. |
| 몹 affix behavior는 **별도 mob AI 스크립트 금지** (`.cursor/rules/godot-mobs.mdc`). | horn child·runtime만 추가. |
| glacial death AoE가 다른 몹을 죽여도 `register_kill`·XP는 **정상 1회** per mob. | 연쇄는 burst 1회당 처치 1회. |
| overloading bomb snapshot은 **hit 1회 raw** (방어·block 전). | Wiki v0.1. |
| `pool_reset()`에서 affix id, shield, runtime, horn child, debuff 예약을 **전부 clear**. | 풀 재사용 회귀 방지. |
| F6 relic 100% 치트는 F5에 **export되지 않게** TestArena 전용. | 메인 밸런스 오염 방지. |
| `gilded` affix·relic은 DLC flag off 시 roller 풀 **제외**. | Wiki v0.1. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| affix 추가 | Catalog, Applier, Runtime, Wiki, F6 override, horn scene, `Mob.pool_reset` |
| roller / phase 연동 | `BalancePhase` 또는 roller table, 9분+ F5, boss 100%, special 제외 |
| 플레이어 debuff 추가 | `PlayerDebuffController`, `Player` move/heal/stamina gate, pause, 대시 |
| 유물 추가 | `RelicCatalog`, bag dedupe, `RelicCombatBridge`, acquire 거부 equip, 툴팁 |
| 사망 burst / hazard | `death_burst_warning`, friendly fire mob damage, 풀 release |
| XP / 드롭 | `KillRewards`, `_die()` stage_clear 분기, `EquipmentDrop` |
| `elite_spawn_ratio` 제거 | `MobSpawnSelector`, balance table, Wiki, 회귀 스폰 |
| Architecture_Mobs 수정 | affix가 contact/ranged/death 경로에 hook 추가 시 풀·`_die()` 계약 유지 |

**MVP-lite 최소 검증:** F6에서 affix `glacial`·`overloading` 강제 스폰 → E1~E2 → relic 치트 100% → E4~E5 → F5 9분 구간 affix 스폰 E6. 구현 Phase는 [`BACKLOG.md`](../../BACKLOG.md) Elite Forms Epic을 따른다.

## 관련 문서

| 문서 | 내용 |
|------|------|
| [`Wiki/EliteForms.md`](../Wiki/EliteForms.md) | affix·유물 수치, QA E1~E9 |
| [`Architecture_Mobs.md`](Architecture_Mobs.md) | `mob.gd`, `_die()`, death_burst |
| [`Architecture_Inventory.md`](Architecture_Inventory.md) | 가방·장착 게이트 (relic 예외) |
| [`Architecture_Player.md`](Architecture_Player.md) | 피격·heal·stamina·무적 |
| [`Architecture_TestArena.md`](Architecture_TestArena.md) | F6 affix 드롭다운·force 스폰 (구현됨) |
