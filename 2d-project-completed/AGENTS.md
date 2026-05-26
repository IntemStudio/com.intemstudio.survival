# AGENTS — Godot 2D Survival

**역할:** 이 문서는 작업을 시작할 때 보는 프로젝트 지도입니다. 상세 설계는 `Docs/Architecture/`, 작업 가이드는 `Docs/Agents/`, 플레이어 규칙은 `Docs/Wiki/`, 계획은 `Docs/Plan/`, 남은 일은 `BACKLOG.md`를 우선합니다.

## 먼저 볼 문서

| 목적 | 문서 |
|------|------|
| 문서 역할 구분 | [`Docs/README.md`](Docs/README.md) |
| 맵 경계·스폰·소나무 작업 | [`Docs/Agents/AGENTS_MapArena.md`](Docs/Agents/AGENTS_MapArena.md) |
| 디스플레이·카메라·UI 스케일 작업 | [`Docs/Agents/AGENTS_Display_UI.md`](Docs/Agents/AGENTS_Display_UI.md) |
| 입력·조작 설정 구조 | [`Docs/Architecture/Architecture_Input.md`](Docs/Architecture/Architecture_Input.md) |
| 인벤토리·장비 구조 | [`Docs/Architecture/Architecture_Inventory.md`](Docs/Architecture/Architecture_Inventory.md) |
| 무기 구조 | [`Docs/Architecture/Architecture_Weapons.md`](Docs/Architecture/Architecture_Weapons.md) |
| 런 루프·밸런스 구조 | [`Docs/Architecture/Architecture_GameLoop_Balance.md`](Docs/Architecture/Architecture_GameLoop_Balance.md) |
| 몹 구조 | [`Docs/Architecture/Architecture_Mobs.md`](Docs/Architecture/Architecture_Mobs.md) |
| 플레이어-facing 규칙 | [`Docs/Wiki/README.md`](Docs/Wiki/README.md) |
| 출시·주차 계획 | [`Docs/Plan/README.md`](Docs/Plan/README.md) |
| 후속 작업 | [`BACKLOG.md`](BACKLOG.md) |

## 문서·언어 정책

| 대상 | 언어 | 역할 |
|------|------|------|
| `.cursor/rules/*.mdc` | 영어 | 에이전트 실행 규칙. 가장 우선합니다. |
| `AGENTS.md` | 한국어 + 경로·타입명 영어 | 프로젝트 지도와 상세 문서 링크 |
| `Docs/Agents/*.md` | 한국어 | 도메인별 작업 가이드, must / must not |
| `Docs/Architecture/*.md` | 한국어 | 기능 단위 코드 구조, 흐름, 불변조건 |
| `Docs/Wiki/*.md` | 한국어 | 플레이어에게 드러나는 게임 규칙과 기획 |
| `Docs/Plan/**/*.md` | 한국어 | 로드맵, Epic, 주차 실행 계획 |
| `BACKLOG.md` | 한국어 | 미구현·후속 작업 |
| 코드 주석 (`.gd`) | 한국어 | 비즈니스/게임 로직 목적 한 줄 |

제약이 겹치면 `.mdc`가 우선입니다. 이 문서는 상세 규칙을 반복하지 않고 위치를 안내합니다.

## 프로젝트 개요

Godot 4.6 기반 2D 뱀파이어 서바이버류 프로젝트입니다. 한 판은 로비에서 서바이벌 또는 아레나를 선택해 시작하고, 무기 획득, 몹 스폰, 경험치 수집, 레벨업 보상, 패배 또는 클리어로 끝납니다.

- F5 메인 진입: `game_lobby.tscn` → `survivors_game.tscn`
- 로비 모드: `RunConfig`로 `survival` / `arena` 전달
- F6 테스트: `test_arena.tscn`
- 메인 오케스트레이션: `game/game.gd`
- Autoload 없음. 다수 스크립트가 `/root/Game` 계약을 사용합니다.
- 창 기준: HD 1280×720, UI 좌표 기준: FHD 1920×1080
- 카메라: `entities/player/player.tscn`의 `Camera2D.zoom = Vector2(0.5, 0.5)`

## 런타임 흐름

