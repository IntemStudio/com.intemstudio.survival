# Input Architecture

## Overview

입력 시스템은 Godot `InputMap`을 실제 바인딩 저장소로 두고, `game/input/action_manager.gd`가 게임 코드와 설정 UI에서 쓰는 조회·리맵 API를 제공한다. 현재 대상은 PC 키보드와 마우스이며, 기본값은 WASD 이동, 좌클릭 공격, E 상호작용, I 인벤토리, F 자동 타겟, G 자동 공격, Space 대시, Esc 일시정지, Tab 전투 세트 전환이다. 런 진입점은 `ActionManager.initialize()`를 한 번 호출해 기본 바인딩과 `user://input_bindings.cfg`의 사용자 바인딩을 적용한다. 일시정지 설정의 `InputBindingSettingsUi`는 직접 `InputMap`을 만지지 않고 `ActionManager` API로 바인딩을 표시·변경한다.

## Responsibilities & Boundaries

In Scope:

- 액션 이름, 기본 바인딩, UI 표시용 라벨/카테고리 키 정의
- `InputMap` 초기화, 입력 조회, 이벤트 기반 입력 판정
- 사용자 바인딩 저장/로드, 기본값 복원, 충돌 검사
- 일시정지 설정의 키/마우스 리맵 UI와 입력 대기 상태
- 플레이어 이동·전투·상호작용·메뉴 입력의 단일 진입점 제공

Out of Scope:

- 패드 입력과 조준 스틱 처리
- 키별 접근성 정책, 튜토리얼, 플레이어-facing 설명 문구 전체 관리
- 무기 발사·인벤토리·일시정지의 게임 규칙 자체

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `game/input/action_binding_defaults.gd` | 액션 목록, 기본 이벤트, UI 라벨/카테고리 키 정의 |
| `game/input/action_binding_store.gd` | `user://input_bindings.cfg` 저장/로드, `InputEvent` 직렬화 |
| `game/input/action_manager.gd` | 초기화, 조회, 리맵, 기본값 복원, 충돌 검사 API |
| `ui/settings/input_binding_settings_ui.gd` | 설정 화면의 액션 목록 생성, 입력 캡처, 충돌 표시, 리셋 버튼 |
| `ui/settings/ui_locale.gd` | 액션/카테고리/상태 문구와 HUD·인벤토리 힌트 템플릿 |
| `entities/player/player.gd` | 이동 벡터, 대시, 자동 타겟/공격 토글을 `ActionManager`로 조회 |
| `weapons/core/gun.gd` | 수동 공격을 `ActionManager.ACTION_ATTACK`으로 조회 |
| `game/interaction/interaction_input.gd` | 상호작용 입력과 표시 라벨을 `ActionManager`로 위임 |
| `inventory/inventory_game_bridge.gd` | 인벤토리 열기와 전투 세트 전환 입력 처리 |
| `ui/pause_menu.gd`, `ui/inventory/inventory_menu.gd` | 메뉴 닫기/일시정지 입력을 액션 기준으로 처리 |

관계:

`ActionBindingDefaults` → `ActionManager.initialize()` → `ActionBindingStore.load_bindings()` → `InputMap`

게임플레이 코드는 `InputMap` 대신 `ActionManager`를 호출한다.

## Flow

### Runtime

1. 로비, 메인 게임, 테스트 아레나 `_ready()`에서 `ActionManager.initialize()`를 호출한다.
2. `ActionManager`가 액션을 보장하고 기본 바인딩을 적용한다.
3. 저장된 사용자 바인딩이 있으면 기본 바인딩 위에 덮어쓴다.
4. 플레이어·무기·상호작용·메뉴 코드는 `ActionManager.get_move_vector()`, `is_pressed()`, `is_just_pressed()`, `event_is_pressed()`로 입력을 읽는다.
5. 리맵 API가 호출되면 `InputMap`을 갱신하고 현재 바인딩을 `ActionBindingStore.save_bindings()`로 저장한다.

### Settings UI

