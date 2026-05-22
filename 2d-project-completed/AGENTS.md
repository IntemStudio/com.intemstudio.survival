# AGENTS — Godot 2D Survival

## 문서·언어 정책

| 대상 | 언어 | 역할 |
|------|------|------|
| `.cursor/rules/*.mdc` | **영어** (짧은 must/must not) | 에이전트 **실행 규칙** — authoritative |
| `AGENTS.md` (이 파일) | **한국어** + 경로·타입명 영어 | **지도·흐름·이유** (사람용) |
| 코드 주석 (`.gd`) | **한국어** 한 줄 목적 | 비즈니스 맥락; must 문장은 `.mdc`에만 |

제약이 겹치면 **`.mdc`가 우선**입니다. 이 파일은 규칙을 한글로 요약만 하고, 상세 must는 각 `.mdc`를 따릅니다.

---

## 프로젝트 개요

Godot 4.6 기반 **2D 뱀파이어 서바이버류** (GDQuest 튜토리얼 + 확장). 한 판에서 이동·대시·접촉 피해·레벨업·무기 선택·시간에 따른 몹 웨이브 생존을 처리합니다.

- **실행 씬:** `survivors_game.tscn` (`project.godot` → `run/main_scene`)
- **오케스트레이션:** 루트 노드 `Game` + `game/game.gd`
- **Autoload 없음** — 다수 스크립트가 `/root/Game` 경로를 하드코딩

---

## 폴더 지도

| 경로 | 역할 |
|------|------|
| `survivors_game.tscn` | 메인 씬: `Game`, `Timer`, `%ObjectPools`, `Player`+스폰 경로, HUD, 일시정지, 무기 UI, `%GameOver`·`%WeaponDamageList` |
| `game/game.gd` | 스폰 타이머, 밸런스 시계, 처치 HUD, 일시정지/게임오버, 무기 선택, 무기별 피해 집계·게임오버 표시 |
| `game/weapon_damage_tracker.gd` | `WeaponDamageTracker` — 무기 `get_unique_key()`별 누적 피해, 게임오버 행 목록 생성 |
| `game/pool/` | `ScenePool` (`scene_pool.gd`), `PoolUtil` — 공통 `acquire` / `release` |
| `game/balance/` | `BalanceTable`, `BalanceTimeline`, phase, `MobSpawnSelector`, `default_balance_table.tres`, `default_balance_timeline.tres` |
| `test_arena.tscn` | **테스트 전용** 씬: `Game` + `game/test_arena.gd` — 몹/무기 수동 스폰, 리스폰 (`run/main_scene` 아님, **F6**) |
| `game/test_arena.gd` | 테스트 아레나 오케스트레이션(스폰·무기 Equip·플레이어/몹 리스폰) |
| `entities/player/` | 이동, 대시·쿨다운 게이지, 경험치, 무기 컨테이너, 피격, **자동 공격 토글(F)** |
| `entities/mob/` | 공용 `mob.gd` + 변종 `.tscn`(플레이 **7종** + 테스트 전용 `mob_dummy`); ranged 전용 `mob_projectile`·`mob_attack_mark` |
| `weapons/` | `WeaponData`, catalog, `gun`, `melee_projectile`·`area_damage_zone`·탄환·마법 등 |
| `ui/` | 무기 선택(3택1 + 설명 + 자동 선택·우선순위), 일시정지 |
| `effects/exp_orb/` | 경험치 오브 (`exp_orbs` 그룹, `ScenePool` 적용) |
| `effects/magnet_pickup/` | 자석 아이템 (1% 드랍, 풀 미적용) |
| `effects/health_pickup/` | 체력 회복 아이템 (1% 드랍, +30 HP, 풀 미적용) |
| `effects/hit_flash/` | `HitFlash` — 피격 시 `CanvasItem.modulate` 짧은 깜박임(풀·씬 없음, 정적 API) |
| `effects/` (기타) | 데미지 텍스트, 사망 연기 등 |
| `characters/` | Slime / HappyBoo 비주얼 |

---

## 런타임 흐름 (요약)

