# Wiki — 엘리트 형태 (Elite Affix)

**역할:** 몹·보스에 확률적으로 붙는 **엘리트 형태(affix)** 규칙, 티어 1 스펙, **엘리트 유물(relic)** 드랍·보유 효과를 정리합니다.  
**관련:** [`Mobs.md`](Mobs.md), [`Combat.md`](Combat.md), [`Items_Inventory.md`](Items_Inventory.md), [`Progression.md`](Progression.md), [`../Architecture/Architecture_EliteForms.md`](../Architecture/Architecture_EliteForms.md), [`../Architecture/Architecture_Mobs.md`](../Architecture/Architecture_Mobs.md), [`../Architecture/Architecture_Inventory.md`](../Architecture/Architecture_Inventory.md), [`../Architecture/Architecture_StatusEffects.md`](../Architecture/Architecture_StatusEffects.md)

**상태:** 기획 v0.1 · 구현 **미착수** · **갱신:** 2026-05-31

---

## 한 줄 정의

**엘리트 형태**는 특정 몬스터를 제외한 **모든 몹·보스**에 확률적으로 붙는 **단일 affix 레이어**입니다. 처치 시 (공허 엘리트 제외) 극히 낮은 확률로 **엘리트 유물**이 떨어지며, 유물은 **장착할 수 없고 가방에 넣기만 해도** 해당 엘리트 계열 효과가 적용됩니다.

현재 코드의 `mob_kind = elite` **독립 스폰 변종**과는 **다른 개념**입니다. 구현 시 affix 시스템으로 통합·대체하는 것을 목표로 합니다.

---

## 설계 원칙

| 원칙 | 설명 |
|------|------|
| **읽히는 위협** | affix 색·머리 장식(뿔/왕관)·이름 접두사로 즉시 구분 |
| **한 몹 = 한 affix** | 티어 1 기준 중첩 affix 없음 |
| **VS 밀도와 공존** | 아군 치유·몹 간 AoE 등은 수치·빈도로 폭주하지 않게 제한 |
| **유물은 수집·선택** | 강하지만 가방 슬롯을 소비 — 인벤 판단과 연결 |
| **데모 범위** | 티어 1 affix 2~3종 + 유물 2~3종 MVP-lite, 나머지·DLC는 후속 |

---

## 등장 규칙

### 대상

| 대상 | 엘리트 형태 | 비고 |
|------|-------------|------|
| basic, fast, ranged | ✅ | affix 롤 대상 |
| boss | ✅ | 확률·affix 풀은 보스 전용 테이블 **미정** |
| special_a, special_b | ❌ (v0.1) | 기믹·affix 중첩 QA 부담 — 후속 화이트리스트 검토 |
| dummy | ❌ | 테스트 전용 |
| (기획상 제외 몹) | ❌ | 목록 **미정** |

### 확률

