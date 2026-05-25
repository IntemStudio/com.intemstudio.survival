# Architecture — Game Loop & Balance (런 루프·밸런스)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이 규칙: [`Wiki/GameRules.md`](../Wiki/GameRules.md), [`Wiki/Mobs.md`](../Wiki/Mobs.md), [`Wiki/Progression.md`](../Wiki/Progression.md) · 계획 기록: [`Plan/Plan_Balance_VS_Curve_Alignment.md`](../Plan/Plan_Balance_VS_Curve_Alignment.md)

메인 서바이버 런의 시작, 진행, 스폰, 밸런스 곡선, 타임라인 이벤트, 보상, 종료 흐름을 정리한다. 출시 일정과 플레이테스트 TODO는 `Docs/Plan/`과 `BACKLOG.md`에서 관리한다.

## Overview

F5 실행은 `game_lobby.tscn`에서 시작하고, 게임 시작 버튼이 `survivors_game.tscn`으로 전환한다. 실제 한 판의 오케스트레이션은 루트 `Game` 노드와 `game/game.gd`가 담당한다. 런은 시작 무기 선택으로 일시정지된 상태에서 시작하며, 첫 무기 선택 후 스폰 타이머와 밸런스 시계가 움직인다.

밸런스는 두 층으로 나뉜다. `BalanceTable`은 경과 시간을 표 축 분으로 변환하고 `BalancePhase` 키프레임을 보간해 HP, 보상, 스폰 밀도, 스폰 비율을 제공한다. `BalanceTimeline`은 9분, 11분, 25분 같은 특정 표 축 시각에 한 번씩 발동하는 밀도 이벤트와 강제 스폰을 담당한다. 표 축 30분에 도달하면 스테이지 클리어로 런이 종료된다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 런 시작 | 로비 이후 `survivors_game.tscn`, 시작 무기 선택, 첫 선택 후 스폰 타이머 시작 |
| 밸런스 시계 | pause 상태가 아닐 때 `_elapsed_seconds` 증가, 표 축 분 계산 |
| 스폰 밀도 | 현재 `BalancePhase.spawn_density`와 일시 density event를 합쳐 Timer 간격 조정 |
| 스폰 구성 | `MobSpawnSelector`가 현재 phase의 비율로 몹 프리팹 선택 |
| 몹 생성 | `%MapArena`에서 위치를 받고 `ScenePool`로 몹 acquire, `initialize_spawn_health()` 호출 |
| 타임라인 이벤트 | 표 축 분 기준 1회 발동, 배너, 밀도 배수, 강제 스폰 처리 |
| 보상 계산 | `KillRewards`가 `mob_kind`와 `loot_multiplier`로 XP·골드 계산 |
| 런 종료 | 플레이어 사망 또는 30분 클리어 시 스폰 중단, 게임오버 패널 표시, pause |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 보스·특수몹 고유 AI | 스폰 시각과 비율만 이 문서 범위이며 패턴은 `Architecture_Mobs.md`에서 다룬다. |
| 무기 성장 기획 | 레벨업 선택 UI 연결만 포함하고 성장 정책은 Wiki/Backlog에서 관리한다. |
| 출시 마일스톤 | `Plan_Release_Roadmap.md`에서 관리한다. |
| 맵 크기·소나무 튜닝 | `Docs/Agents/AGENTS_MapArena.md`가 작업 가이드를 가진다. |
| F5 인벤 loadout 전면 통합 | `Architecture_Inventory.md`와 별도 정책 결정 대상이다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `ui/lobby/game_lobby.gd` | F5 시작 화면, 설정 apply, `survivors_game.tscn` 전환 |
| `game/game.gd` | 런 상태, 무기 선택, 스폰 타이머, 밸런스 tick, 종료 UI 오케스트레이션 |
| `game/balance/balance_table.gd` | 경과 시간 → 표 축 분, `BalancePhase` 보간, spawn ratio 정규화 |
| `game/balance/balance_phase.gd` | HP·보상·밀도·몹 구성 키프레임 데이터 |
| `game/balance/balance_timeline.gd` | 표 축 분 기준 1회 이벤트 목록 |
| `game/balance/balance_timeline_event.gd` | 배너, density 배수, duration, 강제 스폰 데이터 |
| `game/balance/mob_spawn_selector.gd` | phase 비율로 basic/fast/ranged/elite/special/boss 프리팹 선택 |
| `game/balance/kill_rewards.gd` | `mob_kind` 기본 XP와 phase loot 배율로 XP·골드 계산 |
| `world/map_arena/map_arena.gd` | 플레이어 주변 금지 반경과 벽 내부 조건을 만족하는 스폰 위치 제공 |
| `game/pool/scene_pool.gd` | 몹과 발사체 등 반복 생성 노드 acquire/release |
| `entities/mob/mob.gd` | 스폰 HP 초기화, 사망 시 보상 요청, 클리어 사망 처리 |
| `ui/weapon_select_menu.gd` | 시작/레벨업 무기 선택으로 런 진행을 일시정지 |
| `game/weapon_damage_tracker.gd` | 런 종료 표시용 weapon 피해 누적 |

관계는 아래처럼 유지한다.

```text
GameLobby
  -> survivors_game.tscn / Game
  -> WeaponSelectMenu
  -> Player.add_weapon()
  -> Timer.timeout
  -> Game.spawn_mob()
  -> BalanceTable + BalanceTimeline + MobSpawnSelector
  -> MapArena + ScenePool + Mob.initialize_spawn_health()
  -> Mob death -> KillRewards -> pickups/gold
  -> GameOver / Clear UI
```

