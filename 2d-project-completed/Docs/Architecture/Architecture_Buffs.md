# Architecture — Buffs (버프)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 패시브: [`Architecture_Passives.md`](Architecture_Passives.md) · 장비 연동: [`Architecture_Inventory.md`](Architecture_Inventory.md) · 런 루프: [`Architecture_GameLoop_Balance.md`](Architecture_GameLoop_Balance.md) · 무기: [`Architecture_Weapons.md`](Architecture_Weapons.md)

버프 시스템의 데이터, 런타임 인스턴스, 지속시간 처리, 플레이어 스탯 반영 흐름을 정리한다. 영구 성장과 장착 장비 스탯은 이 문서의 `ActiveBuff` 대상이 아니며, 런 중 조건으로 켜졌다 꺼지는 효과만 버프 런타임 계층에서 관리한다.

## Overview

버프는 `buff/` 아래의 `BuffData` 정의와 `ActiveBuff` 런타임 상태로 나뉜다. `BuffController`는 대상별 활성 버프를 보관하고, 초·웨이브·충전 수 기반 만료를 처리한 뒤 `stat_modifiers`를 합산한다. 플레이어는 장비 modifier와 활성 버프 modifier를 `CharacterStats`에 source로 전달하고, `CharacterStats`가 이동속도, 무기 피해, APS 계산에 반영한다. 몹에게 적용되는 출혈·화상·독·냉기 같은 상태이상은 `status/`의 `StatusEffectController` 범위이며, 플레이어 능력치 버프와 수명/피해 통계 규칙을 섞지 않는다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 버프 정의 | `BuffData`의 id, 표시명, 지속 타입, 스택 정책, `stat_modifiers` |
| 런타임 상태 | `ActiveBuff`의 남은 초, 남은 웨이브, 남은 충전 수, 스택, source id |
| 대상별 관리 | `BuffController`가 add/remove/tick/wave/charge 만료와 변경 신호 처리 |
| 스탯 합산 | `BuffStatMerge`가 활성 버프 modifier를 `GearStatMerge` 규칙으로 병합 |
| 트리거 연결 | `BuffTriggerRouter`가 웨이브 시작, 대시 같은 게임 이벤트를 버프 부여로 연결 |
| 플레이어 적용 | `Player`가 `CharacterStats`에 활성 버프 modifier를 전달해 이동속도, 무기 피해, APS 계산에 반영 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 영구 성장 스탯 | 저장 데이터나 런 시작 기본값 계층에서 다룰 대상이며 `ActiveBuff`로 보관하지 않는다. |
| 장비 상시 스탯 | `InventoryCombatBridge`, `GearStatMerge`, `LoadoutStatApply` 흐름을 유지한다. |
| HUD 버프 아이콘 | 현재는 `get_active_buff_summaries()` 조회 API만 제공하고 UI는 후속 범위다. |
| 몹 상태이상 | `status/`가 담당한다. DoT 피해 통계와 풀 reset 규칙은 `Architecture_Mobs.md`를 따른다. |
| 발사체별 특수 효과 | 발사체 이동·충돌은 `Architecture_Projectiles.md` 범위다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `buff/buff_duration.gd` | `seconds`, `waves`, `charges`, `until_event`, `while_equipped`, `permanent` 지속 타입 상수와 판정 helper |
| `buff/buff_data.gd` | 버프 정의 `Resource`, 표시명, 지속값, 스택 정책, `stat_modifiers` |
| `buff/active_buff.gd` | 적용 중인 버프 1개의 남은 지속값, 스택, source id |
| `buff/buff_controller.gd` | 대상별 활성 버프 목록, 만료 tick, 변경 signal, modifier 조회 |
| `buff/buff_stat_merge.gd` | 활성 버프 modifier를 하나의 Dictionary로 병합 |
| `buff/buff_catalog.gd` | `en_garde`, `dash_haste` 같은 초기 버프 정의 카탈로그 |
| `buff/buff_trigger_router.gd` | `Game`/`Player`/장비 패시브 이벤트를 버프 부여 API로 연결 |
| `entities/player/player.gd` | `BuffController` 보유, 버프 변경 시 `CharacterStats` 갱신과 무기 타이머 갱신 요청 |
| `entities/player/stats/character_stats.gd` | 장비·버프 modifier source를 보관하고 최종 이동속도·피해·APS 계산 |
| `inventory/loadout_grant_passive.gd` | `grant_on_dash: haste`를 플레이어 버프 부여로 위임 |
| `game/game.gd` | 아레나 웨이브 시작/완료 이벤트를 버프 트리거와 웨이브 만료로 전달 |

관계는 아래처럼 유지한다.

```text
Game wave event / Player dash / Loadout grant
  -> BuffTriggerRouter
  -> BuffCatalog.get_buff()
  -> Player.apply_buff()
  -> BuffController.add_buff()
  -> BuffStatMerge.merge_active_buffs()
  -> CharacterStats.set_buff_modifiers()
  -> Player get_move_speed / roll_weapon_damage / get_effective_attacks_per_second
  -> Gun.refresh_loadout_combat_modifiers()
```

## Flow

### Runtime

