class_name EliteAffixRuntimeRegistry
extends RefCounted

## affix id → runtime Script.

const _RUNTIME_NOOP: GDScript = preload("res://elite/affix/elite_affix_runtime_noop.gd")
const _RUNTIME_GLACIAL: GDScript = preload("res://elite/affix/elite_affix_runtime_glacial.gd")
const _RUNTIME_OVERLOADING: GDScript = preload("res://elite/affix/elite_affix_runtime_overloading.gd")


static func create_runtime(affix_id: StringName) -> EliteAffixRuntime:
	if affix_id == EliteAffixIds.GLACIAL:
		return _RUNTIME_GLACIAL.new() as EliteAffixRuntime
	if affix_id == EliteAffixIds.OVERLOADING:
		return _RUNTIME_OVERLOADING.new() as EliteAffixRuntime
	return _RUNTIME_NOOP.new() as EliteAffixRuntime