1. `_ready`: `BalanceTable` 로드 → 시작 무기 선택(버튼 호버 시 `%WeaponSelectMenu` 설명 패널) → 트리 `paused`
2. `Game.show_weapon_select` → `present_random_choices` → `show()` → `on_menu_opened()` → `paused`. 닫을 때 `on_menu_closed()` → `hide()` (`game.gd`)
3. `on_weapon_chosen` → `Player.add_weapon` → `_ensure_game_started` → 스폰 `Timer` 시작
4. 타이머마다: `%PathFollow2D` 위치에 `spawn_mob` (`ScenePool`으로 몹 acquire) → `initialize_spawn_health`로 HP
5. `leveled_up` → 무기 선택 대기열; 메뉴가 열려 있으면 스폰 시계 정지. 선택 UI는 `WeaponSelectMenu.present_random_choices` → 버튼 라벨 + `WeaponData.build_select_tooltip_bbcode()` 상세
6. `health_depleted` → `%GameOverTitle` `"Game Over"` · 무기별 피해 · `paused`
7. 표 축 **30분** → 클리어: `Timer` 정지 · `mobs` → `die_from_stage_clear()`(연기만, 드랍·처치 없음) · `%GameOverTitle` `"클리어!"` · `paused` (실시간 = `1800 / balance_pace_multiplier`초)
8. `_process`(시계 가동 중): `BalanceTimeline` 9·11·25·28분 1회 발동 · 밀도 버스트 시 `spawn_density × density_mult`
9. 몹 일반 `_die()` → `register_kill` → 연기 → 오브(`ScenePool`) → 1% 자석·체력 → `PoolUtil.release_node`

---

## 테스트 아레나 (`test_arena.tscn`)

밸런스·레벨업·게임오버 없이 **몹·무기·피해**만 빠르게 검증하는 씬입니다. 메인 루프와 **씬·스크립트가 분리**되어 있고, `project.godot`의 `run/main_scene`은 `survivors_game.tscn` 그대로입니다.

| 항목 | 내용 |
|------|------|
| 실행 | Godot에서 `test_arena.tscn` 연 뒤 **F6**(현재 씬 실행). F5는 메인 게임 |
| 루트 계약 | 노드 이름 **`Game`**, 자식 **`Player`**, **`ObjectPools`** — `mob.gd`의 `/root/Game/Player`·풀 경로와 동일해야 함 |
| 오케스트레이션 | `game/test_arena.gd` (`game.gd` 대체). `is_weapon_select_open` / `is_pause_menu_open` / `is_game_over` 스텁으로 `player.gd` F키·입력 차단과 호환 |

### UI (탭 없음 — `TestUI` 세로 패널)

| 블록 | 동작 |
|------|------|
| **몹** | `%MobTypeOption` + **Spawn** → `spawn_test_mob` (`ScenePool` + `initialize_spawn_health(1.0)`). 한 번에 1마리(교체 시 이전 몹 `PoolUtil.release_node`) |
| | `%MobRespawnCheck` — 처치 후 `register_kill()` → `mob_respawn_delay`(기본 2초) 뒤 `_last_mob_scene` 재스폰. **Spawn·수동 교체 시** `_mob_respawn_token`으로 대기 콜백 취소 |
| **무기** | 시작 `revolver.tres` Equip. `%WeaponTypeFilter`(전체/원거리/마법/근접) + `%WeaponRarityFilter`(전체/커먼/…) + `%WeaponOption` + **Equip** → `Player.clear_weapons()` 후 `add_weapon` |
| | 필터 결과 0개 → `%StatusLabel` `"조건에 맞는 무기가 없습니다."` |
| **플레이어** | `health_depleted` → 3초 후 스폰 지점·최대 HP·이전 자동공격 복구. `player.reset_health_depleted_state()` 호출 |

### 몹 목록 (UI 8종)

`MobSpawnSelector` 상수와 동일 + **`MOB_DUMMY_SCENE`** (`mob_dummy.tscn`).

| UI 라벨 | 비고 |
|---------|------|
| Basic ~ Special B | 메인과 동일 7변종 |
| **Dummy (static)** | `movement_enabled`·`combat_enabled` = false — 이동·원거리 공격 없음. **메인 `pick_scene`·밸런스 스폰에는 미포함**(테스트·풀 prewarm만) |

**더미 주의:** 접촉 DPS(`%HurtBox`)는 그대로 — 완전 무피해 허수아비가 필요하면 `mob_kind`/collision 별도 정책 필요.

### `mob.gd` export (변종·더미 공용)

- `movement_enabled` — false면 추적·몹 분리 이동 없음, 슬라임 `play_idle()`
- `combat_enabled` — false면 원거리 텔레그래프/발사 없음

### 플레이어 (`player.gd` 연동)

- `health_depleted` — `_health_depleted_emitted`로 **1회만** emit(접촉·투사체 공통). 회복·`reset_health_depleted_state()` 시 해제
- `clear_weapons()` — 테스트 Equip 전 `gun.free()` + `_owned_weapons` 비움

**튜닝·확장 시:** 메인에 더미를 넣지 않으려면 `pick_scene`·`default_balance_table.tres`는 건드리지 말 것. 새 테스트 전용 변종은 `MOB_OPTIONS`·`MobSpawnSelector` 상수·`scene_pool` prewarm 목록만 추가해도 됨.

---

## 무기 선택 UI (`WeaponSelectMenu`)

