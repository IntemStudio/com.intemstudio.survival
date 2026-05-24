# Architecture — Inventory (인벤토리·장비)

**진입:** [`AGENTS.md`](../AGENTS.md) · 무기 정의: [`weapons/data/weapon_data.gd`](../weapons/data/weapon_data.gd) · 전투 장착: [`weapons/core/gun.gd`](../weapons/core/gun.gd), [`entities/player/player.gd`](../entities/player/player.gd)

**상태:** **Phase 0~2·4~6·3(최소) 구현** — UI v2·**Common 장비 73종** 카탈로그·`GearStatMerge`/`GearStatDisplay`·`use_inventory_loadout` 시 활성 `weapon`→Player. **미구현(Phase 7):** 스탯→플레이어·offhand 패시브/비주얼·F5 기본 on·퀵슬롯.

**목차:** [Overview](#overview) · [Responsibilities](#responsibilities--boundaries) · [Key Types](#key-types--relationships) · [장비 카탈로그](#장비-카탈로그) · [stat_modifiers](#stat_modifiers--gearstatmerge) · [Flow](#flow) · [UI 구성안](#ui-구성안) · [구현 단계](#구현-단계) · [Invariants](#invariants--gotchas) · [Change Guidelines](#change-guidelines)

---

## Overview

인게임 **소지품 8칸**과 **장비 프리셋 2세트**를 관리한다. 각 세트는 **무기·방어구 5부위·보조손·악세사리** 7개 착용 슬롯을 가진다. **활성 전투 세트**(`active_set_index`)는 **W**·**닫힌 RMB**·인벤에서 **비활성 무기/offhand 좌클릭**으로 전환하며, 비활성 세트 무기·보조는 미리 구성해 둔 채로 둔다.

인벤 UI에서는 **무기·offhand**를 세트 1·2 **4칸 동시 표시**. **방어구·악세**는 항상 `sets[0]`(`SHARED_ARMOR_SET_INDEX`) — **편집 1/2 탭**은 UI·`edit_set_index`만 바꾸고 전투 세트·방어구 데이터는 바꾸지 않는다(§UI).

예: 1세트 = 한손 검 + 방패, 2세트 = 양손 검 — **W**로 전투에 쓰는 세트만 바꾼다. 가방 아이템은 **우클릭** 또는 **더블클릭(좌)** 으로 장착(`try_equip_from_bag_smart`).

데이터는 **카탈로그 정의(읽기 전용)** 와 **플레이어 상태(ID만 보관)** 를 분리한다. 세이브·UI·전투 적용은 모두 `item_id` 문자열을 경유하며, `WeaponData`·`GearData`는 런타임에 `ItemRegistry`로 해석한다.

**장비 카탈로그:** `gear_catalog_entries.gd`에 **Common 73종** (offhand 7·helmet 17·armor 21·gloves 4·boots 10·accessory 14). 툴팁은 `GearStatDisplay`, 세트 합산은 `GearStatMerge` — Phase 7에서 `Player`가 소비 예정.

현재 메인 루프의 **서바이버 무기 스택**(`Player._owned_weapons`, 레벨업 3택, `Gun` 궤도 다중 장착)과는 **별 모델**이다. 전투 반영은 `Game.use_inventory_loadout` / `TestArena.use_inventory_loadout`으로 켠다 — **F6 테스트 아레나 기본 on**, **F5 메인 서바이버 기본 off**.

---

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 소지품 | 고정 **8슬롯** 가방. 슬롯당 `item_id` 하나 또는 빈 칸(`""`). |
| 장비 세트 | **2세트**. 세트마다 아래 7슬롯. |
| 활성 세트 | `active_set_index` (0 \| 1). **W**·**RMB(인벤 닫힘)**·비활성 무기/offhand **좌클릭** → 전환 후 전투·HUD 재적용. |
| 착용 규칙 | 슬롯별 허용 `equip_slot`, 양손 무기 시 Offhand 비움, 가방↔장비 이동 시 중복 소유 금지. |
| 아이템 정의 | `item_id`, 표시명, `equip_slots`, 스탯·전투 연동 필드. 무기는 기존 `WeaponData` 확장/매핑. |
| 세이브 | `ConfigFile` + `SettingsSaveUtil` 패턴 (`user://` 경로는 구현 시 확정). |
| 스탯 합산 | `ItemRegistry.sum_stat_modifiers_for_set` + `GearStatMerge` (배율 곱·min/max 합·태그 OR). **전투 반영은 Phase 7.** |
| 장비 카탈로그 | `gear_catalog.gd` + `gear_catalog_entries.gd` — 슬롯별 `item_id`·`stat_modifiers`·`attunement`. |

### Out of Scope (초기 구현 제외 — 필요 시 BACKLOG)

| 제외 | 비고 |
|------|------|
| 서바이버 레벨업 무기와의 자동 병합 | 정책 결정 전 코드에 섞지 않음. |
| 상점·제작·드랍 테이블 | 인벤 API만 열어 두고 별 Epic. |
| 강화·내구도·소켓 | `item_id` 외 인스턴스 데이터는 v2 (`instance` dict). |
| 다중 악세사리(반지 2개) | 현재 슬롯 1개. 확장 시 `ACCESSORY_1` 등 enum 분리. |
| 인벤 **아이콘·슬롯 프레임 아트** | 레이아웃·노드 트리는 §UI. 픽셀 아트·등급 테두리 색은 콘텐츠 제작. |

---

## Key Types & Relationships

### 착용 슬롯 (`EquipSlot`)

| 슬롯 | 키 (저장/코드) | 용도 |
|------|----------------|------|
| 무기 | `weapon` | 주 공격. `WeaponData` + `Gun` (또는 고정 `WeaponPivot`). |
| 헬멧 | `helmet` | 방어·저항 스탯. |
| 갑옷 | `armor` | 방어·저항 스탯. |
| 장갑 | `gloves` | 방어·공격 보조 스탯. |
| 부츠 | `boots` | 이동·회피 등 스탯. |
| 보조손 | `offhand` | 방패·토치·한손 보조 무기. 양손 무기 착용 시 **반드시 비움**. |
| 악세사리 | `accessory` | 반지·목걸이 등 패시브. |

세트당 슬롯 수 = **7**. 슬롯 키 배열 순서는 UI·세이브·코드에서 **동일한 상수**로 고정한다 (`inventory/equip_slots.gd` 등).

### 데이터 계층

```
ItemDefinition (Resource, 추상/공통)
  ├─ item_id, display_name, display_name_ko, rarity, texture
  ├─ equip_slots: Array[EquipSlot]   # 이 아이템이 들어갈 수 있는 슬롯
  └─ stat_modifiers: Dictionary        # 예: {"armor_min": 1, "armor_max": 1, "move_speed_mult": 1.05}

WeaponData extends ItemDefinition (또는 병행 + adapter)
  └─ 기존 weapon_type, hand, damage, gun 분기 필드 유지

GearData extends ItemDefinition        # helmet / armor / gloves / boots / accessory / offhand
  ├─ gear_slot: EquipSlot (단일)       # equip_slots와 중복 시 gear_slot 우선
  ├─ effect / effect_ko: String        # 궤도·대시 등 툴팁용 긴 설명 (`get_effect_localized()`)
  └─ attunement: int                   # 조율 비용(0이면 UI에서 조율 줄 숨김)

GearStatMerge (RefCounted)
  └─ normalize_modifiers · merge_into — sum_stat_modifiers_for_set 전용

GearStatDisplay (RefCounted)
  └─ format_stat_lines · build_gear_tooltip — inventory_menu 툴팁

gear_catalog.gd + gear_catalog_entries.gd
  └─ _create_gear 팩토리 · append_all → ItemRegistry.register_gear

PlayerLoadoutState (Resource 또는 RefCounted)
  ├─ active_set_index: int
  ├─ sets: Array[Dictionary]           # 길이 2, 각 dict = 7슬롯 → item_id
  └─ bag_ids: Array[String]            # 길이 8

ItemRegistry (RefCounted)
  ├─ resolve_gear / resolve_weapon
  ├─ can_item_occupy_slot
  └─ sum_stat_modifiers_for_set → GearStatMerge

InventoryService (RefCounted)
  └─ loadout, edit_set_index, try_* / can_drop / swap_equip_sets / set_active_combat_set

InventoryCombatBridge (RefCounted)
  └─ get_active_weapon_id · apply_active_weapon_to_player (clear + 단일 add_weapon)

InventoryGameBridge (RefCounted)
  └─ F5/F6: show/hide/toggle 인벤 · `swap_combat_set`(W)·닫힌 RMB 스왑 · `refresh_combat_set_hud`

InventoryLoadoutSeed (RefCounted)
  └─ is_loadout_empty · apply_random_starter(빈 세이브) · apply_demo(수동/디버그 고정 시드)

Player (기존)
  └─ _owned_weapons / add_weapon / clear_weapons  ← 서바이버 모드
  └─ use_inventory_loadout=true 일 때 인벤 활성 weapon만 단일 Gun
```

### 한 손 / 양손 (`WeaponData.hand`)

| `hand` | `weapon` 슬롯 | `offhand` 슬롯 |
|--------|----------------|----------------|
| `One-Handed` | 허용 | 방패·보조 무기 등 허용 (`equip_slots`에 `offhand` 포함 시) |
| `Two-Handed` | 허용 | **착용 불가** — 장착 시 해당 세트 `offhand=""`, 기존 offhand는 가방으로 반환(가방 full이면 장착 실패) |

### 세트·가방 예시 (저장 형태)

```ini
[inventory]
version=1
active_set=0

[set/0]
weapon=broken_hero_sword
helmet=
armor=leather_tunic
gloves=
boots=traveler_boots
offhand=wooden_shield
accessory=

[set/1]
weapon=bastard_sword
helmet=
armor=
gloves=
boots=
offhand=
accessory=

[bag]
slot0=
slot1=health_potion
; ... slot7=
```

---

## 장비 카탈로그

| 슬롯 | 등록 수 | 데이터 파일 | 비고 |
|------|---------|-------------|------|
| `offhand` | 7 | `gear_catalog_entries.gd` | 방패·오브·화살통 등 |
| `helmet` | 17 | 동일 | 서클렛·모자·반다나 등 |
| `armor` | 21 | 동일 | 로브·판금·코트 등 (`leather_tunic` 포함) |
| `gloves` | 4 | 동일 | |
| `boots` | 10 | 동일 | `traveler_boots`·`leather_boots` 등 |
| `accessory` | 14 | 동일 | 반지·리본·펜던트 등 |
| **합계** | **73** | | 전부 `rarity = Common` |

- **등록:** `gear_catalog.gd` `_build_cache()` → `gear_catalog_entries.append_all(_cache, Callable(_create_gear))`.
- **아이콘:** 공통 플레이스홀더 `art/shared/pistol.png` (아트 폴리시 전).
- **빈 세이브 시드:** `inventory_menu.gd` `_ensure_service()` — `is_loadout_empty`이면 `apply_random_starter`(방어구 5칸·2세트 무기/offhand 무작위) 후 즉시 저장.
- **수동 데모:** `InventoryLoadoutSeed.apply_demo` — 고정 무기·offhand·가방 8칸(디버그·문서 예시용).

새 장비 추가 시 `gear_catalog_entries.gd`에 `_create_gear` 호출 한 블록 추가 → Godot 재실행 시 `_cache` 재빌드.

---

## stat_modifiers & GearStatMerge

`GearData.stat_modifiers`는 **전투 수치용 Dictionary**. 표시·합산 규칙을 분리해 둔다.

| 규칙 종류 | 키 패턴·예 | `GearStatMerge` 동작 |
|-----------|------------|----------------------|
| min/max 쌍 | `armor_min`+`armor_max`, `block_min`+`block_max`, `heart_*`, `mana_*`, `flask_*`, `revive_*`, `dart_damage_*` | min·max 각각 **합산** |
| 배율 | `*_mult`, `damage_mult` (`move_speed_mult`, `melee_damage_mult` …) | **곱연산** (1.2×1.1) |
| flat 가산 | `power`, `stamina`, `curse`, `strength`, `dexterity`, `intelligence`, `weapon_upgrade_level`, `sword_crit_chance_bonus`, `damage_mult_per_level` | **합산** |
| 최대값 | `invincibility_after_damage_sec`, `invincibility_after_dash_sec` | **max** |
| 불리언 OR | `prevent_curse` | 하나라도 true면 true |
| 태그 목록 | `grant_orbital`, `grant_on_dash` | 문자열 **배열** 누적 |
| 레거시 | `armor` (flat int) | `normalize` 시 `armor_min`/`armor_max`로 변환 |

**표시:** `GearStatDisplay.format_stat_lines` — 위 키를 사람이 읽는 문장으로 변환. `GearData.effect`는 궤도·대시 등 **추가 설명** (툴팁 마지막 줄).

**Must not:** `sum_stat_modifiers_for_set`에서 배율 키를 **덧셈**하지 말 것. 새 `*_mult` 추가 시 `GearStatMerge._is_mult_key` 또는 merge 분기 확인.

**Phase 7:** 활성 세트 `sets[active_set_index]`의 offhand + `sets[0]` 방어구 5칸 + `accessory` 합산 정책을 `player.gd`에서 한 번에 정의할 것(문서·코드 동기화).

---

## Flow

### Runtime

1. **런 시작 / 로드** — `InventorySave.load_state()` → `InventoryService` 생성 시 `ItemRegistry.register_all_catalogs()`. 인벤 **최초 열기**(`_ensure_service`) 시 빈 loadout이면 `InventoryLoadoutSeed.apply_random_starter` → 저장.
2. **활성 세트 무기 → 전투** (`use_inventory_loadout == true`):
   - `Game.apply_inventory_loadout_to_player()` / `TestArena.apply_inventory_loadout_to_player()` → `InventoryCombatBridge.apply_active_weapon_to_player` (F6는 튜닝 스냅샷 `_equip_weapon` 경유).
   - 호출 시점: 인벤 열기, 드래그/장착/해제 후, 비활성 전투 슬롯 좌클릭, **W**·닫힌 **RMB** 스왑.
   - F6 로드아웃 on 시 **W**는 위 이동 대신 세트 전환 — `Player._move_vector_excluding_physical_key(KEY_W)` (`↑` 방향키로 상승).
   - **미구현:** offhand 패시브(`grant_*`)·방어구 `stat_modifiers` → `player` (`refresh_stats_from_loadout`, Phase 7).
3. **W / RMB (인벤 닫힘)** — `InventoryGameBridge.swap_equip_sets` → `toggle_active_set_index` → 저장 → `apply_inventory_loadout_to_player` · HUD `CombatSetLabel` 갱신.
4. **가방 → 장착** — `try_equip_from_bag_smart`: 무기·offhand → **active_set_index**, 방어구·악세 → **sets[0]** (`SHARED_ARMOR_SET_INDEX`). 가방 **우클릭**·**더블클릭(좌)**.
5. **장착 해제** — 인벤 열림 + 슬롯 RMB → `try_unequip`.
6. **세트 간 드래그** — `try_swap_set_slots`는 **동일 set_index만** — 실패 시 `ERROR_CROSS_SET`.

### Editor

1. 무기: 기존 카탈로그·`.tres` 유지, `item_id` = `weapon_id`.
2. 장비: `gear_catalog_entries.gd`에 엔트리 추가 (`_create_gear` 인자: id, en/ko 이름, `EquipSlots.*`, `stats`, 선택 `effect_en/ko`, `attunement`).
3. 새 `stat_modifiers` 키: `gear_stat_merge.gd` 규칙 + `gear_stat_display.gd` 툴팁 포맷 동시 갱신.
4. `equip_slots` / `gear_slot` 오류 시 `can_item_occupy_slot` false.

---

## UI 구성안

인벤 UI는 **전체 화면 오버레이** 1장. 해상도·스케일 정책은 [`Docs/AGENTS_Display_UI.md`](Docs/AGENTS_Display_UI.md)와 동일 — 루트 `Control` **1920×1080**, `UiViewportLayout`, `align_mode = center`, `pass_mouse_to_game = false`.

**레퍼런스:** 장비·가방·(선택) 퀵슬롯이 **세로 3단**으로 쌓인 픽셀 UI. 핵심 규칙은 **전투에서 W/RMB로 바꾸는 무기·offhand는 세트 1·2를 탭 전환 없이 한 화면에 동시에 보여 준다**는 점이다.

### 열기·닫기·일시정지

| 항목 | 제안 |
|------|------|
| 열기 | 입력 액션 `toggle_inventory` (**I**, `project.godot`) |
| 닫기 | **Esc**, 헤더 **닫기** 버튼, `toggle_inventory` 재입력 |
| 게임 정지 | 메뉴 표시 시 `get_tree().paused = true` — **일시정지 메뉴·무기 선택·게임오버·클리어**가 열려 있으면 인벤 열기 **무시** (`pause_menu`·`game.gd`와 동일 게이트) |
| 전투 중 세트 스왑 | 입력 `swap_combat_set` (**W**) · 닫힌 **RMB** — `InventoryGameBridge.swap_equip_sets`. 인벤 **열림** 시 W/RMB 전역 스왑 **금지**, RMB는 슬롯 해제만 |
| 이동 (F6) | `use_inventory_loadout` on 시 **W** ≠ `move_up` — 위 이동은 **↑** (`Player`에서 물리 키 W 제외) |

`CanvasLayer.layer`는 `%PauseMenu`(20)와 겹치지 않게 **19** 또는 Pause보다 위(21) 중 하나로 고정 — 구현 시 한 번만 결정하고 문서·씬에 주석.

### 씬·스크립트 (구현 경로)

| 자산 | 역할 |
|------|------|
| `ui/inventory/inventory_overlay.tscn` | `%InventoryMenu` 루트 `CanvasLayer` (layer 19) |
| `ui/inventory/inventory_menu.gd` | 탭·4칸 전투 슬롯·드래그·`InventoryService`·`_sync_combat_loadout` |
| `ui/inventory/inventory_slot.tscn` + `inventory_slot.gd` | 슬롯 1칸 — `set_combat_active`, 드래그, dry-run 검증 |
| `inventory/inventory_game_bridge.gd` | `game.gd` / `test_arena.gd` 공통 입·출력 |

`survivors_game.tscn` · `test_arena.tscn`에 `InventoryMenu` 인스턴스.

### 화면 레이아웃 (FHD 1920×1080, 레퍼런스 UI)

반투명 딤 + 중앙 패널. 패널 안은 **위→아래**로 **장비(3열 그리드)** → **소지품 8(2×4, 번호 1~8)** → **(선택) 퀵슬롯 4(1×4)**. 우측 또는 하단에 **상세 패널**·헤더 **닫기**.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ [딤]  인벤토리                         [편집 1] [편집 2]  [닫기]          │
├──────────────────────────────────────────────────────────────────────────┤
│  ┌─ 장비 (3열) ─────────────────────────────────────────────────────┐   │
│  │   무기2  │  헬멧  │  보조2  (↕)                                        │   │
│  │   무기1  │  갑옷  │  보조1  (↕)                                        │   │
│  │   장갑   │  악세  │  부츠   (방어구=sets[0] 공유)                      │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│  소지품  [1][2][3][4]                                                    │
│          [5][6][7][8]                                                    │
│  퀵슬롯  [Q1][Q2][Q3][Q4]   ← 선택 기능, 초기 Epic 제외 가능            │
│  ─────────────────────────────────────────────────────────────────────   │
│  상세 (RichTextLabel) · ● 활성 전투 세트: 1                               │
├──────────────────────────────────────────────────────────────────────────┤
│  힌트: W·닫힌 RMB — 전투 세트 · 가방 RMB/더블클릭 — 장착 · 드래그 — 이동    │
└──────────────────────────────────────────────────────────────────────────┘
```

**치수 가이드 (FHD, 튜닝 가능):**

| 영역 | 크기·배치 |
|------|-----------|
| 중앙 패널 | 약 **1680×920**, `CenterContainer` |
| 장비 3열 | 열당 슬롯 **88×88**, 열 간격 **12**, 무기·offhand 열은 **세로 2칸 + 화살표** 여유 |
| 가방 그리드 | **4×2**, 슬롯 **80×80**, 라벨 **1~8** |
| 퀵슬롯 행 | **1×4** (구현 시), 가방과 동일 슬롯 위젯 재사용 가능 |
| 상세 패널 | 패널 하단 또는 우측 **~400px**, `WeaponSelectMenu` `DetailPanel` 톤 |

### 무기·offhand — 2세트 동시 표시 (필수)

| 규칙 | 설명 |
|------|------|
| **항상 4칸** | `sets[0].weapon`, `sets[1].weapon`, `sets[0].offhand`, `sets[1].offhand` — **편집 탭과 무관하게** 항상 화면에 바인딩. |
| **열 배치** | 레퍼런스와 같이 **무기 열(좌)** · **offhand 열(우)** 각각 세로 2칸. 세트 번호는 슬롯 라벨 또는 작은 `1`/`2` 뱃지. |
| **활성 전투 세트** | `active_set_index`에 해당하는 무기·offhand 칸 — **채도 높은 아이콘**, 테두리 강조, **▲** 등 활성 표시. |
| **비활성 세트** | 반대 세트 칸 — **고스트/저채도** 아이콘(빈 칸이면 실루엣만), **▼** 또는 약한 화살표로 “대기” 표시. |
| **양손 무기** | 활성·비활성 **모든** offhand 칸에서, 해당 세트 `weapon`이 양손이면 그 세트 offhand 칸 **blocked** (회색·입력 불가). |
| **드래그 대상** | 각 칸은 고정 `(set_index, slot_key)` — `weapon`/`offhand` 드롭은 **해당 세트**에만 적용. |
| **탭과 분리** | **편집 1/2 탭**은 `edit_set_index`·탭 하이라이트만 — 무기·offhand·방어구 표시·데이터는 **변하지 않음**. |

**Must:** 플레이어가 탭을 바꾸지 않아도 **두 세트의 무기·보조손 구성을 한눈에** 보고, W/RMB 전환 결과가 어느 칸이 활성인지 즉시 알 수 있어야 한다.

### 방어구·악세 — 세트 0 공유

| 슬롯 | UI 동작 |
|------|---------|
| `helmet`, `armor`, `gloves`, `boots`, `accessory` | **항상 `sets[0]`** (`inventory_menu.gd` `SHARED_ARMOR_SET_INDEX`). 편집 탭과 무관. |
| 배치 | **3×3**: 행0 `weapon2`·`helmet`·`offhand2` · 행1 `weapon1`·`armor`·`offhand1` · 행2 `gloves`·`accessory`·`boots`. |

좌·우 열 = 전투 스왑용 무기·offhand(세트 0·1). 중앙 열 = 공유 방어구.

### 세트 탭 vs 활성 전투 세트

| UI 상태 | 의미 |
|---------|------|
| **편집 탭** (편집 1 / 2) | `edit_set_index`만 변경(UI 탭 강조·예약). **활성 전투 세트·가방 자동 장착 대상은 바꾸지 않음**. |
| **방어구 5칸** | 항상 `sets[0]` (`SHARED_ARMOR_SET_INDEX`) — 헬멧·갑옷·장갑·부츠·악세. 탭과 무관. |
| **활성 전투 세트** | `active_set_index` — 무기·offhand 활성 강조 · HUD `전투 세트 N` · `● 전투 세트: N`(인벤 내). |
| **W / RMB (인벤 닫힘)** | `InventoryGameBridge.swap_equip_sets` → 토글 · 저장 · `apply_inventory_loadout_to_player` |
| **RMB (인벤 열림, 장비 슬롯)** | `try_unequip(set_index, slot_key)` |
| **좌클릭 (비활성 무기/offhand)** | `set_active_combat_set` + 저장 + 전투 반영 + 토스트 |
| **좌클릭 (활성 무기/offhand, 아이템 있음)** | 상세 패널 + `inventory.combat_active_slot` 안내 |

### 슬롯 위젯 (`inventory_slot.gd`)

| 표시 | 동작 |
|------|------|
| 빈 칸 | 어두운 `Panel` + 슬롯 실루엣 아이콘(선택) |
| 아이템 있음 | `ItemDefinition.texture` 또는 무기 `WeaponData.texture`, 희귀도 테두리 색(추후) |
| 호버 | `detail` 패널 — 무기 `WeaponData.build_select_tooltip_bbcode()`, 장비 `GearStatDisplay.build_gear_tooltip` |
| 좌클릭 드래그 | 가방↔장비, 장비↔장비(같은 세트), 장비↔빈 가방 |
| 더블클릭·우클릭 (가방) | `try_equip_from_bag_smart` — 무기·offhand → **active_set_index**, 방어구·악세 → **sets[0]** |
| 비활성 offhand | 해당 **세트**의 `weapon`이 양손이면 그 세트 offhand 칸 **회색 + 입력 불가** (활성·비활성 열 각각 판정) |
| 무기·offhand 열 | 세트 0/1 **동시 표시** — 비활성 세트는 고스트 아이콘, 활성 세트는 강조 |

슬롯은 데이터에 `bag_index` **또는** `(set_index, slot_key)` 중 하나만 가짐 — UI 갱신 시 `refresh_all_slots(state)` 한 번으로 동기화.

### 드래그·드롭 규칙 (UI → Service)

1. 드롭 시 항상 `InventoryService` / `ItemRegistry.can_item_occupy_slot` 경유 — UI만으로 슬롯에 넣지 않음.
2. 양손 무기를 `weapon`에 놓으면 Service가 `offhand` 비우고 기존 offhand를 가방으로 — 가방 full이면 **드롭 취소** + 토스트.
3. 동일 `item_id` 중복 배치 금지 — 드래그 소스 칸을 먼저 비운 뒤 대상에 씀.
4. **다른 세트** 슬롯끼리 스왑 불가 — `ERROR_CROSS_SET` 토스트.

### `%` 노드 계약 (`inventory_overlay.tscn`)

| 노드 | 용도 |
|------|------|
| `%MenuOverlay` | `UiViewportLayout` 루트 |
| `%EditSetTab0` / `%EditSetTab1` | **편집 1/2** 탭 (`inventory.set_tab`) — `edit_set_index`만, 전투 세트 미변경 |
| `%EquipPanel` | 장비 슬롯 부모 — **코드에서** `InventorySlot` 9개+열 제목·↕ 힌트 배치 |
| `%EquipArmorTitle` | `방어구` 열 제목 (`inventory.col_armor`) — 탭과 무관 |
| `%BagGrid` | 가방 2×4 (`configure_bag`) |
| `%DetailLabel` | 호버·BBCode 상세 |
| `%ActiveSetLabel` | `● 전투 세트: N` |
| `%CloseButton` | 닫기 |

**코드 배치 (고정 `set_index`):** `_weapon_slots[0|1]`, `_offhand_slots[0|1]` — `WEAPON_LAYOUT` / `OFFHAND_LAYOUT`. 방어구 4칸 + `_accessory_slot`은 항상 `SHARED_ARMOR_SET_INDEX`(0)로 `configure_equip`.

**폐기:** 탭에 묶인 단일 weapon/offhand 1칸. 씬에 `%WeaponSlotSet0` 등 **별도 노드 없음** — `inventory_menu.gd`가 `%EquipPanel` 아래 동적 생성.

### HUD·입력 연동

| 항목 | 제안 |
|------|------|
| HUD | `%CombatSetLabel` — `use_inventory_loadout` 시 `HUDRoot` 좌하단 `전투 세트 N` (`refresh_combat_set_hud`) |
| 로케일 | `inventory.hud_combat_set`, `inventory.error.two_hand_bag_full`, `inventory.error.cross_set`, `inventory.hint` 등 (`ui_locale.gd`) |
| HUD (씬) | `survivors_game.tscn` · `test_arena.tscn` — `%CombatSetLabel` (`unique_name_in_owner`) |
| 사운드 | 열기/닫기·장착 성공/실패 SFX — `AudioSettings` 버스 `SFX` (후순위) |

### UI 데이터 바인딩

```
InventoryGameBridge.show_inventory(game, menu)
  → on_menu_opened → InventorySave.load (최초) → refresh_all_slots → _sync_combat_loadout
  → paused = true

변경 (드롭 / 가방 장착·해제 / 비활성 전투 슬롯 좌클릭 / W·닫힌 RMB)
  → InventoryService.try_* · try_equip_from_bag_smart · set_active_combat_set
  → InventorySave.save_state (세트 전환·닫기 시)
  → refresh_all_slots
  → game.apply_inventory_loadout_to_player()  # use_inventory_loadout
  → InventoryGameBridge.refresh_combat_set_hud

InventoryGameBridge.hide_inventory
  → on_menu_closed → save → paused 해제 (다른 메뉴 없을 때)
```

`WeaponSelectMenu`처럼 `CanvasLayer`의 `show()`/`hide()` **오버라이드 금지** — `on_menu_opened()` / `on_menu_closed()` 패턴 사용.

### Must not (UI)

- FHD 좌표를 HD 픽셀로 수동 축소하지 말 것 — `UiViewportLayout`만 스케일.
- 슬롯에 `item_id`를 직접 쓰기만 하고 `ItemRegistry` 검증을 건너뛰지 말 것.
- **무기·offhand를 편집 탭에만 묶어 한 세트만 보이게 하지 말 것** — RMB 스왑 UI의 핵심 요구사항.
- 인벤 열린 채로 **W·RMB** 전역 세트 스왑을 켜지 말 것(슬롯 우클릭 해제와 충돌).
- 무기·장비 툴팁을 인벤 스크립트에 **중복 작성**하지 말 것 — `WeaponData.build_select_tooltip_bbcode()` · `GearStatDisplay` 재사용.

UI 구현 상세 순서는 [§구현 단계](#구현-단계) Phase 4~6에 포함.

---

## 구현 단계

Epic을 **한 Phase = 한 PR·한 커밋 묶음**으로 나눈다. 각 단계 끝에 Godot 실행·해당 성공 기준 통과 후 다음 Phase로 진행.

### 진행 표

| Phase | 이름 | 상태 | 성공 시 플레이어가 할 수 있는 것 |
|-------|------|------|----------------------------------|
| **0** | 데이터·세이브·Registry | ✅ | 상태·`user://`·`item_id` 해석 |
| **1** | InventoryService | ✅ | 가방↔장착·양손·드래그·세트 스왑 |
| **2** | 장비 카탈로그 | ✅ | Common **73종** · `GearStatMerge`/`GearStatDisplay` |
| **3** | 전투 연동 (주 무기) | 🔶 | `InventoryCombatBridge`·`use_inventory_loadout`(F6 on, F5 off) |
| **4** | UI 껍데기 | ✅ | 3열 장비 — 무기·offhand 4칸 동시, 탭=방어구 5칸 |
| **5** | UI 드래그·게임 연동 | ✅ | 드래그·I·세이브·4칸 전투 슬롯 바인딩 |
| **6** | 전투 UX·마무리 | ✅ | W·RMB·좌클릭 세트 전환·로케일·cross_set·가방 장착·HUD 칩 |
| **7** | 확장 (선택) | ⬜ | 방어구 스탯·offhand `Gun`/비주얼·서바이버 병행 정책 |

**선행 결정 (Phase 3 전에 문서·코드에 고정):**

| 결정 | 권장 초기값 |
|------|-------------|
| 서바이버 `_owned_weapons` vs 인벤 | **인벤 전용 테스트 씬** 또는 `Game.use_inventory_loadout = true`일 때만 인벤 `weapon` 적용, 레벨업 3택은 기존 유지 |
| 런 중 세이브 | 닫을 때 `InventorySave.save_state` + 런 시작 시 로드 |
| 양손 시 offhand 반환 실패 | **장착 취소** (가방 full이면 weapon 장착도 롤백) |

---

### Phase 0 — 데이터·세이브·Registry ✅

| 항목 | 내용 |
|------|------|
| **목표** | `item_id`만으로 상태·세이브·카탈로그 해석 가능 |
| **산출물** | `equip_slots.gd`, `item_definition.gd`, `gear_data.gd`, `player_loadout_state.gd`, `inventory_save.gd`, `item_registry.gd`, `gear_catalog.gd`, `gear_catalog_entries.gd` |
| **성공 기준** | `PlayerLoadoutState.create_empty()` → `InventorySave.save/load` 왕복 · `ItemRegistry.register_all_catalogs()` 후 무기 `can_item_occupy_slot` 동작 |
| **범위 밖** | UI, Service, 전투 |

---

### Phase 1 — InventoryService

| 항목 | 내용 |
|------|------|
| **목표** | UI·전투 없이 **모든 착용 규칙**을 한 곳에서 처리 |
| **산출물** | `inventory/inventory_service.gd` (`class_name InventoryService`) |
| **API (주요)** | `try_equip_from_bag`, `try_equip_from_bag_smart(bag_index, armor_set_index)`, `try_unequip`, `try_drop`(dry_run), `swap_equip_sets`, `set_active_combat_set`, `can_drop` |
| **오류 키** | `ERROR_BAG_FULL`, `ERROR_TWO_HAND_BAG_FULL`, `ERROR_OFFHAND_BLOCKED`, `ERROR_CROSS_SET` 등 → `UiLocale` |
| **규칙** | `ItemRegistry` 검증 · 동일 `item_id` 단일 위치 · 양손 `weapon` 시 offhand 클리어+가방 반환 · offhand blocked 검사 |
| **성공 기준** | GDScript 단위 시나리오(또는 `test_arena` 임시 버튼)로 1세트 검+방패 / 2세트 양손 전환 시 상태 dict가 기대와 일치 |
| **범위 밖** | 씬·`Gun`·드래그 |
| **의존** | Phase 0 |

---

### Phase 2 — 장비 카탈로그 ✅

| 항목 | 내용 |
|------|------|
| **목표** | 6슬롯 Common 장비 데이터 + 스탯 합산·툴팁 인프라 |
| **산출물** | `gear_catalog.gd` + `gear_catalog_entries.gd`(~70종) · `gear_stat_merge.gd` · `gear_stat_display.gd` |
| **예시 id** | 슬롯별 Common 장비(offhand·helmet·armor·gloves·boots·accessory) — 레거시 `armor` flat 키는 정규화됨 |
| **성공 기준** | `ItemRegistry.resolve_gear` · `can_item_occupy_slot` · `sum_stat_modifiers_for_set`가 `GearStatMerge` 규칙으로 합산 |
| **범위 밖** | 아이콘 아트 폴리시 |
| **의존** | Phase 0 |

---

### Phase 3 — 전투 연동 (주 무기) 🔶

| 항목 | 내용 |
|------|------|
| **목표** | **활성 세트 `weapon`만** 플레이어에 반영 (`clear_weapons` + 단일 `add_weapon`) |
| **산출물 (완료)** | `inventory_combat_bridge.gd` · `game.gd` / `test_arena.gd` `use_inventory_loadout` · `apply_inventory_loadout_to_player()` |
| **성공 기준 (F6)** | 세트 스왑·인벤 장착 후 발사 무기가 활성 세트 `weapon` id와 일치 |
| **잔여** | F5에서 플래그 on + 레벨업 3택과 공존 정책 · 전용 `%InventoryWeaponGun` 노드 분리(선택) |
| **범위 밖** | offhand·방어구 스탯(Phase 7) |
| **의존** | Phase 1 |

---

### Phase 4 — UI 껍데기

| 항목 | 내용 |
|------|------|
| **목표** | §UI 레이아웃(3열 장비 + 2×4 가방)을 씬으로 고정하고 **읽기 전용** 갱신 |
| **산출물** | `ui/inventory/inventory_slot.tscn`, `inventory_slot.gd`, `inventory_overlay.tscn`, `inventory_menu.gd` · `survivors_game.tscn` 인스턴스 |
| **성공 기준** | `toggle_inventory`로 열기/닫기 · **무기 2칸 + offhand 2칸 항상 표시**, 활성 세트 강조/비활성 고스트 · 방어구 `sets[0]` · 편집 탭은 UI만 · 8 가방 · `%DetailLabel` 호버 |
| **범위 밖** | 드래그·Service mutating · RMB 전역 스왑 · 퀵슬롯 4칸(선택) |
| **의존** | Phase 1, 2 |

---

### Phase 5 — UI 드래그·게임 연동

| 항목 | 내용 |
|------|------|
| **목표** | 인벤에서 상태 변경이 끝까지 동작 |
| **산출물** | 슬롯 drag&drop · `game.gd` `show_inventory`/`hide_inventory` · `on_menu_opened`/`closed` · `paused` · 무기선택/게임오버 시 열기 차단 |
| **성공 기준** | 가방→장비·해제→가방 · 양손 장착 시 offhand 자동 이동 · 닫을 때 `InventorySave` · 편집 탭과 `active_set_index` 분리 표시 |
| **범위 밖** | 인벤 닫힌 RMB 스왑(Phase 6) |
| **의존** | Phase 3(전투 반영은 스왑/장착 후 `apply_active_set` 호출), Phase 4 |

---

### Phase 6 — 전투 UX·마무리 ✅

| 항목 | 내용 |
|------|------|
| **목표** | 전투 중 세트 전환·문구·입력·HUD 정리 |
| **산출물** | `toggle_inventory`(I) · `swap_combat_set`(W) · `InventoryGameBridge` · `try_equip_from_bag_smart` · `%CombatSetLabel` · `UiLocale` |
| **성공 기준** | W·닫힌 RMB로 1↔2 세트 무기 즉시 교체 · HUD `전투 세트 N` · 인벤 열림 시 RMB=해제만 · 가방 RMB/더블클릭 장착 · 양손+가방 full 전용 오류 |
| **범위 밖** | 상점·드랍 |
| **의존** | Phase 5 |

---

### Phase 7 — 확장 (선택, BACKLOG)

| 항목 | 내용 |
|------|------|
| **목표** | 방어구·악세 **스탯 합산**·offhand·비주얼·서바이버와 공존 정책 |
| **산출물** | `player.gd` `refresh_stats_from_loadout` — `ItemRegistry.sum_stat_modifiers_for_set` + `GearStatMerge` 소비 · offhand 패시브/비주얼 |
| **성공 기준** | 배율 곱·min/max 합·`grant_*` 태그가 전투에 반영 · 한손+방패 vs 양손 체감 차이 |
| **의존** | Phase 6 |

---

### Phase별 터치 파일 (체크리스트)

| Phase | 주요 경로 |
|-------|-----------|
| 1 | `inventory/inventory_service.gd` |
| 2 | `inventory/gear_catalog.gd`, `gear_catalog_entries.gd`, `gear_stat_merge.gd`, `gear_stat_display.gd` |
| 3 | `inventory/inventory_combat_bridge.gd`, `game/game.gd`, `game/test_arena.gd` (`use_inventory_loadout`) |
| 4~6 | `ui/inventory/*`, `inventory/inventory_game_bridge.gd`, `survivors_game.tscn`, `test_arena.tscn`, `project.godot` (`swap_combat_set`), `ui/settings/ui_locale.gd`, `entities/player/player.gd` (W 이동 분리) |
| 7 | `player.gd`, `item_registry.gd`, `gear_stat_merge.gd`, `entities/player/player.tscn` |

**품질 게이트 (매 Phase):** Godot 파싱 에러 없음 · 해당 Phase 성공 기준 수동 1회 · 기존 F5 메인 루프 회귀(Phase 3+는 플래그 off 시 기존과 동일).

---

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 동일 `item_id`는 **한 위치**에만 존재 (가방 XOR 특정 세트 슬롯). | 복제·중복 장착 버그 방지. |
| `sets.size() == 2`, `bag_ids.size() == 8` 고정. | 세이브 마이그레이션 단순화. |
| 빈 슬롯은 항상 `""`. `null`·잘못된 id 혼용 금지. | `ConfigFile`·JSON 호환. |
| 양손 무기 장착 시 해당 세트 `offhand`는 **자동 클리어** (정책: 가방 반환 또는 실패). | `gun.gd` 단일 무기 스케일과 일관. |
| 전투 피해·통계는 **활성 세트의 `weapon`** 기준 `get_unique_key()` 유지. | `WeaponDamageTracker`·`register_weapon_damage` 경로 유지. |
| `ItemRegistry.resolve` 실패 시 장착·스왑 **거부**, 로그만 (조용한 무시 금지). | 누락 카탈로그 조기 발견. |
| 서바이버 `_owned_weapons`와 인벤 `weapon`을 **같은 배열에 넣지 않음**. | 레벨업 무기 수와 장비 세트 의미 충돌. |
| Offhand 방패는 `attacks_per_second == 0`인 `WeaponData`로 끼우지 말 것. | `Gun` 타이머·분기 오염 — `GearData` + 스탯 권장. |
| 스탯 합산은 `GearStatMerge`만 사용 — `*_mult`는 **곱**, min/max·flat은 **합**, `prevent_curse`는 OR. | `sum_stat_modifiers_for_set`에서 배율 덧셈 버그 방지. |
| 레거시 `armor` flat 키는 쓰지 말고 `armor_min`/`armor_max` 쌍 사용. | `GearStatMerge.normalize_modifiers`가 flat만 호환. |
| `use_inventory_loadout == false`이면 인벤 weapon 변경이 `Player._owned_weapons`에 **자동 반영되지 않음**. | F5 서바이버 회귀. |
| 세트 간 장비 슬롯 드래그 **금지** (`ERROR_CROSS_SET`). | UI 4칸 나란히 보여도 데이터는 세트별 분리. |

---

## Change Guidelines

구현·수정 전 확인:

| 확인 항목 | 관련 |
|-----------|------|
| 빈 세이브 시드 | `inventory_menu.gd` `_ensure_service` → `apply_random_starter` — §Flow |
| 새 장비 종류 | `gear_catalog_entries.gd` + `ItemRegistry` 등록 + `equip_slot` · 툴팁은 `gear_stat_display.gd` · 합산 키는 `gear_stat_merge.gd` |
| 새 무기 | 기존 [`godot-weapons.mdc`](../.cursor/rules/godot-weapons.mdc) — 카탈로그·`weapon_id` 고유·`gun.gd` 분기 |
| 슬롯 키 추가/이름 변경 | 세이브 `version` bump, `EquipSlot` enum, UI 바인딩 일괄 |
| W / RMB | 인벤 **닫힘** = `swap_equip_sets` · **열림** = 슬롯 RMB 해제만 — §UI Must not |
| 가방 장착 | `try_equip_from_bag_smart` — 무기·offhand=`active_set_index`, 방어구=`SHARED_ARMOR_SET_INDEX` |
| 인벤 UI | 4칸 전투 슬롯·편집 탭(UI만)·`%EquipPanel` — §UI |
| HUD | `refresh_combat_set_hud` · `%CombatSetLabel` — `apply_inventory_loadout_to_player` 후 |
| 전투 반영 | `apply_inventory_loadout_to_player` · `use_inventory_loadout` — §Flow |
| 인벤 UI | `%` 노드·`on_menu_opened` / `InventoryGameBridge` — §UI, `AGENTS_Display_UI.md` |
| 플레이어 씬 | `WeaponPivot` / `OffhandPivot` / 방어구 비주얼 노드 (미정 시 BACKLOG) |
| 테스트 | `test_arena` — Equip 패널과 별도 “인벤 프리셋” 디버그 또는 전용 씬 |
| 문서 | 슬롯 수·세트 수·가방 크기 변경 시 **이 파일 + `AGENTS.md` 요약 + BACKLOG** |

**구현 순서:** [§구현 단계](#구현-단계) Phase 0~6 순차. Phase 7·서바이버 병행은 BACKLOG.

### 구현된 스크립트

| 경로 | class_name | 역할 |
|------|------------|------|
| `inventory/equip_slots.gd` | `EquipSlots` | 슬롯 키·`BAG_SIZE`·`SET_COUNT` |
| `inventory/item_definition.gd` | `ItemDefinition` | 공통 Resource |
| `inventory/gear_data.gd` | `GearData` | 방어구·방패·악세 |
| `inventory/player_loadout_state.gd` | `PlayerLoadoutState` | 2×7 + 가방 8 · `set_active_set_index` |
| `inventory/inventory_save.gd` | `InventorySave` | `user://player_loadout.cfg` |
| `inventory/item_registry.gd` | `ItemRegistry` | 해석·`can_item_occupy_slot` |
| `inventory/gear_catalog.gd` | — | 캐시·`_create_gear` 팩토리 |
| `inventory/gear_catalog_entries.gd` | — | Common 장비 **73** 엔트리 |
| `inventory/gear_stat_merge.gd` | `GearStatMerge` | `stat_modifiers` 합산 규칙 |
| `inventory/gear_stat_display.gd` | `GearStatDisplay` | 장비 툴팁 포맷 |
| `inventory/inventory_service.gd` | `InventoryService` | `try_equip_from_bag_smart`·드래그·`ERROR_CROSS_SET`·`ERROR_TWO_HAND_BAG_FULL` |
| `inventory/inventory_combat_bridge.gd` | `InventoryCombatBridge` | 활성 weapon → Player |
| `inventory/inventory_game_bridge.gd` | `InventoryGameBridge` | 인벤 I·W/RMB 스왑·`refresh_combat_set_hud` |
| `inventory/inventory_loadout_seed.gd` | `InventoryLoadoutSeed` | 빈 세이브 `apply_random_starter` · `apply_demo`(고정) |
| `ui/inventory/inventory_menu.gd` | — | UI v2 · `GearStatDisplay` 위임 |
| `ui/inventory/inventory_slot.gd` | `InventorySlot` | 슬롯 위젯 |

---

## AGENTS.md 요약 (한 줄)

인벤: **가방 8**, **2×7슬롯**, **장비 73종** 카탈로그, UI **무기·offhand 4칸**, `use_inventory_loadout` 시 활성 weapon→Player, **I**·**W**/닫힌 **RMB**·비활성 슬롯 **좌클릭** 세트 전환, `GearStatMerge`/`GearStatDisplay`, Phase 7=스탯→Player.
