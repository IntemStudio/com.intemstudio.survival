# Plan — Vampire Survivors형 난이도 곡선 정렬

**상태:** **A·B·C 구현 완료** (2025-05) — D·E·F는 [`BACKLOG.md`](../BACKLOG.md)로 이관  
**작성 목적:** VS(뱀파이어 서바이버즈)식 **스파이크·완화·25분 보스·30분 클리어** 리듬 정렬 계획·구현 기록.  
**관련:** [`AGENTS.md`](../AGENTS.md) 밸런스·런타임, [`BACKLOG.md`](../BACKLOG.md), `game/balance/*`, `game/game.gd`

---

## 0. 구현 스냅샷 (A·B·C — 코드 반영됨)

| 파일 | 역할 |
|------|------|
| `game/balance/default_balance_table.tres` | VS형 A 키프레임 |
| `game/balance/balance_table.gd` | 보간·`balance_pace_multiplier` |
| `game/balance/default_balance_timeline.tres` | B: 9·11·25·28분 이벤트 |
| `game/balance/balance_timeline.gd` · `balance_timeline_event.gd` | 타임라인 리소스 |
| `game/game.gd` | 타임라인 tick·밀도 버스트·30분 클리어·`spawn_mob(forced, cap무시)` |
| `entities/mob/mob.gd` | `die_from_stage_clear()` — 드랍·처치 없음 |
| `ui/balance_notice_banner.gd` | `show_timeline_alert()` |
| `survivors_game.tscn` | `balance_table` · `balance_timeline` · `%GameOverTitle` |

**BACKLOG (미구현):** D · E · F · Q2(31~40분) — [`BACKLOG.md`](../BACKLOG.md) 밸런스·디자인 섹션.

---

## 1. Overview

### 1.1 목표

- 한 판의 **난이도 체감**을 VS 광기의 숲(30분 런)에 가깝게 만든다.
- **1차 완결 시점 = 30분 클리어(C1 확정)** — 화면 내 모든 적 일괄 처치 후 성공 UI. **31~40분**은 선택적 하드/보너스(후순위).
- 기존 `BalanceTable` + `MobSpawnSelector` + 풀 스폰 계약은 유지하고, **곡선 모양·이벤트·런 종료**를 추가한다.

### 1.2 성공 기준 (플레이테스트)

| 시각 (1.0× 배율) | 기대 체감 |
|------------------|-----------|
| 0~8분 | 기본 몹 위주, 빌드가 굴러가는 구간 |
| ~9분 | 단발 압박 스파이크 (VS 거대 박쥐에 상응) |
| ~11분 | **1차 커트라인** — 물량·압박 급증, 미준비 빌드 탈락 다수 |
| 16~24분 | **호흡** — 스폰 압력 완화, 체력 높은 적 비중 (VS 완만 구간) |
| ~25분 | 맵 보스급 등장 (B: 보스 1체 강제 스폰). **하이퍼(E)** 는 BACKLOG |
| 25~29분 | 2차 급상승 (원거리·보스 비율·밀도) |
| 30분 | **클리어** — 전장 몹 소거(드랍 없음) → 성공 UI |

`balance_pace_multiplier` 1.5 / 2.0 사용 시 위 시각은 `30 / 배율` 분에 비례해 압축된다.

### 1.3 비목표 (이번 Epic 밖)

- 맵별·스테이지별 별도 곡선 (VS 도서관/공장 등)
- 메타 진행·영구 업그레이드
- 몹 레벨 마스터表 전면 도입 (별도 Epic, 본 계획과 병행 가능)
- 특수 몹 A/B·보스 **고유 패턴 AI** (콘텐츠 Epic — 본 계획은 **등장 시각·수치·연출 훅**만)

---

## 2. 현재 vs VS — 갭 요약 (A·B·C 반영 후)

