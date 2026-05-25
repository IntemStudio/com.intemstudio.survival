class_name ArenaWaveDirector
extends RefCounted

signal wave_started(wave_number: int, title: String, is_boss_wave: bool)
signal wave_completed(wave_number: int)
signal arena_completed(wave_number: int)

const MAX_WAVE := 10
const SPAWN_INTERVAL := 0.45

var current_wave := 0

var _pending_spawns: Array[Dictionary] = []
var _wave_active := false
var _wave_title := ""
var _is_boss_wave := false


func start() -> void:
	current_wave = 0
	_pending_spawns.clear()
	_wave_active = false
	_wave_title = ""
	_is_boss_wave = false


func begin_next_wave() -> void:
	if current_wave >= MAX_WAVE:
		arena_completed.emit(current_wave)
		return

	current_wave += 1
	_pending_spawns = _build_wave_spawns(current_wave)
	_is_boss_wave = current_wave % 5 == 0
	_wave_title = _build_wave_title(current_wave, _is_boss_wave)
	_wave_active = true
	wave_started.emit(current_wave, _wave_title, _is_boss_wave)


func has_pending_spawns() -> bool:
	return not _pending_spawns.is_empty()


# 웨이브 큐에서 다음 몹 하나를 스폰하고, 성공한 경우에만 큐를 소비합니다.
func spawn_next(game_node: Object) -> bool:
	if _pending_spawns.is_empty() or game_node == null or not game_node.has_method("spawn_mob"):
		return false

	var spawn_spec: Dictionary = _pending_spawns[0]
	var mob_scene := spawn_spec.get("scene") as PackedScene
	if mob_scene == null:
		_pending_spawns.pop_front()
		return false

	var hp_multiplier := float(spawn_spec.get("hp_multiplier", 1.0))
	var spawned_mob := game_node.call("spawn_mob", mob_scene, true, hp_multiplier) as Mob
	if spawned_mob == null:
		return false

	_pending_spawns.pop_front()
	return true


func check_wave_completion(alive_mob_count: int) -> void:
	if not _wave_active or not _pending_spawns.is_empty():
		return
	if alive_mob_count > 0:
		return

	_wave_active = false
	if current_wave >= MAX_WAVE:
		arena_completed.emit(current_wave)
	else:
		wave_completed.emit(current_wave)


func get_hud_text() -> String:
	if current_wave <= 0:
		return "Arena"
	return "Wave %d" % current_wave


func get_notice_text() -> String:
	if current_wave <= 0:
		return "아레나 준비"
	return _wave_title


func get_wave_progress() -> float:
	if current_wave <= 0:
		return 0.0
	return clampf(float(current_wave) / float(MAX_WAVE), 0.0, 1.0)


func get_segment_text() -> String:
	if current_wave <= 0:
		return "Wave 0 / %d" % MAX_WAVE
	if not _wave_active and current_wave < MAX_WAVE:
		return "Wave %d / %d · 텔레포터 대기" % [current_wave, MAX_WAVE]
	if _pending_spawns.is_empty():
		return "Wave %d / %d · 필드 정리 중" % [current_wave, MAX_WAVE]
	return "Wave %d / %d · 남은 스폰 %d" % [current_wave, MAX_WAVE, _pending_spawns.size()]


func _build_wave_title(wave_number: int, boss_wave: bool) -> String:
	if boss_wave:
		return "Wave %d - 보스 웨이브" % wave_number
	return "Wave %d - 몬스터 웨이브" % wave_number


func _build_wave_spawns(wave_number: int) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	match wave_number:
		1:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 8, 1.0)
		2:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 10, 1.05)
			_append_spawns(spawns, MobSpawnSelector.MOB_FAST_SCENE, 2, 1.05)
		3:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 12, 1.1)
			_append_spawns(spawns, MobSpawnSelector.MOB_FAST_SCENE, 3, 1.1)
		4:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 14, 1.15)
			_append_spawns(spawns, MobSpawnSelector.MOB_RANGED_SCENE, 2, 1.15)
		5:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 8, 1.25)
			_append_spawns(spawns, MobSpawnSelector.MOB_BOSS_SCENE, 1, 1.25)
		6:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 16, 1.25)
			_append_spawns(spawns, MobSpawnSelector.MOB_FAST_SCENE, 5, 1.25)
			_append_spawns(spawns, MobSpawnSelector.MOB_RANGED_SCENE, 3, 1.25)
		7:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 18, 1.35)
			_append_spawns(spawns, MobSpawnSelector.MOB_FAST_SCENE, 5, 1.35)
			_append_spawns(spawns, MobSpawnSelector.MOB_ELITE_SCENE, 2, 1.35)
		8:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 20, 1.45)
			_append_spawns(spawns, MobSpawnSelector.MOB_RANGED_SCENE, 5, 1.45)
			_append_spawns(spawns, MobSpawnSelector.MOB_ELITE_SCENE, 3, 1.45)
		9:
			_append_spawns(spawns, MobSpawnSelector.MOB_FAST_SCENE, 10, 1.55)
			_append_spawns(spawns, MobSpawnSelector.MOB_RANGED_SCENE, 6, 1.55)
			_append_spawns(spawns, MobSpawnSelector.MOB_SPECIAL_A_SCENE, 2, 1.55)
		10:
			_append_spawns(spawns, MobSpawnSelector.MOB_RANGED_SCENE, 6, 1.8)
			_append_spawns(spawns, MobSpawnSelector.MOB_ELITE_SCENE, 4, 1.8)
			_append_spawns(spawns, MobSpawnSelector.MOB_BOSS_SCENE, 1, 1.8)
		_:
			_append_spawns(spawns, MobSpawnSelector.MOB_BASIC_SCENE, 8, 1.0)
	return spawns


func _append_spawns(
	spawns: Array[Dictionary],
	mob_scene: PackedScene,
	count: int,
	hp_multiplier: float
) -> void:
	for _i in range(count):
		spawns.append({
			"scene": mob_scene,
			"hp_multiplier": hp_multiplier,
		})
