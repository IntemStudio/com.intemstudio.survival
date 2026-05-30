class_name MobChaseOrbit
extends MobChaseStrategy

## 플레이어 주위를 돌며 접근 — standoff 밖에서 접선 이동, 멀면 직선 접근.


func compute_desired_velocity(context: MobChaseContext) -> Vector2:
	var distance := context.target_offset.length()
	if distance <= context.stop_distance or distance < 0.01:
		return Vector2.ZERO

	var toward := context.target_offset / distance
	var tangent := Vector2(-toward.y, toward.x)
	if not context.orbit_clockwise:
		tangent = -tangent

	var orbit_radius := context.stop_distance + context.orbit_radius_buffer
	var speed := context.effective_speed
	var blend_span := maxf(context.orbit_approach_blend, 1.0)

	if distance > orbit_radius + blend_span:
		return toward * speed

	var radial_error := distance - orbit_radius
	var radial_dir := toward if radial_error > 0.0 else -toward
	var radial_weight := clampf(absf(radial_error) / blend_span, 0.0, 1.0) * 0.35
	var orbit_dir := (tangent + radial_dir * radial_weight).normalized()

	var blend_t := 1.0 - clampf((distance - orbit_radius) / blend_span, 0.0, 1.0)
	var final_dir := toward.lerp(orbit_dir, blend_t).normalized()
	return final_dir * speed