1. F5 로비에서 설정을 적용하고, 서바이벌 시작 또는 아레나 시작 시 `RunConfig`를 설정한 뒤 `survivors_game.tscn`으로 이동합니다.
2. `Game._ready()`가 모드를 읽고, 서바이벌이면 balance table/timeline을 준비하며, 아레나면 `ArenaWaveDirector`를 준비합니다.
3. 시작 무기 획득 UI가 열리고, 획득한 무기는 런 인벤토리의 빈 `weapon` 슬롯에 자동 배치됩니다.
4. 서바이벌은 스폰 Timer가 `Game.spawn_mob()`을 반복 호출하고, `_process()`가 밸런스 시계·타임라인·30분 클리어를 처리합니다.
5. 아레나는 `ArenaWaveDirector`가 1~10웨이브 큐를 만들고, Timer가 큐의 몹을 `Game.spawn_mob()`으로 스폰합니다.
6. Timer 스폰은 `%MapArena` 위치 + `ScenePool`로 몹을 생성합니다.
7. 몹 사망은 `KillRewards`로 XP·골드를 계산하고 픽업을 생성합니다.
8. 레벨업은 무기 획득 UI를 열고, 사망/클리어는 게임오버 패널과 무기별 피해 목록을 표시합니다.

상세: [`Architecture_GameLoop_Balance.md`](Docs/Architecture/Architecture_GameLoop_Balance.md)

## 폴더 지도

| 경로 | 역할 |
|------|------|
| `game_lobby.tscn` | F5 시작 화면 |
| `survivors_game.tscn` | 메인 플레이 씬 |
| `test_arena.tscn` | F6 무기·몹 테스트 씬 |
| `game/game.gd` | 메인 런 오케스트레이션, 서바이벌/아레나 모드 분기 |
| `game/run_config.gd` | 로비 선택 모드 전달 |
| `game/arena/` | 아레나 웨이브 디렉터 |
| `game/balance/` | 밸런스 표, 타임라인, 스폰 선택, 보상 |
| `game/input/` | 액션 이름, 기본 바인딩, 리맵 저장/로드 |
| `game/pool/` | `ScenePool`, `PoolUtil` |
| `entities/player/` | 이동, 대시, 경험치, 무기 컨테이너, 피격 |
| `entities/mob/` | 공통 `Mob`, 변종, 원거리 투사체, 공격 예고 |
| `weapons/` | `WeaponData`, 카탈로그, `Gun`, 발사체·장판·궤도 |
| `inventory/` | 장비 loadout, 세이브, registry, 전투 bridge |
| `ui/` | 로비 외 UI, 일시정지, 무기 획득, 설정, 인벤토리 |
| `effects/` | 경험치, 골드, 자석, 체력, hit flash, 플로팅 데미지 |
| `world/map_arena/` | 맵 경계, 내부 스폰 좌표 |
| `world/trees/` | Poisson 소나무 배치 |
| `Docs/` | 문서 |

## 작업별 진입점

| 작업 | 먼저 볼 파일 |
|------|--------------|
| 맵 크기·스폰·소나무 | `Docs/Agents/AGENTS_MapArena.md`, `world/map_arena/map_arena.gd`, `survivors_game.tscn`, `test_arena.tscn` |
| UI 스케일·카메라 | `Docs/Agents/AGENTS_Display_UI.md`, `ui/ui_viewport_layout.gd`, `ui/ui_resolution_config.gd`, `entities/player/player.tscn` |
| 입력·조작 설정 | `Docs/Architecture/Architecture_Input.md`, `game/input/*`, `ui/settings/input_binding_settings_ui.gd`, `ui/pause_menu_overlay.tscn` |
| 런 루프·스폰·클리어 | `Docs/Architecture/Architecture_GameLoop_Balance.md`, `game/game.gd`, `game/balance/*` |
| 아레나 웨이브 | `game/arena/arena_wave_director.gd`, `game/game.gd`, `Docs/Wiki/GameRules.md` |
| 무기 추가·수정 | `Docs/Architecture/Architecture_Weapons.md`, `weapons/data/weapon_data.gd`, `weapons/catalogs/*`, `weapons/core/gun.gd` |
| 몹 추가·수정 | `Docs/Architecture/Architecture_Mobs.md`, `entities/mob/mob.gd`, `game/balance/mob_spawn_selector.gd`, `game/pool/scene_pool.gd` |
| 인벤토리·장비 | `Docs/Architecture/Architecture_Inventory.md`, `inventory/*.gd`, `ui/inventory/*` |
| 무기 획득 UI | `ui/weapon_select_menu.gd`, `survivors_game.tscn`, `Docs/Architecture/Architecture_Weapons.md` |
| 일시정지·설정 | `ui/pause_menu.gd`, `ui/settings/*`, `Docs/Agents/AGENTS_Display_UI.md` |
| 픽업·보상 | `game/balance/kill_rewards.gd`, `effects/exp_orb/*`, `effects/gold_coin/*`, `entities/mob/mob.gd` |
| 후속 작업 확인 | `BACKLOG.md`, `Docs/Plan/README.md` |

