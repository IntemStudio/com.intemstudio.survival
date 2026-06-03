class_name PlayerCharacterVisual
extends Node2D

## 플레이어 직업 비주얼 공통 — idle/walk 애니메이션 계약.

const _ANIM_LIB := &""
const _ANIM_LIB_RES := preload("res://characters/happy_boo/happy_boo_anim_library.tres")


func _ready() -> void:
	_ensure_animation_library()


func play_idle_animation() -> void:
	var player: AnimationPlayer = _get_animation_player()
	if player:
		player.play(&"idle")


func play_walk_animation() -> void:
	var player: AnimationPlayer = _get_animation_player()
	if player:
		player.play(&"walk")


func _get_animation_player() -> AnimationPlayer:
	return find_child("AnimationPlayer", true, false) as AnimationPlayer


# 4.5에서 libraries 직렬화가 깨졌을 때 외부 .tres로 라이브러리 복구.
func _ensure_animation_library() -> void:
	var player := _get_animation_player()
	if player == null:
		return
	if not player.get_animation_list().is_empty():
		return
	if player.has_animation_library(_ANIM_LIB):
		player.remove_animation_library(_ANIM_LIB)
	player.add_animation_library(_ANIM_LIB, _ANIM_LIB_RES)
