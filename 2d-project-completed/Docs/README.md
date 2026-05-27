# Docs

**역할:** 이 폴더는 프로젝트 문서를 역할별로 나누어 관리하는 진입점입니다.

문서를 작성하거나 갱신할 때는 먼저 “이 내용이 누구를 위한 정보인가?”를 결정합니다. 코드 변경 안전성을 위한 정보는 Architecture, 작업 진입용 요약은 Agents, 플레이어에게 드러나는 규칙은 Wiki, 일정과 실행 계획은 Plan, 아직 하지 않은 일은 `BACKLOG.md`에 둡니다.

## 문서 역할

| 위치 | 역할 | 작성할 내용 |
|------|------|-------------|
| `../AGENTS.md` | 프로젝트 작업 입구 | 짧은 개요, 문서 링크, Quick verify, 상세는 Docs로 위임 |
| `Agents/` | 도메인별 작업 가이드 | 작업 진입점, QA, 제약, must / must not, 확인 시나리오 |
| `Architecture/` | 기능별 코드 구조 | 책임 경계, 주요 타입, 런타임 흐름, 불변조건, 변경 가이드 |
| `Wiki/` | 게임 규칙과 기획 | 플레이어 경험 기준의 규칙, 현재 구현 상태, 미정/후속 기획 |
| `Plan/` | 실행 계획과 결정 기록 | Epic, 마일스톤, 주차 계획, 품질 게이트, 의사결정 기록 |
| `../BACKLOG.md` | 남은 일 목록 | 미구현 기능, 기술 부채, 후속 개선, 우선순위 미정 아이디어 |

## 판단 기준

- **코드를 안전하게 바꾸려면 알아야 한다** → `Architecture/`
- **작업 시작 전에 어디를 봐야 하는지 알아야 한다** → `Agents/` 또는 `../AGENTS.md`
- **게임이 어떻게 플레이되어야 하는지 설명한다** → `Wiki/`
- **언제, 어떤 순서로 할지 정한다** → `Plan/`
- **아직 하지 않았거나 나중에 결정할 일이다** → `../BACKLOG.md`

## 작성 규칙

- 같은 내용을 여러 문서에 길게 복사하지 않습니다. 상위 문서는 요약과 링크만 둡니다.
- 구현 구조와 플레이어 규칙을 섞지 않습니다. 예를 들어 무기 공격 체감은 `Wiki/Weapons.md`와 `Wiki/Projectiles.md`, `Gun` 이후 발사체 흐름은 `Architecture/Architecture_Projectiles.md`에 둡니다.
- 완료된 구현 이력은 필요할 때만 짧게 남기고, 긴 Phase/PR 기록은 Plan 또는 Backlog로 옮깁니다.
- Architecture 문서는 가능한 한 `Overview`, `Responsibilities & Boundaries`, `Key Types & Relationships`, `Flow`, `Invariants & Gotchas`, `Change Guidelines` 구조를 따릅니다.
- Wiki 문서는 코드 경로를 최소화하고, “현재 구현됨 / 부분 구현 / 미정 / 후속”을 구분합니다.
- Agents 문서는 실행 가이드입니다. 상세 설계를 반복하지 말고, 읽을 문서와 주의할 규칙을 안내합니다.
- Backlog는 살아 있는 목록입니다. 완료·기각·범위 변경 시 항목을 삭제하거나 짧게 갱신합니다.

## 코드 폴더 지도

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
| `buff/` | 런타임 버프 데이터, 지속시간, 스택, 트리거 연결 |
| `entities/player/` | 이동, 대시, 경험치, 무기 컨테이너, 피격 |
| `entities/mob/` | 공통 `Mob`, 변종, 원거리 투사체, 공격 예고 |
| `weapons/` | `WeaponData`, 카탈로그, `Gun`, 발사체·장판·궤도 |
| `inventory/` | 장비 loadout, 세이브, registry, 전투 bridge |
| `ui/` | 로비 외 UI, 일시정지, 무기 획득, 설정, 인벤토리 |
| `effects/` | 경험치, 골드, 자석, 체력, hit flash, 플로팅 데미지 |
| `world/map_arena/` | 맵 경계, 내부 스폰 좌표 |
| `world/trees/` | Poisson 소나무 배치 |
| `Docs/` | 문서 |

작업별로 먼저 볼 파일은 [`Agents/README.md#작업별-진입점`](Agents/README.md#작업별-진입점)을 참고합니다.

## 현재 주요 문서

- [`Architecture/Architecture_Inventory.md`](Architecture/Architecture_Inventory.md)
- [`Architecture/Architecture_Input.md`](Architecture/Architecture_Input.md)
- [`Architecture/Architecture_AttackSystem.md`](Architecture/Architecture_AttackSystem.md)
- [`Architecture/Architecture_Weapons.md`](Architecture/Architecture_Weapons.md)
- [`Architecture/Architecture_Projectiles.md`](Architecture/Architecture_Projectiles.md)
- [`Architecture/Architecture_Buffs.md`](Architecture/Architecture_Buffs.md)
- [`Architecture/Architecture_GameLoop_Balance.md`](Architecture/Architecture_GameLoop_Balance.md)
- [`Architecture/Architecture_Mobs.md`](Architecture/Architecture_Mobs.md)
- [`Agents/README.md`](Agents/README.md)
- [`Agents/CoreConstraints.md`](Agents/CoreConstraints.md)
- [`Architecture/README.md`](Architecture/README.md)
- [`Wiki/README.md`](Wiki/README.md)
- [`Plan/README.md`](Plan/README.md)
- [`Plan/Plan_Release_Roadmap.md`](Plan/Plan_Release_Roadmap.md)
