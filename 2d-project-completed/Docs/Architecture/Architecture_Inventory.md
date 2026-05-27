# Architecture — Inventory (인벤토리·장비)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이 규칙: [`Wiki/Items_Inventory.md`](../Wiki/Items_Inventory.md) · 버프 구조: [`Architecture_Buffs.md`](Architecture_Buffs.md) · UI 스케일: [`AGENTS_Display_UI.md`](../Agents/AGENTS_Display_UI.md)

인벤토리·장비 시스템의 코드 구조와 변경 시 지켜야 할 경계를 정리한다. Phase 이력, PR 순서, 미구현 선택지는 이 문서가 아니라 [`BACKLOG.md`](../../BACKLOG.md)와 `Docs/Plan/`에서 관리한다.

## Overview

인벤토리는 **가방 8칸**과 **장비 세트 2개**를 관리한다. 각 세트는 `weapon`, `helmet`, `armor`, `gloves`, `boots`, `offhand`, `accessory` 7개 슬롯을 가진다. 전투에 쓰는 세트는 `active_set_index`로 고르며, Tab·닫힌 RMB·인벤의 비활성 weapon/offhand 좌클릭으로 전환한다.

무기와 offhand는 세트 1·2를 동시에 보여 주고, 방어구 5칸과 악세사리는 `sets[0]`을 공유한다. 플레이어 상태에는 `item_id` 문자열만 저장하고, `WeaponData`와 `GearData`는 런타임에 `ItemRegistry`가 해석한다. 데모 기준 인벤토리는 런 한정이며, 가방·장비 세트·상자 보상·골드는 클리어, 패배, 로비 복귀, 새 런 시작 시 저장하지 않고 초기화한다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 상태 모델 | `PlayerLoadoutState`의 2세트×7슬롯, 8칸 가방, 활성 세트 인덱스 유지 |
| 장착 규칙 | 슬롯 허용 여부, 양손 무기와 offhand 충돌, 동일 `item_id` 중복 소유 방지 |
| 장비 획득 배치 | 획득한 장비를 대상 빈 슬롯, 대기 슬롯, 가방 순서로 배치 |
| 아이템 해석 | `ItemRegistry`를 통한 weapon/gear 해석, 장비 카탈로그 등록, 스탯 합산 |
| 런 수명 | 새 런 시작 시 상태 생성, 런 종료 시 가방·장비 세트·상자 보상 초기화 |
| UI 연동 | `InventoryService`를 통해 드래그, 우클릭, 더블클릭, 세트 전환, 왼쪽 Shift+좌클릭 버리기를 상태 변경으로 반영 |
| 전투 연동 | 장착된 활성 세트 weapon/offhand와 공유 방어구만 현재 런의 플레이어에 적용 |
| 조건부 장비 효과 | `grant_on_dash` 같은 태그를 런타임 버프 또는 발사체 부여로 연결 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 영구 장비 세이브 | 장비 상태는 저장하지 않고, 영구 저장은 해금·설정·통계 같은 메타 정보만 다룬다. |
| 제작·강화·분해 | 현재 상자는 런 한정 장비 획득만 담당한다. |
| 강화·내구도·소켓 | 현재 상태는 인스턴스 데이터 없이 `item_id` 단위다. |
| 퀵슬롯 4칸 | 선택 후속 작업으로 `BACKLOG.md`에서 관리한다. |
| Rare 이상 장비 확장 | 11웨이브 이후, 하드 모드, 보스 보상 같은 후속 범위에서 다룬다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `inventory/equip_slots.gd` | 슬롯 키, 세트 수, 가방 크기의 단일 상수 소스 |
| `inventory/item_definition.gd` | `item_id`, 표시명, 허용 슬롯, `stat_modifiers` 공통 정의 |
| `weapons/data/weapon_data.gd` | 무기 데이터. 인벤에서는 `weapon_id`를 `item_id`처럼 사용한다. |
| `inventory/gear_data.gd` | 방어구·악세·offhand 장비 데이터 |
| `inventory/player_loadout_state.gd` | 세트/가방/활성 세트 상태 저장 모델 |
| `inventory/item_registry.gd` | weapon/gear 등록·해석, 슬롯 검증, 상자 보상 기본 슬롯 분류, loadout 스탯 합산 |
| `inventory/item_reward_picker.gd` | 상자 보상 후보를 슬롯 필터, 등급, 중복 제외 조건으로 추린다 |
| `inventory/gear_stat_merge.gd` | `*_mult` 곱연산, min/max 합산, 태그 누적 같은 스탯 병합 규칙 |
| `inventory/gear_stat_display.gd` | 장비 툴팁용 표시 문자열 생성 |
| `inventory/inventory_service.gd` | UI가 호출하는 장착·해제·드래그·세트 전환·버리기 API. F6 GUI: `try_force_equip_weapon_on_active_set()` |
| `inventory/inventory_combat_bridge.gd` | 장착된 활성 weapon과 장비 스탯을 `Player`에 적용 |
| `inventory/inventory_game_bridge.gd` | I/Tab/RMB 입력, 메뉴 열기/닫기, HUD 전투 세트 표시 연결 |
| `inventory/loadout_stat_apply.gd` | 이동·피해·공격속도·방어·체력 스탯 공식 제공 |
| `entities/player/stats/character_stats.gd` | 장비·버프 modifier source를 보관하고 `LoadoutStatApply` 공식으로 최종 플레이어 수치 계산 |
| `inventory/loadout_grant_passive.gd` | 장착 장비 grant 태그로 궤도, dash haste 버프, dash darts, offhand 비주얼 적용 |
| `ui/inventory/inventory_menu.gd` | 4칸 전투 슬롯, 공유 방어구, 가방 UI, `InventoryService` 호출, 버린 장비 월드 드롭 위임 |
| `ui/inventory/inventory_slot.gd` | 슬롯 1칸 표시·드래그·입력 위젯, 왼쪽 Shift 상태 추적 |
| `game/rewards/gold_chest.gd` | 웨이브 사이 월드 상자, 가격 라벨, 구매 UI 요청 |
| `ui/chest_purchase_menu.gd` | 상자 구매 확인, 보유 골드·가격·부위·등급 확률·실패 사유 표시 |

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
  -> CharacterStats.set_loadout_modifiers()
