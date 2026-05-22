extends VBoxContainer

## 일시정지 설정 — 소나무 밀도 슬라이더(드래그 시 %MapArena 실시간 재배치).

@onready var _slider: HSlider = %TreeDensitySlider
@onready var _value_label: Label = %TreeDensityValueLabel
@onready var _tree_title: Label = get_node_or_null("../TreeDensityTitle") as Label
@onready var _sparse_label: Label = get_node_or_null("TreeDensitySliderRow/SparseLabel") as Label
@onready var _dense_label: Label = get_node_or_null("TreeDensitySliderRow/DenseLabel") as Label


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
	add_to_group(UiLocale.GROUP_REFRESH)
	_slider.min_value = 0.0
	_slider.max_value = 100.0
	_slider.step = 1.0
	_slider.value_changed.connect(_on_slider_value_changed)
	sync_from_arena()
	refresh_locale()


func refresh_locale() -> void:
	if _tree_title:
		_tree_title.text = UiLocale.t(&"settings.tree_density")
	if _sparse_label:
		_sparse_label.text = UiLocale.t(&"tree.sparse")
	if _dense_label:
		_dense_label.text = UiLocale.t(&"tree.dense")
	if _get_map_arena():
		var arena := _get_map_arena()
		_update_value_label(arena.tree_min_spacing, arena.get_tree_density_normalized())


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
	_value_label.text = UiLocale.t(&"tree.density_value") % [percent, spacing]


func _get_map_arena() -> MapArena:
	return get_node_or_null("/root/Game/MapArena") as MapArena
