extends Node2D

## 몹·무기 전투를 빠르게 검증하는 테스트 아레나(메인 루프·밸런스 스폰 없음).

const RangedWeaponCatalog = preload("res://weapons/catalogs/ranged_weapon_catalog.gd")
const MeleeWeaponCatalog = preload("res://weapons/catalogs/melee_weapon_catalog.gd")
const MagicWeaponCatalog = preload("res://weapons/catalogs/magic_weapon_catalog.gd")

const START_WEAPON := preload("res://weapons/data/revolver.tres")
const PLAYER_RESPAWN_DELAY := 3.0
const MOB_SPAWN_OFFSET_FROM_PLAYER := Vector2(280.0, 0.0)
const DUMMY_BASE_MAX_HEALTH := 500
const NON_DUMMY_HP_VS_DUMMY_MULTIPLIER := 10.0

const WEAPON_TYPE_ORDER: Array[String] = ["Ranged", "Magic", "Melee"]
const WEAPON_TYPE_LABELS_KO := {
	"Ranged": "원거리",
	"Magic": "마법",
	"Melee": "근접",
}

# 카탈로그에 아직 없어도 필터에 미리 노출할 등급(추가 시 자동 반영).
const WEAPON_RARITY_ORDER: Array[String] = [
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
]
const WEAPON_RARITY_LABELS_KO := {
	"Common": "커먼",
	"Uncommon": "언커먼",
	"Rare": "레어",
	"Epic": "에픽",
	"Legendary": "전설",
}

const MOB_OPTIONS: Array[Dictionary] = [
	{"label": "Basic", "scene": MobSpawnSelector.MOB_BASIC_SCENE},
	{"label": "Fast", "scene": MobSpawnSelector.MOB_FAST_SCENE},
	{"label": "Ranged", "scene": MobSpawnSelector.MOB_RANGED_SCENE},
	{"label": "Elite", "scene": MobSpawnSelector.MOB_ELITE_SCENE},
	{"label": "Boss", "scene": MobSpawnSelector.MOB_BOSS_SCENE},
	{"label": "Special A", "scene": MobSpawnSelector.MOB_SPECIAL_A_SCENE},
	{"label": "Special B", "scene": MobSpawnSelector.MOB_SPECIAL_B_SCENE},
	{"label": "Dummy (static)", "scene": MobSpawnSelector.MOB_DUMMY_SCENE},
]

@export var mob_respawn_enabled := false
@export_range(0.0, 30.0, 0.1, "or_greater") var mob_respawn_delay := 2.0

var _all_weapon_options: Array[WeaponData] = []
var _available_rarities: Array[String] = []
var _filtered_weapon_options: Array[WeaponData] = []
var _active_mob: Mob = null
var _last_mob_scene: PackedScene = null
var _player_is_dead := false
var _saved_player_collision_layer := 0
var _saved_player_collision_mask := 0
var _saved_auto_attack_enabled := true
var _mob_respawn_token := 0


func _ready() -> void:
	_place_player_at_spawn()
	%Player.set_contact_damage_enabled(true)
	_build_weapon_options()
	_setup_mob_type_option()
	_setup_weapon_filters()
	_equip_weapon(START_WEAPON)
	%SpawnMobButton.pressed.connect(_on_spawn_mob_button_pressed)
	%EquipWeaponButton.pressed.connect(_on_equip_weapon_button_pressed)
	%WeaponTypeFilter.item_selected.connect(_on_weapon_filters_changed)
	%WeaponRarityFilter.item_selected.connect(_on_weapon_filters_changed)
	%Player.health_depleted.connect(_on_player_health_depleted)
	%MobRespawnCheck.toggled.connect(_on_mob_respawn_toggled)
	_on_mob_respawn_toggled(%MobRespawnCheck.button_pressed)


# player.gd F키 차단 훅(메인 Game API 호환).
func is_weapon_select_open() -> bool:
	return false


func is_pause_menu_open() -> bool:
	return false


func is_game_over() -> bool:
	return _player_is_dead


func _build_weapon_options() -> void:
	_all_weapon_options.clear()
	for weapon in RangedWeaponCatalog.get_all():
		_all_weapon_options.append(weapon)
	for weapon in MagicWeaponCatalog.get_all():
		_all_weapon_options.append(weapon)
	for weapon in MeleeWeaponCatalog.get_all():
		_all_weapon_options.append(weapon)
	_all_weapon_options.sort_custom(_sort_weapons_for_picker)
	_collect_available_rarities()