씬: `survivors_game.tscn` — `WeaponSelectMenu/MenuOverlay/.../VBoxContainer` 아래 `AutoSelectRow`, `AutoPriorityPanel`, `ContentHBox`(선택 버튼·`DetailPanel`). 스크립트: `ui/weapon_select_menu.gd`.

| 기능 | 동작 |
|------|------|
| 수동 선택 | `ChoicesVBox` 버튼 4개(표시는 `CHOICE_COUNT`=3) → `Game.on_weapon_chosen` |
| 설명 | 호버·포커스·자동 대상 시 `WeaponData.build_select_tooltip_bbcode()` → `DetailLabel` |
| 자동 선택 | `AutoSelectToggle` 켜면 `on_menu_opened` 후 **3초** 뒤 `_pick_auto_select_index()`로 확정 |
| 우선순위 | `AutoPriorityPanel`의 `PrioritySlot0~2` ▲▼ — `_auto_priority_order` (`Ranged`/`Magic`/`Melee` 순서, **한 판 동안** 유지). 기본: 원거리 → 마법 → 근접 |
| 카운트다운 | `AutoSelectCountdownLabel` (`자동 선택까지 N.N초`) |
| 자동 게이지 | 대상 버튼 자식 `AutoGaugeTrack`·`AutoGaugeFill` (`show_behind_parent`) — 글자 위를 가리지 않음 |

**왜 `on_menu_opened` / `on_menu_closed`:** `CanvasLayer`의 `show()`/`hide()`는 네이티브 오버라이드 불가(경고·에러). `game.gd`가 표시·숨김 직후 위 메서드를 호출해 자동 선택 타이머를 시작·정리한다.

**자동 선택 중:** 대상 버튼만 투명 테두리 스타일 + 배경 게이지; 수동 클릭·토글 OFF·우선순위 변경 시 타이머 취소(우선순위 변경 시 자동 ON이면 3초 재시작).

---

## 무기별 피해 집계·게임오버

한 판 동안 몹에게 입힌 피해를 무기 단위로 누적하고, 사망 시 게임오버 패널에 표시합니다.

| 항목 | 동작 |
|------|------|
| 집계 | `Game`의 `WeaponDamageTracker` (`game/weapon_damage_tracker.gd`), 키 = `WeaponData.get_unique_key()` |
| 기록 경로 | `mob.gd` `apply_weapon_damage`·독 틱 `_apply_poison_tick` → `Game.register_weapon_damage` (무기 스크립트에서 직접 호출하지 않음) |
| 독 도트 | `apply_poison` 스택에 `weapon` 보관 — 틱 피해도 해당 무기에 귀속 |
| 게임오버 UI | `survivors_game.tscn` `GameOver/.../WeaponDamagePanel` — `%WeaponDamageList`에 보유 무기 전부(0 포함), 피해량 내림차순 + **합계** |
| 미집계 | `Mob.take_damage`만 쓰는 폴백 경로(무기 없음), 플레이어·몹 투사체 피해 |

**왜 `apply_weapon_damage` 한곳:** 탄환·근접·마법·연금·독 등 대부분이 이미 이 API를 탐. 새 무기도 `health -=` 대신 이 경로를 쓰면 통계·플로팅 텍스트가 같이 맞춰짐.

**튜닝·확장 시:** 게임오버에 처치 수·생존 시간·레벨을 붙일 때는 `game.gd` `_on_player_health_depleted` / `_populate_game_over_weapon_damage` 근처에서 HUD 값을 읽어 라벨만 추가하면 됨.

---

## 무기 공격 전달 방식

`WeaponData.attack_delivery`와 `weapon_type`으로 `gun.shoot()` 분기가 정해집니다. 피해는 항상 `mob.apply_weapon_damage` / `apply_poison` 경유.

| 구분 | 조건 | 씬·코드 | 비고 |
|------|------|---------|------|
| **근접 관통 탄** | `weapon_type == "Melee"` | `melee_projectile.tscn`, `gun._shoot_melee_projectile()` | 사거리 `get_melee_range()`, 속도 `get_melee_projectile_speed()`. 타겟 없어도 발사. `hit_count` > 1이면 충돌 후 0.07s 연타 |
| **영역 존** | `attack_delivery == "AreaZone"` | `area_damage_zone.tscn`, `setup_circle` / `setup_rectangle` | 연금: `concoction` 포물선 착지 → 존 스폰 + 독. 짧은 overlap 펄스 후 풀 반환 |
| **원거리 탄** | `Ranged`, `Bullet` | `bullet_2d.tscn` | 1몹 1타 후 소멸 |
| **투척·연금 비행** | `Throwing` + `projectile_scene` | `concoction` 등 | 영역 무기도 비행 껍데기는 유지, **피해는 착지 존** |
| **마법** | `Magic` | `magic_bolt`, `king_bible_orb` | 궤도는 `Orbit` |

