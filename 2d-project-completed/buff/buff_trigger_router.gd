class_name BuffTriggerRouter
extends RefCounted

## 게임 이벤트를 플레이어 버프 부여로 연결합니다.

const SOURCE_WEAPON_PREFIX := "weapon:"
const SOURCE_LOADOUT_PREFIX := "loadout:"


static func apply_arena_wave_start(player: Node, _wave_number: int) -> void:
	if player == null or not player.has_method(&"get_owned_weapons"):
		return
	for weapon in player.call("get_owned_weapons"):
		var weapon_data := weapon as WeaponData
		if weapon_data != null and weapon_data.weapon_id == "rapier":
			_apply_player_buff(player, BuffCatalog.BUFF_EN_GARDE, SOURCE_WEAPON_PREFIX + "rapier")
			return


static func apply_loadout_dash_haste(player: Node) -> void:
	_apply_player_buff(player, BuffCatalog.BUFF_DASH_HASTE, SOURCE_LOADOUT_PREFIX + "dash_haste")


static func _apply_player_buff(player: Node, buff_id: String, source_id: String) -> void:
	if player == null or not player.has_method(&"apply_buff"):
		return
	var buff := BuffCatalog.get_buff(buff_id)
	if buff == null:
		push_warning("BuffTriggerRouter: unknown buff '%s'" % buff_id)
		return
	player.call("apply_buff", buff, source_id)
