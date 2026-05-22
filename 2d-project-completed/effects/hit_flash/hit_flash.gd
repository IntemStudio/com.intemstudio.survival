extends RefCounted
class_name HitFlash

const FLASH_MULTIPLIER := Color(2.4, 2.4, 2.4, 1.0)
const BLINK_ON_SEC := 0.05
const BLINK_OFF_SEC := 0.055
const BLINK_COUNT := 2

static var _tweens: Dictionary = {}


# 진행 중인 피격 깜박임 트윈을 중단하고 modulate를 복구합니다(풀 반환 등).
static func cancel(target: CanvasItem, restore_modulate: Color = Color.WHITE) -> void:
	if target == null or not is_instance_valid(target):
		return
	var key := target.get_instance_id()
	if _tweens.has(key):
		var tween: Tween = _tweens[key]
		if tween and tween.is_valid():
			tween.kill()
		_tweens.erase(key)
	target.modulate = restore_modulate


# CanvasItem modulate를 짧게 밝게 깜박입니다.
static func play(target: CanvasItem, restore_modulate: Color = Color.WHITE) -> void:
	if target == null or not is_instance_valid(target):
		return

	var key := target.get_instance_id()
	cancel(target, restore_modulate)

	var peak := Color(
		restore_modulate.r * FLASH_MULTIPLIER.r,
		restore_modulate.g * FLASH_MULTIPLIER.g,
		restore_modulate.b * FLASH_MULTIPLIER.b,
		restore_modulate.a,
	)

	var tween := target.create_tween()
	_tweens[key] = tween
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	for _i in BLINK_COUNT:
		tween.tween_property(target, "modulate", peak, BLINK_ON_SEC)
		tween.tween_property(target, "modulate", restore_modulate, BLINK_OFF_SEC)

	tween.finished.connect(
		func() -> void:
			if is_instance_valid(target):
				target.modulate = restore_modulate
			_tweens.erase(key),
		CONNECT_ONE_SHOT,
	)