| 항목 | 구현 상태 (A·B·C) | VS (광기의 숲) | 잔여 (BACKLOG) |
|------|-------------------|----------------|----------------|
| 런 상한 | **30분 클리어**, 드랍 없음 | 30분 사신 즉사 | — |
| 곡선 형태 | 11분 피크·16~20 dip·25~28 spike (A) | 울퉁불퉁 | F 튜닝 |
| 보스 시각 | **25분** ON + B 보스 1체 | ~25분 + 하이퍼 | **E** 하이퍼 |
| 초반 타입 | fast 5분·ranged 8분 (A) | 0~8분 낮음 | F 튜닝 |
| 적 HP vs 플레이어 | `hp_multiplier`만 | × 플레이어 레벨 | **D** |
| 11분 물량 | 표 1.75 + B ×1.4 45초 | 스폰 급증 | F 체감 검증 |
| 40분 표 | 30분 plateau (35·40) | 30분 끝 | **Q2** 31~40 정책 |

**유지할 강점:** 무기 3택1·`WeaponDamageTracker`, 원거리 몹 텔레그래프, `ScenePool`, `balance_pace_multiplier`.

---

## 3. 목표 곡선 (개념)

```
난이도(체감)
  ↑                    ✓ 30분 클리어
  │                       ╱╲
  │                     ╱    ╲ 25~29 2차 스파이크
  │               25분 ╱
  │         11분 ╱╲
  │              ╱  ╲___ 16~24 호흡(밀도↓)
  │        9분╱
  │      ╱
  └──────────────────────────────────→ 시간(분)
   0    8   11      20   25        30
```

현재 곡선(단조):

```
  ↑                        ╭── 40 (plateau)
  │                  ╭─────╯
  │            ╭─────╯
  └──────────────────────────────────→
   0   10  18(보스)  20        40
```

---

## 4. 구현 단계 (Epic 분할)

의존 순서: **A → B → C** 필수에 가깝고, **D·E**는 병행/후순위.

### 단계 A — 키프레임 곡선 VS형 재작성 (데이터)

**범위:** `game/balance/default_balance_table.tres` (및 필요 시 `balance_phase.gd` 주석만).

**작업:**

1. **0~30분** 키프레임을 VS 리듬에 맞게 재배치 (아래 §5 표 초안).
2. **16~24분:** `spawn_density`를 11분 피크 대비 **낮추거나** 키프레임에서 명시적 dip (예: 15분 1.9 → 20분 1.6 → 24분 1.65).
3. **보스:** `boss_spawn_enabled` / `boss_spawn_ratio` 의미 있는 상승을 **24~25분**부터 (18분 ON 제거 또는 18분은 예고만).
4. **초반:** 0~8분 `fast_spawn_ratio`·`ranged_spawn_ratio` 상승을 **지연** (fast 4~5분, ranged 7~8분 등 — 플레이테스트로 미세 조정).
5. **31~40분:** 당장은 **30분 값 유지(plateau)** 또는 `design_intent`만 “클리어 후”로 표기. 별도 Epic에서 하드 모드.

**완료 정의:** `balance_pace_multiplier = 1.0`으로 30분까지 플레이 시, HUD 구간 문구·밀도·HP가 §5 표와 대략 일치.

**리스크:** 보간만으로 11분 **급증** 체감이 약할 수 있음 → 단계 B로 보완.

---

### 단계 B — 시간 이벤트 (스파이크·웨이브)

**범위:** 새 리소스/스크립트 + `game.gd` (또는 `BalanceDirector` 노드).

**제안 API (초안):**

```gdscript
# balance_timeline_event.gd (Resource) — 예시
@export var at_minute: float = 11.0
@export var density_mult: float = 1.4      # 일시 스폰 밀도 배수
@export var duration_seconds: float = 45.0
@export var one_shot_spawn_count: int = 0  # 0이면 미사용
@export var force_mob_scene: PackedScene   # null이면 기존 pick_scene
```

**필수 이벤트 (VS 대응):**

| 분 | 이벤트 | VS 대응 |
|----|--------|---------|
| 9 | elite 1체 또는 `mob_boss` 미니 스폰 + 짧은 HUD 경고 | 거대 박쥐 |
| 11 | `density_mult` 1.3~1.5, 30~60초 | 1차 커트라인 |
| 25 | 보스 1체 guaranteed + `hyper_mode` ON (단계 E) | 맵 보스 |
| 28~29 | `density_mult` 또는 ranged 비율 일시 상향 | 후반 포위 |

**완료 정의:** 11분·25분 전후에 체감 가능한 압박 변화; 일시정지 시 이벤트 타이머도 정지 (`create_timer` / `_is_balance_clock_running` 정책과 일치).

