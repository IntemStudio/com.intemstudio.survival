# Plan — 소나무 장애물 배치 (Poisson Disk Sampling)

**상태:** **구현 완료** — `MapArena` Poisson 생성, HUD 밀도 슬라이더, 메인 수동 나무 제거  
**작성 목적:** Unity/일반 게임에서 검증된 **Poisson Disk Sampling + 예약 구역 + 반경 밀도**를 Godot 2D Survival 프로젝트(`MapArena`, `pine_tree`)에 맞게 정리한다.  
**관련:** [`AGENTS.md`](../AGENTS.md) 고정 맵 경계·`world/trees/`, [`BACKLOG.md`](../BACKLOG.md) 맵·장식, `world/map_arena/map_arena.gd`

---

## 0. 구현 스냅샷 (코드 반영됨)

| 파일 | 역할 |
|------|------|
| `world/trees/poisson_sampler.gd` | `PoissonSampler.sample()` — Bridson |
| `world/map_arena/map_arena.gd` | `_rebuild_trees()`, export, `get/set_tree_density_normalized()` |
| `survivors_game.tscn` | `%MapArena` **3×** `arena_rect`·`spawn_margin` **씬 오버라이드**; `HUD/%TreeDensityGui` |
| `test_arena.tscn` | `%MapArena` 1× 기본값, `spawn_trees = false` |
| `ui/tree_density_settings.gd` | 슬라이더 → `MapArena.set_tree_density_normalized()` |

### 맵 크기 (메인 vs 테스트)

| 실행 | `arena_rect` | 비고 |
|------|--------------|------|
| **F5** 메인 | `Rect2(-3167, -2065, 6336, 4104)` | `survivors_game.tscn` 인스턴스 속성 — **스크립트 기본만 수정하면 F5는 안 바뀜** |
| **F6** / 스크립트 기본 | `ARENA_RECT_1X` = `(-1055, -697, 2112, 1368)` | `map_arena.gd` |

---

## 1. Overview

### 1.1 목표

- `%MapArena` 직사각형 **플레이 영역 안**에 소나무(`pine_tree.tscn`)를 **듬성듬성·자연스럽게** 배치한다.
- 나무가 한쪽에 뭉치거나 서로 겹치지 않도록 **최소 간격**을 보장한다.
- **밀도 튜닝**은 HUD `%TreeDensityGui` 슬라이더(`tree_spacing_dense`↔`sparse` → `tree_min_spacing`)로 한다.
- 플레이어 시작·벽 근처는 **금지 구역**으로 비워 실제 플레이 가능한 장애물 맵을 만든다.

### 1.2 성공 기준 (구현 후)

| 항목 | 기대 |
|------|------|
| 밀도 | `tree_min_spacing`·HUD 슬라이더만으로 나무 수가 눈에 띄게 변함 |
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
| 샘플러 | `world/trees/poisson_sampler.gd` (`PoissonSampler`, Bridson) |
| 배치 | `map_arena.gd` `_rebuild_trees()` → 자식 `Obstacles`에 `pine_tree` 인스턴스 |
| 밀도 | `tree_spacing_dense` 50 · `tree_spacing_sparse` 960 · `tree_min_spacing` 기본 **50%**(≈505) |
| HUD 밀도 | `%TreeDensityGui` — 슬라이더 **0%=희박**(간격 `tree_spacing_sparse` 960) · **100%=밀집**(50) · **기본 50%**(≈505); 드래그 중 즉시 `_rebuild_trees()` |
| 금지 구역 | `wall_padding`(288) + `player_clear_radius`(280), 원심 `(0,0)` |
| 테스트 아레나 | `spawn_trees = false` |
| 맵 경계 | 메인 3× / F6·스크립트 1× — §0 표 |
| 몹 스폰 | `get_random_spawn_position(exclude_near_world?)` — layer 1, r=52, 12회; 메인은 플레이어 위치 제외(`mob_spawn_player_clear_extra`) |

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
| 스포너 | `TreeSpawner` | `MapArena._rebuild_trees()` → 자식 `Obstacles`에 `pine_tree` |

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
  → get_random_spawn_position(player_pos)   # 나무 layer 1 검사 + 플레이어 근처 금지
