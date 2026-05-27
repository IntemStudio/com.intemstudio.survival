# Week 01 - Demo Scope Lock

**기간:** 1주차 · **상태:** 완료  
**상위 계획:** [`../Plan_Release_Roadmap.md`](../Plan_Release_Roadmap.md)  
**관련:** [`../../Design/GDD.md`](../../Design/GDD.md), [`../../Wiki/GameRules.md`](../../Wiki/GameRules.md), [`../../Wiki/Weapons.md`](../../Wiki/Weapons.md), [`../../Wiki/Projectiles.md`](../../Wiki/Projectiles.md), [`../../Wiki/Mobs.md`](../../Wiki/Mobs.md), [`../../Wiki/Progression.md`](../../Wiki/Progression.md), [`../../Wiki/Items_Inventory.md`](../../Wiki/Items_Inventory.md)

---

## Goal

1주차의 목표는 데모 개발을 시작하기 전에 **데모에 넣을 것과 뺄 것**을 확정하는 것이다. 큰 기능 구현보다 결정, 기준선 테스트, 작업 목록 축소, **GDD·Wiki·BACKLOG 정렬**을 우선한다.

주가 끝날 때는 `Plan_Release_Roadmap.md`의 `Demo Must`가 현실적인 크기로 정리되고, 2주차 `Demo Core`에 바로 들어갈 작업 3~5개가 확정되어 있어야 한다.

---

## Success Criteria

- [x] 데모 기본 모드를 확정한다: **아레나 MVP** (서바이벌은 비교 모드).
- [x] 데모 인벤토리를 **런 한정** 장비 빌드로 노출 범위를 확정한다.
- [x] 골드를 웨이브 사이 **상자 비용**으로 사용하는 기준을 확정한다.
- [x] **GDD 초안**으로 필러·아레나 정체성(웨이브 modifier MVP-lite, 인벤토리 판단 강화)을 문서화한다.
- [x] `GameRules.md`, `BACKLOG.md`를 GDD와 1차 정렬한다.
- [ ] 데모 무기 풀 후보 10~15종 축소 — **2주차로 이관**
- [ ] F5/F6 기준선 플레이 기록 — **2주차 QA로 이관**

---

## In Scope

- 데모 범위·모드·골드·인벤토리 결정.
- GDD 1페이지 치트시트 초안 및 Design 폴더 정리.
- Wiki `GameRules`, BACKLOG와 GDD 정합성.
- 보스/특수몹 데모 최소 목표 방향 정리.
- 2주차 Demo Core 작업 후보 확정.

---

## Out of Scope

- 보유 무기 강화·보스 패턴·웨이브 modifier **구현**.
- Export Preset·스토어 페이지 완성.
- 영구 장비 세이브, 메타 진행, 캐릭터 선택, 퀵슬롯, 무기 합성·진화.
- Simulacrum식 **독립 모드** (아레나 modifier로만 일부 흡수 — GDD Later).

---

## Work Items

| ID | 작업 | 상태 | 완료 기준 | 관련 |
|----|------|------|-----------|------|
| W01-01 | 데모 기본 모드/런 구조 결정 | Done | 아레나 MVP 기본, 서바이벌 비교 모드 | `GameRules.md`, `GDD.md` |
| W01-02 | 인벤토리 노출 정책 결정 | Done | 런 한정, 영구 장비 세이브 분리 | `Items_Inventory.md` |
| W01-03 | 데모 무기 풀 후보 선정 | Carryover → W02 | 10~15종 축소·F6 검증은 2주차 | `Weapons.md` |
| W01-04 | 보스/특수몹 데모 목표 결정 | Done | 데모 체감은 **특수몹** 우선(`special_a`/`special_b`), 보스 패턴 후속 | `Mobs.md` |
| W01-05 | 골드 정책 결정 | Done | 웨이브 사이 상자 비용, 런 한정 | `Progression.md` |
| W01-06 | F5 기준선 플레이 기록 | Carryover → W02 | 아레나 1~10·서바이벌 비교 | `Plan_Release_Roadmap.md` |
| W01-07 | F6 테스트 아레나 기준선 | Carryover → W02 | 무기 풀 검증과 병행 | `AGENTS.md` |
| W01-08 | 프로젝트 표기 준비 정리 | Carryover | M1/M3: 프로젝트명·아이콘·Export | `Plan_Release_Roadmap.md` |
| W01-09 | 2주차 Demo Core 작업 확정 | Done | 무기 성장·풀 검증·특수몹·통계·상자·F5 기준선 | `Week02_Demo_Core.md` |
| W01-10 | GDD 초안 및 문서 정렬 | Done | `GDD.md`, `GameRules`, BACKLOG modifier·인벤 정책 반영 | `Design/GDD.md` |

---

## Decisions Needed

### D01 - 데모 기본 모드