**Must not:** `Game.spawn_mob()` / `MobSpawnSelector` / 풀 계약 우회 스폰 금지.

---

### 단계 C — 30분 클리어 (✅ Q1 확정: C1)

**범위:** `game/game.gd`, `entities/mob/mob.gd`, `survivors_game.tscn`, UI.

**기획 확정 (2025-05):**

| 항목 | 규칙 |
|------|------|
| 마감 방식 | 실시간 **30:00** 도달 시 **클리어** (사신 즉사 없음) |
| 전장 정리 | `mobs` 그룹에 있는 **모든 활성 몹** 즉시 사망 처리 |
| 드랍 | 클리어로 죽는 몹은 **경험치 오브·자석·체력 픽업 드랍 없음** |
| VS 대비 | 30분 “승리 마감”에 가깝고, VS 사신 연출은 **미적용** |

**클리어 시퀀스 (런타임 순서):**

1. `_elapsed_seconds >= RUN_CLEAR_SECONDS` (기본 `1800`, `balance_pace_multiplier`로는 **표 축 30분** = `1800 / pace` 실시간 초 — §C.1 참고).
2. 스폰 `Timer.stop()` — 추가 스폰 중단.
3. `get_tree().get_nodes_in_group("mobs")` 순회 → 각 `Mob`에 **클리어 전용 사망** 호출.
4. (선택) 짧은 연출 대기 0.3~0.5초 후 UI — 연출 없이 즉시 UI도 가능.
5. `%GameOver` 또는 `%StageClear` 패널 **성공 문구** + 기존 무기별 피해 통계(선택) 표시.
6. `get_tree().paused = true`. 플레이어 입력·F 자동공격 등 `is_game_over()`와 동일 차단.

**클리어 몹 사망 vs 일반 사망 (`mob.gd` `_die()`):**

| | 일반 `_request_die()` | 클리어 `die_from_stage_clear()` |
|--|----------------------|----------------------------------|
| 연기 `smoke_explosion` | ✅ 스폰 | ✅ 유지 권장 (피드백) |
| 경험치 오브 | ✅ `ScenePool.acquire` | ❌ |
| 자석 1% | ✅ | ❌ |
| 체력 1% | ✅ | ❌ |
| `Game.register_kill()` | ✅ | ❌ (처치 수 인플레 방지) |
| `died` 시그널 | ✅ | ✅ (리스너 있으면 동작) |
| `PoolUtil.release_node` | ✅ | ✅ |

**UI:**

- `GameOver/.../Label` → 클리어 시 `"클리어!"` / `"생존 성공"` 등 (패배 `"Game Over"`와 분기).
- `is_game_over()` → 패배·클리어 **둘 다 true**로 처리해 무기 선택·일시정지 재개 방지 (`_run_ended` 플래그 권장).

**완료 정의:**

- 30분(1.0×) 도달 시 화면 몹 전멸, 바닥에 **새 오브/픽업 없음**.
- 클리어 후 재시작 시 씬 리로드로 상태 초기화.
- 테스트 아레나(F6)는 클리어 로직 **비활성** 또는 `test_arena.gd` 스텁 유지.

#### C.1 구현 스펙 (코드 초안)

**`game.gd`**

```gdscript
const RUN_CLEAR_SECONDS := 1800.0  # 표 30분 @ pace 1.0

var _run_cleared := false
var _run_failed := false  # health_depleted

func _process(delta):
    # ... 기존 ...
    if _game_started and not _run_cleared and not _run_failed:
        if _elapsed_seconds >= _get_clear_elapsed_seconds():
            _trigger_stage_clear()

func _get_clear_elapsed_seconds() -> float:
    if not balance_table:
        return RUN_CLEAR_SECONDS
    # 표 30분 지점 = 30 * 60 / balance_pace_multiplier
    return 30.0 * 60.0 / maxf(balance_table.balance_pace_multiplier, 0.01)

func _trigger_stage_clear() -> void:
    _run_cleared = true
    $Timer.stop()
    for node in get_tree().get_nodes_in_group("mobs"):
        if node is Mob and node.has_method(&"die_from_stage_clear"):
            (node as Mob).die_from_stage_clear()
    _show_stage_clear()  # GameOver 패널 성공 변형

func is_game_over() -> bool:
    return _run_cleared or _run_failed or %GameOver.visible
```

