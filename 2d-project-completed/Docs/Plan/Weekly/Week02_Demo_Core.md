# Week 02 - Demo Core

**기간:** 2주차 · **상태:** 진행 중  
**상위 계획:** [`../Plan_Release_Roadmap.md`](../Plan_Release_Roadmap.md)  
**이전 주:** [`Week01_Demo_ScopeLock.md`](Week01_Demo_ScopeLock.md)  
**관련:** [`../../Design/GDD.md`](../../Design/GDD.md), [`../../Wiki/GameRules.md`](../../Wiki/GameRules.md), [`../../Wiki/Weapons.md`](../../Wiki/Weapons.md), [`../../Wiki/Projectiles.md`](../../Wiki/Projectiles.md), [`../../Wiki/Mobs.md`](../../Wiki/Mobs.md), [`../../Wiki/Combat.md`](../../Wiki/Combat.md), [`../../Wiki/Progression.md`](../../Wiki/Progression.md), [`../../Wiki/Items_Inventory.md`](../../Wiki/Items_Inventory.md)

---

## Goal

1주차·GDD에서 고정한 **아레나 MVP** 안에서 플레이어가 바로 체감하는 핵심 재미를 만든다. 우선순위는 무기 성장 체감, 특수몹 고유성, 게임오버·클리어 통계, 골드 상자·**아레나 인벤토리 판단** 1차 검증이다.

이번 주에는 **웨이브 modifier 구현은 하지 않는다**. 3주차용으로 modifier **종류·배치 웨이브만** 기획 확정한다.

---

## Success Criteria

- [ ] 레벨업(서바이벌)·웨이브 보상(아레나)에서 최소 **성장 체감** 또는 대체안 적용.
- [x] 특수몹 2종(`special_a`/`special_b`)이 스탯 차이를 넘는 행동 1차 구현.
- [x] 게임오버/클리어에 생존 시간·레벨·처치 수 **3개** 표시 (`RunStatsLabel`).
- [ ] 데모 무기 풀 후보 F6 1차 검증(movement·피해·자동 공격).
- [ ] F5 아레나 1~10웨이브 또는 10분 이상 **치명 오류 없이** 진행 기록.
- [ ] 웨이브 보상 후 **인벤 정리·상자·텔레포터** 흐름이 GDD 필러(선택의 무게)에 맞는지 1차 확인.
- [ ] 3주차에 넘길 작업( modifier MVP-lite 포함)을 **5개 이하**로 정리.
- [x] 3주차 modifier **1~2종·배치 웨이브** 기획 확정 — 웨이브 6 위험 지대, 9 회복 감소 (`GameRules.md`).

---

## In Scope

- 무기 성장 체감 구현 또는 대체안.
- `special_a`/`special_b` F6·F5 검증 및 마무리.
- 게임오버·클리어 통계 UI.
- 데모 무기 풀 F6 검증.
- 골드 상자 가격·확률·실패 UX 1차 튜닝.
- 아레나 인벤토리 판단(버리기·스왑·가방 가득 참) F5 체감 확인.
- 공격 시스템 1차 인프라 유지·확장(범위 내).
- modifier 배치·종류 **기획 확정** → Week03 입력.

---

## Out of Scope

- 웨이브 modifier **구현**(위험 지대·안전 구역 등) — 3주차.
- 무기 합성·진화, 메타·영구 인벤, 캐릭터 선택.
- 모든 무기/몹 밸런스 완료, Export·스토어 최종.
- Simulacrum 독립 모드.

---

## Work Items

