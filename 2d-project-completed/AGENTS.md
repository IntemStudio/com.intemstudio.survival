# AGENTS — Godot 2D Survival

## 문서·언어 정책

| 대상 | 언어 | 역할 |
|------|------|------|
| `.cursor/rules/*.mdc` | **영어** (짧은 must/must not) | 에이전트 **실행 규칙** — authoritative |
| `AGENTS.md` (이 파일) | **한국어** + 경로·타입명 영어 | **지도·흐름·이유** (사람용) |
| 코드 주석 (`.gd`) | **한국어** 한 줄 목적 | 비즈니스 맥락; must 문장은 `.mdc`에만 |

제약이 겹치면 **`.mdc`가 우선**입니다. 이 파일은 규칙을 한글로 요약만 하고, 상세 must는 각 `.mdc`를 따릅니다.

---

## 프로젝트 개요

Godot 4.6 기반 **2D 뱀파이어 서바이버류** (GDQuest 튜토리얼 + 확장). 한 판에서 이동·접촉 피해·레벨업·무기 선택·시간에 따른 몹 웨이브 생존을 처리합니다.

- **실행 씬:** `survivors_game.tscn` (`project.godot` → `run/main_scene`)
- **오케스트레이션:** 루트 노드 `Game` + `game/game.gd`
- **Autoload 없음** — 다수 스크립트가 `/root/Game` 경로를 하드코딩

---

## 폴더 지도

| 경로 | 역할 |
|------|------|
| `survivors_game.tscn` | 메인 씬: `Game`, `Timer`, `Player`+스폰 경로, HUD, 일시정지, 무기 UI |
| `game/game.gd` | 스폰 타이머, 밸런스 시계, 처치 HUD, 일시정지/게임오버, 무기 선택 |
| `game/balance/` | `BalanceTable`, phase, `MobSpawnSelector`, `default_balance_table.tres` |
| `entities/player/` | 이동, 경험치, 무기 컨테이너, 피격 |
| `entities/mob/` | 공용 `mob.gd` + 변종 `.tscn` |
| `weapons/` | `WeaponData`, catalog, `gun`, 투사체·근접·마법 등 |
| `ui/` | 무기 선택(3택1 + 설명 패널), 일시정지 |
| `effects/` | 경험치 구슬, 데미지 텍스트, 사망 이펙트 |
| `characters/` | Slime / HappyBoo 비주얼 |

---

## 런타임 흐름 (요약)

1. `_ready`: `BalanceTable` 로드 → 시작 무기 선택(버튼 호버 시 `%WeaponSelectMenu` 설명 패널) → 트리 `paused`
2. `on_weapon_chosen` → `Player.add_weapon` → `_ensure_game_started` → 스폰 `Timer` 시작
3. 타이머마다: `%PathFollow2D` 위치에 `spawn_mob`, 경과 시간으로 phase, `initialize_spawn_health`로 HP
4. `leveled_up` → 무기 선택 대기열; 메뉴가 열려 있으면 스폰 시계 정지. 선택 UI는 `WeaponSelectMenu.present_random_choices` → 버튼 라벨 + `WeaponData.build_select_tooltip_bbcode()` 상세
5. `health_depleted` → 게임오버 UI, `paused`

---

## 밸런스 모델 (왜 이렇게 동작하는지)

- phase는 **분(minute)** 키프레임; `BalanceTable`이 키 사이 float를 **선형 보간**
- `boss_spawn_enabled`, `special_mob_count`는 보간 후 **계단(step)** 적용
- 스폰 비율 합이 1 초과 시 **정규화** 가능
- 몹 **행동**은 동일; 변종은 프리팹 수치 + `MobSpawnSelector` 가중치만 다름

밸런스 전용 규칙 파일(`godot-balance.mdc`)은 `game/balance/**` 작업이 잦아질 때 추가.

---

## 자주 쓰는 Godot 패턴

- 메인 씬 스크립트에서 `%UniqueNode` 참조
- 기본 리소스·VFX: `preload("res://...")`
- 살아 있는 몹: `get_tree().get_nodes_in_group("mobs")`
- 무기 추가·몹 사망: `call_deferred`
- 무기 데이터: `WeaponData` Resource + catalog 풀 → 랜덤 3택1; 설명 문자열은 `build_select_tooltip_bbcode()` (표시는 `ui/weapon_select_menu.gd` + `survivors_game.tscn` `ContentHBox/DetailPanel`)

---

## 작업별로 먼저 볼 파일

| 작업 | 파일 |
|------|------|
| 스폰·시간·UI | `game/game.gd`, `survivors_game.tscn` |
| 난이도 곡선 | `default_balance_table.tres`, `balance_table.gd` |
| 몹 타입 추가 | `mob.gd`, `mob_spawn_selector.gd`, `mob_*.tscn`, balance `.tres` |
| 무기 추가 | `weapon_data.gd`, `weapons/catalogs/*`, `gun.gd`, `player.gd`, `ui/weapon_select_menu.gd` |
| 무기 선택·설명 UI | `ui/weapon_select_menu.gd`, `survivors_game.tscn` (`ContentHBox`, `DetailPanel`), `weapon_data.gd` (`build_select_tooltip_bbcode`) |

---

## 연동 규칙 (`.mdc` 요약)

에이전트 must는 **영어 `.mdc` 원문**을 따릅니다.

| 파일 | 붙는 조건 |
|------|-----------|
| `godot-core.mdc` | 항상 (`alwaysApply`) |
| `godot-mobs.mdc` | `entities/mob/**`, `game/balance/mob_spawn_selector.gd` |
| `godot-weapons.mdc` | `weapons/**`, `entities/player/**`, `game/game.gd`, `ui/weapon_select_menu*` |

**몹 추가 시 (한 줄):** 새 `mob_*.tscn`만으로는 스폰되지 않음 → 반드시 `mob_spawn_selector.gd` + `default_balance_table.tres`를 같은 변경에 포함. (`godot-mobs.mdc`)

**무기 추가 시 (한 줄):** catalog·`gun.gd` 처리·`weapon_id` 고유성·선택 UI 풀을 같이 맞출 것. (`godot-weapons.mdc`)

---

## 핵심 제약 (영어 원문 — `godot-core.mdc`)

- Do not rename root `Game` or `%` nodes without repo-wide path updates.
- Do not change group `mobs` or per-variant mob scripts.
- Spawn only via `Game.spawn_mob()` → `Mob` + `initialize_spawn_health`.
- Do not start spawn `Timer` before `_ensure_game_started()`.
