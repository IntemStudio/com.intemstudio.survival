@tool
extends EditorPlugin


const PRESETS_FILENAME := 'presets.gpl'


func _enter_tree() -> void:
	var presets_path: String = get_script().resource_path.get_base_dir().path_join(PRESETS_FILENAME)
	var presets_file := FileAccess.open(presets_path, FileAccess.READ)

	if FileAccess.get_open_error() == OK:
		var presets_raw := presets_file.get_as_text().strip_edges().split("\n")
		presets_file.close()
		presets_raw = presets_raw.slice(presets_raw.find("#") + 1)
		var presets: Array[Color] = []
		for line_variant in presets_raw:
			var line: String = str(line_variant).strip_edges()
			if line.is_empty():
				continue

			var value_tokens: Array = Array(line.replace("\t", " ").split(" ").slice(0, -1)).filter(
				func(token: String) -> bool: return not token.is_empty()
			)
			if value_tokens.size() < 3:
				continue

			var r: int = int(str(value_tokens[0]).to_int())
			var g: int = int(str(value_tokens[1]).to_int())
			var b: int = int(str(value_tokens[2]).to_int())
			presets.append(Color8(r, g, b))
		get_editor_interface().get_editor_settings().set_project_metadata(
			"color_picker", "presets", presets
		)
