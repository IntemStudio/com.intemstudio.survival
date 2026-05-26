# Architecture Docs

**역할:** 기능 단위의 코드 구조, 책임 경계, 런타임 흐름, 변경 시 주의점을 정리합니다.

이 폴더의 문서는 구현자가 코드를 안전하게 수정하기 위한 설계 지도입니다. 플레이어용 기획 설명이나 장기 TODO보다, 현재 코드가 어떤 타입과 흐름으로 동작하는지에 집중합니다.

## 기본 구조

각 기능 문서는 가능한 한 아래 섹션만 유지합니다.

1. Overview
2. Responsibilities & Boundaries
3. Key Types & Relationships
4. Flow
5. Invariants & Gotchas
6. Change Guidelines

## 포함할 문서

- `Architecture_Inventory.md`처럼 기능 단위의 타입, 의존 관계, 런타임 흐름을 설명하는 문서.
- 새 기능을 수정하거나 확장할 때 깨면 안 되는 불변조건이 많은 문서.
- `Architecture_Weapons.md`, `Architecture_GameLoop_Balance.md`, `Architecture_Mobs.md`처럼 여러 파일과 시스템이 맞물리는 문서.

## 작성/예정 범위

| 문서 | 다룰 범위 | 제외할 범위 |
|------|-----------|-------------|
| `Architecture_Input.md` | `ActionManager`, 기본 바인딩, 리맵 저장/로드, 입력 호출부와 조작 설정 UI 계약 | 게임패드 지원, 튜토리얼 문구 |
| `Architecture_Weapons.md` | `WeaponData`, 무기 카탈로그, `Gun`, 투사체·장판·궤도, 자동 공격, 무기별 피해 기록 | 무기별 데모 선정 기준, 성장 기획, 아이콘 정책 |
| `Architecture_GameLoop_Balance.md` | 로비 이후 런 시작, 스폰 타이머, `BalanceTable`, `BalanceTimeline`, 클리어/게임오버, 보상 호출 경로 | 출시 일정, 플레이테스트 TODO, 장기 난이도 아이디어 |
| `Architecture_Mobs.md` | `mob.gd` 공통 계약, 변종 씬, 원거리 공격, 접촉 피해, 사망·보상·풀 반환, 보스/특수몹 확장 지점 | 몹 역할 기획, 등장 체감, 데모 콘텐츠 우선순위 |

## 포함하지 않을 문서

- 작업 시작용 요약과 must / must not 중심 가이드: `Docs/Agents/`
- 플레이어에게 드러나는 규칙과 기획 의도: `Docs/Wiki/`
- 일정, 마일스톤, Epic 계획: `Docs/Plan/`
- 남은 일과 아이디어: `BACKLOG.md`
