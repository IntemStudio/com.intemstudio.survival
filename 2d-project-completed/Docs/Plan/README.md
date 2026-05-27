# Plan

**역할:** 출시·기능·밸런스 같은 큰 작업을 실행 가능한 계획과 결정 기록으로 관리합니다.

`Plan/` 바로 아래 문서는 마일스톤, Epic, 장기 범위, 완료 기준처럼 여러 주에 걸치는 계획을 다룹니다. `Weekly/` 아래 문서는 상위 계획을 1주 단위로 쪼갠 실행 계획입니다. 두 문서는 서로 대체하지 않고, 상위 계획은 방향과 기준을, 주차 계획은 이번 주 실행과 검증을 담당합니다.

## Plans 레이어

| 레이어 | 경로 | 용도 |
|--------|------|------|
| Active | [`Weekly/Current.md`](Weekly/Current.md) | 이번 주 진행·막힘·다음 액션 |
| Completed | [`Weekly/Week*.md`](Weekly/) → `Result` | 주차 종료 요약 |
| Tech debt | [`../../BACKLOG.md`](../../BACKLOG.md) | 미구현·후속·기술 부채 |

에이전트·개발자 참고 순서: **Current → 해당 Week 문서 → BACKLOG**

## 문서 구분

| 위치 | 역할 | 작성할 내용 |
|------|------|-------------|
| `Plan_*.md` | 상위 계획·Epic·결정 기록 | 목표, 범위, 마일스톤, 성공 기준, 품질 게이트, 주요 결정 |
| `Weekly/Week*.md` | 1주 단위 실행 계획 | 이번 주 목표, 완료 기준, 작업 항목, 필요한 결정, QA, 리스크, 결과 |
| `Weekly/Current.md` | 현재 주 작업판 | 진행 중 작업, 완료한 일, 막힌 점, 검증, 다음 인계 |
| `Weekly/README.md` | 주차 계획 운영 규칙 | 4주 롤링 플랜, 주차 문서 템플릿, 갱신 원칙 |

## 상위 Plan 작성 규칙

- 여러 주 이상 유지될 방향과 기준만 적습니다.
- 구현 순서보다 **왜 이 범위를 선택했는지**, **성공을 어떻게 판정할지**를 우선합니다.
- 완료된 대형 계획은 긴 구현 스냅샷보다 결정 기록과 결과 요약 중심으로 줄입니다.
- 미구현 후속 작업은 상세하게 붙잡아 두지 말고 `../../BACKLOG.md`로 넘깁니다.
- 코드 구조 설명이 길어지면 `../Architecture/` 문서로 분리합니다.
- 플레이어에게 드러나는 규칙과 기획 의도는 `../Wiki/`에 둡니다.

## Weekly 작성 규칙

- 현재 주 + 다음 3주까지만 상세히 관리합니다.
- 한 주 안에 끝낼 수 있는 범위로 쪼갭니다.
- 이번 주 작업 중 상태는 `Weekly/Current.md`에 기록합니다.
- `Goal`, `Success Criteria`, `In Scope`, `Out of Scope`, `Work Items`, `Decisions Needed`, `QA / Verification`, `Risks`, `Result` 구조를 유지합니다.
- 주차가 끝나면 `Result`를 짧게 적고, 남은 작업은 다음 주 문서나 상위 Plan/Backlog로 이동합니다.
- `Weekly/Current.md`는 주간 작업판이므로, 주가 끝나면 핵심 결과만 `Week*.md`의 `Result`로 옮기고 초기화합니다.
- Weekly 문서는 장기 설계 저장소가 아닙니다. 시간이 지나도 남아야 하는 구조 정보는 Architecture나 Wiki로 옮깁니다.

## 현재 문서

- [`Plan_Release_Roadmap.md`](Plan_Release_Roadmap.md) — 공개 데모, 얼리 액세스, 1.0까지의 출시 로드맵
- [`Plan_Balance_VS_Curve_Alignment.md`](Plan_Balance_VS_Curve_Alignment.md) — VS형 밸런스 곡선 정렬 계획과 구현 기록
- [`Weekly/Current.md`](Weekly/Current.md) — 이번 주 실시간 작업판
- [`Weekly/README.md`](Weekly/README.md) — 4주 롤링 주차 계획 운영 규칙