```

장비 카탈로그는 `gear_catalog.gd`와 `gear_catalog_entries.gd`가 담당한다. 현재 Common 장비는 offhand, helmet, armor, gloves, boots, accessory에 등록되어 있으며, 새 장비는 카탈로그에 추가한 뒤 `ItemRegistry` 해석과 툴팁 표시가 함께 맞아야 한다.

## Flow

### Runtime

1. 새 런이 시작되면 빈 `PlayerLoadoutState` 또는 런 시작 장비로 `InventoryService`를 준비한다.
2. 시작 보상, 레벨업 보상, 상자에서 `weapon`을 획득하면 활성 세트 `weapon` 빈 슬롯, 비활성 세트 `weapon` 빈 슬롯, 가방 순서로 배치한다.
3. `offhand`를 획득하면 활성 세트 `offhand` 빈 슬롯을 먼저 확인하되, 같은 세트의 weapon이 양손이면 막힌 것으로 본다. 즉 `offhand 1`은 `weapon 1`이 양손이 아닐 때만, `offhand 2`는 `weapon 2`가 양손이 아닐 때만 장착할 수 있다. 활성 세트에 넣을 수 없으면 같은 규칙으로 비활성 세트 `offhand`를 확인한 뒤 가방으로 보낸다.
4. `helmet`, `armor`, `gloves`, `boots`, `accessory`를 획득하면 공유 방어구 슬롯이 비어 있을 때 바로 장착하고, 이미 차 있으면 가방에 넣는다.
5. 아레나 웨이브 클리어 보상에서는 무기 획득 UI가 끝난 뒤 중앙 주변에 전체/부위 `GoldChest`가 배치된다. 상자는 가격 라벨을 표시하고 상호작용 시 `ChestPurchaseMenu`를 연다.
6. 상자 구매는 골드 확인 → `ItemRewardPicker` 슬롯/등급/중복 제외 후보 선택 → `InventoryService.can_acquire_item()` 배치 가능성 확인 → 골드 차감 → `InventoryService.acquire_item()` 순서로 처리한다. 실패 시 골드를 차감하지 않거나 환불하고, 가방 가득 참 같은 실제 실패 사유를 표시한다.
7. 무기 획득 UI에서 `weapon` 자동 배치가 가방 가득 참으로 실패하면 선택한 무기를 월드의 `EquipmentDrop` 오브젝트로 떨어뜨린 뒤 보상 흐름을 종료한다.
8. 플레이어가 `EquipmentDrop`에 다가가 상호작용을 누르면 같은 `InventoryService.acquire_item()` 경로로 획득을 재시도한다. 장착 슬롯과 가방이 여전히 가득 차 있으면 오브젝트는 남아 있고, 성공하면 오브젝트를 제거한다.
9. 가방 우클릭/더블클릭 또는 드래그는 항상 `InventoryService` API를 거쳐 상태를 바꾼다.
10. 인벤토리에서 왼쪽 Shift+좌클릭으로 가방 또는 장착 슬롯 장비를 버리면 `Game.can_drop_equipment_item()`을 먼저 확인한 뒤 슬롯을 비우고 `EquipmentDrop`을 플레이어 앞에 생성한다. 생성 실패 시 같은 슬롯에 원래 `item_id`를 복원한다.
11. weapon/offhand는 `active_set_index` 세트에 장착되고, 방어구·악세는 `sets[0]`에 장착된다.
12. Tab·닫힌 RMB·비활성 전투 슬롯 좌클릭은 활성 세트를 바꾸고 HUD 갱신, 전투 재적용을 수행한다.
13. `InventoryCombatBridge.apply_loadout_to_player()`가 장착된 활성 세트 weapon/offhand와 공유 방어구의 스탯을 `Player.refresh_stats_from_loadout()`에 전달하고, 플레이어는 합산 modifier를 `CharacterStats`의 loadout source로 저장한다. grant 패시브와 offhand 비주얼만 별도 적용하며, `grant_on_dash: haste`처럼 시간이 있는 효과는 `BuffTriggerRouter`를 통해 `Player`의 런타임 버프로 부여한다.
14. 클리어, 패배, 로비 복귀, 새 런 시작 시 런 인벤토리 상태를 영구 저장하지 않고 폐기한다.

### Editor / Data

1. 새 무기는 기존 무기 카탈로그 또는 `.tres` 데이터의 `weapon_id`가 고유해야 한다.
2. 새 장비는 `gear_catalog_entries.gd`에 `item_id`, 표시명, 슬롯, `stat_modifiers`, 선택 효과 설명을 추가한다.
3. 새 스탯 키는 `gear_stat_merge.gd`, `gear_stat_display.gd`, 필요 시 `loadout_stat_apply.gd`를 함께 확인한다.
4. UI 노드 구조나 해상도 정책은 `UiViewportLayout` 기준을 따른다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| `sets.size() == 2`, `bag_ids.size() == 8`을 유지한다. | UI 바인딩과 장착 규칙이 고정 크기를 전제로 한다. |
| 빈 슬롯은 `""`로 표현한다. | `null`과 잘못된 id 혼용을 막는다. |
| 동일 `item_id`는 가방 또는 장비 슬롯 중 한 위치에만 존재한다. | 복제·중복 장착 버그를 막는다. |
| 장비 버리기는 월드 드롭 가능 여부를 먼저 확인한 뒤 슬롯을 비운다. | 드롭 실패로 장비가 사라지거나 자동 배치로 위치가 바뀌는 일을 막는다. |
| 런 인벤토리 상태는 영구 저장하지 않는다. | 상자 보상과 골드가 메타 진행으로 새지 않게 한다. |
| 가방에 있는 장비는 스탯, 패시브, 비주얼 효과를 적용하지 않는다. | 획득과 장착을 분리해 장비 선택 의미를 유지한다. |
| weapon 획득은 활성 weapon 빈 슬롯, 비활성 weapon 빈 슬롯, 가방 순서로 배치한다. | 시작 무기는 즉시 사용할 수 있고, 두 번째 무기는 세트 전환 전까지 대기하게 한다. |
| offhand 획득은 같은 세트 weapon이 양손이 아닌 활성 offhand 빈 슬롯, 비활성 offhand 빈 슬롯, 가방 순서로 배치한다. | `offhand 1`은 `weapon 1`, `offhand 2`는 `weapon 2`의 양손 여부에 종속된다. |
| 공유 방어구 획득은 대상 공유 슬롯이 비어 있으면 바로 장착하고, 차 있으면 가방에 넣는다. | 헬멧·갑옷·장갑·부츠·악세도 빈 슬롯일 때는 획득 즉시 빌드에 반영한다. |
| 전투 적용은 활성 세트 weapon만 대상으로 한다. | 비활성 weapon이 자동 공격, 궤도, 장판을 만들지 않게 한다. |
| F6 무기 GUI 착용은 `try_force_equip_weapon_on_active_set`로 활성 weapon만 바꾼다. 기존 무기는 가방이 아닌 삭제. | `acquire_item`의 빈 슬롯·가방 우선 규칙과 분리 |
| 비활성 세트 offhand는 스탯, 패시브, 비주얼 효과를 적용하지 않는다. | 세트 전환 전까지 대기 장비로만 취급한다. |
| 양손 weapon 장착 시 같은 세트의 offhand는 비워야 한다. | 한손/offhand 빌드와 양손 빌드의 경계를 유지한다. |
| 다른 세트의 장비 슬롯끼리 직접 스왑하지 않는다. | UI는 4칸을 동시에 보여도 데이터는 세트별로 분리된다. |
| 방어구 5칸과 악세는 항상 `sets[0]`을 공유한다. | 편집 탭과 전투 세트가 방어구 데이터를 바꾸지 않게 한다. |
| loadout 합산은 장착된 방어구·악세 `sets[0]` + 활성 세트 offhand만 포함하고 weapon은 제외한다. | weapon은 `InventoryCombatBridge`가 단일 `Gun`으로 처리한다. |
| `*_mult` 스탯은 더하지 말고 곱한다. | 장비 배율이 선형 합산되어 과도하게 왜곡되는 것을 막는다. |
| `damage_element == "magic"`인 마법 무기는 `magic_damage_mult`를 타입·원소 중 한 번만 곱한다. | 마법 타입과 magic 원소의 중복 배율을 방지한다. |
| 상자 지급은 슬롯 필터, 등급 필터, 중복 제외를 모두 통과해야 한다. | 부위 상자와 1~10웨이브 `Common`/`Uncommon` 제한을 지킨다. |
| 상자 슬롯 필터는 `ItemRegistry.get_item_reward_slot()` 기준으로 판정한다. | 한손 weapon이 `offhand`에 착용 가능하더라도 보조손 상자 결과로 나오지 않게 한다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 슬롯 추가·이름 변경 | `EquipSlots`, `PlayerLoadoutState`, UI 바인딩, `InventoryService` 검증 |
| 새 장비 추가 | `gear_catalog_entries.gd`, `ItemRegistry.resolve_gear`, 툴팁, `GearStatMerge` 합산 |
| 새 스탯 키 추가 | merge 규칙, 표시 문구, `LoadoutStatApply`, `CharacterStats`, F6 수동 검증 |
| weapon/offhand 정책 변경 | 양손 처리, offhand 반환 실패, 활성 세트 전환, HUD, F5 회귀 |
| 장비 획득 배치 변경 | 활성/비활성 weapon·offhand 빈 슬롯 우선순위, 공유 방어구 빈 슬롯, 가방 가득 참, `EquipmentDrop` 상호작용 획득 처리 |
| 인벤 UI 변경 | 4칸 weapon/offhand 동시 표시, 공유 방어구, RMB 해제와 닫힌 RMB 스왑 충돌 여부, 왼쪽 Shift+좌클릭 버리기와 월드 드롭 복원 |
| 전투 적용 변경 | 장착 장비만 합산하는지, 가방/비활성 장비 제외, `apply_inventory_loadout_to_player()`, `refresh_stats_from_loadout()`, `clear_loadout_stats()`, `CharacterStats` source 갱신 순서, 런타임 버프와 중복 적용 여부 |
| 상자 보상 변경 | 골드 차감/환불, 부위 필터, 등급 확률, 중복 제외, 가방 가득 참 처리 |
| 런 초기화 변경 | 새 런, 클리어, 패배, 로비 복귀에서 장비 상태와 골드가 저장되지 않는지 확인 |

최소 검증은 아레나에서 상자 구매, 장착·해제·세트 전환·양손/offhand·스탯 체감, 클리어/패배/로비 복귀 후 런 인벤토리 초기화를 확인하는 것이다.
