# Architecture — Inventory (인벤토리·장비)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이 규칙: [`Wiki/Items_Inventory.md`](../Wiki/Items_Inventory.md) · UI 스케일: [`AGENTS_Display_UI.md`](../Agents/AGENTS_Display_UI.md)

인벤토리·장비 시스템의 코드 구조와 변경 시 지켜야 할 경계를 정리한다. Phase 이력, PR 순서, 미구현 선택지는 이 문서가 아니라 [`BACKLOG.md`](../../BACKLOG.md)와 `Docs/Plan/`에서 관리한다.

## Overview

인벤토리는 **가방 8칸**과 **장비 세트 2개**를 관리한다. 각 세트는 `weapon`, `helmet`, `armor`, `gloves`, `boots`, `offhand`, `accessory` 7개 슬롯을 가진다. 전투에 쓰는 세트는 `active_set_index`로 고르며, W·닫힌 RMB·인벤의 비활성 weapon/offhand 좌클릭으로 전환한다.

무기와 offhand는 세트 1·2를 동시에 보여 주고, 방어구 5칸과 악세사리는 `sets[0]`을 공유한다. 플레이어 상태에는 `item_id` 문자열만 저장하고, `WeaponData`와 `GearData`는 런타임에 `ItemRegistry`가 해석한다. F6 테스트 아레나는 기본적으로 loadout을 전투에 반영하고, F5 메인 루프는 `use_inventory_loadout == false`를 기본으로 유지한다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 상태 모델 | `PlayerLoadoutState`의 2세트×7슬롯, 8칸 가방, 활성 세트 인덱스 유지 |
| 장착 규칙 | 슬롯 허용 여부, 양손 무기와 offhand 충돌, 동일 `item_id` 중복 소유 방지 |
| 아이템 해석 | `ItemRegistry`를 통한 weapon/gear 해석, 장비 카탈로그 등록, 스탯 합산 |
| 세이브 | `InventorySave`로 `user://player_loadout.cfg` 저장·로드 |
| UI 연동 | `InventoryService`를 통해 드래그, 우클릭, 더블클릭, 세트 전환을 상태 변경으로 반영 |
| 전투 연동 | `use_inventory_loadout == true`일 때 활성 weapon, 장비 스탯, grant 패시브, offhand 비주얼 적용 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 서바이버 레벨업 무기와 인벤 weapon의 자동 병합 | F5 기본은 `_owned_weapons`와 레벨업 3택을 유지한다. |
| 상점·제작·드랍 테이블 | 인벤 API와 `item_id` 기반 확장 지점만 유지한다. |
| 강화·내구도·소켓 | 현재 상태는 인스턴스 데이터 없이 `item_id` 단위다. |
| 퀵슬롯 4칸 | 선택 후속 작업으로 `BACKLOG.md`에서 관리한다. |
| F5 loadout 전면 통합 | 레벨업 무기와 우선순위 정책 확정 후 별도 Epic으로 다룬다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `inventory/equip_slots.gd` | 슬롯 키, 세트 수, 가방 크기의 단일 상수 소스 |
| `inventory/item_definition.gd` | `item_id`, 표시명, 허용 슬롯, `stat_modifiers` 공통 정의 |
| `weapons/data/weapon_data.gd` | 무기 데이터. 인벤에서는 `weapon_id`를 `item_id`처럼 사용한다. |
| `inventory/gear_data.gd` | 방어구·악세·offhand 장비 데이터 |
| `inventory/player_loadout_state.gd` | 세트/가방/활성 세트 상태 저장 모델 |
| `inventory/item_registry.gd` | weapon/gear 등록·해석, 슬롯 검증, loadout 스탯 합산 |
| `inventory/gear_stat_merge.gd` | `*_mult` 곱연산, min/max 합산, 태그 누적 같은 스탯 병합 규칙 |
| `inventory/gear_stat_display.gd` | 장비 툴팁용 표시 문자열 생성 |
| `inventory/inventory_service.gd` | UI가 호출하는 장착·해제·드래그·세트 전환 API |
| `inventory/inventory_combat_bridge.gd` | 활성 weapon과 장비 스탯을 `Player`에 적용 |
| `inventory/inventory_game_bridge.gd` | I/W/RMB 입력, 메뉴 열기/닫기, HUD 전투 세트 표시 연결 |
| `inventory/loadout_stat_apply.gd` | 이동·피해·공격속도·방어·체력 스탯을 플레이어 수치로 변환 |
| `inventory/loadout_grant_passive.gd` | 장비 grant 태그로 궤도, dash haste, dash darts, offhand 비주얼 적용 |
| `ui/inventory/inventory_menu.gd` | 4칸 전투 슬롯, 공유 방어구, 가방 UI, `InventoryService` 호출 |
| `ui/inventory/inventory_slot.gd` | 슬롯 1칸 표시·드래그·입력 위젯 |

관계는 아래처럼 유지한다.

```text
InventoryMenu / InventorySlot
  -> InventoryService
  -> PlayerLoadoutState
  -> ItemRegistry
  -> GearStatMerge / GearStatDisplay

Game / TestArena
  -> InventoryGameBridge
  -> InventoryCombatBridge
  -> Player.refresh_stats_from_loadout()
```

