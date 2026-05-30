# AGENTS — Godot 2D Survival

**역할:** 작업 시작 시 보는 **짧은 입구**입니다. 상세는 `Docs/`에 두고, 실행 must는 `.cursor/rules/*.mdc`가 최우선입니다.

**우선순위:** `.cursor/rules/*.mdc` > `AGENTS.md` > `Docs/*`

## 먼저 볼 문서

| 목적 | 문서 |
|------|------|
| 문서 역할·코드 폴더 지도 | [`Docs/README.md`](Docs/README.md) |
| 핵심 제약 | [`Docs/Agents/CoreConstraints.md`](Docs/Agents/CoreConstraints.md) |
| 작업별 진입점 | [`Docs/Agents/README.md`](Docs/Agents/README.md) |
| 맵·스폰·소나무 | [`Docs/Agents/AGENTS_MapArena.md`](Docs/Agents/AGENTS_MapArena.md) |
| 디스플레이·UI | [`Docs/Agents/AGENTS_Display_UI.md`](Docs/Agents/AGENTS_Display_UI.md) |
| 런 루프·밸런스 | [`Docs/Architecture/Architecture_GameLoop_Balance.md`](Docs/Architecture/Architecture_GameLoop_Balance.md) |
| 공격·무기·발사체·버프·몹·인벤·입력 | [`Docs/Architecture/README.md`](Docs/Architecture/README.md) |
| GDD (기획 의도) | [`Docs/Design/GDD.md`](Docs/Design/GDD.md) |
| 플레이어 규칙 | [`Docs/Wiki/README.md`](Docs/Wiki/README.md) |
| 계획·주차 | [`Docs/Plan/README.md`](Docs/Plan/README.md) · Active: [`Weekly/Current.md`](Docs/Plan/Weekly/Current.md) |
| 후속 작업 | [`BACKLOG.md`](BACKLOG.md) |

## 문서·언어 정책

| 대상 | 언어 | 역할 |
|------|------|------|
| `.cursor/rules/*.mdc` | 영어 | 에이전트 실행 규칙 (최우선) |
| `AGENTS.md`, `Docs/*`, `BACKLOG.md` | 한국어 + 경로·타입명 영어 | 지도·설계·기획 |
| 코드 주석 (`.gd`) | 한국어 | 비즈니스/게임 로직 목적 한 줄 |

## 프로젝트 개요

Godot 4.5.2 기반 2D 뱀파이어 서바이버류. 로비에서 서바이벌/아레나 선택 → 무기·스폰·XP·레벨업 → 패배 또는 클리어.

- F5: `game_lobby.tscn` → `survivors_game.tscn` · 모드: `RunConfig` (`survival` / `arena`)
- F6: `test_arena.tscn` (현재 씬 — 무기·몹 튜닝·인벤 연동, [`Architecture_TestArena.md`](Docs/Architecture/Architecture_TestArena.md))
- 오케스트레이션: `game/game.gd` · Autoload 없음 · `/root/Game` 계약
- 뷰포트 HD 1280×720 · UI FHD 1920×1080 · 카메라 zoom `0.5` (`entities/player/player.tscn`)

**런타임 흐름:** [`Architecture_GameLoop_Balance.md`](Docs/Architecture/Architecture_GameLoop_Balance.md) (Overview·Flow)

**코드 폴더 지도:** [`Docs/README.md#코드-폴더-지도`](Docs/README.md#코드-폴더-지도)

## 수정 금지 (요약)

- Godot 프로젝트 — Unity `.meta` 규칙 적용 안 함
- 씬 루트 `Game`, `%` 노드, `mobs` 그룹 이름 변경 금지 (상세: `.cursor/rules/`)
- `.tscn`/`.tres` UTF-8 **BOM 없음** (파일 첫 바이트 `[`)
- F5 메인 런 ≠ F6 `test_arena` (목적 혼합 금지)
- 상세 제약: [`CoreConstraints.md`](Docs/Agents/CoreConstraints.md) · Architecture Invariants · `.mdc`

## 변경 후 확인

**CLI smoke (commit/PR 전, PowerShell 5.1+):** F6/F5 수동 QA를 **대체하지 않습니다**. 파싱·헤드리스 로드·정적 검사·gdUnit4 `test/` 회귀 게이트입니다.

```powershell
cd "2d-project-completed"
.\scripts\verify\run_smoke.ps1                    # 기본
.\scripts\verify\run_smoke.ps1 -SelfTest          # Godot 없이 인프라만 (quoting·argv round-trip·env probe)
.\scripts\verify\run_smoke.ps1 -FullStaticChecks -RetryOnFailure   # CI/nightly에 가깝게
```

| 옵션 | 용도 |
|------|------|
| `-GodotBinary` / `$env:GODOT_BIN` | Godot tools exe 경로 |
| `-SkipStaticChecks` · `-SkipUnitTests` | 단계 생략 |
| `-LogDir` | 로그 기본 `reports/smoke_logs/` |

스크립트·SelfTest 상세: [`scripts/verify/run_smoke.ps1`](scripts/verify/run_smoke.ps1) 상단 주석.

**수동 (Godot):** 변경 범위에 맞게 확인. 주차별 목표는 [`Docs/Plan/Weekly/`](Docs/Plan/Weekly/)의 `QA / Verification`을 따릅니다.

- 파싱 에러 없이 프로젝트 열기
- **F6:** `test_arena.tscn` — 몹 Spawn·전투 튜닝·Special A/B, 무기 Equip→인벤·**피해/APS/사거리/발사체 수**·movement 스냅샷, 탭 UI
- **F5 (해당 시):** 서바이벌 또는 아레나 한 판 — 로비 → 시작 무기 → 스폰/웨이브 → 패배 또는 클리어

## Plans

Active → [`Docs/Plan/Weekly/Current.md`](Docs/Plan/Weekly/Current.md) · 레이어 설명 → [`Docs/Plan/README.md`](Docs/Plan/README.md)