| ID | 작업 | 상태 | 완료 기준 | 관련 |
|----|------|------|-----------|------|
| W02-01 | 무기 성장 대체안 | Carryover | D01: 신규 무기+풀 축소 — 강화 구현은 EA. 풀·툴팁은 W02-02 | `Weapons.md` |
| W02-02 | 데모 무기 풀 1차 검증 | Todo | 10~15종 F6 movement·피해·자동 공격 | `Weapons.md`, `Projectiles.md` |
| W02-03 | 특수몹 고유 체감 | In progress | `special_a` burst, `special_b` 돌진·자폭 구현 — **F6 수동 QA 남음** | `Mobs.md`, `Architecture_AttackSystem.md` |
| W02-04 | 게임오버·클리어 통계 | Done | `RunStatsLabel` — 생존/웨이브·시간·Lv·처치 | `GameRules.md`, `game.gd` |
| W02-05 | 기본 사운드 연결 지점 | Todo | BGM·피격·레벨업·보스·클리어 후보 위치 기록 | `Plan_Release_Roadmap.md` |
| W02-06 | 골드 상자 보상 튜닝 | Todo | F5 아레나 가격·수급·등급·실패 UX 1차 | `Progression.md` |
| W02-07 | F5 기준선 테스트 | Todo | 10분+ 또는 아레나 1~10웨이브 기록 | `GameRules.md` |
| W02-08 | 3주차 Content Lock 후보 | Todo | 남은 작업 5개 이하 + modifier 종류·웨이브 확정 | `Week03_Content_Lock.md` |
| W02-09 | 공격 시스템 1차 인프라 | Done | `AttackContext`, `AttackFactory`, `DamageResolver`, `Gun` 위임 | `Architecture_AttackSystem.md` |
| W02-10 | 아레나 인벤토리 판단 1차 검증 | Todo | 웨이브 보상 후 정리·상자·가방 압박 F5 체감 | `Items_Inventory.md`, `GDD.md` |
| W02-11 | modifier 기획 확정(구현 없음) | Done | 웨이브 6 국소 위험 지대, 9 회복 감소 | `GameRules.md` |

---

## Decisions Needed

### D01 - 무기 성장 방식

| 선택지 | 적용 조건 | 이번 주 완료 기준 |
|--------|-----------|------------------|
| 보유 무기 강화 | 데모 핵심 성장 | 보유 무기 후보·수치 상승 |
| 기본 스탯 보정 | 구현 범위 축소 | 데모 풀 초·중·후반 체감 |
| 신규 무기 중심 유지 | 일정 촉박 | 풀 축소·툴팁으로 선택 의미 보강 |

**결정(2026-05-28):** **신규 무기 중심 + 데모 풀 10~15종 축소**. 보유 무기 강화는 EA. [`Weapons.md`](../../Wiki/Weapons.md).

### D02 - 보스/특수몹 최소 체감

**결정(1주차·GDD):** **특수몹 우선** — `special_a`, `special_b`. 보스 전용 패턴은 3주차 Polish 또는 Cut.

### D03 - modifier 3주차 입력

**결정(2026-05-28):** 웨이브 **6** = 국소 위험 지대, **9** = 회복 감소. 구현은 3주차(W03-10~11).

---

## QA / Verification

| 항목 | 확인 내용 | 결과 |
|------|-----------|------|
| F5 10분 / 아레나 1~10 | 로비→무기→텔레포터→웨이브→보상→클리어/패배 | 미확인 |
| F5 인벤·상자 | 무기 3택1→상자→가방/장착→다음 텔레포터 | 미확인 |
| F6 무기 | 데모 후보 발사·피해·movement·자동 공격 | 미확인 |
| F6 특수몹 | Special A burst, Special B 돌진·자폭 | 미확인 |
| 통계 UI | 패배/클리어 2개+ 지표 | 미확인 |
| 문서 | GDD·Week01 Result·Current 정합 | 진행 중 |

---

## Risks

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 무기 성장 미결정 | W02-01 지연 | 주 중 D01 확정, 대체안 허용 |
| modifier 욕심 | 3주차 밀림 | 2주차는 기획만 |
| 상자+인벤 복잡도 | QA 증가 | 실패 UX·가방 메시지 1차만 |

---

## Result

주차 종료 시 기록한다. 진행 중 스냅샷은 [`Current.md`](Current.md).

```text
완료한 구현:
- (진행) W02-09 공격 인프라, W02-03 special_a/b 1차

완료한 검증:

3주차로 넘길 콘텐츠:
- modifier MVP-lite, 무기 풀 lock, 사운드, 밸런스 1차

삭제/보류한 작업:

새로 발견한 리스크:
```
