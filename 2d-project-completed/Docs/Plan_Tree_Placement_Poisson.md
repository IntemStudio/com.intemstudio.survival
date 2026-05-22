# Plan — 소나무 장애물 배치 (Poisson Disk Sampling)

**상태:** **미구현** (설계·제안 문서) — 현재는 `survivors_game.tscn` 수동 배치 11그루  
**작성 목적:** Unity/일반 게임에서 검증된 **Poisson Disk Sampling + 예약 구역 + 반경 밀도**를 Godot 2D Survival 프로젝트(`MapArena`, `pine_tree`)에 맞게 정리한다.  
**관련:** [`AGENTS.md`](../AGENTS.md) 고정 맵 경계·`world/trees/`, [`BACKLOG.md`](../BACKLOG.md) 맵·장식, `world/map_arena/map_arena.gd`

---

## 1. Overview

### 1.1 목표

- `%MapArena` 직사각형 **플레이 영역 안**에 소나무(`pine_tree.tscn`)를 **듬성듬성·자연스럽게** 배치한다.
- 나무가 한쪽에 뭉치거나 서로 겹치지 않도록 **최소 간격**을 보장한다.
- **밀도 튜닝**은 슬라이더 하나(최소 거리 `tree_min_spacing`)로 시작한다.
- 플레이어 시작·벽 근처는 **금지 구역**으로 비워 실제 플레이 가능한 장애물 맵을 만든다.

### 1.2 성공 기준 (구현 후)

| 항목 | 기대 |
|------|------|
| 밀도 | `tree_min_spacing`만 바꿔도 나무 수가 눈에 띄게 변함 |
| 분포 | 시각적으로 균일 격자가 아닌, 뭉침·과밀 구간이 드묾 |
| 시작 | `(0, 0)` 근처 반경 안에 나무 없음 |
| 몹 스폰 | 나무 위 스폰이 거의 없음(기존 `MapArena` layer 1 검사와 시너지) |
| 이동 | (선택) 플레이어에서 넓은 영역 도달 가능 — 막힌 맵 재시드 |

### 1.3 왜 Poisson Disk인가

| 방식 | 문제 |
|------|------|
| 완전 랜덤 | 뭉침·붙음·한쪽 쏠림 |
| 격자 배치 | 인공적 |
| **Poisson (Bridson)** | 샘플 간 최소 거리 `r` 강제 → 블루 노이즈에 가까운 분포, 오브젝트 배치 대표 사례 |

**밀도:** `r`을 크게 → 나무 수 감소, 작게 → 증가. “소나무 밀도” 슬라이더를 **`tree_min_spacing`(= Poisson 반경)** 에 연결하는 것이 1차 구현에 가장 단순·안정적이다.

---

## 2. 현재 구현 (기준선)

| 항목 | 내용 |
|------|------|
| 나무 프리팹 | `world/trees/pine_tree.tscn` — `StaticBody2D`, 원형 충돌 **r ≈ 22.5**, 기본 **physics layer 1** |
| 배치 | `survivors_game.tscn`에 `pine_tree` 인스턴스 **11개**, 각 `position` 수동 지정 |
| 생성 스크립트 | 없음 (`pine_tree.gd` 없음) |
| 밀도 파라미터 | 없음 |
| 테스트 아레나 | `test_arena.tscn` — 나무 없음 |
| 맵 경계 | `%MapArena` — `arena_rect` 기본 `Rect2(-1055, -697, 2112, 1368)`, 벽·`spawn_margin` 96 |
| 몹 스폰 | `get_random_spawn_position()` — layer 1 `intersect_shape`(반경 52, 최대 12회)로 나무·벽 겹침 회피 |

**주의:** `spawn_density`(`default_balance_table.tres`)는 **몹 웨이브** 전용이며 나무와 무관하다.

---

## 3. 제안 아키텍처 (Godot)

Unity 조사에서 제안된 5분할을 이 프로젝트 경로·노드에 대응한다.

