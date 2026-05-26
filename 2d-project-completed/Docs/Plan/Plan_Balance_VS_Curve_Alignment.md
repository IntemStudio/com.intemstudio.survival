# Plan — VS형 난이도 곡선 정렬

**상태:** A·B·C 구현 완료. D·E·F·Q2는 [`../../BACKLOG.md`](../../BACKLOG.md)로 이관.  
**작성 목적:** Vampire Survivors형 30분 런 리듬을 현재 프로젝트에 맞춘 결정 기록과 결과 요약을 보관합니다.  
**관련:** 구조 문서 [`../Architecture/Architecture_GameLoop_Balance.md`](../Architecture/Architecture_GameLoop_Balance.md), 기획 문서 [`../Wiki/GameRules.md`](../Wiki/GameRules.md), [`../Wiki/Mobs.md`](../Wiki/Mobs.md)

---

## Overview

이 계획은 기존 단조 상승형 밸런스 곡선을 30분 생존 런에 맞게 재정렬하기 위해 작성되었다. 목표는 초반 학습, 9~11분 압박, 16~24분 호흡, 25분 보스, 28분 후반 압박, 30분 클리어를 하나의 리듬으로 만드는 것이었다.

현재 A·B·C는 코드에 반영되어 있다. 런 루프와 밸런스 구조의 현재 동작은 `Architecture_GameLoop_Balance.md`를 기준으로 본다. 이 문서는 왜 이런 곡선을 선택했는지, 어떤 결정이 내려졌는지, 무엇이 후속으로 남았는지만 남긴다.

---

## Implemented Decisions

| ID | 결정 | 결과 |
|----|------|------|
| A | 0~30분 키프레임을 VS형 리듬으로 재배치 | 11분 피크, 16~20분 완화, 25분 보스 구간, 28분 후반 압박이 생김 |
| B | 키프레임만으로 부족한 순간 압박을 타임라인 이벤트로 보강 | 9·11·25·28분 이벤트가 표 축 기준 1회 발동 |
| C | 30분 도달 시 사신 대신 스테이지 클리어 처리 | 스폰 정지, 필드 몹 클리어 사망, 성공 UI 표시 |
| C-1 | 클리어 사망은 드랍과 처치 집계를 만들지 않음 | 30분 클리어가 대량 보상으로 변질되지 않음 |
| C-2 | `balance_pace_multiplier`는 표 축 진행 속도를 바꿈 | 압축 런에서도 이벤트와 30분 클리어가 같은 곡선 위치에 맞음 |

---

## Current Runtime Summary

| 영역 | 현재 동작 |
|------|-----------|
| 곡선 | `default_balance_table.tres`의 `BalancePhase` 키프레임을 `BalanceTable`이 보간 |
| 이벤트 | `default_balance_timeline.tres`의 `BalanceTimelineEvent`가 표 축 분 기준 1회 발동 |
| 스폰 밀도 | phase `spawn_density`와 일시 density event 배수를 합쳐 Timer 간격 조정 |
| 몹 구성 | `MobSpawnSelector`가 phase 비율로 basic/fast/ranged/elite/special/boss 선택 |
| 보상 | `KillRewards`가 `mob_kind`와 phase 보상 배율로 XP·골드 계산 |
| 클리어 | 표 축 30분 도달 시 `_run_cleared`, Timer 정지, 몹 클리어 사망, UI pause |

자세한 타입과 호출 순서는 [`Architecture_GameLoop_Balance.md`](../Architecture/Architecture_GameLoop_Balance.md)를 기준으로 한다.

---

## Deferred Work

아래 항목은 이 Plan에서 더 이상 상세 관리하지 않고 `BACKLOG.md`에서 우선순위를 정한다.

| ID | 후속 항목 | 이유 |
|----|-----------|------|
| D | 몹 HP × 플레이어 레벨 | 강한 빌드에 맞춰 적도 단단해지는 장르 체감 보강 |
| E | 하이퍼 모드 | 25분 이후 전역 압박과 보스 구간 차별화 |
| F | 플레이테스트·튜닝 | 실제 체감에 따른 키프레임·밀도·보상 조정 |
| Q2 | 31~40분 구간 | 30분 클리어 유지 또는 하드 모드 확장 결정 필요 |

---

## Decision Log

| 날짜 | 결정 | 이유 | 후속 |
|------|------|------|------|
| 2025-05 | 30분 사신 즉사 대신 클리어 채택 | 데모 기준으로 성공 UI와 완주 체감을 우선 | 보스 처치 승리 등은 별도 후보 |
| 2025-05 | 타임라인 이벤트를 키프레임과 분리 | 선형 보간만으로는 9·11·25분 순간 압박이 약함 | 이벤트 수치 플레이테스트 |
| 2025-05 | 클리어 사망은 드랍 없음 | 성공 순간에 보상 폭발이 생기면 진행 의도가 흐려짐 | 클리어 보상은 별도 설계 |
| 2026-05-25 | 구현 구조 설명을 Architecture로 이관 | Plan은 결정 기록과 결과 요약만 유지 | 구조 변경 시 Architecture 갱신 |

---

## Quality Gates

- F5에서 시작 무기 획득과 자동 장착 후 스폰 시계가 시작된다.
- 표 축 9·11·25·28분 이벤트가 한 번씩만 발동한다.
- 표 축 30분 도달 시 클리어 UI가 표시되고 추가 스폰이 멈춘다.
- 클리어로 죽은 몹은 XP, 골드, 자석, 체력 픽업을 드랍하지 않는다.
- `balance_pace_multiplier` 변경 시 이벤트와 클리어가 같은 표 축 위치에 맞춰 압축된다.
