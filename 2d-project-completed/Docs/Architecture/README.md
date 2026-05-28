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
| `Architecture_AttackSystem.md` | 4계층, Attack Entity 목표, **`game/attack/` 1차 인프라**(Context/Factory/Resolver), 1차 행동 7종, 마이그레이션 | `AttackEntity` 베이스, TargetAttack, AttackDefinition |
| `Architecture_Player.md` | 이동, 대시, 스태미나·회복 딜레이, 대시·피격 후·부활 무적, 피격 게이트, revive, 장비 무적·스태미나 키 | 무기·Gun, 몹 AI, 입력 바인딩 정의 |
| `Architecture_Input.md` | `ActionManager`, 기본 바인딩, 리맵 저장/로드, 입력 호출부와 조작 설정 UI 계약 | 게임패드 지원, 튜토리얼 문구 |
| `Architecture_Weapons.md` | `WeaponData`, 무기 카탈로그, 장착, `Gun`, 자동 공격, 무기별 피해 기록 | 발사체 이동·충돌 세부 구현, 무기별 데모 선정 기준, 성장 기획, 아이콘 정책 |
| `Architecture_Projectiles.md` | 플레이어 발사체, movement, 장판, 궤도, 환경 충돌, 풀링, 피해 귀속 | 무기 획득·장착, 몹 원거리 투사체, 플레이어-facing 기획 설명 |
| `Architecture_StatusEffects.md` | `status/` 데이터·런타임, 몹 상태이상 적용/만료/DoT, 피해·이동 배율 반영, 무기 피해 통계 귀속 | 플레이어 버프, 장비 상시 스탯, HUD 상태이상 패널, 스폰/웨이브 밸런스 |
| `Architecture_Buffs.md` | 런타임 버프 정의, 지속시간, 스택, 플레이어 스탯 modifier 반영, 웨이브/대시 트리거 | 영구 성장, 장비 상시 스탯, HUD 버프 아이콘, 몹 상태이상 통합 |
| `Architecture_Passives.md` | LoadoutPassive·RunPassive·TimedBuff·WaveModifier 4층, `WeaponRunState`, `AccessorySynergy`, `PassiveResolver` | HUD, 이벤트 큐·확률 데이터(EA), GDD Enabler 정의 본문 |
| `Architecture_GameLoop_Balance.md` | 로비 이후 런 시작, 스폰 타이머, `BalanceTable`, `BalanceTimeline`, 클리어/게임오버, 보상 호출 경로 | 출시 일정, 플레이테스트 TODO, 장기 난이도 아이디어 |
| `Architecture_Mobs.md` | `mob.gd` 공통 계약, 변종 씬, 원거리 공격, 접촉 피해, 사망·보상·풀 반환, 보스/특수몹 확장 지점 | 몹 역할 기획, 등장 체감, 데모 콘텐츠 우선순위 |
| `Architecture_TestArena.md` | F6 씬, 몹/무기/보조/상태이상 튜닝(적용/저장), 상태이상 탭 진입·자동 선택·저장 자동 반영, 사망 폭발 지연·예고 링, 인벤 GUI, 탭 UI | F5 웨이브·상자·밸런스 타임라인 |

## 포함하지 않을 문서

- 작업 시작용 요약과 must / must not 중심 가이드: `Docs/Agents/`
- 플레이어에게 드러나는 규칙과 기획 의도: `Docs/Wiki/`
- 일정, 마일스톤, Epic 계획: `Docs/Plan/`
- 남은 일과 아이디어: `BACKLOG.md`
