class_name ProjectileVisualUtil
extends RefCounted

## 발사체 스프라이트·충돌 크기에 WeaponData.projectile_scale을 적용합니다.


static func get_scale_mult(weapon: WeaponData) -> float:
	if weapon == null:
		return 1.0
	return weapon.get_projectile_scale()


static func apply_circle_projectile(
	area: Node2D,
	weapon: WeaponData,
	base_sprite_scale: Vector2,
	base_sprite_position: Vector2,
	base_circle_radius: float,
	collision_position: Vector2 = Vector2.ZERO
) -> void:
	var mult := get_scale_mult(weapon)
	var sprite := _find_sprite(area)
	if sprite != null:
		sprite.scale = base_sprite_scale * mult
		sprite.position = base_sprite_position * mult

	var collision := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = base_circle_radius * mult
	collision.shape = circle
	collision.position = collision_position * mult


static func apply_rect_collision(
	area: Node2D,
	weapon: WeaponData,
	base_size: Vector2,
	base_position: Vector2
) -> void:
	var mult := get_scale_mult(weapon)
	var collision := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = base_size * mult
	collision.shape = rectangle
	collision.position = base_position * mult


static func _find_sprite(area: Node2D) -> Sprite2D:
	var sprite := area.get_node_or_null("Sprite") as Sprite2D
	if sprite != null:
		return sprite
	return area.get_node_or_null("Sprite2D") as Sprite2D
