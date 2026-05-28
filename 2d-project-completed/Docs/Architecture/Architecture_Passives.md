# Architecture — Passives (패시브)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이어·대시: [`Architecture_Player.md`](Architecture_Player.md) · 장비: [`Architecture_Inventory.md`](Architecture_Inventory.md) · 버프: [`Architecture_Buffs.md`](Architecture_Buffs.md) · 성장 기획: [`Wiki/Progression.md`](../Wiki/Progression.md) · 일정: [`Plan/Plan_Release_Roadmap.md`](../Plan/Plan_Release_Roadmap.md), [`BACKLOG.md`](../../BACKLOG.md)

패시브는 **단일 `PassiveSystem`이 아니라 역할별 4층**으로 나뉜다. LoadoutPassive·RunPassive·TimedBuff는 구현됨. WaveModifier는 3주차 Must(별 트랙). GDD의 Enabler/Blocker “Passive”(발견·발생)와 VS형 런 패시브를 문서에서 구분한다.

**상태:** Phase A~C 완료 · **갱신:** 2026-05-28  
**구현:** LoadoutPassive grant · RunPassive · `WeaponRunState` · 패시브 진화 · `AccessorySynergy` · `PassiveResolver`(grant 진입점)

---

## Overview

1. **LoadoutPassive** — 활성 세트 weapon/offhand·공유 방어구·악세서리의 `stat_modifiers`·`grant_*`. `GearStatMerge` → `CharacterStats` loadout source. 궤도·대시 등은 `LoadoutGrantPassive`.
2. **RunPassive** — 런 한정 슬롯(최대 6)·레벨 스택. 레벨업·웨이브 보상 `RewardPool` → `PassiveRunState` → `passive_modifiers`.
3. **TimedBuff** — 초·웨이브·충전 수명. `BuffController` + `BuffTriggerRouter`. [`Architecture_Buffs.md`](Architecture_Buffs.md).
4. **WaveModifier** — 아레나 전장 규칙(MVP-lite). 패시브 슬롯과 별 모듈 · 3주차.

**무기 런 강화(Phase C):** `WeaponRunState`가 무기 id별 강화 레벨(1~8)을 들고, `CharacterStats.roll_weapon_damage`에 레벨당 피해 +10%를 곱한다. 보상 풀에 **신규 무기 / 무기 강화 / 패시브**가 혼합 등장한다.

데모 우선순위: **WaveModifier(3주차) → LoadoutPassive(A) → RunPassive(B) → 성장 심화(C)**. C는 EA 전 단계로 무기 강화·진화·악세서리 시너지·grant 진입점 통합까지 포함한다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 담당 층 | 설명 |
|------|---------|------|
| 장착 상시 스탯 | LoadoutPassive | `GearData.stat_modifiers`, `LoadoutStatApply` |
| 장착 grant | LoadoutPassive | `grant_*` → `LoadoutGrantPassive` |
| grant → 버프 | LoadoutPassive + TimedBuff | `PassiveResolver` → `LoadoutGrantPassive` / `BuffTriggerRouter` |
| 런 패시브 소유·합산 | RunPassive | `PassiveRunState`, `PassiveStatMerge`, `passive_modifiers` |
| 패시브 진화 | RunPassive | `PassiveData.evolves_into_id`, `try_evolve()` (MAX 시 슬롯 유지·id 교체) |
| 악세서리 시너지 | RunPassive + Loadout | `AccessorySynergy` — **활성 세트 악세서리** + 보유 패시브 |
| 무기 런 강화 | RunPassive(보상) | `WeaponRunState`, `RewardChoice.WEAPON_UPGRADE` |
| 보상 풀 혼합 | Game + UI | `RewardPool`, `weapon_select_menu.present_reward_choices` |
| grant 트리거 진입 | 공통 | `PassiveResolver.on_kill` / `on_wave_start` / `on_dash` / `on_hit` |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 영구 메타 패시브 | EA 이후 |
| 몹 상태이상 | `status/` |
| GDD Enabler/Blocker 본문 | [`GDD.md`](../Design/GDD.md) |
| HUD 패시브·무기 Lv 아이콘 | Polish |
| `PassiveResolver` 이벤트 큐·확률/쿨다운 데이터 | C는 진입점만. EA |
| 무기 합성·영구 무기 성장 | 로드맵 EA |
| 수치·밸런스 표 | 카탈로그·Wiki |

## Key Types & Relationships

### LoadoutPassive

| 타입/파일 | 역할 |
|-----------|------|
| `inventory/gear_data.gd` | 장비 `stat_modifiers` |
| `inventory/gear_stat_merge.gd` | 합산·`grant_*` 리스트 병합 |
| `inventory/loadout_grant_passive.gd` | 궤도·대시·kill/wave/on-hit grant 핸들러 |
| `inventory/loadout_stat_apply.gd` | loadout → 이동·피해·APS·체력 |
| `inventory/gear_catalog_entries.gd` | 액세서리 grant 데이터 |

### RunPassive · 보상 (Phase B~C)