## Flow

### Runtime

1. F5는 `game_lobby.tscn`을 열고, 로비에서 언어·디스플레이·오디오 설정을 적용한다.
2. 게임 시작 시 `survivors_game.tscn`으로 전환되고 `Game._ready()`가 기본 balance table/timeline을 보장한다.
3. 시작 무기 선택 UI가 열리며 트리는 pause된다. 후보가 없으면 즉시 런을 시작한다.
4. 무기 선택이 완료되면 `Player.add_weapon()`이 deferred로 호출되고 `_ensure_game_started()`가 스폰 타이머를 시작한다.
5. pause가 아니고 런이 시작된 동안 `_elapsed_seconds`가 증가한다.
6. 매 프레임 `BalanceTable.get_phase_for_time()`로 현재 phase를 얻고, `spawn_density` 변화가 있으면 Timer wait time을 조정한다.
7. `BalanceTimeline` 이벤트가 표 축 시각에 도달하면 한 번만 발동한다. 배너를 띄우고, density event를 적용하거나 강제 몹을 스폰한다.
8. Timer timeout은 `spawn_mob()`을 호출한다. 살아 있는 몹 상한을 넘으면 스킵한다.
9. `spawn_mob()`은 현재 phase로 몹 종류를 고르고, `%MapArena.get_random_spawn_position(%Player.global_position)`로 위치를 받은 뒤 `ScenePool`에서 몹을 가져온다.
10. 몹 사망은 일반 사망이면 `Game.register_kill()`과 `KillRewards.compute()`를 통해 XP·골드·픽업을 만든다.
11. 플레이어 HP가 0이면 `_run_failed`가 되고 스폰 타이머를 멈춘 뒤 게임오버 UI를 보여 준다.
12. 표 축 30분에 도달하면 `_run_cleared`가 되고 모든 활성 몹에 `die_from_stage_clear()`를 호출한다. 이 사망은 드랍과 처치 수 증가를 만들지 않는다.

### Editor / Data

1. 곡선 조정은 `default_balance_table.tres`의 `BalancePhase` 키프레임을 수정한다.
2. 순간 이벤트 조정은 `default_balance_timeline.tres`의 `BalanceTimelineEvent`를 수정한다.
3. 새 몹 프리팹을 메인 스폰에 넣을 때는 `MobSpawnSelector`, `ScenePool`, `BalancePhase` 비율을 함께 확인한다.
4. `balance_pace_multiplier`는 표 축 진행 속도를 바꾸므로 30분 클리어 실시간도 같이 압축된다.
5. 보상 배율은 `hp_multiplier`와 별도인 `loot_multiplier`로 관리한다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 밸런스 시계는 `_game_started`이고 tree가 pause가 아닐 때만 증가한다. | 무기 선택, 일시정지, 게임오버 중 시간이 흐르지 않아야 한다. |
| 스폰 Timer는 `spawn_density`의 역수로 wait time을 조정한다. | 밀도 상승이 즉시 스폰 빈도 증가로 이어진다. |
| `BalanceTable`의 시간 축은 실시간 초가 아니라 `balance_pace_multiplier`가 적용된 표 축 분이다. | 압축 런에서도 이벤트와 30분 클리어가 같은 곡선 위치에 맞아야 한다. |
| `BalanceTimelineEvent`는 event id 또는 위치 key로 한 번만 발동한다. | 11분/25분 이벤트가 프레임마다 반복되지 않게 한다. |
| 강제 스폰은 alive cap을 무시할 수 있지만 일반 스폰은 `max_alive_mobs`를 지킨다. | 보스/엘리트 이벤트와 성능 상한의 역할을 분리한다. |
| 몹 스폰 위치는 `MapArena`를 통해 얻는다. | 벽 밖 스폰과 플레이어 바로 옆 스폰을 피한다. |
| 클리어 사망은 드랍·처치 집계가 없어야 한다. | 30분 클리어가 대량 보상으로 변질되지 않게 한다. |
| 테스트 아레나는 메인 런 클리어/밸런스 루프를 그대로 쓰지 않는다. | F6는 빠른 무기·몹 검증 용도다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 곡선 키프레임 변경 | 0~30분 체감, `spawn_density`, `hp_multiplier`, `loot_multiplier`, HUD phase 표시 |
| 타임라인 이벤트 추가 | `event_id` 고유성, pause 중 시간 정지, forced spawn cap 정책, 배너 문구 |
| 새 몹 타입 추가 | `MobSpawnSelector`, `ScenePool`, `BalancePhase` 비율, `KillRewards`, Wiki/Mobs |
| 보상 공식 변경 | XP 오브, 골드 코인, 클리어 사망 드랍 없음, 더미 보상 0 유지 |
| 클리어 조건 변경 | `_run_cleared`, Timer stop, 몹 정리, 게임오버 UI 제목, 입력 차단 |
| pause/menu 변경 | 무기 선택, 일시정지, 인벤토리, 게임오버가 서로 pause 상태를 덮어쓰지 않는지 |
| 압축 런 변경 | `balance_pace_multiplier`, 30분 표 축 클리어, 이벤트 시각, QA 체크리스트 |

최소 검증은 F5에서 로비→시작 무기 선택→스폰 시작→레벨업 선택→일시정지→패배 또는 클리어까지 진행하고, 9·11·25·28분 이벤트가 표 축 기준으로 한 번씩만 발동하는지 확인하는 것이다.