func _collect_available_rarities() -> void:
	var seen: Dictionary = {}
	for weapon in _all_weapon_options:
		var rarity_key := weapon.rarity if not weapon.rarity.is_empty() else "Common"
		seen[rarity_key] = true

	_available_rarities.clear()
	for rarity in WEAPON_RARITY_ORDER:
		if seen.has(rarity):
			_available_rarities.append(rarity)
			seen.erase(rarity)
	for rarity in seen.keys():
		_available_rarities.append(str(rarity))


func _sort_weapons_for_picker(a: WeaponData, b: WeaponData) -> bool:
	var type_a := WEAPON_TYPE_ORDER.find(a.weapon_type)
	var type_b := WEAPON_TYPE_ORDER.find(b.weapon_type)
	if type_a < 0:
		type_a = WEAPON_TYPE_ORDER.size()
	if type_b < 0:
		type_b = WEAPON_TYPE_ORDER.size()
	if type_a != type_b:
		return type_a < type_b
	return a.get_display_name_localized() < b.get_display_name_localized()


func _setup_mob_type_option() -> void:
	var option: OptionButton = %MobTypeOption
	option.clear()
	for entry in MOB_OPTIONS:
		option.add_item(entry["label"])


func _setup_weapon_filters() -> void:
	var type_filter: OptionButton = %WeaponTypeFilter
	type_filter.clear()
	type_filter.add_item("전체")
	for weapon_type in WEAPON_TYPE_ORDER:
		type_filter.add_item(WEAPON_TYPE_LABELS_KO[weapon_type])
	var ranged_index := WEAPON_TYPE_ORDER.find("Ranged") + 1
	type_filter.select(maxi(ranged_index, 0))

	var rarity_filter: OptionButton = %WeaponRarityFilter
	rarity_filter.clear()
	rarity_filter.add_item("전체")
	for rarity in _available_rarities:
		var label: String = WEAPON_RARITY_LABELS_KO.get(rarity, rarity)
		rarity_filter.add_item(label)
	var common_index := _available_rarities.find("Common")
	if common_index >= 0:
		rarity_filter.select(common_index + 1)
	else:
		rarity_filter.select(0)

	_refresh_weapon_option_list(START_WEAPON.get_unique_key())


func _on_weapon_filters_changed(_index: int = -1) -> void:
	var current := _get_selected_weapon()
	var preserve_key := current.get_unique_key() if current else ""
	_refresh_weapon_option_list(preserve_key)


func _get_weapon_filter_type() -> String:
	var index: int = %WeaponTypeFilter.selected
	if index <= 0:
		return ""
	return WEAPON_TYPE_ORDER[index - 1]


func _get_weapon_filter_rarity() -> String:
	var index: int = %WeaponRarityFilter.selected
	if index <= 0:
		return ""
	if index - 1 < _available_rarities.size():
		return _available_rarities[index - 1]
	return ""


func _weapon_matches_rarity(weapon: WeaponData, rarity_filter: String) -> bool:
	if rarity_filter.is_empty():
		return true
	var weapon_rarity := weapon.rarity if not weapon.rarity.is_empty() else "Common"
	return weapon_rarity == rarity_filter


func _refresh_weapon_option_list(preserve_key: String = "") -> void:
	var filter_type := _get_weapon_filter_type()
	var filter_rarity := _get_weapon_filter_rarity()
	_filtered_weapon_options.clear()
	for weapon in _all_weapon_options:
		if not filter_type.is_empty() and weapon.weapon_type != filter_type:
			continue
		if not _weapon_matches_rarity(weapon, filter_rarity):
			continue
		_filtered_weapon_options.append(weapon)

	var option: OptionButton = %WeaponOption
	option.clear()
	if _filtered_weapon_options.is_empty():
		if not _player_is_dead:
			_update_status("조건에 맞는 무기가 없습니다.")
		return

	var select_index := 0
	for i in _filtered_weapon_options.size():
		var weapon: WeaponData = _filtered_weapon_options[i]
		option.add_item(weapon.get_display_name_localized())
		if not preserve_key.is_empty() and weapon.get_unique_key() == preserve_key:
			select_index = i
	option.select(select_index)
	if not _player_is_dead and _filtered_weapon_options.size() > 0:
		_update_status("")


func _on_mob_respawn_toggled(enabled: bool) -> void:
	mob_respawn_enabled = enabled


func _on_spawn_mob_button_pressed() -> void:
	spawn_test_mob(_get_selected_mob_scene())


func _on_equip_weapon_button_pressed() -> void:
	var weapon := _get_selected_weapon()
	if weapon:
		_equip_weapon(weapon)


