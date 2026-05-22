extends Node2D

## 몹·무기 전투를 빠르게 검증하는 테스트 아레나(메인 루프·밸런스 스폰 없음).

const START_WEAPON := preload("res://weapons/data/revolver.tres")
const DEBUG_SPAWN_MOB_SCENE := MobSpawnSelector.MOB_BASIC_SCENE

@export var debug_spawn_mob_on_ready := true

var _active_mob: Mob = null
var _last_mob_scene: PackedScene = null


func _ready() -> void:
	_place_player_at_spawn()
	%Player.add_weapon.call_deferred(START_WEAPON)
	if debug_spawn_mob_on_ready:
		spawn_test_mob(DEBUG_SPAWN_MOB_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode != KEY_R:
		return
	# PR1: R로 basic 몹 재스폰(UI는 PR2)
	spawn_test_mob(DEBUG_SPAWN_MOB_SCENE)


# 선택한 몹 프리팹을 스폰 포인트에 배치합니다.
func spawn_test_mob(scene: PackedScene) -> void:
	if scene == null:
		push_error("TestArena.spawn_test_mob: scene is null.")
		return
	_clear_active_mob()
	var pool: ScenePool = $ObjectPools as ScenePool
	var mob: Mob
	if pool:
		mob = pool.acquire(scene, self) as Mob
	else:
		mob = scene.instantiate() as Mob
		add_child(mob)
	if not mob:
		push_error("TestArena.spawn_test_mob: scene must instantiate a Mob.")
		return
	mob.global_position = %MobSpawnPoint.global_position
	mob.initialize_spawn_health(1.0)
	_active_mob = mob
	_last_mob_scene = scene


# 몹 사망 시 kill 카운트 훅(PR3에서 리스폰 연동).
func register_kill() -> void:
	pass


func _place_player_at_spawn() -> void:
	var player: Node2D = %Player
	player.global_position = %PlayerSpawnPoint.global_position


func _clear_active_mob() -> void:
	if _active_mob == null or not is_instance_valid(_active_mob):
		_active_mob = null
		return
	PoolUtil.release_node(_active_mob)
	_active_mob = null
