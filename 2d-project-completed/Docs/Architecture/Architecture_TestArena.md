# Architecture — Test Arena (F6)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 몹: [`Architecture_Mobs.md`](Architecture_Mobs.md) · 발사체: [`Architecture_Projectiles.md`](Architecture_Projectiles.md) · 인벤: [`Architecture_Inventory.md`](Architecture_Inventory.md) · UI: [`AGENTS_Display_UI.md`](../Agents/AGENTS_Display_UI.md)

## Overview

`test_arena.tscn`(F6, 현재 씬 실행)은 메인 런(F5)과 분리된 **무기·몹 전투 검증** 공간이다. `game/test_arena.gd`는 코디네이터로서 씬 부트스트랩·런타임(스폰/리스폰/킬)·브리지 API만 유지하고, 탭별 UI/튜닝 로직은 패널 컨트롤러(`StatusEffect`, `Weapon`, `Gear`, `Mob`)로 분리되어 동작한다. 씬 루트는 F5와 동일하게 `Game`이며 `%Player`, `%ObjectPools`, `%AttackServices`, `InventoryMenu` 계약을 유지한다.

`use_inventory_loadout`(기본 true)일 때 무기/보조 GUI 착용은 인벤 **활성 세트 weapon/offhand 슬롯**에 반영된다. 플레이어 반영은 `apply_inventory_loadout_to_player()`가 `TestArenaWeaponSnapshot`(무기)과 `TestArenaGearSnapshot`(보조 `stat_modifiers`)을 적용한 뒤 `Gun`·loadout 스탯을 갱신한다.
인벤토리 정책(세트 구조·합산 규칙·획득/장착 경계)은 [`Architecture_Inventory.md`](Architecture_Inventory.md)를 단일 기준으로 따른다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 몹 스폰·리스폰 | `MOB_OPTIONS` 씬 선택, `%MobSpawnPoint`(플레이어 스폰 기준 고정), 선택적 리스폰 |
| 몹 전투 튜닝 | 접촉/원거리·**사망 폭발**(특수 A 등, 범위·피해·지연)·**돌진 거리**(특수 B 등) — `TestArenaMobSnapshot`, `user://test_arena_mob_snapshots.cfg` |
| 무기/보조 선택·착용 | 카탈로그 필터, 인벤 강제 장착, 튜닝 스냅샷 적용 |
| 무기·발사체 튜닝 | 피해·APS·사거리·발사체 수 + movement·타입별 SpinBox, **적용/저장**, `user://test_arena_weapon_snapshots.cfg` |
| 보조손 튜닝 | `block_min/max`, `armor_min/max`, `weapon_damage_mult`, `power` SpinBox, **적용/저장**, `user://test_arena_gear_snapshots.cfg` (`power`는 피해·범위에 합산 1회 softcap) |
| 상태이상 튜닝 | `duration/tick/배율` SpinBox, **적용/저장**, `user://test_arena_status_effect_snapshots.cfg` |
| SpinBox 값 확정 | LineEdit 직접 입력 → **적용** 또는 **저장**(`spin.apply()`), Enter·포커스 이탈 시에도 반영 |
| 패널 UI | 몹/무기/상태이상 탭, 고정 너비 탭 바(행당 최대 4칸) |
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
| `game/test_arena.gd` | F6 코디네이터(부트스트랩, 컨트롤러 의존성 주입, 스폰/리스폰, pause·inventory bridge) |
| `game/test_arena_status_effect_controller.gd` | 상태이상 탭 옵션/잠금 규칙(poison)·튜닝 UI·적용/저장/초기화 |
| `game/test_arena_weapon_panel_controller.gd` | 무기 필터/옵션/설명, GUI 장착, 무기 튜닝 UI, 즉시 적용 |
| `game/test_arena_gear_panel_controller.gd` | 보조손/방어구 옵션·장착·설명·튜닝 UI, 상태이상 탭 연계 |
| `game/test_arena_mob_panel_controller.gd` | 몹 옵션/설명, 전투 튜닝 UI(기본/사망 폭발/돌진), 적용/저장/초기화 |
| `game/test_arena_weapon_snapshot.gd` | 무기 **공통·타입별** 튜닝 필드 def, movement, `user://` 스냅샷 |
| `game/test_arena_gear_snapshot.gd` | 장비 `stat_modifiers` 튜닝 필드 def(막기·방어·무기피해·파워·부활·스태미나·피격무적 등), `user://` 스냅샷 |
| `game/test_arena_status_effect_snapshot.gd` | 상태이상 튜닝 필드 def(지속·틱·배율), `user://` 스냅샷 |
| `game/test_arena_tuning_ui.gd` | 무기/보조 공통 SpinBox 행 생성, +/- 버튼, Enter/포커스 이탈 commit 유틸 |
| `weapons/data/weapon_data.gd` | `melee_range_override` / `projectile_range_override`(F6), `build_test_arena_info_bbcode` omit |
| `game/test_arena_mob_snapshot.gd` | 몹 전투 수치 세션/저장, 튜닝 상태 색상 |
| `inventory/inventory_service.gd` | `try_force_equip_weapon_on_active_set()` / `try_force_equip_offhand_on_active_set()` — GUI 착용 시 기존 장비 삭제 후 슬롯 장착 |
| `inventory/item_registry.gd` | `set_gear_modifier_resolver()` — F6에서 보조 튜닝 `stat_modifiers` 합산 경로 주입 |
| `inventory/inventory_combat_bridge.gd` | 활성 weapon → `Player.add_weapon()` (F6는 스냅샷 튜닝 후 덮어씀) |
| `ui/test_arena_tab_bar.gd` | `TabContainer` 내장 탭 숨김 + 행당 4등분 고정 너비 탭 버튼 |
| `entities/mob/mob_attack_mark.gd` | 접촉·원거리·돌진 공격 예고 `!` |
| `entities/mob/mob_charge_lane.gd` | 특수 B 돌진 직선 경로·화살표 예고(`charge_lane_display_duration`, 기본 1s) |
| `effects/death_burst/death_burst_warning.gd` | Special A 등 — 사망 위치 폭발 **지연** 중 커지는 범위 링 |
| `game/attack/attack_factory.gd` | `schedule_mob_death_burst` — 지연 후 `spawn_mob_death_burst`(연출 ×1.35) |