**`mob.gd`**

```gdscript
var _stage_clear_death := false

func die_from_stage_clear() -> void:
    if _is_dying:
        return
    _stage_clear_death = true
    health = 0
    _request_die()

func _die() -> void:
    # died.emit() — 유지
    var game := get_node_or_null("/root/Game")
    if not _stage_clear_death:
        if game and game.has_method("register_kill"):
            game.register_kill()
        # smoke, exp, magnet, health — 기존 블록
    else:
        # 연기만 (선택) 또는 연기도 생략 — 기획: 연기 유지
        var smoke = smoke_scene.instantiate()
        ...
    PoolUtil.release_node(self)

func pool_reset() -> void:
    _stage_clear_death = false
    # ...
```

**Must not:**

- 클리어 사망 경로에서 `instantiate` exp/magnet/health.
- 클리어 중 `spawn_mob()` 추가 호출.
- `register_kill()`로 30분 순간 처치 수 급증.

**`balance_pace_multiplier`:** 마감 실시간 = `1800 / pace`. 2.0이면 **15분**에 클리어.

---

### 단계 D — 플레이어 레벨 ↔ 몹 HP (선택)

**범위:** `mob.gd` `initialize_spawn_health`, `game.gd` `spawn_mob`.

**공식 (초안):**

```
final_hp = base_max_health * phase.hp_multiplier * f(player.level)
f(L) = 1.0 + (L - 1) * 0.05   # 튜닝 가능
```

VS의 “빌드가 강하면 적도 단단해짐”에 가깝게 맞춤. **단계 A만으로도 곡선은 가능** — D는 체감 미세 조정.

---

### 단계 E — 하이퍼 모드 (25분)

**범위:** `game.gd` 플래그 `_hyper_mode` + 스폰/페이즈 쿼리 시 배수.

**초안:** 25분부터 `spawn_density × 1.15`, `hp_multiplier × 1.1` (이벤트와 중복 시 상한 캡).

VS 25분 하이퍼 해제에 상응. `BalanceNoticeBanner`에 “HYPER” 표시.

---

### 단계 F — 문서·튜닝·규칙

- [`AGENTS.md`](../AGENTS.md) 밸런스 섹션: VS 정렬 후 구간 표 갱신.
- [`BACKLOG.md`](../BACKLOG.md): 본 Plan 링크, 완료 시 체크리스트 반영.
- (선택) `.cursor/rules/godot-balance.mdc` — spawn/키프레임/이벤트 must.
- 플레이테스트 시트: 0·9·11·18·25·30분 스냅샷 (HP, 밀도, alive mobs).

---

## 5. 키프레임 초안 (0~30분, `balance_pace_multiplier = 1.0`)

**주의:** 수치는 **시작점**이며, 단계 A 적용 후 F6/F5 플레이테스트로 조정한다.  
`special_mob_count`·`boss_spawn_enabled`는 기존처럼 **계단형** (`BalanceTable._finalize_phase`).

| 분 | hp_mult | spawn_density | fast | ranged | elite | special | special# | boss | boss_on | design_intent |
|----|---------|---------------|------|--------|-------|---------|----------|------|---------|---------------|
| 0 | 1.0 | 1.0 | 0 | 0 | 0 | 0 | 0 | 0 | false | VS 0~8: 적응 |
| 4 | 1.12 | 1.05 | 0 | 0 | 0 | 0 | 0 | 0 | false | 완만 상승 |
| 5 | 1.18 | 1.08 | 0.08 | 0 | 0 | 0 | 0 | 0 | false | fast 지연 |
| 8 | 1.35 | 1.12 | 0.12 | 0.08 | 0 | 0 | 0 | 0 | false | 0~8 종료 |
| 9 | 1.42 | 1.25 | 0.12 | 0.1 | 0.05 | 0 | 0 | 0 | false | 9분 스파이크(표만, B에서 강화) |
| 11 | 1.55 | **1.75** | 0.15 | 0.15 | 0.06 | 0.04 | 1 | 0 | false | **1차 커트라인** |
| 14 | 1.75 | 1.55 | 0.18 | 0.2 | 0.08 | 0.06 | 1 | 0 | false | 스파이크 후 완만 하강 시작 |
| 16 | 1.9 | **1.35** | 0.18 | 0.22 | 0.08 | 0.08 | 2 | 0 | false | **호흡** 밀도↓ |
| 20 | 2.1 | **1.25** | 0.2 | 0.25 | 0.1 | 0.08 | 2 | 0 | false | 호흡 유지 |
| 24 | 2.35 | **1.3** | 0.2 | 0.28 | 0.12 | 0.1 | 2 | 0.04 | false | 25분 전 ramp |
| 25 | 2.5 | **1.85** | 0.22 | 0.3 | 0.12 | 0.1 | 2 | 0.12 | **true** | 보스 + 하이퍼(E) |
| 28 | 2.75 | **2.0** | 0.22 | 0.35 | 0.14 | 0.1 | 2 | 0.18 | true | 2차 스파이크 |
| 30 | 2.9 | 2.1 | 0.22 | 0.35 | 0.14 | 0.1 | 2 | 0.2 | true | 표 상한(마감 직전) |

