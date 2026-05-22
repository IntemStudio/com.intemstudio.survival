class_name UiResolutionConfig
extends RefCounted

## UI 레이아웃·폰트 배치의 기준 해상도(FHD). 뷰포트가 HD(1280×720)여도 UI 배치는 이 좌표계 — 스케일은 UiViewportLayout. AGENTS.md 참고.
const DESIGN_FHD := Vector2(1920.0, 1080.0)
const HD := Vector2(1280.0, 720.0)
const FHD := Vector2(1920.0, 1080.0)


static func uniform_scale_for_viewport(viewport_size: Vector2, design_size: Vector2 = DESIGN_FHD) -> float:
	if design_size.x <= 0.0 or design_size.y <= 0.0:
		return 1.0
	return minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)


static func scale_vector_for_viewport(viewport_size: Vector2, design_size: Vector2 = DESIGN_FHD) -> Vector2:
	var s := uniform_scale_for_viewport(viewport_size, design_size)
	return Vector2(s, s)
