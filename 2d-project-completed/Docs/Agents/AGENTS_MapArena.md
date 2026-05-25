# MapArena — 맵 경계·스폰·소나무

**진입:** [`AGENTS.md`](../../AGENTS.md) · 에이전트 must: [`.cursor/rules/godot-core.mdc`](../../.cursor/rules/godot-core.mdc)

메인·테스트 씬이 **같은 `map_arena.tscn` 프리팹**을 쓰지만, **맵 크기는 씬별로 다릅니다.** 예전 `Player/Path2D`·`%PathFollow2D` 테두리 스폰은 제거됨.

## 맵 크기 — 메인(F5) vs 테스트(F6)

| 구분 | `arena_rect` (크기) | `spawn_margin` | 소나무 |
|------|---------------------|----------------|--------|
| **메인** `survivors_game.tscn` | **6336×4104** — `Rect2(-3167, -2065, 6336, 4104)` **씬 인스턴스 오버라이드** | **288** (씬 오버라이드) | Poisson 생성 (`spawn_trees` 기본 true) |
| **스크립트·F6** `map_arena.gd` / `test_arena.tscn` | **2112×1368** — `ARENA_RECT_1X` | **96** — `SPAWN_MARGIN_1X` | `test_arena`: `spawn_trees = false` |

**Must not (맵 크기):** `map_arena.gd`의 `ARENA_RECT_1X`만 바꾸면 **F6만** 바뀝니다. **F5 메인 맵을 바꿀 때는 반드시 `survivors_game.tscn`의 `%MapArena` 노드**에서 `arena_rect`·`spawn_margin`을 오버라이드하세요. (스크립트 기본값을 3×로 올리면 테스트 아레나까지 커집니다.)

1× 기준 rect 중심 ≈ `(1, -13)`(플레이어 원점 근처). 3×는 같은 중심을 유지한 선형 확대.

## 동작 요약

| 항목 | 내용 |
|------|------|
| 씬·스크립트 | `world/map_arena/map_arena.tscn`, `map_arena.gd` (`class_name MapArena`) |
| 벽 | `StaticBody2D` 4면 + `Polygon2D` (`wall_thickness` 48), 레이어 **1** |
| 몹 스폰 | `get_random_spawn_position(exclude_near_world?)` → 글로벌 좌표, `spawn_margin` 안쪽 랜덤, layer 1 `intersect_shape`(r=52, 12회). 메인은 `game.gd`가 `%Player.global_position` 전달 → `player_clear_radius + mob_spawn_player_clear_extra`(기본 **130**) 반경 밖만 허용 |
| 호출 | `spawn_mob()` → `acquire(..., spawn_pos)` + `initialize_spawn_health` (`spawn_pos`는 `get_random_spawn_position` 결과) |

## 소나무 (Poisson)

| 항목 | 내용 |
|------|------|
| 샘플러 | `world/trees/poisson_sampler.gd` (`PoissonSampler`, Bridson) |
| 배치 | `_rebuild_trees()` → 자식 `Obstacles`에 `pine_tree.tscn` |
| 밀도 | `tree_spacing_dense` **50**(많음) · `tree_spacing_sparse` **960**(적음) · `tree_min_spacing` 기본 **50%**(`TREE_MIN_SPACING_DEFAULT`≈505) |
| 밀도 UI | `%PauseMenu` → `%SettingsPanel` → `TreeDensitySettings` (`ui/settings/tree_density_settings.gd`) — 슬라이더 **0~100%** → `set_tree_density_normalized()` → 드래그 중 즉시 `_rebuild_trees()`. (구 HUD `%TreeDensityGui` 제거) |
| 금지 | `wall_padding`(기본 288), `player_clear_radius`(기본 280), 원심 `(0,0)` |
| 수동 나무 | 메인 씬 `PineTree*` 노드 **없음** (전부 절차 생성) |
| 미구현(선택) | BFS로 막힌 맵 재시드 — `BACKLOG.md` §맵·장식 |

**인스펙터:** `arena_rect` / `wall_thickness` / `wall_color` / 나무 export 변경 시 `call_deferred`로 벽·나무 재생성.

**튜닝·확장 시:** 맵 3× 유지 시 `wall_padding`·`spawn_margin`·`player_clear_radius`를 1× 대비 약 **3배**로 맞추는 것이 자연스럽습니다. 메인 맵이 여전히 빽빽하면 일시정지 **설정 0%** 또는 `%MapArena` **`tree_spacing_sparse`** 를 **1200~1600**으로 올립니다. 밀집(간격 50 근처)은 몹 스폰(r=52) 압박. **링 스폰**·**카메라 클램프**·바닥 `checker_background` 맞춤은 BACKLOG.