| 역할 | Unity 예시 | Godot 제안 |
|------|------------|------------|
| 방 경계 | `RoomBounds` | `MapArena.arena_rect` + `wall_padding`으로 축소한 `sample_rect` |
| 금지 구역 | `ReservedArea[]` | `Rect2` / 원형 금지 목록, `IsAllowed(point)` |
| 설정 | `TreePlacementSettings` | `MapArena` `@export` 그룹 또는 `TreePlacementSettings.tres` |
| 샘플러 | `PoissonSampler` | `world/trees/poisson_sampler.gd` (`RefCounted`, 순수 로직) |
| 스포너 | `TreeSpawner` | `MapArena._spawn_trees()` → 자식 `Obstacles` 노드에 `pine_tree` 인스턴스 |

### 3.1 런타임 흐름

```text
_ready (MapArena)
  → _rebuild_walls()
  → _rebuild_trees()          # 신규
       → sample_rect = arena_rect.grow(-wall_padding)
       → points = PoissonSampler.sample(sample_rect, tree_min_spacing, ...)
       → 각 point: IsAllowed? → pine_tree.tscn 인스턴스 → Obstacles.add_child
       → (선택) scale/rotation 랜덤

spawn_mob (game.gd)
  → get_random_spawn_position()   # 기존 — 생성된 나무 layer 1과 충돌 검사
```

### 3.2 씬 정리 (구현 시)

- `survivors_game.tscn`의 `PineTree` ~ `PineTree11` **삭제**
- 나무는 **오직** `MapArena` 생성 경로만 사용
- `test_arena`: `@export var spawn_trees: bool = false` 또는 동일 `MapArena` export로 끄기

### 3.3 좌표계

- Poisson은 **`MapArena` 로컬** 좌표에서 샘플링
- 인스턴스 `position` = 로컬 점 (부모가 `MapArena`이면 `global_position` = `to_global(point)`)
- 몹 스폰 API는 이미 **글로벌** 반환 — 패턴 일치

---

## 4. Poisson Disk Sampling (Bridson)

### 4.1 알고리즘 요약

1. 유효 영역 `sample_rect`와 최소 거리 **`radius`**(`tree_min_spacing`) 설정
2. **`cell_size = radius / sqrt(2)`** 보조 그리드
3. 허용된 첫 점 하나 랜덤 배치 → `active` 리스트에 추가
4. `active`에서 점 하나 선택 → 중심 기준 **`radius` ~ `2×radius` 고리**에서 후보 최대 **k**번 생성
5. 후보가 맵 안·금지 구역 밖·이웃 셀 점들과 모두 **≥ radius** 이면 채택
6. 더 이상 후보 없으면 해당 active 제거; `active` 비면 종료

### 4.2 GDScript 의사코드

```gdscript
# poisson_sampler.gd — RefCounted
static func sample(
    bounds: Rect2,
    radius: float,
    is_allowed: Callable,  # func(Vector2) -> bool
    k: int = 30,
    rng: RandomNumberGenerator = null
) -> PackedVector2Array:
    var cell_size := radius / sqrt(2.0)
    # grid: Dictionary[Vector2i, Vector2]
    # active: Array[Vector2]
    # ... Bridson 루프, 후보마다 is_allowed.call(candidate) 및 grid 이웃 거리 검사
    return points
```

### 4.3 `IsAllowed` (예약 구역)

| 규칙 | 제안 | 비고 |
|------|------|------|
| 샘플 영역 | `sample_rect.has_point(p)` | `arena_rect.grow(-wall_padding)` |
| 플레이어 스폰 | 원심 `(0, 0)`, 반경 **200~350** | `player_clear_radius` export |
| 벽 | `wall_padding`으로 sample_rect 자체가 안쪽 | 출입구 없음 — 문 금지 구역 불필요 |
| 맵 중앙 전투 | (선택) 중앙 원/사각형 금지 | “가장자리만 숲” 연출 시 |
| 기존 충돌체 | (선택) layer 1 `intersect_point` | 수동 나무와 공존 시에만 |

