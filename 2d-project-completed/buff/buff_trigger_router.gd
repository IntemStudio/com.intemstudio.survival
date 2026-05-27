class_name BuffTriggerRouter
extends RefCounted

## 게임 이벤트를 플레이어 버프 부여로 연결합니다.

const SOURCE_WEAPON_PREFIX := "weapon:"
const SOURCE_LOADOUT_PREFIX := "loadout:"


static func apply_arena_wave_start(player: Node, wave_number: int) -> void:
	if player == null:
		return
	if player.has_method(&"get_owned_weapons"):
		for weapon in player.call("get_owned_weapons"):
			var weapon_data := weapon as WeaponData
			if weapon_data != null and weapon_data.weapon_id == "rapier":
				_apply_player_buff(player, BuffCatalog.BUFF_EN_GARDE, SOURCE_WEAPON_PREFIX + "rapier")
				break
	if player.has_method(&"apply_loadout_on_wave_start"):
		player.call("apply_loadout_on_wave_start", wave_number)


static func apply_loadout_dash_haste(player: Node) -> void:
	_apply_player_buff(player, BuffCatalog.BUFF_DASH_HASTE, SOURCE_LOADOUT_PREFIX + "dash_haste")


static func apply_loadout_wave_vigor(player: Node) -> void:
	_apply_player_buff(player, BuffCatalog.BUFF_WAVE_VIGOR, SOURCE_LOADOUT_PREFIX + "wave_vigor")


static func apply_loadout_kill_momentum(player: Node) -> void:
	_apply_player_buff(player, BuffCatalog.BUFF_KILL_MOMENTUM, SOURCE_LOADOUT_PREFIX + "kill_momentum")


static func _apply_player_buff(player: Node, buff_id: String, source_id: String) -> void:
	if player == null or not player.has_method(&"apply_buff"):
		return
	var buff := BuffCatalog.get_buff(buff_id)
	if buff == null:
		push_warning("BuffTriggerRouter: unknown buff '%s'" % buff_id)
		return
	player.call("apply_buff", buff, source_id)
