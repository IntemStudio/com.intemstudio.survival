# Week 03 - Content Lock

**기간:** 3주차  
**상위 계획:** [`../Plan_Release_Roadmap.md`](../Plan_Release_Roadmap.md)  
**이전 주:** [`Week02_Demo_Core.md`](Week02_Demo_Core.md)  
**관련:** [`../../Design/GDD.md`](../../Design/GDD.md), [`../../Wiki/GameRules.md`](../../Wiki/GameRules.md), [`../../Wiki/Weapons.md`](../../Wiki/Weapons.md), [`../../Wiki/Projectiles.md`](../../Wiki/Projectiles.md), [`../../Wiki/Mobs.md`](../../Wiki/Mobs.md), [`../../Wiki/Progression.md`](../../Wiki/Progression.md), [`../../BACKLOG.md`](../../BACKLOG.md)

---

## Goal

공개 데모 콘텐츠를 고정한다. 1~2주차에서 만든 **아레나 핵심 루프**에 GDD의 **웨이브 modifier MVP-lite**(1~2종·소수 웨이브)를 넣어 아레나 정체성을 검증한 뒤, 무기 풀·몹·사운드·밸런스를 더 이상 크게 흔들지 않는다.

이번 주 이후 신규 기능 추가는 금지하고, 4주차는 치명 버그·Export만 다룬다.

---

## Success Criteria

- 데모 무기 풀·대표 projectile movement **최종 확정**.
- 아레나 1~10웨이브 몹 구성·이벤트(5/10 보스) 확정.
- **웨이브 modifier 1~2종**이 지정 웨이브에서 F5로 읽히고 플레이 가능.
- 위험/안전 구역(해당 시) **튜토리얼 없이** 구분 가능.
- 기본 BGM/SFX 최소 세트 연결 또는 연결 목록 확정.
- 아레나 **인벤토리 판단**·상자 흐름 1차 튜닝 완료.
- 아레나 F5 **1~10웨이브** 무중단 기준선 1회 이상.
- 4주차 QA 체크리스트 완성.

---

## In Scope

- 데모 무기 풀·몹·특수몹/보스 범위 최종 선택.
- **아레나 웨이브 modifier MVP-lite** 구현·UI·시인성.
- modifier 데이터·배치표, 라이프사이클(웨이브 종료 시 해제).
- 기본 사운드 연결( modifier 경고 SFX 포함).
- 아레나 밸런스 1차(웨이브·상자·골드).
- 게임오버/클리어 통계·피해 통계 점검.
- Content Lock 선언 및 Cut 목록.

---

## Out of Scope

- modifier **복합**·4종 전부·서바이벌 적용.
- Simulacrum **독립 모드**, 30/50/70/100웨이브, Rare+ 상자.
- 신규 무기·몹 대량 추가, 대규모 UI 재배치.
- Export·스토어 최종, 데모 범위 **기획 변경**.

---

## Work Items

| ID | 작업 | 상태 | 완료 기준 | 관련 |
|----|------|------|-----------|------|
| W03-01 | 데모 무기 풀 최종 확정 | Todo | 포함/제외·movement 기록 | `Weapons.md` |
| W03-02 | 데모 몹·아레나 웨이브 구성 확정 | Todo | 1~10 표 + 5/10 보스 | `Mobs.md`, `GameRules.md` |
| W03-03 | 서바이벌 이벤트 타임라인(비교) | Todo | 9·11·25·28분 사용 여부 | `Plan_Balance_VS_Curve_Alignment.md` |
| W03-04 | 기본 사운드 최소 세트 | Todo | BGM·피격·레벨업·보스·클리어·**modifier 경고** | `Plan_Release_Roadmap.md` |
| W03-05 | 아레나 밸런스 1차 튜닝 | Todo | 웨이브·상자·골드·modifier 웨이브 체감 | `GameRules.md` |
| W03-06 | 데모 제외 목록 재확인 | Todo | 메타·합성·Simulacrum 모드 등 Cut | `GDD.md`, `Plan_Release_Roadmap.md` |
| W03-07 | QA 체크리스트 작성 | Todo | F5 아레나+modifier, F6, Export | `Week04_QA_Build.md` |
| W03-08 | Content Lock 선언 | Todo | Must/Polish/Cut 분류·신규 기능 금지 | 이 문서 |
| W03-09 | modifier 데이터·배치표 | Todo | 웨이브↔modifier id, arena 리소스 단일 출처 | `BACKLOG.md`, Architecture |
| W03-10 | modifier 구현(1~2종) | Todo | 국소 위험/안전/회복감소/엘리트 중 선택 구현 | `GameRules.md` |
| W03-11 | modifier UI·시인성 | Todo | 텔레포터 전 안내, 위험·안전 구역 VFX/SFX | `GDD.md` |
| W03-12 | 아레나 인벤·상자 마무리 | Todo | 웨이브 보상 후 정리·실패 UX GDD 정합 | `Items_Inventory.md` |
| W03-13 | F5 아레나+modifier 기준선 | Todo | 1~10웨이브 무중단 1회+, modifier 웨이브 포함 | `Current.md` (4주차 handoff) |

---

## Decisions Needed

### D01 - 데모 콘텐츠 Must/Polish/Cut

주차 종료 시 각 항목 분류. **Must** 예: 아레나 1~10, modifier 1종+, 무기 풀 10~15, 통계 2개+, 최소 SFX.

### D02 - modifier 종류·웨이브 (2주차 말 입력)

| 후보 | 3주차 구현 우선순위 메모 |
|------|-------------------------|
| 국소 위험 지대 | 공간 판단·시인성 검증에 유리 |
| 제한 안전 구역 | Simulacrum 감각, 상시 안전지대 금지 준수 |
| 회복 감소 | 구현 단순, 상자 보완과 시너지 |
| 엘리트 강화 | 기존 elite와 역할 겹침 주의 |

**결정(Week02):** 웨이브 **6** = 국소 위험 지대, **9** = 회복 감소. 3주차에 구현·튜닝.

### D03 - 밸런스 튜닝 기준

**결정(1주차):** 데모 기본은 **아레나 1~10웨이브**. 서바이벌 30분은 비교·부분 이벤트만 점검.

---

## QA / Verification

| 항목 | 확인 내용 | 결과 |
|------|-----------|------|
| 무기 풀 | 데모 후보만 획득 UI 노출 | 미확인 |
| 아레나 웨이브 | 1~10·5/10 보스 의도대로 | 미확인 |
| modifier | 지정 웨이브에서 규칙·해제·승패 불변 | 미확인 |
| 위험/안전 시인성 | 설명 없이 구역 구분 | 미확인 |
| 인벤·상자 | 보상 후 정리·골드 부족·가방 가득 참 | 미확인 |
| 사운드 | bus·중복·modifier 경고 | 미확인 |
| 통계 | 패배/클리어 2개+ | 미확인 |

---

## Risks

| 리스크 | 영향 | 대응 |
|--------|------|------|
| modifier 3주차 신규 구현 | QA 빌드 지연 | 1~2종·1~2웨이브 엄수 |
| 콘텐츠 락 후 feature creep | 4주차 밀림 | Cut 엄격 적용 |
| 사운드 리소스 부족 | 피드백 약화 | bus·위치 먼저, 임시 SFX 허용 |

---

## Result

주차 종료 후 기록한다.

```text
확정한 데모 콘텐츠:
Cut으로 넘긴 항목:
4주차 QA 체크리스트:
남은 치명 리스크:
다음 주 우선순위:
```