**삭제됨:** `melee_swipe` — 근접은 발사체만, 영역은 `AreaDamageZone`만 사용.

**튜닝·확장 시:** 새 영역 무기는 `attack_delivery = "AreaZone"` + `aoe_radius`(원형) 또는 `setup_rectangle`. 새 근접은 카탈로그 `Melee`만으로 `melee_projectile` 자동.

---

## 픽업·경험치·자석

| 대상 | 스폰 | 수집 | 비고 |
|------|------|------|------|
| 경험치 오브 | `mob.gd` `_die()` → `ScenePool.acquire(EXP_ORB_SCENE)` | `Player` `%PickupRange`(layer 4) → `start_magnet` / 플레이어 근접 시 자동 자석 | 수집 시 `gain_experience` → `PoolUtil.release_node` |
| 자석 아이템 | `_die()`에서 `randf() < 0.01` → `magnet_pickup.tscn` `instantiate` | `%PickupRange` → `collect(player)` | `exp_orbs` 그룹 전원 `start_magnet(player)` 후 `queue_free` |
| 체력 아이템 | `_die()`에서 `randf() < 0.01` → `health_pickup.tscn` `instantiate` | `%PickupRange` → `collect(player)` | `heal_health(heal_amount)` (기본 30, 최대 체력까지) 후 `queue_free` |

- **물리:** 픽업·오브·자석 모두 `Area2D`, `collision_layer = 4`. 플레이어 `PickupRange`는 `collision_mask = 4`.
- **비주얼:** 오브 scale `0.35`(파란), 자석·체력 `0.7`(주황·초록, 오브의 2배).
- **플레이어 분기:** `player.gd` `_on_pickup_range_area_entered` — `collect` 우선, 없으면 `start_magnet`.
- **자석·체력은 풀 밖:** 드랍 빈도가 낮아 `ScenePool` 미사용. 풀 도입 시 `pool_reset`/`pool_on_acquire`·`PoolUtil.release_node` 계약 필요.

---

## 플레이어 이동·대시

