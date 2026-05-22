extends VBoxContainer

## HUD — 소나무 밀도 슬라이더(플레이 중 실시간 %MapArena 재배치).

@onready var _slider: HSlider = %TreeDensitySlider
@onready var _value_label: Label = %TreeDensityValueLabel


func _on_slider_value_changed(value: float) -> void:
	var arena := _get_map_arena()
	if arena == null:
		return
	var density := value / 100.0
	var spacing := lerpf(
		arena.tree_spacing_sparse,
		arena.tree_spacing_dense,
		density
	)
	_update_value_label(spacing, density)
	_apply_density(density)


func _ready() -> void:
	_slider.min_value = 0.0
	_slider.max_value = 100.0
	_slider.step = 1.0
	_slider.value_changed.connect(_on_slider_value_changed)
	sync_from_arena()


# MapArena 현재 밀도로 슬라이더·라벨을 맞춥니다.
func sync_from_arena() -> void:
	var arena := _get_map_arena()
	if arena == null:
		visible = false
		return
	visible = arena.spawn_trees
	if not visible:
		return
	var density := arena.get_tree_density_normalized()
	_slider.set_value_no_signal(density * 100.0)
	_update_value_label(arena.tree_min_spacing, density)


func _apply_density(density: float) -> void:
	var arena := _get_map_arena()
	if arena == null:
		return
	arena.set_tree_density_normalized(density)


func _update_value_label(spacing: float, density: float) -> void:
	var percent := int(round(density * 100.0))
	_value_label.text = "밀도 %d%% · 간격 %.0f" % [percent, spacing]


func _get_map_arena() -> MapArena:
	return get_node_or_null("/root/Game/MapArena") as MapArena
