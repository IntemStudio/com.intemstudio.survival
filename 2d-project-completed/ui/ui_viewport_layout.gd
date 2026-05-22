class_name UiViewportLayout
extends Control

## FHD(1920×1080) 기준 Control 트리를 현재 뷰포트(HD/FHD)에 맞게 균일 스케일·정렬. Docs/AGENTS_Display_UI.md 참고.

enum AlignMode {
	TOP_LEFT,
	CENTER,
}

@export var design_size: Vector2 = UiResolutionConfig.DESIGN_FHD
@export var align_mode: AlignMode = AlignMode.TOP_LEFT
@export var update_on_viewport_resize: bool = true
## false면 클릭·호버를 받습니다(일시정지·무기 선택 등). HUD는 true로 두세요.
@export var pass_mouse_to_game: bool = true


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE if pass_mouse_to_game else MOUSE_FILTER_STOP
	_apply_design_rect()
	_fit_to_viewport()
	if update_on_viewport_resize and not get_viewport().size_changed.is_connected(_fit_to_viewport):
		get_viewport().size_changed.connect(_fit_to_viewport)


func _apply_design_rect() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = design_size.x
	offset_bottom = design_size.y
	size = design_size


func _fit_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var s := UiResolutionConfig.uniform_scale_for_viewport(viewport_size, design_size)
	scale = Vector2(s, s)
	match align_mode:
		AlignMode.TOP_LEFT:
			position = Vector2.ZERO
		AlignMode.CENTER:
			position = (viewport_size - design_size * s) * 0.5