| 항목 | 값/동작 |
|------|---------|
| 이동 입력 | `move_left` / `move_right` / `move_up` / `move_down` (WASD, `project.godot`) |
| 대시 입력 | `dash` (스페이스) |
| 자동 공격 토글 | `toggle_auto_attack` (F) — [자동 공격 토글](#자동-공격-토글) |
| 이동 속도 | 600 (`player.gd` `_physics_process`) |
| 대시 방향 | 현재 이동 입력 벡터; 입력 없으면 `_last_move_direction`(최근 이동 방향) |
| 대시 속도·지속 | 1400, 0.18초 — 대시 중에는 방향 고정, 일반 이동 입력 무시 |
| 쿨다운 | 0.5초 (`DASH_COOLDOWN`) |
| 무적 | 없음 — 대시 중에도 접촉 피해 동일 ([접촉 피해](#플레이어-접촉-피해) 참고) |

- **쿨다운 게이지:** `player.tscn` `%DashCooldownBar` (56×12, 발밑 `ProgressBar`). `_dash_cooldown_remaining > 0`일 때만 표시, 채움 = 경과 쿨다운, 0이 되면 `visible = false`. 갱신은 `player.gd` `_update_dash_cooldown_gauge()`.
- **플레이어 `%` 노드:** `%HappyBoo`, `%Weapons`, `%HurtBox`, `%PickupRange`, `%HealthBar`, `%DashCooldownBar` — 이름·경로 변경 시 `player.gd`·`player.tscn` grep.

---

## 자동 공격 토글

무기는 기본적으로 `gun.gd` 타이머로 자동 발사합니다. **F**로 일시 정지·재개할 수 있습니다(무기 선택 UI의 “자동 선택”과 무관).

| 항목 | 동작 |
|------|------|
| 입력 | `toggle_auto_attack` (**F**, `project.godot`) |
| 상태 | `player.gd` `auto_attack_enabled` (기본 `true`) |
| HUD | `survivors_game.tscn` `%AutoAttackLabel` — `자동 공격: ON/OFF (F)`, ON 녹색·OFF 붉은색 |
| 일반 무기 | `gun.gd` `_shoot_timer` 정지·`refresh_auto_attack()` 재개; OFF 시 `_on_timer_timeout`도 무시 |
| 궤도 마법 | `king_bible_orb.gd` — 플레이어 `is_auto_attack_enabled()`가 false면 궤도·이동만, 피해 없음 |
| 입력 차단 | 무기 선택·일시정지·게임오버 중 F 무시 (`_is_auto_attack_input_blocked`) |

**왜 플레이어가 소유:** `Gun`이 `_get_player()`로 상태를 읽고, `set_auto_attack_enabled` 시 `%Weapons` 자식 전원에 `refresh_auto_attack()` 호출. 새 무기 장착 시에도 OFF면 타이머가 켜지지 않음(`_start_shooting` 게이트).

**튜닝·확장 시:** 수동 1회 공격(키 홀드) 등을 넣을 때는 `gun.shoot()`와 타이머 경로를 분리하고, OFF 상태에서도 허용할지 정책을 먼저 정한 뒤 `godot-weapons.mdc`와 같이 맞출 것.

---

## 플레이어 접촉 피해

플레이어 이동·대시와 무관하게, `%HurtBox`와 겹친 몹 `CharacterBody2D`가 있으면 매 프레임 체력이 깎입니다 (`player.gd` `_physics_process`).

| 항목 | 값·위치 |
|------|---------|
| 판정 | `%HurtBox.get_overlapping_bodies()` — `collision_mask = 2` (몹 레이어) |
| HurtBox 크기 | `player.tscn` 사각형 **84×54** (`monitorable = false`) |
| 초당 피해 | `DAMAGE_RATE = 6.0` × **겹친 몹 수** |
| 플로팅 숫자 | `DAMAGE_FLOAT_INTERVAL = 0.2`초마다, `maxi(int(누적), 1)` → 화면 **최소 1** (실제 DPS와 체감이 다를 수 있음) |
| 피격 깜박임 | 플로팅 숫자와 **동일 0.2초 간격**으로 `HitFlash` ([피격 깜박임](#피격-깜박임-hitflash) 참고) |

**가만히 서 있어도 맞는 이유**

1. 몹은 `Player/Path2D`의 `%PathFollow2D`에 스폰된 뒤 플레이어를 추적합니다.
2. `mob.gd`는 중심 간 거리가 `attack_distance`(기본 **85**) 이하이면 `velocity = 0`으로 정지합니다.
3. 정지 거리(중심↔중심)와 충돌체 크기는 별개입니다. 기본 몹 원형 충돌 **r≈67**(Y 오프셋 -28) + HurtBox 사각형이면, 85px에서 멈춰도 **HurtBox와 물리 겹침이 남아** 접촉 피해가 계속됩니다.
4. 스폰 타이머가 돌면 주변에 몹이 쌓이고, 겹친 수만큼 피해량이 배수됩니다.

**튜닝 시 같이 볼 것:** `mob.gd` `attack_distance`, 몹 `.tscn` `CollisionShape2D`, `player.tscn` `HurtBox`, `player.gd` `DAMAGE_RATE` / `DAMAGE_FLOAT_INTERVAL`. 한쪽만 바꾸면 “멈췄는데 안 맞음” 또는 “멀리서 1씩 뜸”처럼 어긋날 수 있습니다.

---

## 피격 깜박임 (`HitFlash`)

몹·플레이어가 **실제로 HP가 깎일 때** 스프라이트 `modulate`를 잠깐 밝게 깜박입니다. `FloatingDamageText`와 별도이며, `ScenePool` 대상이 아닙니다.

| 항목 | 동작 |
|------|------|
| API | `effects/hit_flash/hit_flash.gd` — `HitFlash.play(target, restore_modulate)`, `HitFlash.cancel(...)` |
| 몹 대상 | `%Slime` — 복구 색은 `slime_tint` (`pool_on_acquire`에서 설정) |
| 몹 호출 | `mob.gd` `_play_hit_flash()` ← `take_damage`, `apply_weapon_damage`, 독 틱 `_apply_poison_tick` |
| 몹 추가 연출 | 기존 `%Slime.play_hurt()` 애니(얼굴·몸 hurt 스프라이트)와 **병행** |
| 플레이어 대상 | `%HappyBoo/Colorizer` — `_ready`에서 `modulate` 캐시 후 복구 |
| 플레이어 호출 | `apply_mob_projectile_damage` 1회당 1회; 접촉 DPS는 플로팅 숫자와 같이 **0.2초마다** 1회 |
| 풀 반환 | `mob.gd` `pool_reset` → `HitFlash.cancel(%Slime, slime_tint)` (트윈·색 초기화) |
| 연타 | 같은 `target`에 새 `play` 시 기존 트윈 `kill` 후 재시작 |

**튜닝:** `hit_flash.gd`의 `FLASH_MULTIPLIER`(기본 2.4), `BLINK_COUNT`(2), `BLINK_ON_SEC` / `BLINK_OFF_SEC`. 몹 tint·플레이어 `Colorizer` 색을 바꿨으면 `restore_modulate` 인자가 맞는지 확인.

**왜 modulate:** 캐릭터 프리팹마다 hurt 애니 유무가 다르지만(슬라임만 전용 hurt 트랙), `CanvasItem`은 공통이라 한 API로 통일. 새 변종 몹도 `%Slime`만 맞으면 추가 씬 작업 없음.

**튜닝·확장 시:** i-frame·넉백을 넣을 때 깜박임을 “무적 중에는 생략”할지 정책을 먼저 정한 뒤 `player.gd`·`mob.gd` 호출부만 게이트하면 됨.

---

## 원거리 몹 (`mob_ranged`)

`mob_ranged.tscn`만 `ranged_attack_enabled = true`. AI·발사·예고는 공용 `mob.gd`; 비주얼·수치는 프리팹 export.

### 스폰

- `MobSpawnSelector.pick_scene` — `phase.ranged_spawn_ratio` 구간에서 `MOB_RANGED_SCENE` (fast 다음 우선순위).
- `default_balance_table.tres` — **8분부터** `ranged_spawn_ratio` > 0 (VS형 A). **25분부터** `boss_spawn_enabled`. **11분** `spawn_density` 피크(1.75), **16~20분** 호흡(밀도 1.35→1.25).

### 전투 루프

| 단계 | 동작 |
|------|------|
| 이동 | 중심 간 `distance > attack_distance`(ranged **360**) → 추적, 이하 → 정지 |
| 예고 | `mob_attack_mark`를 몹 자식으로 풀 acquire → 머리 위(`ranged_attack_mark_offset`, 기본 `(0,-72)`) |
| 대기 | `ranged_telegraph_delay`(기본 **0.5초**, `create_timer` — 일시정지 시 함께 정지) |
| 발사 | 타이머 후 `mob_projectile` 풀 spawn → `PoolUtil.release_node`로 마크 제거 |
| 쿨다운 | 발사 직후 `ranged_cooldown`(기본 1.4초); 예고 중 `_ranged_windup_active`로 중복 예고 방지 |

### 피해·물리

| 항목 | 값·경로 |
|------|---------|
| 투사체 피해 | `player.apply_mob_projectile_damage` — `take_damage`/`WeaponDamageTracker` **미경유** |
| 접촉 DPS | `%HurtBox` 기존과 **동시 가능** (가까이 붙으면 둘 다) |
| 투사체 물리(A안) | `mob_projectile` `collision_mask = 1`; `body == Player`만 피해, `StaticBody2D`(소나무)는 탄 소멸 |
| 탄 비행 | `ranged_max_distance` 900, `ranged_projectile_speed` 520 (발사 거리 ≠ `attack_distance`) |

### 비주얼

- 보라 슬라임 `slime_tint`, HP 바 보라.
- `AttackRangeRing` — `attack_distance` 반경 링 (`_sync_attack_range_ring`, `pool_on_acquire` 시 갱신).
- 예고 마크 — 주황빛 `circle.png`, 슬라임 tint 기반.

### 풀 (`ObjectPools`)

| 씬 | prewarm 기본 |
|----|----------------|
| `mob_projectile.tscn` | 32 |
| `mob_attack_mark.tscn` | 20 |

사망·`pool_reset` 시 `_cancel_ranged_telegraph()` — 마크 반환, 탄환 미발사.

### 주요 export (`mob_ranged.tscn` / `mob.gd`)

`attack_distance`, `ranged_attack_enabled`, `ranged_cooldown`, `ranged_damage_min/max`, `ranged_projectile_speed`, `ranged_max_distance`, `ranged_spawn_offset`, `ranged_telegraph_delay`, `ranged_attack_mark_offset`.

**튜닝 시:** 몹 `collision_layer` 2 유지. 투사체 전용 레이어(B안)는 `godot-core.mdc` 물리 mask 일괄 변경 필요 — 현재 미적용.

---

## 밸런스 모델 (왜 이렇게 동작하는지)

### 공통

- phase는 **분(minute)** 키프레임; `BalanceTable.get_phase_for_time(elapsed)`가 키 사이 **선형 보간**
- 곡선 축(분) = `BalanceTable.get_curve_minutes(elapsed_seconds)` (`balance_table.gd` — 타임라인·`game.gd` 공용)
- `boss_spawn_enabled`, `special_mob_count`는 보간 후 **계단(step)** (`_finalize_phase`)
- 스폰 비율 합 > 1 시 `_normalize_spawn_ratios`
- 스폰: `Game.spawn_mob(forced_scene?, ignore_alive_cap?)` → `ScenePool` → `initialize_spawn_health(phase.hp_multiplier)`

### VS형 곡선 (구현됨 — Plan A·B·C)

| 단계 | 리소스·코드 | 요약 |
|------|-------------|------|
| **A** | `default_balance_table.tres` | 0·4·5·8·9·11·14·16·20·24·25·28·30분 키프레임. **11분** `spawn_density` 1.75. **16~20** 밀도 dip(1.35→1.25). **25분** `boss_spawn_enabled`. 35·40 = 30분 plateau |
| **B** | `default_balance_timeline.tres`, `game.gd`, `balance_notice_banner.gd` | 표 축 **9** elite 1 · **11** 밀도×1.4 45초 · **25** 보스 1 · **28** 밀도×1.35 40초. 강제 스폰은 `ignore_alive_cap`. 이벤트 키 `event_id`. 밀도 버스트 겹침 시 `max(배율·잔여시간)` |
| **C** | `game.gd`, `mob.gd`, `%GameOverTitle` | 표 **30분** 클리어 · `die_from_stage_clear()` · 드랍·처치·연기 없음 |

- **`balance_pace_multiplier`** (`BalanceTable`, 기본 1.0): 2.0이면 30분 키프레임 ≈ 실시간 **15분**에 도달
- **미구현 (BACKLOG):** D 플레이어 레벨↔몹 HP · E 25분 하이퍼 · F 플레이테스트 튜닝 — [`Docs/Plan_Balance_VS_Curve_Alignment.md`](Docs/Plan_Balance_VS_Curve_Alignment.md)

### 몹·원거리

- 변종: 프리팹 + `MobSpawnSelector`. **ranged** 8분+ (`ranged_spawn_ratio` > 0). 행동은 `mob.gd` 공용
- **테스트 더미:** `movement_enabled`/`combat_enabled` off, 메인 스폰·타임라인 없음

---

## 자주 쓰는 Godot 패턴

- 메인 씬 스크립트에서 `%UniqueNode` 참조
- 기본 리소스·VFX: `preload("res://...")`
- 살아 있는 몹: `get_tree().get_nodes_in_group("mobs")` (풀에 있는 비활성 몹은 그룹에 없음)
- 무기 추가·몹 사망: `call_deferred`
- 무기 데이터: `WeaponData` Resource + catalog 풀 → 랜덤 3택1; 설명·자동 선택 UI는 `ui/weapon_select_menu.gd` + `survivors_game.tscn` (`AutoSelectRow`, `AutoPriorityPanel`, `ContentHBox/DetailPanel`)

## 오브젝트 풀 (`ScenePool`)

런타임에 자주 생성·파괴되는 노드는 **풀 클래스를 타입마다 두지 않고**, `Game/ObjectPools` 한 곳에서 `PackedScene`만 넘겨 재사용합니다.

| API | 용도 |
|-----|------|
| `ScenePool.acquire(scene, parent)` | 꺼내기 → `pool_reset` → 부모 재부착 → 활성화 → `pool_on_acquire`(마지막). 위치·`setup`·HP는 호출자가 `acquire` 반환 후 설정 |
| `PoolUtil.release_node(node)` | 반환(풀 미등록이면 `queue_free`) |

**이미 풀 적용:** 발사체(`gun.gd` — 총알·`melee_projectile`·마법 등), **영역 존**(`area_damage_zone`, 연금 착지), 경험치 오브(`mob.gd` `_die`), 몹 7종+더미 prewarm, 몹 투사체·공격 예고 마크.

**풀링 노드 계약:** 스크립트에 `pool_reset()` / `pool_on_acquire()` 구현. **매 스폰 설정은 `_ready`가 아니라** `pool_on_acquire` 또는 호출자 설정(`initialize_spawn_health` 등). 수명 종료는 `queue_free` 대신 `PoolUtil.release_node(self)`. 그룹 `exp_orbs`는 `pool_on_acquire`에서 추가, `pool_reset`에서 제거.

**prewarm:** `ObjectPools` 인스펙터(`prewarm_*`) 또는 `scene_pool.gd`의 `MOB_SCENES` 등. 새 몹 변종 추가 시 `MobSpawnSelector`와 `ScenePool.MOB_SCENES`를 같이 갱신.

**풀 미적용(의도·백로그):** `magnet_pickup`, `health_pickup`(저빈도 `instantiate`/`queue_free`), `FloatingDamageText`, `smoke_explosion`, `poison_explosion`, `concoction`(풀 spawn은 되나 `pool_reset`/release 미완).

에이전트 must: [`.cursor/rules/godot-pool.mdc`](.cursor/rules/godot-pool.mdc)

---

## 작업별로 먼저 볼 파일

| 작업 | 파일 |
|------|------|
| 오브젝트 풀 | `game/pool/scene_pool.gd`, `pool_util.gd`, `survivors_game.tscn` (`ObjectPools`) |
| 스폰·시간·UI | `game/game.gd`, `survivors_game.tscn` |
| 무기별 피해·게임오버 통계 | `game/weapon_damage_tracker.gd`, `game/game.gd` (`register_weapon_damage`, `_populate_game_over_weapon_damage`), `entities/mob/mob.gd` (`apply_weapon_damage`, `apply_poison`), `survivors_game.tscn` (`%WeaponDamageList`) |
| 난이도 곡선·타임라인·클리어 | `default_balance_table.tres`, `default_balance_timeline.tres`, `balance_table.gd`, `balance_timeline*.gd`, `game.gd` (`_trigger_stage_clear`, `_tick_balance_timeline`) |
| 몹 타입 추가 | `mob.gd`, `mob_spawn_selector.gd`, `mob_*.tscn`, balance `.tres` (메인 스폰 시). 테스트 전용만이면 `MOB_DUMMY`처럼 상수+prewarm+`test_arena` `MOB_OPTIONS` |
| 테스트 아레나 | `test_arena.tscn`, `game/test_arena.gd`, `MobSpawnSelector`, `scene_pool.gd` prewarm, `player.gd` (`clear_weapons`, `reset_health_depleted_state`) |
| 원거리 몹 | `mob.gd`, `mob_ranged.tscn`, `mob_projectile.*`, `mob_attack_mark.*`, `player.apply_mob_projectile_damage`, `mob_spawn_selector.gd`, `default_balance_table.tres` (`ranged_spawn_ratio`), `scene_pool.gd` prewarm |
| 무기 추가 | `weapon_data.gd`, `weapons/catalogs/*`, `gun.gd`, `player.gd`, `ui/weapon_select_menu.gd` |
| 근접·영역 전달 | `weapons/melee/melee_projectile.*`, `weapons/area/area_damage_zone.*`, `weapon_data.gd` (`attack_delivery`, `melee_projectile_speed`), `concoction.gd`, `scene_pool.gd` prewarm |
| 무기 선택·자동 선택 UI | `ui/weapon_select_menu.gd`, `game/game.gd` (`on_menu_opened`/`closed`), `survivors_game.tscn` (`AutoSelectRow`, `AutoPriorityPanel`, `ContentHBox`), `weapon_data.gd` (`build_select_tooltip_bbcode`) |
| 경험치·픽업 아이템 | `effects/exp_orb/exp_orb.gd`, `effects/magnet_pickup/`, `effects/health_pickup/`, `entities/player/player.gd` (`heal_health`), `entities/mob/mob.gd` (드랍 확률) |
| 대시·쿨다운 UI | `entities/player/player.gd`, `entities/player/player.tscn` (`%DashCooldownBar`), `project.godot` (`dash` 입력) |
| 자동 공격 토글·HUD | `player.gd` (`toggle_auto_attack`, `set_auto_attack_enabled`), `gun.gd` (`refresh_auto_attack`), `king_bible_orb.gd`, `survivors_game.tscn` (`%AutoAttackLabel`), `project.godot` |
| 접촉 피해·피격 표시 | `player.gd`/`player.tscn` (`HurtBox`), `mob.gd` (`attack_distance`), `floating_damage_text.gd`, `effects/hit_flash/hit_flash.gd`; 원거리 탄환은 `apply_mob_projectile_damage` |
| 피격 깜박임 | `effects/hit_flash/hit_flash.gd`, `mob.gd` (`_play_hit_flash`, `pool_reset`), `player.gd` (`_play_hit_flash`, `HappyBoo/Colorizer`) |

---

## 연동 규칙 (`.mdc` 요약)

에이전트 must는 **영어 `.mdc` 원문**을 따릅니다.

| 파일 | 붙는 조건 |
|------|-----------|
| `godot-core.mdc` | 항상 (`alwaysApply`) |
| `godot-pool.mdc` | `game/pool/**`, `game/game.gd`, `mob.gd`, `exp_orb`, `gun`·발사체 스크립트 |
| `godot-mobs.mdc` | `entities/mob/**`, `game/balance/mob_spawn_selector.gd` |
| `godot-weapons.mdc` | `weapons/**`, `entities/player/**`, `game/game.gd`, `ui/weapon_select_menu*` |

**몹 추가 시 (한 줄):** 새 `mob_*.tscn`만으로는 스폰되지 않음 → 메인 플레이에 넣을 때는 `mob_spawn_selector.gd` `pick_scene` + `default_balance_table.tres`를 같은 변경에 포함. **테스트 전용**(`mob_dummy` 등)은 `MOB_*_SCENE` 상수 + `scene_pool` prewarm + `test_arena.gd` `MOB_OPTIONS`만으로도 됨. (`godot-mobs.mdc`)

**무기 추가 시 (한 줄):** catalog·`gun.gd` 처리·`weapon_id` 고유성·선택 UI 풀을 같이 맞출 것. (`godot-weapons.mdc`)

---

## 핵심 제약 (영어 원문 — `godot-core.mdc`)

- Do not rename root `Game` or `%` nodes without repo-wide path updates.
- Do not change group `mobs` or per-variant mob scripts.
- Spawn only via `Game.spawn_mob()` → `Mob` + `initialize_spawn_health`.
- Do not start spawn `Timer` before `_ensure_game_started()`.
