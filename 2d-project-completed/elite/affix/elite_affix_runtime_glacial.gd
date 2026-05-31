class_name EliteAffixRuntimeGlacial
extends EliteAffixRuntime

## glacial affix — 피격 chill, 사망 2초 후 중립 얼음 폭탄 + 플레이어 freeze.

const DEATH_BURST_RADIUS := 160.0
const DEATH_BURST_DELAY := 2.0
const DEATH_BURST_DAMAGE_MULT := 1.5


func on_hit_player(_raw_damage: int, mob: Node2D) -> void:
	if mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	if not is_instance_valid(mob_node.player):
		return
	if mob_node.player.has_method(&"apply_elite_debuff"):
		mob_node.player.call(&"apply_elite_debuff", &"elite_chill", {})


func on_death(mob: Node2D) -> void:
	if mob == null or not mob is Mob:
		return
	var mob_node := mob as Mob
	var damage := roundi(float(mob_node.get_elite_pre_affix_attack_damage()) * DEATH_BURST_DAMAGE_MULT)
	if damage <= 0:
		return
	var burst_position := mob_node.get_footprint_global_center()
	var on_player_hit := func() -> void:
		if not is_instance_valid(mob_node.player):
			return
		if mob_node.player.has_method(&"apply_elite_debuff"):
			mob_node.player.call(&"apply_elite_debuff", &"elite_freeze", {})
	var factory := AttackServices.find_factory(null, false)
	if factory:
		factory.schedule_mob_death_burst(
			burst_position,
			DEATH_BURST_RADIUS,
			damage,
			DEATH_BURST_DELAY,
			on_player_hit,
			true
		)
	else:
		_schedule_death_burst_fallback(burst_position, damage, on_player_hit)


func _schedule_death_burst_fallback(
	burst_position: Vector2,
	damage: int,
	on_player_hit: Callable
) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.create_timer(DEATH_BURST_DELAY).timeout.connect(
		func() -> void:
			DamageResolver.apply_neutral_burst_in_radius(
				burst_position,
				DEATH_BURST_RADIUS,
				damage,
				on_player_hit
			),
		CONNECT_ONE_SHOT
	)
