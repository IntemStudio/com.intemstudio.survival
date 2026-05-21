extends ColorRect

## 카메라 기준 월드 좌표 체크 바닥(화면 전체 ColorRect + 셰이더).

@export var cell_size: float = 64.0
@export var color_a: Color = Color(0.72, 0.76, 0.68, 1.0)
@export var color_b: Color = Color(0.66, 0.70, 0.62, 1.0)

var _shader_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = preload("res://world/floor/checker_background.gdshader")
	_shader_material.set_shader_parameter("color_a", color_a)
	_shader_material.set_shader_parameter("color_b", color_b)
	_shader_material.set_shader_parameter("cell_size", cell_size)
	material = _shader_material


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null or _shader_material == null:
		return
	var zoom := camera.zoom
	var half := get_viewport_rect().size / zoom * 0.5
	_shader_material.set_shader_parameter("camera_center", camera.get_screen_center_position())
	_shader_material.set_shader_parameter("viewport_half", half)
	_shader_material.set_shader_parameter("cell_size", cell_size)