| 타입/파일 | 역할 |
|-----------|------|
| `passive/passive_data.gd` | `evolves_into_id`, `stat_modifiers_by_level`, `grant_tags_by_level` |
| `passive/passive_catalog*.gd` | 기본 8종 + 진화 2종 (`evolved` 태그) |
| `passive/passive_run_state.gd` | `owned: id → level`, `try_evolve()` |
| `passive/passive_stat_merge.gd` | 패시브 + `AccessorySynergy` |
| `passive/accessory_synergy.gd` | 악세서리 id + 패시브 id 규칙 테이블 |
| `passive/passive_resolver.gd` | grant 트리거 진입점 |
| `game/weapon_run_state.gd` | 무기 id → Lv.1~8, `compute_damage_mult()` |
| `game/reward_choice.gd` | `WEAPON` / `WEAPON_UPGRADE` / `PASSIVE` |
| `game/reward_pool.gd` | 3슬롯 롤·서바이벌 `wave_rider` 제외 |
| `game/game.gd` | `_roll_reward_choices`, `_get_upgrade_eligible_weapons` |
| `ui/weapon_select_menu.gd` | 혼합 3택 UI·강화 금색·자동 선택(무기·강화만) |
| `entities/player/stats/character_stats.gd` | `passive_modifiers`, 무기 Lv 피해 배율 |

### PassiveData (flat 경로)

| 필드 | 사용 | 비고 |
|------|------|------|
| `passive_id`, `display_name*` | ○ | |
| `max_level`, `tags` | ○ | `evolved` → 보상 풀 신규 등장 제외 |
| `evolves_into_id` | ○ | MAX 달성 선택 시 `try_evolve` |
| `stat_modifiers_by_level` | ○ | 레벨별 `GearStatMerge` 누적 |
| `grant_tags_by_level` | ○ | loadout grant dict에 병합 |
| `trigger_id`, `conditions`, `effects` | 확장 슬롯 | EA |

**진화 수치:** 진화체 스탯은 **이전 패시브 Lv.max 누적(배율 곱) 이상**이 되도록 카탈로그에 맞춘다 (`swift_feet_master`, `sharp_edge_master`).

### CharacterStats source

```text
loadout_modifiers   ← 활성 장착 (InventoryCombatBridge)
passive_modifiers   ← PassiveRunState + AccessorySynergy
buff_modifiers      ← BuffController
```

무기 피해 롤: `roll_weapon_damage(weapon, player_level, weapon_run_level)` — `weapon_run_level`은 `WeaponRunState`만 사용(AP S 미적용).

### 관계 (런타임)

```text
[LoadoutPassive]
  sum_stat_modifiers_for_loadout → set_loadout_modifiers
  LoadoutGrantPassive ← get_combined_persistent_modifiers() 내 grant

[RunPassive]
  RewardPool.roll_choices(owned, upgrade_pool, …, upgrade_bonus)
    → RewardChoice → PassiveRunState / WeaponRunState
  PassiveStatMerge → set_passive_modifiers
  grant_tags → PassiveResolver → LoadoutGrantPassive

[WeaponRunState]
  Player.roll_weapon_damage → CharacterStats + compute_damage_mult(level)

[TimedBuff]  (Architecture_Buffs.md)
[WaveModifier]  (3주차, 별도)
```

### 악세서리 시너지 (현재 규칙)

| 악세서리 | 패시브 | 보너스 |
|----------|--------|--------|
| `hunter_charm` | `hunter_instinct` | `damage_mult` 1.05 |
| `scout_medallion` | `hunter_instinct` | `attack_speed_mult` 1.05 |
| `bamboo_bracelet` | `steady_aim` | `ranged_damage_mult` 1.05 |
| `battle_crest` | `wave_rider` | `heart_min/max` +1 |

활성 세트 `accessory`만 `Game._get_equipped_accessory_ids()`로 전달. 장착 변경 시 `apply_inventory_loadout_to_player()` → `_refresh_passive_stats()`.

### 트리거 표

| 트리거 | 발화 | 연결 |
|--------|------|------|
| `on_dash` | `Player` 대시 **시작 성공 시** (`Architecture_Player.md`) | `PassiveResolver.on_dash` |
| `on_wave_start` | 아레나 웨이브 | `PassiveResolver.on_wave_start` + `BuffTriggerRouter` |
| `on_kill` | `Game.register_kill` | `PassiveResolver.on_kill` |
| `on_hit` | 무기 적중 (`Mob.apply_weapon_damage`) | `PassiveResolver.on_hit` |
| `on_level_up` | 레벨업·웨이브 보상 | `RewardPool` (무기·강화·패시브) |

## Flow

### Runtime — LoadoutPassive

1. `InventoryCombatBridge.apply_loadout_to_player()` — 활성 weapon·스탯.
2. `Player.refresh_stats_from_loadout()` — `set_loadout_modifiers`, 궤도·offhand.
3. grant는 `get_combined_persistent_modifiers()`에 포함 → `PassiveResolver`가 트리거 시 소비.

### Runtime — RunPassive · 보상