**31~40분 (후순위):** 30분 값 고정 복제 또는 `minute=40`에 소폭만 상향 (하드 서바이벌 모드용).

**제거·이동 요약 (현재 표 대비):**

- 1분 간격 0~10 촘촘 키프레임 → **위 표 간격으로 대체** (인스펙터 가독성↑).
- 18분 보스 ON → **25분**으로 이동.
- 20~40 완만 상승 구간 → **16~24 dip + 25~30 spike**로 교체.

---

## 6. 변경 파일 맵

| 단계 | 파일 (예상) |
|------|-------------|
| A | `game/balance/default_balance_table.tres` |
| B | `game/balance/balance_timeline.gd` (신규), `balance_timeline_event.gd` (신규), `game/game.gd`, `survivors_game.tscn` |
| C | `game/game.gd`, `entities/mob/mob.gd`, `survivors_game.tscn`, UI (`%GameOver` 성공 분기) |
| D | `entities/mob/mob.gd`, `game/game.gd` |
| E | `game/game.gd`, `ui/balance_notice_banner.gd` |
| F | `AGENTS.md`, `BACKLOG.md`, 본 문서 상태 갱신 |

**grep 필수 (경로·계약):** `/root/Game`, `spawn_mob`, `initialize_spawn_health`, `MobSpawnSelector`, `godot-core.mdc`, `godot-pool.mdc`, `godot-mobs.mdc`.

---

## 7. Invariants & Gotchas

에이전트·구현 시 **절대 깨지면 안 되는 것** (`.cursor/rules` 요약):

- 스폰은 `Game.spawn_mob()` → `ScenePool.acquire` → `initialize_spawn_health` (D 적용 시 시그니처 확장만).
- 루트 노드 `Game`, `%` 노드, 그룹 `mobs` 이름 유지.
- 무기 선택·일시정지 중 `_is_balance_clock_running` false — 이벤트 타이머도 동일 정책.
- `boss_spawn_enabled` / `special_mob_count`는 선형 보간하지 않음 (기존 `BalanceTable` 규칙).
- 스폰 비율 합 > 1 시 `_normalize_spawn_ratios` — 11·28분에 비율 급증 시 합산 확인.
- `test_arena.gd`는 밸런스 시계 없음 — 메인 `survivors_game` F5로 검증.

**함정:**

- 11분 `spawn_density`만 올리고 `max_alive_mobs`(100)에 막히면 체감 스파이크 약함 → B의 burst 또는 일시 상한 상향 검토.
- `balance_pace_multiplier = 2.0`이면 15분에 30분 곡선 도달 → **30분 마감**은 실시간 15분이 됨; 마감 시각도 `30 / multiplier`로 문서화.
- 플레이어 레벨 D 도입 시 테스트 아레나 `_get_test_mob_hp_multiplier()`(Dummy vs 10×)와 분리 유지.

---

## 8. 테스트 계획