func _get_selected_mob_scene() -> PackedScene:
	var index: int = %MobTypeOption.selected
	if index < 0 or index >= MOB_OPTIONS.size():
		return MobSpawnSelector.MOB_BASIC_SCENE
	return MOB_OPTIONS[index]["scene"] as PackedScene


func _get_selected_weapon() -> WeaponData:
	var index: int = %WeaponOption.selected
	if index < 0 or index >= _filtered_weapon_options.size():
		return null
	return _filtered_weapon_options[index]


# 플레이어 무기 슬롯을 비운 뒤 새 무기만 장착합니다.
func _equip_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return
	var player: CharacterBody2D = %Player
	player.clear_weapons()
	player.add_weapon(weapon)
	player.set_auto_attack_enabled(true)


# 선택한 몹 프리팹을 스폰 포인트에 배치합니다.
func spawn_test_mob(scene: PackedScene) -> void:
	if scene == null:
		push_error("TestArena.spawn_test_mob: scene is null.")
		return
	_cancel_pending_mob_respawn()
	_clear_active_mob()
	var spawn_pos: Vector2 = %Player.global_position + MOB_SPAWN_OFFSET_FROM_PLAYER
	var pool: ScenePool = $ObjectPools as ScenePool
	var mob: Mob
	if pool:
		mob = pool.acquire(scene, self, spawn_pos) as Mob
	else:
		mob = scene.instantiate() as Mob
		add_child(mob)
		mob.global_position = spawn_pos
	if not mob:
		push_error("TestArena.spawn_test_mob: scene must instantiate a Mob.")
		return
	mob.initialize_spawn_health(_get_test_mob_hp_multiplier(scene, mob))
	_active_mob = mob
	_last_mob_scene = scene


# 더미는 프리팹 기본 HP, 그 외 몹은 더미 최대 체력의 10배가 되도록 배수를 맞춥니다.
func _get_test_mob_hp_multiplier(scene: PackedScene, mob: Mob) -> float:
	if scene == MobSpawnSelector.MOB_DUMMY_SCENE:
		return 1.0
	var target_max := float(DUMMY_BASE_MAX_HEALTH * NON_DUMMY_HP_VS_DUMMY_MULTIPLIER)
	return target_max / maxf(float(mob.base_max_health), 1.0)


# 몹 사망 시 선택적으로 동일 프리팹을 재스폰합니다.
func register_kill() -> void:
	_active_mob = null
	if not mob_respawn_enabled or _last_mob_scene == null:
		return
	_cancel_pending_mob_respawn()
	var scene := _last_mob_scene
	var token := _mob_respawn_token
	get_tree().create_timer(mob_respawn_delay).timeout.connect(
		func() -> void:
			if token != _mob_respawn_token:
				return
			spawn_test_mob(scene)
	)


func _on_player_health_depleted() -> void:
	if _player_is_dead:
		return
	_begin_player_death()


func _begin_player_death() -> void:
	_player_is_dead = true
	var player: CharacterBody2D = %Player
	_saved_player_collision_layer = player.collision_layer
	_saved_player_collision_mask = player.collision_mask
	_saved_auto_attack_enabled = player.is_auto_attack_enabled()
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_physics_process(false)
	player.set_auto_attack_enabled(false)
	player.visible = false
	_update_status("플레이어 사망 — %.1f초 후 리스폰" % PLAYER_RESPAWN_DELAY)
	get_tree().create_timer(PLAYER_RESPAWN_DELAY).timeout.connect(_respawn_player)


func _respawn_player() -> void:
	if not _player_is_dead:
		return
	var player: CharacterBody2D = %Player
	var max_hp: float = player.get_node("%HealthBar").max_value
	player.health = max_hp
	player.get_node("%HealthBar").value = max_hp
	player.global_position = %PlayerSpawnPoint.global_position
	player.collision_layer = _saved_player_collision_layer
	player.collision_mask = _saved_player_collision_mask
	player.set_physics_process(true)
	player.visible = true
	player.set_auto_attack_enabled(_saved_auto_attack_enabled)
	player.reset_health_depleted_state()
	_player_is_dead = false
	_update_status("")


func _update_status(text: String) -> void:
	%StatusLabel.text = text


func _place_player_at_spawn() -> void:
	var player: Node2D = %Player
	player.global_position = %PlayerSpawnPoint.global_position


func _cancel_pending_mob_respawn() -> void:
	_mob_respawn_token += 1


func _clear_active_mob() -> void:
	if _active_mob == null or not is_instance_valid(_active_mob):
		_active_mob = null
		return
	PoolUtil.release_node(_active_mob)
	_active_mob = null