1. 레벨업·아레나 웨이브 마일스톤 → `Game.show_reward_select()`.
2. `Game._roll_reward_choices()` — `owned`·`upgrade_pool`·`upgrade_bonus`·빈 풀 최대 3회 재롤.
3. `RewardPool` — 슬롯당 패시브(~38%) / 강화(~28%, 신규 무기 있을 때) / 신규 무기 / 폴백.
4. 선택 → `on_passive_chosen` / `on_weapon_upgrade_chosen` / `on_weapon_chosen`.
5. 패시브 MAX + `evolves_into_id` → `try_evolve()` → `_refresh_passive_stats()`.
6. 씬 재로드 시 `Game._ready`의 `PassiveRunState`·`WeaponRunState` 신규 인스턴스(런 초기화).

### 보상 풀 규칙 (구현)

| 규칙 | 내용 |
|------|------|
| 서바이벌 | `wave_rider` 보상 풀 제외 (`wave_number == 0`) |
| 인벤 강화 후보 | `upgrade_pool` = 활성 세트 **weapon 1개** (`_get_upgrade_eligible_weapons`) |
| VS 모드 | `upgrade_pool` = `Player.get_owned_weapons()` |
| `weapon_upgrade_level` 장비 | 강화 1회에 `1 + bonus` 레벨 (`town_guard_armor` 등). 툴팁·롤 `target_level`에 반영 |
| 자동 선택 | 무기·강화 행만. 패시브는 수동 |
| 빈 풀 | 3회 재롤 후에도 없으면 보상 UI 스킵·pending 소비 |

## 개발 단계 (로드맵)

| 단계 | 상태 | 요약 |
|------|------|------|
| **Phase A** | 완료 | `grant_on_kill` / `grant_on_wave_start`, 액세서리 3종 |
| **Phase B** | 완료 | RunPassive 8종·슬롯 6·`RewardPool` 혼합 |
| **Phase C** | 완료 | 무기 Lv.강화·진화·시너지·`PassiveResolver` |

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 가방·비활성 weapon/offhand는 스탯·grant·공격 없음 | CoreConstraints |
| RunPassive·WeaponRunState는 런(씬) 단위. 세이브 없음 | 데모 런 한정 |
| 활성 세트 weapon만 발사 | 공격 계약 |
| modifier는 `WeaponData` 원본을 수정하지 않음 | source만 갱신 |
| grant 태그는 loadout+passive **리스트 병합** | `GearStatMerge` |
| 진화체는 Lv.max 누적 이상 수치 | 곱셈 누적 하향 방지 |
| 인벤 `use_explicit_upgrade_pool` | 활성 무기 없으면 강화 후보 없음(가방 무기로 폴백하지 않음). |
| 강화 라벨 | `RewardChoice.weapon_from_level`·`weapon_target_level`로 롤 시점 레벨 표기. |
| `BuffTriggerRouter` `rapier` 하드코딩 | BACKLOG, Must 아님 |

## Change Guidelines

| 변경 | 확인 |
|------|------|
| 새 `grant_*` | `gear_stat_merge`, `loadout_grant_passive`, `PassiveResolver`, 풀 누수 |
| `PassiveData` / 카탈로그 | `passive_catalog_entries`, 진화 수치·`evolved` 태그 |
| `RewardPool` 가중치 | `game.gd` `_roll_reward_choices`, F5/F6 보상 |
| `AccessorySynergy` | `passive_stat_merge`, F5 악세서리 장착·해제 |
| `WeaponRunState` | `roll_weapon_damage`, 무기 HUD·통계 |
| 보상 UI | `weapon_select_menu`, 자동 선택·pause |
| WaveModifier | `Architecture_GameLoop_Balance`, 서바이벌 미적용 |

### Phase A 검증

- grant 액세서리: **장착 슬롯만** 효과.
- 궤도 해제 시 `clear_orbitals`.

### Phase B 검증

- 패시브 3스택·grant 병합·런 종료 초기화.

### Phase C 검증

- 무기 강화(금색)·피해 상승·`weapon_upgrade_level` 툴팁/적용 일치.
- `swift_feet` / `sharp_edge` MAX → 진화·슬롯 유지·스탯 하락 없음.
- 악세서리 시너지 장착/해제.
- 서바이벌 `wave_rider` 미등장.
- 인벤: 활성 무기만 강화(무기 슬롯 비었을 때 강화 슬롯 없음).
- 혼합 보상 + 자동 선택: 크래시 없음.

---

## 관련 문서

| 문서 | 역할 |
|------|------|
| [`Wiki/Progression.md`](../Wiki/Progression.md) | 성장·보상 갭 |
| [`Wiki/Weapons.md`](../Wiki/Weapons.md) | 무기 풀·런 강화(경량) |
| [`Wiki/Items_Inventory.md`](../Wiki/Items_Inventory.md) | 악세서리·장착 |
| [`Plan_Release_Roadmap.md`](../Plan/Plan_Release_Roadmap.md) | R-005 |
| [`BACKLOG.md`](../../BACKLOG.md) | 장착 게이트·EA 확장 |

구조가 크게 바뀔 때만 본문을 갱신한다. 주차 작업은 [`Plan/Weekly/Current.md`](../Plan/Weekly/Current.md)와 맞춘다.