장비 카탈로그는 `gear_catalog.gd`와 `gear_catalog_entries.gd`가 담당한다. 현재 Common 장비는 offhand, helmet, armor, gloves, boots, accessory에 등록되어 있으며, 새 장비는 카탈로그에 추가한 뒤 `ItemRegistry` 해석과 툴팁 표시가 함께 맞아야 한다.

## Flow

### Runtime

1. 인벤 메뉴가 처음 필요해지면 `InventorySave.load_state()`로 상태를 읽고 `InventoryService`를 준비한다.
2. 빈 loadout이면 `InventoryLoadoutSeed.apply_random_starter()`로 시작 장비를 채우고 저장한다.
3. 가방 우클릭/더블클릭 또는 드래그는 항상 `InventoryService` API를 거쳐 상태를 바꾼다.
4. weapon/offhand는 `active_set_index` 세트에 장착되고, 방어구·악세는 `sets[0]`에 장착된다.
5. W·닫힌 RMB·비활성 전투 슬롯 좌클릭은 활성 세트를 바꾸고 저장, HUD 갱신, 전투 재적용을 수행한다.
6. `use_inventory_loadout == true`이면 `InventoryCombatBridge.apply_loadout_to_player()`가 활성 weapon, 장비 스탯, grant 패시브, offhand 비주얼을 플레이어에 적용한다.
7. `use_inventory_loadout == false`이면 인벤 변경은 F5 서바이버 `_owned_weapons`와 레벨업 무기 선택에 자동 반영되지 않는다.

### Editor / Data

1. 새 무기는 기존 무기 카탈로그 또는 `.tres` 데이터의 `weapon_id`가 고유해야 한다.
2. 새 장비는 `gear_catalog_entries.gd`에 `item_id`, 표시명, 슬롯, `stat_modifiers`, 선택 효과 설명을 추가한다.
3. 새 스탯 키는 `gear_stat_merge.gd`, `gear_stat_display.gd`, 필요 시 `loadout_stat_apply.gd`를 함께 확인한다.
4. UI 노드 구조나 해상도 정책은 `UiViewportLayout` 기준을 따른다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| `sets.size() == 2`, `bag_ids.size() == 8`을 유지한다. | 세이브와 UI 바인딩이 고정 크기를 전제로 한다. |
| 빈 슬롯은 `""`로 표현한다. | `null`과 잘못된 id 혼용을 막는다. |
| 동일 `item_id`는 가방 또는 장비 슬롯 중 한 위치에만 존재한다. | 복제·중복 장착 버그를 막는다. |
| 양손 weapon 장착 시 같은 세트의 offhand는 비워야 한다. | 한손/offhand 빌드와 양손 빌드의 경계를 유지한다. |
| 다른 세트의 장비 슬롯끼리 직접 스왑하지 않는다. | UI는 4칸을 동시에 보여도 데이터는 세트별로 분리된다. |
| 방어구 5칸과 악세는 항상 `sets[0]`을 공유한다. | 편집 탭과 전투 세트가 방어구 데이터를 바꾸지 않게 한다. |
| loadout 합산은 방어구·악세 `sets[0]` + 활성 세트 offhand만 포함하고 weapon은 제외한다. | weapon은 `InventoryCombatBridge`가 단일 `Gun`으로 처리한다. |
| `*_mult` 스탯은 더하지 말고 곱한다. | 장비 배율이 선형 합산되어 과도하게 왜곡되는 것을 막는다. |
| `damage_element == "magic"`인 마법 무기는 `magic_damage_mult`를 타입·원소 중 한 번만 곱한다. | 마법 타입과 magic 원소의 중복 배율을 방지한다. |
| F5 기본 `use_inventory_loadout == false`에서는 인벤 weapon을 `_owned_weapons`에 섞지 않는다. | 레벨업 3택, 다중 궤도, 피해 통계 회귀를 막는다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 슬롯 추가·이름 변경 | `EquipSlots`, 세이브 버전, `PlayerLoadoutState`, UI 바인딩, `InventoryService` 검증 |
| 새 장비 추가 | `gear_catalog_entries.gd`, `ItemRegistry.resolve_gear`, 툴팁, `GearStatMerge` 합산 |
| 새 스탯 키 추가 | merge 규칙, 표시 문구, `LoadoutStatApply`, F6 수동 검증 |
| weapon/offhand 정책 변경 | 양손 처리, offhand 반환 실패, 활성 세트 전환, HUD, F5 회귀 |
| 인벤 UI 변경 | 4칸 weapon/offhand 동시 표시, 공유 방어구, RMB 해제와 닫힌 RMB 스왑 충돌 여부 |
| 전투 적용 변경 | `apply_inventory_loadout_to_player()`, `refresh_stats_from_loadout()`, `clear_loadout_stats()` 호출 순서 |
| F5 loadout on 검토 | `_owned_weapons`, 레벨업 선택, `WeaponDamageTracker`, 자동 공격, 궤도 무기 공존 정책 |

최소 검증은 F6 테스트 아레나에서 장착·해제·세트 전환·양손/offhand·스탯 체감을 확인하고, F5 메인 루프에서 `use_inventory_loadout == false` 회귀가 없는지 확인하는 것이다.
