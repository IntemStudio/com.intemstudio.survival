shader_type canvas_item;

uniform vec2 camera_center;
uniform vec2 viewport_half;
uniform float cell_size = 64.0;
uniform vec4 color_a : source_color = vec4(0.72, 0.76, 0.68, 1.0);
uniform vec4 color_b : source_color = vec4(0.66, 0.70, 0.62, 1.0);

void fragment() {
	vec2 world_pos = camera_center + (UV - vec2(0.5)) * viewport_half * 2.0;
	vec2 cell = floor(world_pos / cell_size);
	float checker = mod(cell.x + cell.y, 2.0);
	COLOR = mix(color_a, color_b, checker);
}
