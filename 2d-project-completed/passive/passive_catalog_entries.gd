extends RefCounted

## 패시브 카탈로그 엔트리 — PassiveCatalog._build_cache에서 호출합니다.


static func append_all(target: Array, create_passive: Callable) -> void:
	_append(
		target,
		create_passive,
		"swift_feet",
		"Swift Feet",
		"신속한 발",
		3,
		[{"move_speed_mult": 1.05}],
		{},
		"이동 속도 +5%",
		"swift_feet_master"
	)
	_append(
		target,
		create_passive,
		"thick_skin",
		"Thick Skin",
		"두꺼운 피부",
		3,
		[{"heart_min": 1, "heart_max": 1}],
		{},
		"최대 체력 +10"
	)
	_append(
		target,
		create_passive,
		"steady_aim",
		"Steady Aim",
		"침착한 조준",
		3,
		[{"attack_speed_mult": 1.06}],
		{},
		"공격 속도 +6%"
	)
	_append(
		target,
		create_passive,
		"sharp_edge",
		"Sharp Edge",
		"날카로운 날",
		3,
		[{"damage_mult": 1.08}],
		{},
		"피해 +8%",
		"sharp_edge_master"
	)
	_append(
		target,
		create_passive,
		"glass_cannon",
		"Glass Cannon",
		"유리 대포",
		2,
		[
			{"damage_mult": 1.1},
			{"damage_mult": 1.12, "move_speed_mult": 0.97},
		],
		{},
		"피해↑ · 이동↓"
	)
	_append(
		target,
		create_passive,
		"hunter_instinct",
		"Hunter Instinct",
		"사냥꾼 본능",
		2,
		[{}, {}],
		{"2": {"grant_on_kill": "momentum"}},
		"처치 시 잠시 이동 가속"
	)
	_append(
		target,
		create_passive,
		"wave_rider",
		"Wave Rider",
		"파도 탑승",
		2,
		[{}, {}],
		{"2": {"grant_on_wave_start": "vigor"}},
		"웨이브 시작 시 공격 속도 상승"
	)
	_append(
		target,
		create_passive,
		"lucky_coin",
		"Lucky Coin",
		"행운의 동전",
		2,
		[{"damage_mult": 1.04}, {"damage_mult": 1.05}],
		{},
		"피해 소폭 증가"
	)
	# Lv3 누적(1.05³≈1.16) 이상 — 진화 하향 방지
	_append(
		target,
		create_passive,
		"swift_feet_master",
		"Swift Feet Master",
		"신속의 대가",
		1,
		[{"move_speed_mult": 1.16, "attack_speed_mult": 1.06}],
		{},
		"진화 — 이동·공격 속도 대폭 상승",
		"",
		true
	)
	# Lv3 누적(1.08³≈1.26) 이상
	_append(
		target,
		create_passive,
		"sharp_edge_master",
		"Sharp Edge Master",
		"예리한 절삭",
		1,
		[{"damage_mult": 1.28}],
		{},
		"진화 — 피해 대폭 상승",
		"",
		true
	)


static func _append(
	target: Array,
	create_passive: Callable,
	id: String,
	name_en: String,
	name_ko: String,
	max_level: int,
	stats_by_level: Array,
	grants_by_level: Dictionary,
	effect_ko: String,
	evolves_into_id: String = "",
	evolved_only: bool = false
) -> void:
	var grant_arrays: Array = []
	if grants_by_level.is_empty():
		for _i in stats_by_level.size():
			grant_arrays.append({})
	else:
		for level_index in stats_by_level.size():
			var level_key := str(level_index + 1)
			grant_arrays.append(grants_by_level.get(level_key, {}))
	target.append(
		create_passive.call(
			id,
			name_en,
			name_ko,
			max_level,
			stats_by_level,
			grant_arrays,
			effect_ko,
			evolves_into_id,
			evolved_only
		)
	)