```text
test_arena.gd (Coordinator)
  -> TestArenaStatusEffectController
  -> TestArenaWeaponPanelController
  -> TestArenaGearPanelController
  -> TestArenaMobPanelController
  -> TestArenaMobSnapshot / TestArenaWeaponSnapshot / TestArenaGearSnapshot / TestArenaStatusEffectSnapshot
  -> InventoryService.try_force_equip_weapon_on_active_set / try_force_equip_offhand_on_active_set
  -> ItemRegistry.set_gear_modifier_resolver(Callable(TestArenaGearSnapshot, "resolve_modifiers"))
  -> StatusEffectCatalog + TestArenaStatusEffectSnapshot.apply_saved_to_catalog()
  -> apply_inventory_loadout_to_player
  -> spawn_test_mob -> Mob + snapshot apply
```

## Flow

### Runtime

1. `_ready`: 스냅샷 로드 → 패널 컨트롤러 `configure()` 의존성 주입 → 옵션 빌드/탭 세팅/튜닝 UI 세팅 → signal connect 순서로 부트스트랩한다. 상태이상 저장 스냅샷은 카탈로그에 자동 반영하고, `use_inventory_loadout`이면 `apply_inventory_loadout_to_player()`를 지연 호출한다.
2. **몹 탭(`TestArenaMobPanelController`):** 타입 선택 → 설명 BBCode → 전투 튜닝 스핀(색: 기본/저장/세션) → **적용** 또는 **저장**. `spawn_test_mob()`는 코디네이터에 남아 씬 계약을 유지한다. **특수 A** — 사망 폭발(범위·피해·지연). **특수 B** — 돌진 거리(사망 폭발 스핀 숨김, `charge_attack_enabled` 우선).
3. **무기 탭(`TestArenaWeaponPanelController`):** 필터·선택 → 설명 BBCode(`omit`으로 튜닝 중 필드 숨김) → Equip → 인벤 활성 weapon 슬롯 교체 → `build_tuned_weapon()` 적용 후 `Gun` 갱신.
4. **장비 탭(`TestArenaGearPanelController`):** 보조손/방어구 선택 → Equip → 인벤 활성 슬롯 교체 → loadout 재적용. 양손 무기면 `inventory.error.offhand_blocked`로 거절.
5. **보조손 상태이상 진입**(`%OffhandStatusOption`, `%EditOffhandStatusButton`): 장비 탭에서 `grant_on_hit`를 읽기 전용으로 고르고, 버튼으로 상태이상 탭으로 이동해 자동 선택한다(장비 탭에서 상태이상 수치 직접 수정 금지).
6. **보조손/방어구 튜닝(`TestArenaGearPanelController`)**: 선택 장비 `stat_modifiers` 중 지원 필드만 SpinBox 표시. **적용**·**저장**·**초기화** → `user://test_arena_gear_snapshots.cfg`. 변경 즉시 `apply_inventory_loadout_to_player()` 반영, `power`는 합산 1회 softcap.
7. **무기 튜닝(`TestArenaWeaponPanelController`)**: `CORE_FIELD_DEFS` + 유형별 사거리/발사체 수 + `FIELD_DEFS_*` SpinBox. 스핀 변경 시 세션 반영(±·Enter). **적용**·**저장**·**초기화** → `user://test_arena_weapon_snapshots.cfg`. 장착 중이면 즉시 반영.
8. **상태이상 튜닝(`TestArenaStatusEffectController`)**: `duration_seconds`, `max_stacks`, `damage_taken_mult`, `move_speed_mult`, DoT(`tick_damage_min/max`, `tick_interval`). **적용**·**저장**·**초기화** → `user://test_arena_status_effect_snapshots.cfg`. 적용 시 활성 몹 동일 상태이상 tick profile을 재계산하되, **남은 지속시간은 유지**한다.
9. movement: `ProjectileMovementOption` — 옵션이 2개 이상일 때만 행 표시.
10. 인벤(I)·전투 세트 Tab은 `InventoryGameBridge`와 동일 계약.

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