```

### 3.2 씬 정리 (완료)

- `survivors_game.tscn` 수동 `PineTree*` **제거** — `%MapArena` + `%TreeDensityGui`만
- 나무는 **오직** `MapArena._rebuild_trees()` 경로
- `test_arena.tscn`: `spawn_trees = false`

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
| Poisson `tree_min_spacing` | **50~960+** (`tree_spacing_dense`~`sparse` export) | 슬라이더 0%=sparse(기본 960); 대형 맵은 sparse 1200+ 권장 |
| 몹 스폰 검사 반경 | 52 | `MapArena.SPAWN_TEST_RADIUS` |

**권장 (메인 3× 맵):** 듬성듬성 → 슬라이더 **0%** 또는 `tree_spacing_sparse` **960~1400**. 1× 테스트 맵은 **150~300**부터.  
간격이 **52**에 가까우면(밀집 100% 근처) 몹 스폰이 빈 칸을 거의 못 찾는다.

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

## 6. Export 파라미터 (`MapArena` — 구현값)

| Export | 기본값 | 설명 |
|--------|--------|------|
| `spawn_trees` | `true` | `test_arena.tscn`: `false` |
| `tree_scene` | `pine_tree.tscn` | |
| `tree_spacing_dense` / `sparse` | `50` / `960` | HUD 100%↔0%; `TREE_DENSITY_DEFAULT` 0.5 → `tree_min_spacing` ≈505 |
| `tree_min_spacing` | `TREE_MIN_SPACING_DEFAULT` | `lerpf(sparse, dense, 0.5)`; 슬라이더·인스펙터 직접 설정 가능 |
| `wall_padding` | `288` | 나무 샘플 영역 shrink (3× 맵 기준; 1× 테스트는 나무 off) |
| `spawn_margin` | `96` (스크립트) / **288** (메인 씬) | 몹 스폰 |
| `player_clear_radius` | `280` | `(0,0)` 금지 원 |
| `rejection_samples` | `30` | Bridson k |
| `tree_spawn_seed` | `0` | 0 = 랜덤 |
| `tree_scale_min` / `max` | `0.9` / `1.1` | 스프라이트만 |
| `tree_rotation_max_deg` | `15` | |

**HUD API:** `get_tree_density_normalized()` / `set_tree_density_normalized(0~1)` — `tree_density_settings.gd` 연동.

**에디터:** `arena_rect`·나무 export 변경 시 `call_deferred("_rebuild_walls")` / `_rebuild_trees()`.

---

## 7. 구현 단계

| 단계 | 내용 | 상태 |
|------|------|------|
| **1** | `poisson_sampler.gd` | ✅ |
| **2** | 금지 구역 (`wall_padding`, `player_clear_radius`) | ✅ |
| **3** | `pine_tree` 인스턴스, 수동 나무 제거 | ✅ |
| **4** | 스케일·회전 랜덤 | ✅ |
| **5** | BFS 연결성·재시드 | ⬜ BACKLOG |
| **HUD** | `%TreeDensityGui` 실시간 재배치 | ✅ |

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
| `game.spawn_mob()` | `get_random_spawn_position(%Player.global_position)` — 나무 생성 후 겹침·플레이어 근처 금지 |
| `pine_tree` | `StaticBody2D` 유지 — 플레이어·몹·탄환 `collision_mask` 3과 기존 동일 |
| `spawn_density` | 몹 전용, 나무와 분리 |
| `.mdc` | layer 1 변경 시 `godot-core.mdc` 일괄 grep |

---

## 10. 변경 파일 맵 (구현됨)

| 파일 | 변경 |
|------|------|
| `world/trees/poisson_sampler.gd` | Bridson 샘플러 |
| `world/map_arena/map_arena.gd` | 벽·나무·스폰·밀도 API |
| `ui/tree_density_settings.gd` | HUD 슬라이더 |
| `survivors_game.tscn` | `%MapArena` 3×, `%TreeDensityGui`, 수동 `PineTree*` 없음 |
| `test_arena.tscn` | `spawn_trees = false` |
| `AGENTS.md` | §고정 맵·소나무(Poisson)·작업 표 |
| `BACKLOG.md` | §4j 체크리스트·맵·장식 |

---

## 11. 문서·체크리스트

**맵 크기 수정 시:** `survivors_game.tscn` `%MapArena` + `AGENTS.md` §고정 맵 경계 + 본 Plan §0.

**소나무·밀도 수정 시:** `map_arena.gd`, `tree_density_settings.gd`, `BACKLOG.md` **4j**.

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

**구현됨:** `PoissonSampler` + `_rebuild_trees()` + `tree_spacing_dense`(50)~`sparse`(960) + HUD 실시간 밀도(기본 50%). 메인 3× 맵은 `survivors_game.tscn` `%MapArena` 오버라이드. 남은 선택 과제: BFS 막힘 재시드(BACKLOG).

---

*마지막 갱신: 2026-05-22 — sparse 960·기본 밀도 50%·HUD `%TreeDensityGui`·메인/F6 맵 분리.*
