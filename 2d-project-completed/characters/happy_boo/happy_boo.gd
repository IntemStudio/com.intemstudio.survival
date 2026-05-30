extends Node2D

const _ANIM_LIB := &""
const _ANIM_LIB_RES := preload("res://characters/happy_boo/happy_boo_anim_library.tres")


func _ready() -> void:
	_ensure_animation_library()


func play_idle_animation():
	%AnimationPlayer.play(&"idle")


func play_walk_animation():
	%AnimationPlayer.play(&"walk")


# 4.5에서 libraries 직렬화가 깨졌을 때 외부 .tres로 라이브러리 복구
func _ensure_animation_library() -> void:
	var player: AnimationPlayer = %AnimationPlayer
	if not player.get_animation_list().is_empty():
		return
	if player.has_animation_library(_ANIM_LIB):
		player.remove_animation_library(_ANIM_LIB)
	player.add_animation_library(_ANIM_LIB, _ANIM_LIB_RES)
