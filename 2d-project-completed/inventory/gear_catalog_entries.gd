class_name GearCatalogEntries
extends RefCounted

## gear_catalog_entries.gd — 장비 엔트리 목록(데이터만).


static func append_all(target: Array, create_gear: Callable) -> void:
	_append(target, create_gear, "wooden_shield", "Wooden Shield", "나무 방패", EquipSlots.OFFHAND, {"block_min": 1, "block_max": 1})
	_append(target, create_gear, "leather_tunic", "Leather Tunic", "가죽 튜닉", EquipSlots.ARMOR, {"armor_min": 12, "armor_max": 12})
	_append(target, create_gear, "traveler_boots", "Traveler Boots", "여행자 부츠", EquipSlots.BOOTS, {"move_speed_mult": 1.05})
	_append(target, create_gear, "buckler", "Buckler", "버클러", EquipSlots.OFFHAND, {"block_min": 1, "block_max": 1})
	_append(target, create_gear, "slime_orb", "Slime Orb", "슬라임 오브", EquipSlots.OFFHAND, {"power": 10, "grant_orbital": "sticky_orbital"}, "Grants a Sticky Orbital that deals 65 to 135 Striking Damage and inflicts Sticky Goo.", "끈적 궤도를 부여합니다. 타격 65~135 피해, 끈적이(Goo) 부여.", 1)
	_append(target, create_gear, "round_shield", "Round Shield", "라운드 실드", EquipSlots.OFFHAND, {"block_min": 1, "block_max": 1, "armor_min": 1, "armor_max": 1})
	_append(target, create_gear, "quiver", "Quiver", "화살통", EquipSlots.OFFHAND, {"weapon_damage_mult": 1.2})
	_append(target, create_gear, "pyromancy_orb", "Pyromancy Orb", "화염술 오브", EquipSlots.OFFHAND, {"power": 10, "grant_orbital": "pyromancy_orbital"}, "Grants a Pyromancy Orbital that deals 80 to 120 Fire Damage and inflicts Burn.", "화염술 궤도를 부여합니다. 화염 80~120 피해, 화상 부여.", 1)
	_append(target, create_gear, "plank_shield", "Plank Shield", "판자 방패", EquipSlots.OFFHAND, {"block_min": 1, "block_max": 1})
	_append(target, create_gear, "daisy_circlet", "Daisy Circlet", "데이지 서클렛", EquipSlots.HELMET, {"suppression_min": 1, "suppression_max": 1})
	_append(target, create_gear, "lavender_circlet", "Lavender Circlet", "라벤더 서클렛", EquipSlots.HELMET, {"defy_death_min": 1, "defy_death_max": 1})
	_append(target, create_gear, "poppy_circlet", "Poppy Circlet", "포피 서클렛", EquipSlots.HELMET, {"heart_min": 1, "heart_max": 1})
	_append(target, create_gear, "knight_helmet", "Knight Helmet", "기사 투구", EquipSlots.HELMET, {"armor_min": 1, "armor_max": 1})
	_append(target, create_gear, "kettle_helm", "Kettle Helm", "케틀 헬름", EquipSlots.HELMET, {"suppression_min": 1, "suppression_max": 1})
	_append(target, create_gear, "bandana", "Bandana", "반다나", EquipSlots.HELMET, {"debuff_effect_mult": 1.25})
	_append(target, create_gear, "bunny_ears", "Bunny Ears", "토끼 귀", EquipSlots.HELMET, {"move_speed_mult": 1.1}, "", "", 0)
	_append(target, create_gear, "buttercup_circlet", "Buttercup Circlet", "버터컵 서클렛", EquipSlots.HELMET, {"stamina": 1})
	_append(target, create_gear, "cornflower_circlet", "Cornflower Circlet", "코른플라워 서클렛", EquipSlots.HELMET, {"mana_min": 1, "mana_max": 1})
	_append(target, create_gear, "ninja_headband", "Ninja Headband", "닌자 머리띠", EquipSlots.HELMET, {"stamina": 1})
	_append(target, create_gear, "skull_cap", "Skull Cap", "해골 모자", EquipSlots.HELMET, {"melee_attack_speed_mult": 1.1})
	_append(target, create_gear, "ronin_hat", "Ronin Hat", "낭인 모자", EquipSlots.HELMET, {"sword_crit_chance_bonus": 0.1})
	_append(target, create_gear, "retina_refractor", "Retina Refractor", "망막 굴절기", EquipSlots.HELMET, {"energy_damage_mult": 1.2})
	_append(target, create_gear, "ranger_cap", "Ranger Cap", "레인저 모자", EquipSlots.HELMET, {"ranged_attack_speed_mult": 1.1})
	_append(target, create_gear, "wilted_circlet", "Wilted Circlet", "시든 서클렛", EquipSlots.HELMET, {"curse": 3})
	_append(target, create_gear, "witch_hat", "Witch Hat", "마녀 모자", EquipSlots.HELMET, {"magic_attack_speed_mult": 1.1})
	_append(target, create_gear, "wizard_hat", "Wizard Hat", "마법사 모자", EquipSlots.HELMET, {"mana_recovery_mult": 1.2})
	_append(target, create_gear, "pouchy_robe", "Pouchy Robe", "파우치 로브", EquipSlots.ARMOR, {"flask_min": 1, "flask_max": 1})
	_append(target, create_gear, "chain_armor", "Chain Armor", "사슬 갑옷", EquipSlots.ARMOR, {"armor_min": 1, "armor_max": 1})
	_append(target, create_gear, "steel_plate_armor", "Steel Plate Armor", "강철 판금 갑옷", EquipSlots.ARMOR, {"armor_min": 2, "armor_max": 2})
	_append(target, create_gear, "warrior_armor", "Warrior Armor", "전사 갑옷", EquipSlots.ARMOR, {"heart_min": 1, "heart_max": 1}, "", "", 0)
	_append(target, create_gear, "cloth_robe", "Cloth Robe", "천 로브", EquipSlots.ARMOR, {"heart_min": 1, "heart_max": 1})
	_append(target, create_gear, "cleric_robe", "Cleric Robe", "성직자 로브", EquipSlots.ARMOR, {"revive_min": 1, "revive_max": 1}, "", "", 3)
	_append(target, create_gear, "bubble_armor", "Bubble Armor", "버블 아머", EquipSlots.ARMOR, {"suppression_min": 1, "suppression_max": 1}, "", "", 3)
	_append(target, create_gear, "battle_vest", "Battle Vest", "전투 조끼", EquipSlots.ARMOR, {"melee_damage_mult": 1.2}, "", "", 0)
	_append(target, create_gear, "druid_coat", "Druid Coat", "드루이드 코트", EquipSlots.ARMOR, {"nature_damage_mult": 1.2}, "", "", 0)
	_append(target, create_gear, "festive_dress", "Festive Dress", "축제 드레스", EquipSlots.ARMOR, {"stamina_recovery_mult": 1.3})
	_append(target, create_gear, "harlequin_costume", "Harlequin Costume", "할레킨 의상", EquipSlots.ARMOR, {"stamina": 1})
	_append(target, create_gear, "necromancer_coat", "Necromancer Coat", "강령술사 코트", EquipSlots.ARMOR, {"companion_damage_mult": 1.35})
	_append(target, create_gear, "monk_gi", "Monk Gi", "승려 도복", EquipSlots.ARMOR, {"block_min": 1, "block_max": 1})
	_append(target, create_gear, "pyromancer_coat", "Pyromancer Coat", "화염술사 코트", EquipSlots.ARMOR, {"fire_damage_mult": 1.2}, "", "", 0)
	_append(target, create_gear, "sage_robe", "Sage Robe", "현자 로브", EquipSlots.ARMOR, {"magic_damage_mult": 1.2}, "", "", 0)
	_append(target, create_gear, "shinobi_suit", "Shinobi Suit", "시노비 슈트", EquipSlots.ARMOR, {"throwing_damage_mult": 1.2}, "", "", 0)
	_append(target, create_gear, "sorcerer_cloak", "Sorcerer Cloak", "소서러 망토", EquipSlots.ARMOR, {"mana_recovery_mult": 1.3})
	_append(target, create_gear, "super_hero_suit", "Super Hero Suit", "슈퍼 히어로 슈트", EquipSlots.ARMOR, {"invincibility_after_damage_sec": 4})
	_append(target, create_gear, "town_guard_armor", "Town Guard Armor", "마을 경비 갑옷", EquipSlots.ARMOR, {"weapon_upgrade_level": 1}, "", "", 0)
	_append(target, create_gear, "wizard_cloak", "Wizard Cloak", "마법사 망토", EquipSlots.ARMOR, {"mana_min": 1, "mana_max": 1})
	_append(target, create_gear, "bone_gloves", "Bone Gloves", "뼈 장갑", EquipSlots.GLOVES, {"companion_attack_speed_mult": 1.2}, "", "", 0)
	_append(target, create_gear, "dart_wrists", "Dart Wrists", "다트 손목", EquipSlots.GLOVES, {"grant_on_dash": "darts", "dart_damage_min": 575, "dart_damage_max": 780}, "On Dash, triggers Darts that deal 575 to 780 Thrusting Damage.", "대시 시 다트를 발사합니다. 관통 575~780 피해.", 1)
	_append(target, create_gear, "leather_gloves", "Leather Gloves", "가죽 장갑", EquipSlots.GLOVES, {"attack_speed_mult": 1.1}, "", "", 0)
	_append(target, create_gear, "iron_gauntlets", "Iron Gauntlets", "철 건틀릿", EquipSlots.GLOVES, {"armor_min": 1, "armor_max": 1})
	_append(target, create_gear, "iron_greaves", "Iron Greaves", "철 그리브", EquipSlots.BOOTS, {"armor_min": 1, "armor_max": 1})
	_append(target, create_gear, "house_slippers", "House Slippers", "실내 슬리퍼", EquipSlots.BOOTS, {"heart_min": 1, "heart_max": 1})
	_append(target, create_gear, "phantom_steps", "Phantom Steps", "팬텀 스텝", EquipSlots.BOOTS, {"invincibility_after_dash_sec": 0.25})
	_append(target, create_gear, "jester_boots", "Jester Boots", "광대 부츠", EquipSlots.BOOTS, {"stamina_recovery_mult": 1.35})
	_append(target, create_gear, "geta", "Geta", "게타", EquipSlots.BOOTS, {"grant_on_dash": "haste"}, "On Dash, gain Haste.", "대시 시 가속(Haste) 획득.", 1)
	_append(target, create_gear, "tabi", "Tabi", "타비", EquipSlots.BOOTS, {"wall_near_move_speed_mult": 1.2})
	_append(target, create_gear, "wool_shoes", "Wool Shoes", "양모 신발", EquipSlots.BOOTS, {"stamina": 1}, "", "", 0)
	_append(target, create_gear, "apprentice_boots", "Apprentice Boots", "견습생 부츠", EquipSlots.BOOTS, {"damage_mult": 1.6, "damage_mult_per_level": -0.1})
	_append(target, create_gear, "leather_boots", "Leather Boots", "가죽 부츠", EquipSlots.BOOTS, {"move_speed_mult": 1.1}, "", "", 0)
	_append(target, create_gear, "heart_vial_pendant", "Heart Vial Pendant", "심장 비약 펜던트", EquipSlots.ACCESSORY, {"flask_min": 1, "flask_max": 1})
	_append(target, create_gear, "amethyst_ring", "Amethyst Ring", "자수정 반지", EquipSlots.ACCESSORY, {"heart_min": 1, "heart_max": 1})
	_append(target, create_gear, "blue_ribbon", "Blue Ribbon", "파란 리본", EquipSlots.ACCESSORY, {"intelligence_stat_mult": 1.25}, "", "", 0)
	_append(target, create_gear, "bamboo_bracelet", "Bamboo Bracelet", "대나무 팔찌", EquipSlots.ACCESSORY, {"ranged_damage_mult": 1.1}, "", "", 0)
	_append(target, create_gear, "green_ribbon", "Green Ribbon", "초록 리본", EquipSlots.ACCESSORY, {"dexterity_stat_mult": 1.25})
	_append(target, create_gear, "knight_ring", "Knight Ring", "기사 반지", EquipSlots.ACCESSORY, {"strength": 5})
	_append(target, create_gear, "red_ribbon", "Red Ribbon", "빨간 리본", EquipSlots.ACCESSORY, {"strength_stat_mult": 1.25}, "", "", 0)
	_append(target, create_gear, "ranger_ring", "Ranger Ring", "레인저 반지", EquipSlots.ACCESSORY, {"dexterity": 5})
	_append(target, create_gear, "quartz_bracelet", "Quartz Bracelet", "석영 팔찌", EquipSlots.ACCESSORY, {"magic_damage_mult": 1.1})
	_append(target, create_gear, "obsidian_bracelet", "Obsidian Bracelet", "흑요석 팔찌", EquipSlots.ACCESSORY, {"melee_damage_mult": 1.1})
	_append(target, create_gear, "lotus_amulet", "Lotus Amulet", "연꽃 부적", EquipSlots.ACCESSORY, {"stamina_recovery_mult": 1.35})
	_append(target, create_gear, "silver_ring", "Silver Ring", "은 반지", EquipSlots.ACCESSORY, {"fiend_undead_damage_mult": 1.3})
	_append(target, create_gear, "sorcerer_ring", "Sorcerer Ring", "마법사 반지", EquipSlots.ACCESSORY, {"intelligence": 5})
	_append(target, create_gear, "wooden_cross_pendant", "Wooden Cross Pendant", "나무 십자가 펜던트", EquipSlots.ACCESSORY, {"prevent_curse": true})


static func _append(
	target: Array,
	create_gear: Callable,
	id: String,
	name_en: String,
	name_ko: String,
	slot: StringName,
	stats: Dictionary,
	effect_en: String = "",
	effect_ko: String = "",
	attunement: int = 1,
) -> void:
	target.append(create_gear.call(id, name_en, name_ko, slot, stats, effect_en, effect_ko, attunement))