| 항목 | 기획값 | 상태 |
|------|--------|------|
| 일반 몹 affix 롤 | **`p_normal`** — 아래 [등장 확률 기획안 (v0.1)](#등장-확률-기획안-v01) | 기획안 |
| 보스 affix 롤 | **`p_boss = 100%`** — tier 1 affix 1종 (금빛 제외) | 기획안 |
| affix 종류 가중치 | tier 1 네 종 **균등 25%** (금빛·공허 풀 제외) | 기획안 |

### 공통 스탯 (affix 부여 시)

affix 적용 **이후** 최종 HP·공격력에 곱합니다. (phase `hp_multiplier`는 기존처럼 스폰 시 먼저 적용)

| affix | HP 배율 | 공격 배율 |
|-------|---------|-----------|
| 불타는, 과전하, 빙하의 | ×4 | ×2 |
| 수리 중인 | ×3 | ×2 |
| 금빛 (DLC) | ×6 | ×3 |

**공격 배율**은 접촉 `contact_attack_damage`, 원거리 `ranged_damage_min/max` 등 해당 몹의 활성 공격 수치에 적용합니다.

---

## 월드 거리 상수

원문 “4m” 등 **미터 단위**는 프로젝트 **픽셀**로 변환합니다.

| 상수 | 값 | 용도 |
|------|-----|------|
| `ELITE_UNIT` | **40 px = 1m** | affix AoE·장판·폭발 반경 통일 |
| 4m | **160 px** | 과전하 폭탄, 빙하의 사망 폭발 등 |
| 3m | **120 px** | 수리 오라 등 (튜닝 가능) |

카메라 zoom·몹 `attack_distance`(약 150px)와 같은 오더로 F6/F5에서 재튜닝합니다.

---

## 등장 확률 기획안 (v0.1)

F5 플레이테스트 전 **초안 수치**입니다. `BalancePhase` 연동은 구현 단계에서 `Architecture_GameLoop_Balance`와 함께 정합니다.

| 구간 (서바이벌) | `p_normal` | 비고 |
|-----------------|------------|------|
| 0~8분 | **0%** | affix 학습 전 구간 |
| 9~10분 | **3%** | 9분 이벤트와 겹치는 첫 체험 |
| 11~24분 | **4%** | 중반 밀도 구간 |
| 25분~ (보스 구간) | **5%** | 보스 이벤트와 병행 |

| 규칙 | 값 |
|------|-----|
| 보스 스폰 시 affix | **100%** (tier 1 네 종 중 1종, 균등) |
| 금빛 affix 스폰 | **0%** (DLC 해금 전) |
| special_a / special_b | **affix 롤 제외** (v0.1) |
| 동시 affix 중첩 | **1몹 1affix** |

**아레나:** 웨이브 번호 대신 `ArenaWaveDirector` 훅으로 동일 `p_normal` 테이블 또는 웨이브 modifier **엘리트 강화**와 중복되지 않게 **미정** — modifier는 “해당 웨이브 elite 스폰·스탯”이므로 affix 롤과 역할 분리 검토.

---

## 엘리트 유물 (Relic)

### 드랍

| 조건 | 확률 |
|------|------|
| **공허 엘리트** 처치 | **0%** (유물 없음) |
| 그 외 **엘리트 형태** 몹·보스 처치 | **0.025%** (1/4,000) |
| affix 없는 일반 몹 | 0% |
| 30분 클리어 사망(필드 전멸) | 0% |

**기대 빈도 (참고):** 런당 엘리트 처치 100회 가정 시 기대 유물 약 2.5%. pity·보스 보장·튜토리얼 1회 고정 드랍은 **미정**.

### 보유·적용 (인벤 정책 예외)

| 동작 | 규칙 |
|------|------|
| weapon / 방어구 슬롯 장착 | **불가** |
| **가방 보유** | 해당 유물 효과 **적용** |
| Shift+버리기 | 가능 — 월드 드롭 후 효과 해제 |
| 동일 유물 중복 | **동일 `item_id` 효과는 1스택** — 가방에 2칸 있어도 효과 중복 없음 |
| 런 수명 | 기존 인벤과 동일 — 클리어·패배·로비 복귀 시 소멸 |

> ⚠️ 현재 [`Items_Inventory.md`](Items_Inventory.md)의 “가방 = 효과 없음” 규칙과 **충돌**합니다. 유물만 예외로 두며, 구현 시 Architecture·UI에 **Relic** 카테고리를 분리합니다.

### 유물 효과 강도

플레이어 유물 효과는 **동일 affix 몹이 플레이어에게 거는 효과의 약 50%** 또는 **동일 affix 공격이 몹/환경에 거는 효과의 50%**를 **공격형 유물**로 번역합니다. 상세는 [유물 카탈로그 (v0.1)](#유물-카탈로그-v01)를 단일 출처로 합니다.

### 유물 카탈로그 (v0.1)

| `item_id` | 표시명 | 출처 affix | 희귀도 | 보유 효과 (가방) | affix 대비 |
|-----------|--------|------------|--------|------------------|------------|
| `relic_blazing` | 불타는 유물 | `blazing` | Legendary | **무기 적중** 시 대상 몹에 **2초** 화상 DoT — 몹 최대 체력 **10%** (0.5초×4 tick) | 몹→플레이어 20%/4초의 50%·지속 50% |
| `relic_overloading` | 과전하 유물 | `overloading` | Legendary | **무기 적중** 시 **0.75초** 후 반경 **80px** 소형 폭발 — 해당 적중 **raw 피해의 25%** (방어 전) | 50% 피해·50% 반경·50% 지연 |
| `relic_glacial` | 빙하의 유물 | `glacial` | Legendary | **무기 적중** 시 **1.5초** `chill` — 이동속도 **40% 감소** (`move_speed_mult = 0.6`) | 80%→40% 감속 |
| `relic_mending` | 수리 유물 | `mending` | Legendary | **3초**마다 최대 체력 **1%** 회복 (`heal_health`) | 오라 heal 대신 self-heal |
| `relic_gilded` | 금빛 유물 | `gilded` | Legendary | 몹 처치 골드 **+15%** (골드 보상 계산 후 floor) | DLC · 후속 |

**공통 규칙 (v0.1):**

- 장착 슬롯 없음 · 가방 1칸 = 1유물 · **Shift+버리기** 가능
- 유물 피해·상태는 **플레이어 무기**를 source로 `register_weapon_damage` / 몹 `status` 귀속
- 드롭 시 [`EquipmentDrop`](../../effects/equipment_drop/)과 동일 상호작용 획득 · 자동 장착 시도 **없음** · **가방 우선**
- 드롭 연출: affix 색 글로우 오브 · SFX **후속**

**드랍 테이블:**

| 처치 affix | 드랍 `item_id` | 확률 |
|------------|----------------|------|
| `blazing` | `relic_blazing` | 0.025% |
| `overloading` | `relic_overloading` | 0.025% |
| `glacial` | `relic_glacial` | 0.025% |
| `mending` | `relic_mending` | 0.025% |
| `gilded` | `relic_gilded` | 0.025% (DLC) |
| `void` / affix 없음 | — | 0% |

---

## 플레이어 상태 (엘리트 affix 전용)

몹 대상 `status/`와 **분리**합니다. 플레이어 전용 debuff(화상·감속·동결·부착 폭탄 등)는 별도 계층에서 관리합니다.

| 규칙 | 기획 |
|------|------|
| 지속시간 | affix 스펙표의 초 단위. refresh 정책은 affix별 명시 |
| 대시 중 | **미정** — 무적과 debuff tick 중첩 여부 |
| tree pause | 접촉 피해·버프와 동일 — pause 중 tick **정지** |
| “체력 재생 차단” (불타는) | **v0.1:** 화상 중 `heal_health` **무효** + **스태미나 회복 배율 0** (대시 비용 회복 포함). 체력 픽업 orb는 획득해도 회복량 0 |
| 대시 중 debuff tick | **v0.1:** tick **정지** (무적과 동일 — 지속시간만 소모) |

### 플레이어 debuff ID (v0.1)

| ID | affix | 지속 | 효과 |
|----|-------|------|------|
| `elite_burn` | 불타는 | 4s refresh | max HP 20% DoT + 재생 차단 (위 표) |
| `elite_bomb` | 과전하 | 1.5s refresh | 만료 시 160px, snapshot×0.5 피해 |
| `elite_chill` | 빙하의 | 1.5s refresh | `move_speed_mult = 0.2` |
| `elite_freeze` | 빙하의 (폭발) | 1.5s | 이동·대시·공격 입력 잠금 |
| — | 금빛 | — | debuff 없음 (골드 강탈·장판) |

---

## Affix 색·UI

| Affix | 색 라벨 | ID (작업용) |
|-------|---------|-------------|
| 불타는 | AffixRed | `blazing` |
| 과전하 | AffixBlue | `overloading` |
| 빙하의 | AffixWhite / Cyan | `glacial` |
| 수리 중인 | AffixEarth | `mending` |
| 금빛 | AffixAure | `gilded` |

HUD·이름표·조준 UI에 affix 색 dot 또는 접두사(예: `불타는 슬라임`)를 표시합니다. **후속.**

---

# 티어 1 — 엘리트 형태

## 2.1.1 불타는 (Blazing)

**상태:** 구현됨 (affix·유물 `relic_blazing`) · 뿔 mesh 후속

| 항목 | 스펙 |
|------|------|
| **외형** | 머리에 염소처럼 **긴 뿔 2개**. 빨강·주황 tint |
| **스탯** | HP ×4, 공격 ×2 |
| **공격 디버프** | 피격 시 **4초 화상**: 체력 재생 차단 + 최대 체력 **20%**에 해당하는 **지속 피해** |
| **이동** | 지나간 자리에 **잠시 잔불**. 접촉 시 화상 (동일 debuff, refresh) |

**프로젝트 번역 (구현 가이드):**

- DoT: `max_hp × 0.20` 을 4초에 분배 — **0.5초 tick × 4회 × 5%**
- 잔불: 지면 hazard, **lifetime 2s**, **반경 32px**, 접촉 시 `elite_burn` refresh
- 재생 차단: [플레이어 debuff ID](#플레이어-debuff-id-v01) `elite_burn` 참고

**유물:** [`relic_blazing`](#유물-카탈로그-v01) — 무기 적중 화상 10%/2s

---

## 2.1.2 과전하 (Overloading)

**상태:** 미착수

| 항목 | 스펙 |
|------|------|
| **외형** | 이마에 코뿔소처럼 **짧은 뿔 2개**. 파란 tint |
| **스탯** | HP ×4, 공격 ×2 |
| **공격** | 피격 시 **폭탄 부착** → **1.5초** 후 폭발, 반경 **4m (160px)**, **해당 공격 총합 피해의 50%**. **발동 계수(스케일) 없음** |
| **방어** | 최대 체력의 **50%**가 **방어막**. **7초**간 피해를 받지 않으면 **빠르게 재충전** |

**프로젝트 번역:**

- “총합 피해 50%”: **해당 hit 1회의 방어·block 적용 전 raw 피해 × 0.5** (접촉 tick·충돌 bump 각각 snapshot)
- 방어막: `shield_max = max_health × 0.5`. **7s** 무피해 후 **1s에 shield_max 100%** 재충전
- 폭발: `death_burst_warning` telegraph 재사용

**유물:** [`relic_overloading`](#유물-카탈로그-v01)

---

## 2.1.3 빙하의 (Glacial)

**상태:** 미착수

| 항목 | 스펙 |
|------|------|
| **외형** | 머리 주변 **얼음 왕관**. 흰색·청록 tint |
| **스탯** | HP ×4, 공격 ×2 |
| **공격** | 피격 시 **1.5초**, **80% 감속** (`move_speed_mult = 0.2`) |
| **사망** | **2초** 후 **얼음 폭탄**. 반경 내 **기본 피해 150%** + **1.5초 동결** |

**프로젝트 번역:**

- “기본 피해 150%”: affix 적용 **전** `contact_attack_damage` 또는 `ranged_damage` 중앙값 × 1.5
- 동결: `elite_freeze` — 이동·대시·`auto_attack` 입력 잠금
- 사망 AoE: 플레이어 + 몹. **몹 사망 시 XP·처치 정상 집계** (연쇄 폭발은 affix 사망 1회당 burst 1회)
- `death_burst_delay = 2s` + 링 예고 **재사용**

**유물:** [`relic_glacial`](#유물-카탈로그-v01)

---

## 2.1.4 수리 중인 (Mending)

**상태:** 미착수

| 항목 | 스펙 |
|------|------|
| **외형** | 회춘의 선반형 **나선 뿔**. 연두·적갈 tint |
| **스탯** | HP ×3, 공격 ×2 |
| **오라** | 주변 **아군 몹**에게 **최대 체력 비례** 지속 치유 |
| **사망** | **파괴 가능한 치유 코어** 잔존 → 일정 시간 후 폭발, **플레이어·몹 구분 없이** 반경 내 **전원 치유** |

**프로젝트 번역:**

- 오라: 반경 **120px**, **0.5s** tick, tick당 `max_health × 1%` heal (아군 몹만)
- 코어: HP **elite max×10%** destructible. **3s** 후 또는 파괴 시 **160px** neutral heal — `max_health × 15%` (사망 snapshot)
- VS 밀도: 오라 heal **1%/tick** 상한 유지

**유물:** [`relic_mending`](#유물-카탈로그-v01)

---

## 2.1.5 금빛 (Gilded) — DLC / 후속

**상태:** 후속 (공허 생존자급 DLC 콘텐츠)

| 항목 | 스펙 |
|------|------|
| **외형** | 오릴리오나이트형 **금빛 뿔** |
| **스탯** | HP ×6, 공격 ×3 (티어 1 최상) |
| **공격** | 피격 시 플레이어 **골드 일부**를 **금덩어리**로 드랍. **10초** 내 미수집 시 소멸 |
| **주기** | 약 **10초**마다 플레이어 발 밑 **1초** 예고 후 타격 장판 |
| **사망** | **금덩어리 2~3개** 추가 드랍 |

**프로젝트 번역:**

- 골드 강탈: `min(floor(gold × 0.08), 50)` → **TimedGoldNugget**, **TTL 10s**
- 장판: **10s** 주기, **1s** telegraph, 반경 **64px**, affix 전 base damage × 1.5
- 사망: 금덩어리 **2~3**개, 각 **25~40** 고정 gold (phase loot 무관)
- **affix 스폰 풀:** DLC 해금 전 **0**

**유물:** [`relic_gilded`](#유물-카탈로그-v01) — 후속

---

## 공허 엘리트 (Void)

**상태:** 미정 (별도 티어·DLC)

- **유물 드랍 0%** — 확정
- affix 목록·스펙·금빛(DLC)과의 **명칭·출처 구분** — **미정**
- Wiki/GDD에 Void tier 추가 시 이 문서 §를 확장

---

## 월드 오브젝트 (affix 잔재)

| 오브젝트 | affix | 핵심 규칙 | 상태 |
|----------|-------|-----------|------|
| 잔불 지대 | 불타는 | 짧은 lifetime, 접촉 화상 | 구현됨 |
| 부착 폭탄 | 과전하 | 플레이어 debuff, 1.5s 후 AoE | 미착수 |
| 얼음 폭탄 | 빙하의 | 2s delay, AoE + 동결 | 미착수 |
| 치유 코어 | 수리 중인 | 파괴 가능, neutral heal burst | 미착수 |
| 금덩어리 | 금빛 | TTL 10s, 상호작용 획득 | 미착수 |

---

## 현재 구현과의 관계

| 현재 | 목표 affix 시스템 |
|------|-------------------|
| `mob_elite.tscn` + `elite_spawn_ratio` | affix 롤로 **대체** (단계적) |
| affix 부여 몹 XP | **기본 kind XP × 1.5** (`KillRewards` 배율 추가) | 기획안 |
| 몹 `status/` only | 플레이어 debuff 계층 **신규** |
| 가방 = 무효 | 유물만 **보유 적용** 예외 |
| 몹 사망 드랍 | XP·골드·1% 픽업만 | 유물 0.025% **추가** |

### 구현 단계 (권장)

| 단계 | affix | 유물 | 인프라 |
|------|-------|------|--------|
| **1 MVP-lite** | `glacial`, `overloading` | `relic_glacial`, `relic_overloading` | affix 롤, F6 강제 affix, `PlayerDebuffController`, 몹 shield, death_burst 재사용 |
| **2** | `blazing`, `mending` | `relic_blazing`, `relic_mending` | ground fire hazard, mob heal aura, healing core |
| **3** | `gilded`, 공허 tier | `relic_gilded` | DLC gate, `elite_spawn_ratio` 제거, pity·HUD |

구현 설계: [`Architecture_EliteForms.md`](../Architecture/Architecture_EliteForms.md).

### F6 / QA 검증 (구현 후)

| ID | 시나리오 | 기대 |
|----|----------|------|
| E1 | F6 affix `glacial` + basic 스폰 | 왕관 비주얼, 피격 80% 감속, 사망 2s 후 AoE·동결 |
| E2 | F6 affix `overloading` | 실드 bar, 7s 후 recharge, bomb 1.5s |
| E3 | F6 affix `blazing` | 잔불 trail, 4s burn + heal block |
| E4 | 유물 드랍 치트 100% | 가방 보유 시 효과, 장착 슬롯 거부 |
| E5 | 동일 유물 2칸 | 효과 1스택만 |
| E6 | F5 9분+ | `p_normal` affix 스폰 체감 |
| E7 | 보스 + affix | 100% affix 1종 |
| E8 | special_a affix 롤 | **없음** (v0.1) |
| E9 | 클리어 사망 | 유물·affix 드랍 없음 |

---

## 미정 / 후속

- 아레나 affix vs **엘리트 강화** modifier 역할 분리
- pity, 보스 1회 유물 보장, 튜토리얼 1회 고정 드랍
- 전용 relic 칸(가방 외) 여부
- affix 등장 연출(SFX, minimap ping, 이름 접두사)
- **공허 엘리트** tier 스펙·Void affix 풀
- `p_normal` phase 보간·아레나 웨이브 테이블
- 유물 드롭 VFX·툴팁 BBcode
- [`Combat.md`](Combat.md) 플레이어 debuff 섹션 추가 (구현 시)

---

## 관련 문서

| 문서 | 내용 |
|------|------|
| [`Mobs.md`](Mobs.md) | 몹 종류, 스폰 타임라인 |
| [`Items_Inventory.md`](Items_Inventory.md) | 장착 vs 가방 (유물 예외 예정) |
| [`Combat.md`](Combat.md) | 플레이어 피해·회복 |
| [`Progression.md`](Progression.md) | XP·골드·드랍 |
| [`Architecture_EliteForms.md`](../Architecture/Architecture_EliteForms.md) | affix·유물·PlayerDebuff 코드 경계 |
| [`BACKLOG.md`](../../BACKLOG.md) | Elite Forms 구현 Epic |
