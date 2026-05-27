# Architecture — Test Arena (F6)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 몹: [`Architecture_Mobs.md`](Architecture_Mobs.md) · 발사체: [`Architecture_Projectiles.md`](Architecture_Projectiles.md) · 인벤: [`Architecture_Inventory.md`](Architecture_Inventory.md) · UI: [`AGENTS_Display_UI.md`](../Agents/AGENTS_Display_UI.md)

## Overview

`test_arena.tscn`(F6, 현재 씬 실행)은 메인 런(F5)과 분리된 **무기·몹 전투 검증** 공간이다. `game/test_arena.gd`가 UI, 스폰, 튜닝 스냅샷, 인벤 연동을 오케스트레이션한다. 씬 루트는 F5와 동일하게 `Game`이며 `%Player`, `%ObjectPools`, `%AttackServices`, `InventoryMenu` 계약을 유지한다.

`use_inventory_loadout`(기본 true)일 때 무기 GUI 착용은 인벤 **활성 세트 weapon 슬롯**에 반영되고, 플레이어 장착은 `apply_inventory_loadout_to_player()`가 `TestArenaWeaponSnapshot` 튜닝을 적용한 뒤 `Gun`에 넘긴다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 몹 스폰·리스폰 | `MOB_OPTIONS` 씬 선택, `%MobSpawnPoint`(플레이어 스폰 기준 고정), 선택적 리스폰 |
| 몹 전투 튜닝 | 접촉/원거리·**사망 폭발**(특수 A 등, 범위·피해·지연)·**돌진 거리**(특수 B 등) — `TestArenaMobSnapshot`, `user://test_arena_mob_snapshots.cfg` |
| 무기 선택·착용 | 카탈로그 필터, 인벤 강제 장착, 튜닝 스냅샷 적용 |
| 무기·발사체 튜닝 | 피해·APS·사거리·발사체 수 + movement·타입별 SpinBox, **적용/저장**, `user://test_arena_weapon_snapshots.cfg` |
| SpinBox 값 확정 | LineEdit 직접 입력 → **적용** 또는 **저장**(`spin.apply()`), Enter·포커스 이탈 시에도 반영 |
| 패널 UI | 몹/무기 탭, 고정 너비 탭 바(행당 최대 4칸) |
| 인벤·일시정지 | `InventoryGameBridge`, `PauseMenu` 오버레이 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 웨이브·밸런스 타임라인 | `game/game.gd`, `BalanceTimeline` |
| 아레나 상자·골드 | F5 아레나 런 전용 |
| 메인 스폰 테이블 | `MobSpawnSelector` — 더미 등 F6 전용 몹은 메인 pick에 넣지 않음 |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `game/test_arena.gd` | F6 오케스트레이션, GUI, 스폰, loadout 적용 |
| `game/test_arena_weapon_snapshot.gd` | 무기 **공통·타입별** 튜닝 필드 def, movement, `user://` 스냅샷 |
| `weapons/data/weapon_data.gd` | `melee_range_override` / `projectile_range_override`(F6), `build_test_arena_info_bbcode` omit |
| `game/test_arena_mob_snapshot.gd` | 몹 전투 수치 세션/저장, 튜닝 상태 색상 |
| `inventory/inventory_service.gd` | `try_force_equip_weapon_on_active_set()` — GUI 착용 시 기존 무기 삭제 후 슬롯 장착 |
| `inventory/inventory_combat_bridge.gd` | 활성 weapon → `Player.add_weapon()` (F6는 스냅샷 튜닝 후 덮어씀) |
| `ui/test_arena_tab_bar.gd` | `TabContainer` 내장 탭 숨김 + 행당 4등분 고정 너비 탭 버튼 |
| `entities/mob/mob_attack_mark.gd` | 접촉·원거리·돌진 공격 예고 `!` |
| `entities/mob/mob_charge_lane.gd` | 특수 B 돌진 직선 경로·화살표 예고(`charge_lane_display_duration`, 기본 1s) |
| `effects/death_burst/death_burst_warning.gd` | Special A 등 — 사망 위치 폭발 **지연** 중 커지는 범위 링 |
| `game/attack/attack_factory.gd` | `schedule_mob_death_burst` — 지연 후 `spawn_mob_death_burst`(연출 ×1.35) |