**1차 구현:** `wall_padding` + `player_clear_radius` 만으로 충분한 경우가 많다.

---

## 5. 밀도·충돌·몹 스폰 정렬

### 5.1 반경 vs `pine_tree` 충돌

| 값 | 약 | 용도 |
|----|-----|------|
| 나무 충돌 반경 | ~22.5 | `pine_tree.tscn` `CircleShape2D` |
| Poisson `tree_min_spacing` | **120~220** (튜닝) | 중심 간 최소 거리 — **≥ 45~55** 이상이면 원 충돌 겹침 방지 |
| 몹 스폰 검사 반경 | 52 | `MapArena.SPAWN_TEST_RADIUS` |

**권장:** 듬성듬성 장애물 → `tree_min_spacing` **150~180** 부터 플레이 테스트.  
간격이 52에 가까우면 몹 스폰이 “빈 칸”을 거의 못 찾는다.

### 5.2 밀도 조절 단계 (우선순위)

1. **반경만** — `tree_min_spacing` export (필수)
2. **가중치 맵** — 위치별 `radius` 가변 (2차)
3. **후처리 제거** — Poisson 후 N% 제거 (1차 비추천)

### 5.3 시드

```gdscript
@export var tree_spawn_seed: int = 0  # 0 = 랜덤, 그 외 고정 시드
```

리플레이·회귀 테스트·막힌 맵 재생성에 유리하다.

---

## 6. Export 파라미터 초안 (`MapArena` 또는 Resource)

| Export | 제안 기본값 | 설명 |
|--------|-------------|------|
| `spawn_trees` | `true` | 테스트 아레나에서 `false` 가능 |
| `tree_scene` | `pine_tree.tscn` | `PackedScene` |
| `tree_min_spacing` | `160` | Poisson 최소 거리 (= 밀도) |
| `wall_padding` | `96` | `spawn_margin`과 맞추면 일관 |
| `player_clear_radius` | `280` | `(0,0)` 금지 원 |
| `rejection_samples` | `30` | Bridson k |
| `tree_spawn_seed` | `0` | 고정 시드 / 랜덤 |
| `tree_scale_min` / `tree_scale_max` | `0.9` / `1.1` | 4단계 비주얼 (스프라이트만) |
| `tree_rotation_max_deg` | `15` | 4단계 비주얼 |

**에디터:** `arena_rect` / 벽과 같이 `call_deferred("_rebuild_trees")` — `@tool` 선택 시 씬 편집 프리뷰 가능.

---

## 7. 구현 단계

| 단계 | 내용 | 완료 조건 |
|------|------|-----------|
| **1** | `poisson_sampler.gd` + `MapArena`에서 점만 로그/디버그 draw | `sample_rect` 안 점 분포 확인 |
| **2** | `player_clear_radius` + `wall_padding` + `IsAllowed` | 시작 구간·벽 근처 비움 |
| **3** | `pine_tree` 인스턴스, 수동 11개 제거, `tree_min_spacing` 튜닝 | F5에서 밀도·분포 만족 |
| **4** | 스케일·회전 랜덤 (충돌은 고정 유지 권장) | 비주얼만 자연스러움 |
| **5** | (선택) 플레이어 flood-fill 연결성 검사, 실패 시 시드 변경 | 극단적 막힘 방지 |

### 7.1 5단계 — 이동 가능성 (선택)

- 그리드 또는 4방향 BFS로 `(0,0)`에서 도달 가능 면적 비율 계산
- 나무·벽 셀을 막힌 칸으로 처리
- 도달 비율 &lt; 임계(예 40%)이면 `tree_spawn_seed` 바꿔 1~3회 재시도

---

## 8. 폴리시·자연스러움

