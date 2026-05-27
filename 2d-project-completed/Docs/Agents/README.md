# Agents Docs

**역할:** `AGENTS.md`에서 길어지는 도메인별 작업 지도를 분리해 보관합니다.

이 폴더의 문서는 AI와 개발자가 작업을 시작할 때 빠르게 보는 운영 가이드입니다. 기능의 전체 설계나 플레이어 규칙을 길게 설명하지 않고, 어디를 먼저 읽고 어떤 제약을 지켜야 하는지에 집중합니다.

## 문서 목록

| 문서 | 역할 |
|------|------|
| [`CoreConstraints.md`](CoreConstraints.md) | 프로젝트 전역 핵심 제약 |
| [`AGENTS_MapArena.md`](AGENTS_MapArena.md) | 맵·스폰·소나무 작업 가이드 |
| [`AGENTS_Display_UI.md`](AGENTS_Display_UI.md) | 디스플레이·카메라·UI 스케일 작업 가이드 |

## 작업별 진입점

| 작업 | 먼저 볼 파일 |
|------|--------------|
| 맵 크기·스폰·소나무 | `AGENTS_MapArena.md`, `world/map_arena/map_arena.gd`, `survivors_game.tscn`, `test_arena.tscn` |
| UI 스케일·카메라 | `AGENTS_Display_UI.md`, `ui/ui_viewport_layout.gd`, `ui/ui_resolution_config.gd`, `entities/player/player.tscn` |
| 입력·조작 설정 | `Docs/Architecture/Architecture_Input.md`, `game/input/*`, `ui/settings/input_binding_settings_ui.gd`, `ui/pause_menu_overlay.tscn` |
| 런 루프·스폰·클리어 | `Docs/Architecture/Architecture_GameLoop_Balance.md`, `game/game.gd`, `game/balance/*` |
| 아레나 웨이브 | `game/arena/arena_wave_director.gd`, `game/game.gd`, `Docs/Wiki/GameRules.md` |
| 버프·조건부 스탯 효과 | `Docs/Architecture/Architecture_Buffs.md`, `buff/*`, `entities/player/player.gd`, `game/game.gd` |
| 공격 시스템·독립체 설계 | `Docs/Architecture/Architecture_AttackSystem.md`, `Architecture_Weapons.md`, `Architecture_Projectiles.md` |
| 무기 추가·수정 | `Docs/Architecture/Architecture_Weapons.md`, `Docs/Architecture/Architecture_Projectiles.md`, `weapons/data/weapon_data.gd`, `weapons/catalogs/*`, `weapons/core/gun.gd` |
| 몹 추가·수정 | `Docs/Architecture/Architecture_Mobs.md`, `entities/mob/mob.gd`, `game/balance/mob_spawn_selector.gd`, `game/pool/scene_pool.gd` |
| 인벤토리·장비 | `Docs/Architecture/Architecture_Inventory.md`, `inventory/*.gd`, `ui/inventory/*` |
| 무기 획득 UI | `ui/weapon_select_menu.gd`, `survivors_game.tscn`, `Docs/Architecture/Architecture_Weapons.md` |
| 일시정지·설정 | `ui/pause_menu.gd`, `ui/settings/*`, `AGENTS_Display_UI.md` |
| 픽업·보상 | `game/balance/kill_rewards.gd`, `effects/exp_orb/*`, `effects/gold_coin/*`, `entities/mob/mob.gd` |
| 후속 작업 확인 | `BACKLOG.md`, `Docs/Plan/README.md` |

## 포함할 문서

- `AGENTS_Display_UI.md`처럼 작업 진입점, 경로, must / must not이 중요한 문서.
- 루트 `AGENTS.md`에 두기에는 길지만, 아키텍처 문서로 분리하기에는 실행 가이드 성격이 강한 문서.
- 특정 기능을 수정할 때 먼저 볼 파일, 관련 규칙, 확인 시나리오를 짧게 모은 문서.

## 포함하지 않을 문서

- 기능의 타입 구조와 런타임 흐름 전체: `Docs/Architecture/`
- 플레이어에게 드러나는 게임 규칙과 기획 의도: `Docs/Wiki/`
- 일정, 마일스톤, Epic 계획: `Docs/Plan/`
- 아직 하지 않은 작업 목록: `BACKLOG.md`