```text
test_arena.gd
  -> TestPanelsWrap / TabBarHost / TestPanelsTab
  -> TestArenaMobSnapshot / TestArenaWeaponSnapshot
  -> InventoryService.try_force_equip_weapon_on_active_set
  -> apply_inventory_loadout_to_player -> _apply_tuning_live
  -> spawn_test_mob -> Mob + snapshot apply
```

## Flow

### Runtime

1. `_ready`: 스냅샷 로드, 무기/몹 UI 구성, `use_inventory_loadout`이면 `apply_inventory_loadout_to_player()` 지연 호출.
2. **몹 탭:** 타입 선택 → 설명 BBCode → 전투 튜닝 스핀(색: 기본/저장/세션) → **적용** 또는 **저장** → 스폰. 스폰·활성 몹에 스냅샷 즉시 반영 가능. **특수 A** — 사망 폭발(범위·피해·지연). **특수 B** — 돌진 거리(사망 폭발 스핀은 숨김, `charge_attack_enabled` 우선).
3. **무기 탭:** 필터·선택 → 설명 BBCode(`omit`으로 튜닝 중 필드 숨김) → Equip → 인벤 활성 weapon 슬롯 교체 → `build_tuned_weapon()` 적용 후 `Gun` 갱신.
4. **무기 튜닝**(`%ProjectileTuningFields`, UI 라벨 「무기 튜닝」): `CORE_FIELD_DEFS` + 유형별 사거리·발사체 수 + `FIELD_DEFS_*` SpinBox. 스핀 변경 시 세션 반영(±·Enter). **적용**·**저장**·**초기화** → `user://test_arena_weapon_snapshots.cfg`. 장착 중이면 `_apply_tuning_live` 즉시 반영.
5. movement: `ProjectileMovementOption` — 옵션이 2개 이상일 때만 행 표시.
6. 인벤(I)·전투 세트 Tab은 `InventoryGameBridge`와 동일 계약.

### 무기 튜닝 필드 (`TestArenaWeaponSnapshot`)

| 구분 | 속성 | 표시 조건 |
|------|------|-----------|
| 공통 | `min_damage`, `max_damage`, `attacks_per_second` | 모든 카탈로그 무기 |
| 사거리 | `melee_range_override` | 근접·궤도 — SpinBox는 **유효 사거리**(`get_melee_range()`), 저장 시 override 값 |
| 사거리 | `projectile_range_override` | 원거리·마법(비궤도) — 유효 사거리 `get_projectile_range()` |
| 사거리 | `throw_range` | 투척·영역(`AreaZone`) |
| 발사체 생성 수 | `melee_spread_count` | 근접(궤도 제외) |
| 발사체 생성 수 | `burst_count` | 원거리 |
| 타입별 | 탄속·관통·연사 간격·궤도·독·영역 등 | `FIELD_DEFS_BY_TYPE` / `ORBIT` / `AREA_ZONE` |

override가 0이거나 세션에 없으면 `range_type` 표(`MELEE_RANGE_BY_TYPE` / `PROJECTILE_RANGE_BY_TYPE`)를 쓴다. **F5 메인 런은 이 스냅샷을 읽지 않는다.**

### Editor

