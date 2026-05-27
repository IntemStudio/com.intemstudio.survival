# 디스플레이·카메라·UI

**진입:** [`AGENTS.md`](../../AGENTS.md) · 에이전트 must: [`.cursor/rules/godot-core.mdc`](../../.cursor/rules/godot-core.mdc) (Display / camera / UI)

게임 **월드**와 **UI**는 해상도·줌 정책이 다릅니다. UI는 FHD 좌표, 월드는 뷰포트·카메라 줌이 직접 반영됩니다.

## 창·뷰포트 (`project.godot`)

| 항목 | 현재 값 |
|------|---------|
| `viewport_width` × `viewport_height` | **1280 × 720** (HD) |
| `resizable` | `false` |
| `stretch/mode` | `canvas_items` |
| `stretch/aspect` | `expand` |

**FHD로 바꿀 때:** 위 두 픽셀만 **1920 × 1080**으로 수정. UI는 `UiViewportLayout`이 자동 스케일(기준 FHD 유지). 월드 스프라이트는 뷰포트 픽셀 1:1이라 HD→FHD 시 화면에 더 많은 픽셀이 그려짐(줌·맵 밸런스는 별도 튜닝).

**런타임(일시정지 → 설정):** `ui/settings/display_settings.gd`(`DisplaySettings`)가 해상도·화면 모드·VSync를 적용하고 `user://display_settings.cfg`에 저장. UI는 `ui/settings/video_display_settings.gd` — 해상도 프리셋(1280×720~2560×1440, 모니터 이하만), 화면 모드(윈도우 / 테두리 없는 전체화면 / 전체 화면), VSync(끔·켜짐). `game.gd` `_ready`에서 `DisplaySettings.load_and_apply()`.

## 카메라 (`entities/player/player.tscn`)

| 항목 | 내용 |
|------|------|
| 노드 | `Player` 자식 `Camera2D` (플레이어 추적) |
| `zoom` | **`Vector2(0.5, 0.5)`** — 기본 1.0 대비 가로·세로 시야 약 **2배** |
| 가시 월드 크기 | 대략 `뷰포트 크기 ÷ zoom` (HD 기준 약 **2560×1440** 월드 단위) |
| 코드 변경 | `player.gd`에서 줌을 건드리지 않음 — **씬 인스펙터·`.tscn`만** |

`world/floor/checker_background.gd`는 매 프레임 `camera.zoom`·`get_viewport_rect().size`로 셰이더 `viewport_half`를 갱신합니다. 줌 변경 시 바닥 체커도 같이 맞춰집니다.

## UI (FHD 기준 스케일)

HUD·메뉴·테스트 UI는 **1920×1080(FHD) 좌표**로 배치하고, 실제 창이 HD여도 `UiViewportLayout`이 균일 스케일합니다.

| 항목 | 내용 |
|------|------|
| 기준 상수 | `ui/ui_resolution_config.gd` — `DESIGN_FHD`, `HD`, `FHD` |
| 스크립트 | `ui/ui_viewport_layout.gd` (`class_name UiViewportLayout`) |
| 메인 HUD | `survivors_game.tscn` → `HUD/HUDRoot` (`align_mode` 좌상, `pass_mouse_to_game` true) |
| 메뉴 | `WeaponSelectMenu`·`PauseMenu`·`GameOver` → 각 `MenuOverlay` (중앙, `pass_mouse_to_game` false) |
| 테스트 | `test_arena.tscn` → `TestUI/TestUILayout` (`pass_mouse_to_game` false). 패널 탭: `TestPanelsWrap` / `TabBarHost`(`ui/test_arena_tab_bar.gd`, 행당 4등분·5개부터 줄바꿈) / `TestPanelsTab` |

**Must not (UI):** FHD offset·폰트를 HD 픽셀에 맞춰 이중으로 줄이지 말 것 — 스케일은 `UiViewportLayout`만 담당.

**새 전체 화면 UI:** FHD 크기 `Control`(1920×1080) + `UiViewportLayout`을 루트에 붙이고, HUD/메뉴와 동일하게 `align_mode`·`pass_mouse_to_game` 선택.

**튜닝:** `design_size`·`align_mode`·뷰포트 HD/FHD 전환. 카메라 시야는 `Camera2D.zoom`만 조정(`UiViewportLayout`과 독립).