## 핵심 제약

- Unity `.meta` 파일이 아니라 Godot 프로젝트입니다. Godot 리소스/씬의 참조를 깨지 않도록 씬·리소스 경로를 보존합니다.
- `.cursor/rules/*.mdc`의 must / must not이 이 문서보다 우선합니다.
- F5 메인과 F6 테스트 아레나는 목적이 다릅니다. 테스트 편의를 위해 F6 `test_arena.tscn`을 아레나 모드와 섞지 않습니다.
- 서바이벌 모드는 시간 밸런스, 아레나 모드는 웨이브 번호가 난이도 축입니다. 아레나 변경 시 30분 클리어·타임라인 이벤트가 다시 켜지지 않게 확인합니다.
- `/root/Game` 계약을 쓰는 스크립트가 많습니다. 씬 루트 이름과 자식 노드 계약을 바꾸면 관련 경로를 함께 점검합니다.
- UI는 FHD 좌표를 기준으로 만들고 `UiViewportLayout`이 스케일합니다. HD 픽셀에 맞춰 이중 축소하지 않습니다.
- 메인 맵 크기 변경은 `survivors_game.tscn`의 `%MapArena` 인스턴스 오버라이드를 확인합니다. `map_arena.gd` 기본값만 바꾸면 F6 기준만 바뀔 수 있습니다.
- 무기 피해는 `Mob.apply_weapon_damage(amount, weapon)` 경로를 우선 사용해 `WeaponDamageTracker` 귀속을 유지합니다.
- 몹 일반 사망과 클리어 사망을 섞지 않습니다. 서바이벌 30분 클리어와 아레나 10웨이브 클리어 모두 클리어 사망은 드랍·처치 집계를 만들지 않습니다.
- 인벤토리는 데모 기준 런 한정 장비 빌드 시스템입니다. 가방·장비 세트·상자 보상·골드는 클리어, 패배, 로비 복귀, 새 런 시작 시 영구 저장하지 않고 초기화합니다.
- 장비 획득은 먼저 런 인벤토리에 넣고 빈 장착 슬롯이 있으면 자동 장착합니다. weapon/offhand는 활성 세트 빈 슬롯 → 비활성 세트 빈 슬롯 → 가방 순서이고, offhand는 같은 세트 weapon이 양손이 아닐 때만 장착할 수 있습니다(`offhand 1`은 `weapon 1`, `offhand 2`는 `weapon 2`). 공유 방어구는 대상 슬롯이 비어 있으면 바로 장착합니다. weapon 전투 적용은 활성 세트 weapon만 `Player.add_weapon()` 경로로 처리합니다.
- 모든 장비 효과는 장착된 슬롯에서만 적용합니다. 가방 장비와 비활성 세트 weapon/offhand는 스탯, 패시브, 비주얼, 공격 효과를 만들지 않습니다.
- 풀링 대상은 `pool_reset()` / `pool_on_acquire()` / `PoolUtil.release_node()` 계약을 지킵니다.

## 품질 게이트

작업 후 관련 범위에 맞춰 최소한 아래를 확인합니다.

- Godot 프로젝트 열기/실행 시 파싱 에러 없음.
- F5 서바이벌: 로비 → 서바이벌 시작 → 시작 무기 획득 → 자동 장착 → 스폰 → 레벨업 → 패배 또는 30분 클리어 흐름 확인.
- F5 아레나: 로비 → 아레나 시작 → 1웨이브 → 5/10 보스 웨이브 → 10웨이브 클리어 흐름 확인.
- F6: 테스트 아레나에서 몹 Spawn, 무기 Equip, 플레이어 리스폰 확인.
- UI 변경: 1280×720 기준 HUD·메뉴·게임오버·무기 획득 레이아웃 확인.
- 무기/몹 변경: 피해 통계, 풀 반환, 자동 공격 on/off, 원거리 예고/투사체 확인.
- 인벤 변경: 상자 구매, 장착·해제·세트 전환, 가방 장비 효과 미적용, 양손/offhand, 런 종료 후 장비·골드 초기화 확인.