**결정:** 기본 데모는 **아레나 MVP**. 서바이벌 30분은 로비 비교 모드.

### D02 - 인벤토리 노출

**결정:** **런 한정** 핵심 기능. 아레나에서 웨이브 보상·가방 압박으로 **판단 빈도**를 높인다 ([`GDD.md`](../../Design/GDD.md) 필러: 선택의 무게).

### D03 - 골드 정책

**결정:** 런 중 자원, 웨이브 클리어 후 상자 비용. 1~10웨이브 `Common`/`Uncommon`만.

### D04 - 아레나 웨이브 modifier (GDD)

| 원칙 | 내용 |
|------|------|
| 범위 | **아레나만**. 서바이벌 타임라인 미적용 |
| 형태 | 상시 시스템 아님, **특정 웨이브 modifier** |
| MVP-lite | 4종 후보 중 **1~2종**, **1~2개 웨이브**만 데모 검증 |
| 후보 | 국소 위험 지대, 제한 안전 구역, 회복 감소, 엘리트 강화 |
| 승패 | modifier는 난도 강화만, **승리 조건 변경 없음** |
| 구현 시기 | **3주차** Content Lock 전 MVP-lite (2주차는 기획·배치표만) |

**결정:** 위 원칙으로 GDD·Wiki·BACKLOG에 반영. 구현은 3주차.

### D05 - 보스/특수몹 데모 체감

**결정:** 2주차 구현 우선은 **특수몹** (`special_a` burst, `special_b` 돌진·자폭). 보스 전용 패턴·연출은 3주차 이후 Polish/Cut 검토.

---

## QA / Verification

| 항목 | 확인 내용 | 결과 |
|------|-----------|------|
| 문서 정합성 | Roadmap, GDD, Wiki, Backlog 데모 범위·아레나 modifier 의도 | 완료 |
| GDD ↔ GameRules | modifier 미정 섹션, 인벤·데모 기준 | 완료 |
| GDD ↔ BACKLOG | Arena modifier MVP-lite 작업 목록 | 완료 |
| F5 로비·아레나·서바이벌 | 기준선 플레이 | **2주차로 이관** |
| F6 테스트 아레나 | 무기·몹 검증 | **2주차로 이관** |

---

## Risks

| 리스크 | 영향 | 대응 |
|--------|------|------|
| modifier가 2주차를 잠식 | Demo Core 지연 | 구현은 3주차, 2주차는 배치·종류 기획만 |
| 영구/런 인벤 혼선 | 저장 버그 | Wiki·GDD에 런 한정 고정 |
| 무기 풀 과다 | 폴리시 저하 | 10~15종, 2주차 축소 |

---

## Result

**완료한 결정**

- 데모 기본: **아레나 MVP 1~10웨이브**, 서바이벌 30분은 비교 모드.
- 런 한정 인벤토리·골드 상자(`Common`/`Uncommon`), 텔레포터 웨이브 시작.
- 아레나 정체성: **웨이브 변이(MVP-lite) + 인벤토리 판단** — Survivors-like 데모 뼈대 유지 ([`GDD.md`](../../Design/GDD.md)).
- 필러: 성장 체감, 읽히는 압박(변이 포함), **선택의 무게**, 안정적 데모.
- 특수몹 우선 체감; 보스 패턴·Simulacrum 독립 모드는 후속.

**완료한 문서·검증**

- `Docs/Design/GDD.md` 초안, `Docs/README.md`·`AGENTS.md` Design 링크.
- `Wiki/GameRules.md` — 아레나 modifier 섹션(미정), 인벤·데모 기준 갱신.
- `BACKLOG.md` — Arena modifier MVP-lite 섹션, 데모 스코프 `[x]` 기본 확정.
- Roadmap·Architecture·Wiki 1차 정합 (1주차 말 기준).

**2주차로 이관 (Demo Core)**

- 무기 성장 방식(D01) 확정 및 적용.
- 데모 무기 풀 10~15종 + F6 movement·피해 검증.
- `special_a`/`special_b` F6·F5 검증, 게임오버/클리어 통계, 골드 상자 튜닝.
- F5 아레나 1~10웨이브·서바이벌 비교 기준선.
- 공격 인프라·특수몹 1차 구현은 2주차 진행 중으로 `Current.md`에 반영.

**3주차로 예약 (Content Lock)**

- 아레나 웨이브 modifier MVP-lite 구현(1~2종·1~2웨이브).
- modifier UI, 위험/안전 구역 시인성, modifier 배치표 확정.

**보류 (데모 밖)**

- 영구 장비 세이브, 메타, 캐릭터 선택, 퀵슬롯, 합성·진화, Simulacrum 독립 모드.

**새 리스크**

- modifier·상자·인벤이 겹치면 3주차 QA 범위 증가 → 2주차 말에 modifier 종류·웨이브 번호만 선확정.
