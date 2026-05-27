# Current Week

**역할:** 이번 주에 실제로 작업 중인 내용을 짧게 추적합니다.  
**상위 계획:** [`README.md`](README.md) · 주차: [`Week02_Demo_Core.md`](Week02_Demo_Core.md) · GDD: [`../../Design/GDD.md`](../../Design/GDD.md)

주가 끝나면 핵심 결과만 해당 주차 `Result`로 옮기고 이 파일을 초기화합니다.

**마지막 갱신:** 2026-05-28

---

## Week

- 주차: **2주차**
- 기준 문서: [`Week02_Demo_Core.md`](Week02_Demo_Core.md)
- 이번 주 초점: **F6 QA 완료** → 무기 풀 검증 → F5 아레나 기준선 → 상자 튜닝

---

## In Progress

- [ ] **F6 특수몹 QA** — 아래 체크리스트 (W02-03 완료 판정)
- [ ] 데모 무기 풀 10~15종 + F6 검증 (W02-02)
- [ ] 골드 상자 가격·수급·등급·실패 UX 1차 (W02-06)
- [ ] F5 아레나 1~10웨이브 또는 10분+ 기준선 기록 (W02-07)
- [ ] 아레나 인벤·상자·텔레포터 체감 (W02-10)

---

## Done This Week

- [x] **D01** 신규 무기 중심 + 데모 풀 10~15종 — [`Weapons.md`](../../Wiki/Weapons.md)
- [x] **W02-11** modifier 기획: 웨이브 6 위험 지대, 9 회복 감소 — [`GameRules.md`](../../Wiki/GameRules.md)
- [x] **W02-08** 3주차 Content Lock Must **5개** 확정 — 아래 «3주차 Handoff»
- [x] **W02-04** 게임오버/클리어 `RunStatsLabel` (생존·웨이브·Lv·처치)
- [x] 공격 인프라, `special_a`/`special_b` 1차, `charge_trigger_distance` 수정
- [x] 1주차·GDD·문서 정렬
- [x] F6 테스트 아레나 GUI — 몹/무기 탭·튜닝 스냅샷·인벤 착용·탭 바·[`Architecture_TestArena.md`](../../Architecture/Architecture_TestArena.md)
- [x] F6 무기 GUI — 피해·APS·사거리·발사체 생성 수 SpinBox (`TestArenaWeaponSnapshot` core)
- [x] F6 특수 A — 사망 burst 지연 링 예고 (`death_burst_warning`, `AttackFactory`)
- [x] F6 특수 B — 돌진 거리 GUI·`mob_charge_lane` 레인 예고 후 돌진 (`TestArenaMobSnapshot`)
- [x] fast 몹 시인성 — `mob_speed_trail` (이동 꼬리·먼지, `mob_fast.tscn`) — [`Mobs.md`](../../Wiki/Mobs.md)
- [x] 상호작용 공통화 — `InteractableArea` (골드 상자·장비 드롭·아레나 텔레포터)

---

## Decisions (확정)

| ID | 결정 |
|----|------|
| D01 | 신규 무기 중심 + 데모 풀 축소. 보유 무기 강화 → EA |
| D02 | 특수몹 우선 (`special_a`/`special_b`) |
| D03 | modifier 웨이브 6·9, 구현 3주차 |

---

## 3주차 Handoff (W02-08 → Week03)

2주차 말 넘길 Must **5개** (이외는 Polish/Cut 또는 4주차):

| # | ID | 작업 |
|---|-----|------|
| 1 | W03-10 | modifier 구현 — 웨이브 6 위험 지대, 9 회복 감소 |
| 2 | W03-11 | modifier UI·위험/안전 구역 시인성 |
| 3 | W03-01 | 데모 무기 풀 최종 lock (10~15종) |
| 4 | W03-04 | 기본 BGM/SFX 최소 세트 |
| 5 | W03-13 | F5 아레나 1~10웨이브 + modifier 포함 기준선 1회+ |

상세: [`Week03_Content_Lock.md`](Week03_Content_Lock.md)

---

## F6 QA 체크리스트 (W02-03)

`test_arena.tscn` 현재 씬 → F6 실행.

| # | 확인 | Pass |
|---|------|------|
| 1 | **Special A** 처치 → 지연 링 예고(기본 3s) → burst·플레이어 피해·범위(튜닝 반영) | [ ] |
| 2 | **Special B** `charge_trigger_distance` 밖에서는 돌진 안 함 | [ ] |
| 3 | **Special B** 트리거 거리 진입 → **레인 예고** → 대기 후 돌진·종료 범위 피해 | [ ] |
| 4 | **Special B** 저체력 자폭 | [ ] |
| 5 | burst/자폭 후 몹 정리·풀 반환 이상 없음 | [ ] |
| 6 | 접촉·원거리·돌진 **공격 예고**(`!`)·돌진 **레인 미리보기**(이동 전) | [ ] |
| 6b | **Special B** F6 몹 탭 — **돌진 거리** 스핀 표시(사망 폭발 스핀 없음) | [ ] |
| 7 | 무기 Equip → **인벤 활성 weapon**·튜닝 즉시 반영 | [ ] |
| 8 | 무기 **피해·APS·사거리·발사체 수** 스핀 → 전투·설명 omit 반영 | [ ] |
| 9 | 몹·무기 튜닝 **적용/저장**(SpinBox 직접 입력 포함)·스폰 즉시 반영·상태 색상 | [ ] |
| 10 | **fast** 스폰 후 이동 시 하늘색 꼬리·먼지, 정지·풀 반환 시 즉시 소거 | [ ] |

통과 시 Week02 W02-03 → **Done**.

---

## F5 QA 체크리스트 (W02-07, W02-10)

F5 → 로비 → **아레나**.

| # | 확인 | Pass |
|---|------|------|
| 1 | 시작 무기 3택1 → 자동 장착 → 텔레포터 1웨이브 | [ ] |
| 2 | 웨이브 클리어 → 무기 3택1 → 상자 구매 → 텔레포터 | [ ] |
| 3 | 가방 가득 참 / 골드 부족 메시지 | [ ] |
| 4 | 5·10 보스 웨이브 체감 | [ ] |
| 5 | 10웨이브 클리어 또는 패배 시 **RunStatsLabel** 3항목 | [ ] |
| 6 | (선택) 서바이벌 30분 또는 10분 비교 | [ ] |

기록 형식: `날짜 / 빌드 / 이슈 한 줄`

---

## Verification

- [ ] F6 특수몹·fast 시인성 (위 표)
- [ ] F6 무기 풀
- [ ] F5 아레나·인벤·상자 (위 표)
- [x] 게임오버/클리어 통계 UI
- [x] D01, W02-11, W02-08 문서·후보 확정

---

## Next Handoff

- **즉시:** F6 QA 체크리스트 1~10 Pass → W02-03 Done 판정
- **이번 주 잔여:** W02-02 무기 풀 F6 → W02-06 상자 튜닝 → W02-07·10 F5 기준선·인벤 체감
- **3주차 착수:** 위 «3주차 Handoff» 5개 — modifier 구현·시인성이 최우선