| # | 시나리오 | 확인 |
|---|----------|------|
| 1 | 신규 게임, 0~8분 | fast/ranged 낮은 비율, 사망률 낮음 |
| 2 | 9~12분 | 11분 전후 몹 수·압박 체감 상승 (B 포함 시 더 명확) |
| 3 | 14~22분 | 16~24 밀도 dip — “숨 고르기” 체감 |
| 4 | 24~27분 | 보스 스폰·하이퍼 HUD |
| 5 | 30분 | 클리어(C): 타이머 정지, 전장 몹 소거, **오브·자석·체력 드랍 0**, 성공 UI, 처치 수 급증 없음 |
| 5b | 클리어 직후 | 바닥 픽업 개수 변화 없음, `paused` 후 재시작 정상 |
| 6 | `balance_pace_multiplier` 2.0 | 실시간 15분 ≈ 30분 곡선, 마감 15분 |
| 7 | 무기 선택·Esc 일시정지 | 이벤트·시계 정지 |
| 8 | F6 테스트 아레나 | 회귀 없음 (스폰 밸런스 무관) |

**스냅샷 로그 (선택):** 디버그 키로 `elapsed`, `hp_multiplier`, `spawn_density`, `alive_mobs` CSV.

---

## 9. 의사결정 로그

| ID | 질문 | 결정 | 비고 |
|----|------|------|------|
| **Q1** | 30분 마감 | **✅ C1 클리어** | 전장 몹 일괄 사망; **드랍 없음**; `register_kill` 없음 |
| Q2 | 31~40분 | (미정) | plateau (30분 값) 권장 |
| Q3 | 9분 이벤트 | (미정) | B + 표 권장 |
| Q4 | 플레이어 레벨 HP | (미정) | A·B·C 후 D |
| Q5 | 18분 보스 제거 | (미정) | 25분 ON 권장 |

### Q1 부록 — 클리어 드랍 제외 범위

- **제외:** `exp_orb`, `magnet_pickup`, `health_pickup` (`mob.gd` `_die()` 내 블록).
- **포함 여부 (구현 시 기본):** `smoke_explosion` VFX — 유지. `died` 시그널 — 유지.
- **제외:** 몹 투사체·예고 마크는 클리어 전에 `_cancel_ranged_telegraph()`로 정리.

---

## 10. 진행 체크리스트

- [x] **A** — `default_balance_table.tres` VS형 0~30 키프레임 (16~24 밀도 dip, 보스 25분)
- [x] **B** — 타임라인 이벤트 (`default_balance_timeline.tres`, 9·11·25·28분)
- [x] **C** — 30분 클리어 (Q1: 전장 몹 소거, 드랍 없음, 성공 UI) — `game.gd`, `mob.gd`, `%GameOverTitle`
- [ ] **D** — 몹 HP × 플레이어 레벨 → **BACKLOG**
- [ ] **E** — 하이퍼 모드 25분 → **BACKLOG**
- [ ] **F** — 플레이테스트·튜닝·(선택) `godot-balance.mdc` → **BACKLOG**

**문서:** AGENTS·BACKLOG·본 Plan §0 갱신 완료. Epic 전체 “완료”는 F 튜닝 후 판단.

---

## 11. 참고 — VS 원곡선 요약 (조사 메모)

- 0~8분: 낮음, 기본 적  
- 9분: 거대 박쥐 (체력·넉백)  
- 11분: 물량 급증 (1차 커트라인)  
- 16~24분: 스폰 완화, 튼튼한 적  
- 25분: 맵 보스 + 하이퍼  
- 25~29분: 재급상승  
- 30분: 사신 즉사  

**우리 게임(Q1):** 30분 **클리어**(사신 없음) + 전장 몹 소거(드랍 없음).

출처: 나무위키 스테이지 항목, Reddit 스폰/스케일링 논의 (플레이어 제공 조사본). 수치는 VS 내부 데이터가 아닌 **체감 구간** 기준으로 매핑한다.

---

## 12. Change Guidelines (에이전트용)

- 한 PR에 **단계 하나** 권장 (A만 / B만 / C만). 곡선 + 클리어 + 하이퍼 한꺼번에 X.  
- 단계 C: `die_from_stage_clear()` 경로만 드랍 차단 — 일반 `_die()` 회귀 테스트 필수.  
- `BalancePhase` 필드 추가 시 `balance_table.gd` `_lerp_phases`·`_compute_phases_cache_key`·`_finalize_phase` 동시 검토.  
- 새 몹 씬 없이 9·25분 이벤트는 기존 `mob_boss` / `mob_elite` 재사용.  
- UI 문자열 한국어, 코드 주석 한 줄 한국어 (기존 `.gd` 스타일).