1. UI 노드는 `TestUI/TestUILayout` FHD 좌표 + `UiViewportLayout`.
2. `%` 고유 이름 노드는 씬에 `unique_name_in_owner = true` 필요(튜닝 라벨 포함).
3. 새 몹 옵션은 `MOB_OPTIONS` + `register_scene` 경로의 프리팹.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| F6 ≠ F5 아레나 모드. 목적·스폰·보상을 섞지 않는다. | QA 혼선 방지 (`CoreConstraints`) |
| 씬 루트 이름 `Game`, `%Player` 유지. | 몹·풀·인벤 bridge 경로 전제 |
| GUI 무기 착용은 `try_force_equip_weapon_on_active_set`만 사용. | 가방 우선 `acquire_item`과 분리 |
| 기존 착용 무기 교체 시 **가방으로 보내지 않고** 슬롯에서 삭제. | 테스트 아레나 빠른 교체 UX |
| `_equip_weapon` / `_apply_tuning_live`는 스냅샷 적용 후 `Player`에 반영. | 인벤 ID와 튜닝 수치 분리 |
| `melee_range_override` / `projectile_range_override`는 F6 튜닝·스냅샷 전용. F5 카탈로그 `.tres`는 0 유지. | 메인 밸런스와 QA 오버라이드 분리 |
| 무기 설명 omit은 `get_field_defs()`와 동일 property 키. | GUI와 BBCode 중복 방지 |
| 몹 튜닝 라벨·스핀은 `%Mob*Label` 등 고유 이름 필수. | 누락 시 `_ready`에서 get_node 실패 |
| `TabContainer.tabs_visible = false`, 탭 바는 `TabBarHost` 스크립트. | 4등분·줄바꿈 레이아웃 |
| SpinBox에 숫자만 입력하고 **저장**만 누르면 반영되지 않을 수 있음. **적용**·Enter·포커스 이탈 또는 저장(내부에서 적용 선행). | Godot SpinBox LineEdit는 `value_changed`가 확정 후에만 발생 |
| `charge_attack_enabled` 몹은 F6에서 **사망 폭발 튜닝 UI를 노출하지 않음**. | 특수 B는 돌진 거리·설명만; 사망 burst는 런타임 export 유지 |
| 맵 기본 크기는 `map_arena.gd` `ARENA_RECT_1X`; F5 맵 변경은 `survivors_game` `%MapArena`만. | F6만 커지는 실수 방지 |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 몹 F6 옵션 | `MOB_OPTIONS`, `TestArenaMobSnapshot.register_scene`, 필드 def, 설명 BBCode |
| 몹 튜닝 필드 | `COMBAT_*` / `DEATH_BURST_*`(특수 A) / `CHARGE_*`(특수 B, `charge_travel_distance`→`charge_duration`), `supports_*_tuning` 우선 규칙, `%MobBurst*`·`%MobCharge*` 고유 이름 |
| SpinBox·적용 버튼 | `_commit_spin_box_pending`, `%ApplyMobCombatTuningButton` / `%ApplyProjectileTuningButton` |
| 무기 GUI 착용 | `try_force_equip_weapon_on_active_set`, 인벤 refresh, `apply_inventory_loadout_to_player` |
| 무기 튜닝 필드 | `CORE_FIELD_DEFS`, `get_range_field_def`, `get_projectile_spawn_field_def`, 타입별 `FIELD_DEFS_*`, `get_tuning_spin_display_value` |
| 무기 설명 omit | `WeaponData.build_test_arena_info_bbcode`, `_get_weapon_omit_properties` |
| 탭 추가 | `TestPanelsTab` 자식 + `TabBarHost.rebuild_tabs()`, 5번째부터 둘째 줄 |
| 공격 예고·돌진 레인 | `mob.gd` windup(`_charge_windup_remaining`) → 이동, `ScenePool` prewarm, `pool_reset` |

**최소 검증 (F6):** Special A — 처치 후 **지연 링 예고** → burst·피해·범위(튜닝 반영). Special B — GUI **돌진 거리** 튜닝, 트리거 거리 내 **레인 예고 → 대기 후 돌진** → 종료 범위 피해·저체력 자폭. 무기 Equip → 인벤 weapon, **피해·APS·사거리·발사체 수** 스핀 즉시 반영·**적용/저장**(직접 입력 포함), movement·타입별 스핀, 몹 튜닝 **적용/저장**, 탭 4등분 레이아웃.
