class_name DevWeaponTuning
extends RefCounted

## F5/F6 공통 무기 튜닝 — TestArenaWeaponSnapshot + res:// authoring 병합.

static var _snapshot: TestArenaWeaponSnapshot = null


static func get_snapshot() -> TestArenaWeaponSnapshot:
	_ensure_snapshot()
	return _snapshot


static func build_tuned_weapon(catalog_weapon: WeaponData) -> WeaponData:
	if catalog_weapon == null:
		return null
	return get_snapshot().build_tuned_weapon(catalog_weapon)


static func reload_authoring() -> void:
	DevTuningStore.reload_weapon_authoring()


static func clear_session() -> void:
	get_snapshot().clear_session()


static func _ensure_snapshot() -> void:
	if _snapshot != null:
		return
	_snapshot = TestArenaWeaponSnapshot.new()
	_snapshot.load_from_disk()
	DevTuningStore.reload_weapon_authoring()
