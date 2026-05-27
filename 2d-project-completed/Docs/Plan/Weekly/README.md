# Weekly Plans

**역할:** 출시 로드맵을 1주 단위 실행 계획으로 쪼개 관리합니다.  
**상위 계획:** [`../README.md`](../README.md), [`../Plan_Release_Roadmap.md`](../Plan_Release_Roadmap.md)

---

## 운영 원칙

- 상세 계획은 **현재 주 + 다음 3주**까지만 작성합니다.
- 5주차 이후는 상위 로드맵의 마일스톤 수준으로만 둡니다.
- 이번 주의 실시간 진행 상태는 [`Current.md`](Current.md)에 기록합니다.
- 매주 끝에 `Result`를 기록하고, 다음 주 계획을 현실에 맞게 갱신합니다.
- 한 주 문서는 구현 목록보다 **결정, 완료 기준, 검증 항목**을 우선합니다.
- 검증 항목은 주차 문서 `QA / Verification`과 [`Current.md`](Current.md)의 Verification에 둡니다. 공통 최소 확인은 [`AGENTS.md`](../../../AGENTS.md)의 «변경 후 확인»을 참고합니다.
- 이번 주에 끝낼 수 없는 작업은 다음 주 또는 `Plan_Release_Roadmap.md`로 되돌립니다.
- `Current.md`는 장기 기록이 아닙니다. 주가 끝나면 결과만 주차 문서의 `Result`로 옮기고 초기화합니다.

---

## 4주 롤링 플랜

| 주차 | 문서 | 목표 | 상태 |
|------|------|------|------|
| 현재 작업판 | [`Current.md`](Current.md) | 이번 주 진행 상태 추적 | 수시 갱신 |
| 1주차 | [`Week01_Demo_ScopeLock.md`](Week01_Demo_ScopeLock.md) | 데모 범위와 기준선 고정 | 작성됨 |
| 2주차 | [`Week02_Demo_Core.md`](Week02_Demo_Core.md) | 핵심 체감 구현 | 작성됨 |
| 3주차 | [`Week03_Content_Lock.md`](Week03_Content_Lock.md) | 데모 콘텐츠 고정 | 작성됨 |
| 4주차 | [`Week04_QA_Build.md`](Week04_QA_Build.md) | QA 빌드와 Export 검증 | 작성됨 |

---

## 주차 문서 템플릿

```markdown
# Week NN - Title

## Goal

## Success Criteria

## In Scope

## Out of Scope

## Work Items

## Decisions Needed

## QA / Verification

## Risks

## Result
```

---

## 현재 작업판 템플릿

`Current.md`는 아래 섹션을 유지합니다.

```markdown
# Current Week

## Week

## In Progress

## Done This Week

## Decisions / Blockers

## Verification

## Next Handoff
```