1. `pause_menu_overlay.tscn`의 `InputBindingSettingsUi`가 `ActionManager.get_action_definitions()`로 액션 목록과 로케일 키를 읽어 행을 만든다.
2. 사용자가 바인딩 버튼을 누르면 `_input(event)`가 다음 키/마우스 버튼 이벤트를 캡처한다.
3. 마우스 휠과 빈 이벤트는 무시하고, 저장에 필요한 필드만 복사한 `InputEventKey` / `InputEventMouseButton`을 만든다.
4. `ActionManager.find_conflicts()` 결과가 있으면 덮어쓰지 않고 상태 라벨에 충돌 액션명을 표시한다.
5. 충돌이 없으면 `ActionManager.rebind_action()`이 `InputMap`과 `user://input_bindings.cfg`를 갱신한다.
6. 기본값 복원은 `reset_action_to_default()` 또는 `reset_all_to_default()`를 호출하고, `UiLocale.notify_refresh()`로 HUD·인벤토리 힌트를 갱신한다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 입력 조회 함수는 기본 바인딩을 다시 붙이지 않는다. | 사용자가 제거한 기본 키가 런타임 조회 중 되살아나면 리맵 UI가 깨진다. |
| `initialize()`는 기본값 적용 후 저장된 사용자 바인딩을 덮어쓴다. | 새 액션 기본값은 유지하면서 사용자의 기존 설정을 우선하기 위함이다. |
| UI와 게임플레이 코드는 `InputMap`을 직접 수정하지 않는다. | 저장/충돌/라벨 정책이 흩어지는 것을 막는다. |
| 입력 캡처는 `input_binding_settings_ui.gd`만 담당한다. | 게임플레이 토글 UI와 리맵 상태가 섞이면 Esc 처리와 상태 라벨 갱신이 꼬인다. |
| 충돌 검사는 modifier를 무시해 같은 물리 키·마우스 버튼을 충돌로 본다. | Godot 액션 매칭에서 `Shift+A`가 `A` 액션과 겹칠 수 있다. |
| 마우스 휠은 리맵 캡처에서 제외한다. | 설정 목록 스크롤이 의도치 않은 바인딩으로 저장되는 것을 막는다. |
| `swap_combat_set` 기본 키는 `Tab`이다. | WASD 이동, 특히 `W`와 충돌하지 않게 하기 위함이다. |
| HUD·인벤토리 힌트는 `get_action_label()`로 현재 바인딩을 표시한다. | 리맵 후에도 플레이어-facing 안내가 기본 키에 고정되지 않게 한다. |
| 전역 입력 차단은 각 기능의 기존 차단 조건을 유지한다. | 무기 선택, 인벤토리, 일시정지, 게임오버 중 입력이 새 경로로 새지 않게 한다. |

## Change Guidelines

| 변경 | 같이 확인할 것 |
|------|---------------|
| 새 액션 추가 | `ActionBindingDefaults`, `project.godot`, `UiLocale`의 `input.*` 키, 관련 입력 호출부 |
| 기본 키 변경 | `project.godot`, `ActionBindingDefaults`, HUD/힌트 문구, `Docs/Wiki/GameRules.md` |
| 리맵 저장 형식 변경 | 기존 `user://input_bindings.cfg` 호환성 또는 마이그레이션 |
| 조작 설정 UI 변경 | `input_binding_settings_ui.gd`, `pause_menu_overlay.tscn`, `pause_menu.gd`, `find_conflicts()` 정책, 기본값 복원, 입력 대기 중 Esc/마우스 처리 |
| 인벤토리/메뉴 입력 변경 | `InventoryGameBridge`, `ui/inventory/inventory_menu.gd`, `ui/pause_menu.gd` |

최소 검증은 F5 로비→서바이벌, F5 아레나, F6 테스트 아레나에서 WASD 이동, 좌클릭 공격, E 상호작용, I 인벤토리, F/G 토글, Esc 일시정지, Tab 전투 세트 전환을 확인하는 것이다.