- **동일 간격만**이면 인공적 → 배치 후 **회전·스케일** 약간 (충돌 원은 그대로가 구현 단순)
- “완전 숲”이 아니라 **장애물** 목적이면 `tree_min_spacing`을 크게, 또는 **가장자리만** 샘플링하는 비대칭 규칙(2차)
- 멀티 종·멀티 반경 Poisson은 1차 범위 밖

---

## 9. 기존 시스템과의 관계

| 시스템 | 관계 |
|--------|------|
| `%MapArena` 벽 | layer 1, `sample_rect`는 벽 안쪽 |
| `game.spawn_mob()` | `%MapArena.get_random_spawn_position()` 유지 — 나무 생성 후 겹침 더 줄어듦 |
| `pine_tree` | `StaticBody2D` 유지 — 플레이어·몹·탄환 `collision_mask` 3과 기존 동일 |
| `spawn_density` | 몹 전용, 나무와 분리 |
| `.mdc` | layer 1 변경 시 `godot-core.mdc` 일괄 grep |

---

## 10. 변경 파일 맵 (구현 시 예상)

| 파일 | 변경 |
|------|------|
| `world/trees/poisson_sampler.gd` | **신규** — Bridson 샘플러 |
| `world/map_arena/map_arena.gd` | `_rebuild_trees()`, export, `Obstacles` 자식 |
| `survivors_game.tscn` | 수동 `PineTree*` 제거 (`MapArena`만) |
| `test_arena.tscn` | (선택) `spawn_trees = false` |
| `AGENTS.md` | 고정 맵·나무 섹션 — Poisson 생성으로 갱신 |
| `BACKLOG.md` | 맵·장식 항목·체크리스트 **4i** (선택) |
| `.cursor/rules/godot-core.mdc` | 나무 layer 1 유지 명시 (필요 시) |

---

## 11. 문서·체크리스트 (구현 후)

**AGENTS.md 동기화**

- `world/trees/` — Poisson 생성, export 이름
- 고정 맵 경계 — 수동 11그루 문구 삭제

**BACKLOG**

- “맵·장식 (추가)” — Poisson 배치 완료 줄이기/이동
- 아이디어 “스폰 금지 구역 마커” — `player_clear_radius`로 부분 충족 시 정리

**작업 체크 (제안)**

```text
4i. 소나무 Poisson 배치 변경
  → poisson_sampler.gd, map_arena.gd, survivors_game.tscn
  → AGENTS.md, Docs/Plan_Tree_Placement_Poisson.md 상태 갱신
```

---

## 12. 참고 — Unity 조사 요약 (원문 대응)

조사에서 권장한 **“Poisson Disk Sampling + 예약 구역 + 반경 기반 밀도”** 를 Godot 2D Survival에 그대로 옮긴 것이 본 Plan이다.

| Unity 권장 | 본 프로젝트 대응 |
|------------|------------------|
| Poisson Disk (Bridson) | `poisson_sampler.gd` |
| 출입구/스폰/중앙 금지 | `player_clear_radius`, `wall_padding`, (선택) 중앙 금지 |
| radius 밀도 | `tree_min_spacing` |
| TreeSpawner | `MapArena._rebuild_trees()` |
| BFS 이동 검사 | 5단계 선택 |

---

## 13. 한 줄 결론

**지금:** 나무는 씬에 11개 수동 배치, 밀도 설정 없음.  
**다음:** `MapArena`가 벽·몹 스폰을 이미 담당하므로, **`PoissonSampler` + 금지 구역 + `tree_min_spacing`** 으로 나무까지 같은 노드에서 생성하는 것이 가장 자연스럽고, 기존 몹 스폰 겹침 회피와도 잘 맞는다.

---

*마지막 갱신: 2026-05-22 — `MapArena` 고정 맵·내부 몹 스폰 기준. 구현 완료 시 상단 **상태**를 “구현 완료”로 바꾸고 §2 기준선을 갱신한다.*