1. `Player._ready()`가 `BuffController.buffs_changed`를 연결한다.
2. 아레나 웨이브가 시작되면 `Game._on_arena_wave_started()`가 `BuffTriggerRouter.apply_arena_wave_start()`를 호출한다.
3. `BuffTriggerRouter`는 플레이어 보유 weapon 중 `rapier`가 있으면 `en_garde`를 부여한다.
4. 플레이어가 대시하면 `LoadoutGrantPassive.apply_on_dash()`가 `grant_on_dash` 태그를 읽고, `haste` 태그는 `dash_haste` 버프 부여로 위임한다.
5. `Player.apply_buff()`는 `BuffController.add_buff()`를 호출하고, 같은 id/source 버프는 스택 정책에 따라 refresh/extend/stack 처리된다.
6. `BuffController` 변경 시 `Player._on_buffs_changed()`가 활성 modifier를 `CharacterStats`에 전달하고 `Gun.refresh_loadout_combat_modifiers()`를 호출한다.
7. 매 physics tick에서 tree가 pause가 아니면 `Player._tick_active_buffs()`가 초 단위 버프 시간을 감소시킨다.
8. 아레나 웨이브 완료와 클리어 시 `Player.on_wave_completed_for_buffs()`가 웨이브 지속 버프를 감소시킨다.
9. 버프가 만료되면 `buffs_changed`가 다시 발생하고 플레이어 최종 스탯과 무기 타이머가 원래 값으로 돌아간다.

### Editor / Data

1. 새 런타임 버프는 `buff_catalog.gd` 또는 `.tres` `BuffData`로 정의한다.
2. `stat_modifiers` 키는 `GearStatMerge`가 이해하는 키를 우선 사용하고, 새 키가 필요하면 merge/display/apply 경로를 함께 추가한다.
3. 지속 타입은 `BuffDuration` 상수로 선택한다. `while_equipped`와 `permanent`는 정의는 가능하지만 `BuffController` 활성 목록에는 넣지 않는다.
4. 새 조건 발동은 먼저 이벤트 소유자를 정하고 `BuffTriggerRouter` 또는 도메인별 호출부에서 `Player.apply_buff()`로 연결한다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 영구 성장과 장비 상시 스탯은 `ActiveBuff`에 넣지 않는다. | 저장 수명, 장착 수명, 런타임 지속 시간이 섞이면 해제와 초기화가 불명확해진다. |
| 활성 버프는 원본 `WeaponData`, 기본 이동속도, 장비 modifier를 직접 수정하지 않고 `CharacterStats`의 버프 source만 갱신한다. | 버프 만료와 세트 전환 시 원복 버그를 막는다. |
| `*_mult`는 `GearStatMerge` 규칙처럼 곱하고 flat/min/max는 합산한다. | 장비와 버프의 수치 의미를 맞춘다. |
| 버프 변경으로 APS가 바뀌면 플레이어가 무기 타이머 갱신을 요청해야 한다. | 공격속도 버프 적용/만료 체감이 즉시 반영되어야 한다. |
| 초 단위 버프는 tree pause 중 감소하지 않는다. | 무기 선택, 일시정지, 상자 UI 중 지속 시간이 새지 않아야 한다. |
| 웨이브 지속 버프는 아레나 `wave_completed` 기준으로 감소한다. | 아레나 난이도 축은 시간이 아니라 웨이브 번호다. |
| 현재 플레이어 적용 범위는 이동속도, 무기 피해, APS다. | 방어·체력 버프를 추가하려면 `get_max_health()`와 피해 경감 경로를 함께 확장해야 한다. |
| burst 무기 APS는 `Gun`의 burst 타이머 경로를 별도로 확인한다. | 일반 타이머 갱신만으로 burst 주기가 바뀌지 않을 수 있다. |
| 몹 DoT는 `buff/`로 옮기지 않고 `status/`에서 source weapon 피해 통계를 유지한다. | 게임오버 피해 목록과 처치 보상 경로가 깨지지 않아야 한다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 버프 추가 | `buff_id`, 표시명, 지속 타입, 스택 정책, `stat_modifiers`, 발동 조건 |
| 새 지속 타입 추가 | `BuffDuration`, `ActiveBuff`, `BuffController` 만료 처리, pause/웨이브 이벤트 |
| 새 스탯 키 추가 | `GearStatMerge`, `LoadoutStatApply`, `CharacterStats`, 장비/버프 툴팁 표시, 플레이어 적용 위치 |
| 웨이브 트리거 변경 | `Game._on_arena_wave_started`, `_on_arena_wave_completed`, 보상 UI pause 흐름 |
| 대시 트리거 변경 | `Player._apply_loadout_on_dash`, `LoadoutGrantPassive`, dash darts와 동시 발동 |
| 버프 UI 추가 | `get_active_buff_summaries()`, UI 스케일 규칙, pause 중 표시 갱신 |
| 몹 상태이상 변경 | `status/`, `mob.gd`, 피해 통계, 사망/풀 reset, 플로팅 텍스트 |

최소 검증은 F5 아레나에서 `rapier` 장착 후 웨이브 시작 시 `en_garde`가 8초 동안 APS를 올리고 만료되는지, `geta` 장착 후 대시 시 `dash_haste`가 2초 동안 이동속도를 올리는지 확인하는 것이다. 이어서 세트 전환, 비활성 장비 미적용, 자동 공격 타이머 갱신, 기존 poison/nettles 동작을 회귀 확인한다.