### 보조손 튜닝 필드 (`TestArenaGearSnapshot`)

| 구분 | 속성 | 표시 조건 |
|------|------|-----------|
| 막기 | `block_min`, `block_max` | 선택 보조 `stat_modifiers`에 block 키가 있을 때 |
| 방어 | `armor_min`, `armor_max` | 선택 보조 `stat_modifiers`에 armor 키가 있을 때 |
| 무기 피해 | `weapon_damage_mult` | 선택 보조 `stat_modifiers`에 키가 있을 때 |
| 파워 | `power` | 선택 보조 `stat_modifiers`에 키가 있을 때 (피해 + 범위, 합산 1회 softcap) |
| 부활 | `revive_min`, `revive_max` | 선택 장비에 키가 있을 때 |
| 스태미나 | `stamina` | flat 스태미나 키가 있을 때 |
| 스태미나 회복 | `stamina_recovery_mult` | 배율 키가 있을 때 |
| 피격 후 무적 | `invincibility_after_damage_sec` | 초 단위 키가 있을 때 |

`grant_orbital` 같은 태그/문자열 키는 SpinBox 튜닝 대상이 아니다. **F5 메인 런은 이 스냅샷을 읽지 않는다.**

### 상태이상 튜닝 필드 (`TestArenaStatusEffectSnapshot`)

| 구분 | 속성 | 표시 조건 |
|------|------|-----------|
| 공통 | `duration_seconds`, `max_stacks` | 선택 상태이상 |
| 배율 | `damage_taken_mult`, `move_speed_mult` | 선택 상태이상 |
| DoT | `tick_damage_min`, `tick_damage_max`, `tick_interval` | DoT 계열 상태이상 |

`poison`은 무기 source 우선 규칙 때문에 `duration/tick` 필드를 잠금 처리한다. 장비 탭/상태이상 탭 모두 규칙 안내 문구를 표시한다.
저장된 상태이상 스냅샷은 F6 재실행 시 `_ready` 단계에서 카탈로그에 자동 반영된다.

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
| 보조 스냅샷 반영은 `ItemRegistry.set_gear_modifier_resolver(Callable(TestArenaGearSnapshot, "resolve_modifiers"))` 경로로만 한다. | F6 전용 오버라이드와 F5 카탈로그 원본 분리 |
| 보조 min/max 튜닝 저장 시 `block_min ≤ block_max`, `armor_min ≤ armor_max`를 유지하도록 clamp한다. | 역전 범위 저장으로 전투 계산(`randi_range`)이 깨지는 것을 방지 |
| `melee_range_override` / `projectile_range_override`는 F6 튜닝·스냅샷 전용. F5 카탈로그 `.tres`는 0 유지. | 메인 밸런스와 QA 오버라이드 분리 |
| 무기 설명 omit은 `get_field_defs()`와 동일 property 키. | GUI와 BBCode 중복 방지 |
| 몹 튜닝 라벨·스핀은 `%Mob*Label` 등 고유 이름 필수. | 누락 시 `_ready`에서 get_node 실패 |
| `TabContainer.tabs_visible = false`, 탭 바는 `TabBarHost` 스크립트. | 4등분·줄바꿈 레이아웃 |
| SpinBox에 숫자만 입력하고 **저장**만 누르면 반영되지 않을 수 있음. **적용**·Enter·포커스 이탈 또는 저장(내부에서 적용 선행). | Godot SpinBox LineEdit는 `value_changed`가 확정 후에만 발생 |
| `charge_attack_enabled` 몹은 F6에서 **사망 폭발 튜닝 UI를 노출하지 않음**. | 특수 B는 돌진 거리·설명만; 사망 burst는 런타임 export 유지 |
| `poison` 지속/틱은 무기 source가 우선이며 상태이상 탭에서 잠금된다. | `ActiveStatusEffect`의 poison override 규칙과 충돌 방지 |
| 상태이상 튜닝 적용은 활성 효과의 tick profile만 갱신하고 남은 시간은 유지한다. | 튜닝 중 duration이 매번 초기화되어 검증값이 왜곡되는 회귀를 방지 |
| 저장된 상태이상 스냅샷은 F6 시작 시 자동 적용되어야 한다. | 저장 후 재실행했을 때 Apply 재클릭 없이 같은 조건으로 재현 가능해야 한다 |
| 맵 기본 크기는 `map_arena.gd` `ARENA_RECT_1X`; F5 맵 변경은 `survivors_game` `%MapArena`만. | F6만 커지는 실수 방지 |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 컨트롤러 의존성 주입 | `test_arena.gd` `_configure_*_controller`, `_ready` 호출 순서(로드→옵션→탭→UI→signal) 유지 |
| 코디네이터 경계 | `spawn_test_mob`, `register_kill`, player death/respawn, pause/inventory bridge API가 `test_arena.gd`에 유지되는지 확인 |
| 새 몹 F6 옵션 | `MOB_OPTIONS`, `TestArenaMobSnapshot.register_scene`, 필드 def, 설명 BBCode |
| 몹 튜닝 필드 | `COMBAT_*` / `DEATH_BURST_*`(특수 A) / `CHARGE_*`(특수 B, `charge_travel_distance`→`charge_duration`), `supports_*_tuning` 우선 규칙, `%MobBurst*`·`%MobCharge*` 고유 이름 |
| SpinBox·적용 버튼 | `_commit_spin_box_pending`, `%ApplyMobCombatTuningButton` / `%ApplyProjectileTuningButton` |
| 무기 GUI 착용 | `try_force_equip_weapon_on_active_set`, 인벤 refresh, `apply_inventory_loadout_to_player` |
| 보조 GUI 착용/튜닝 | `try_force_equip_offhand_on_active_set`, `%OffhandTuning*`, `TestArenaGearSnapshot.get_field_defs`, `set_gear_modifier_resolver` |
| 튜닝 UI 공통화 | `test_arena_tuning_ui.gd` (`create_tuning_row`, `wire_spin_box_text_commit`, `commit_spin_box_pending`) 사용 유지 |
| 무기 튜닝 필드 | `CORE_FIELD_DEFS`, `get_range_field_def`, `get_projectile_spawn_field_def`, 타입별 `FIELD_DEFS_*`, `get_tuning_spin_display_value` |
| 무기 설명 omit | `WeaponData.build_test_arena_info_bbcode`, `_get_weapon_omit_properties` |
| 상태이상 탭 | `%StatusEffectOption`, `%StatusEffectTuning*`, `TestArenaStatusEffectSnapshot`, poison 잠금 UX |
| 탭 추가 | `TestPanelsTab` 자식 + `TabBarHost.rebuild_tabs()`, 5번째부터 둘째 줄 |
| 공격 예고·돌진 레인 | `mob.gd` windup(`_charge_windup_remaining`) → 이동, `ScenePool` prewarm, `pool_reset` |

**최소 검증 (F6):** Special A — 처치 후 **지연 링 예고** → burst·피해·범위(튜닝 반영). Special B — GUI **돌진 거리** 튜닝, 트리거 거리 내 **레인 예고 → 대기 후 돌진** → 종료 범위 피해·저체력 자폭. 무기 Equip → 인벤 weapon, **피해·APS·사거리·발사체 수** 스핀 즉시 반영·**적용/저장**(직접 입력 포함), movement·타입별 스핀, 몹 튜닝 **적용/저장**, 탭 4등분 레이아웃.

## Verification Note (Step6)

- 이번 단계 문서 갱신은 컨트롤러 분리 반영(`test_arena.gd` + `test_arena_*_controller.gd`) 기준으로 수행했다.
- F6 플레이 수동 검증은 Godot 에디터 실행 환경에서 아래 항목을 체크한다: Mob/Weapon/Gear/StatusEffect 탭의 적용·저장·초기화, player death/respawn, spawn/respawn 루프, 탭 레이아웃.
