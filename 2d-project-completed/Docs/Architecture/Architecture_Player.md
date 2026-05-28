# Architecture — Player (이동·대시·스태미나·피격)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이 규칙: [`Wiki/Combat.md`](../Wiki/Combat.md) · 입력: [`Architecture_Input.md`](Architecture_Input.md) · 장비: [`Architecture_Inventory.md`](Architecture_Inventory.md) · 버프: [`Architecture_Buffs.md`](Architecture_Buffs.md) · 패시브: [`Architecture_Passives.md`](Architecture_Passives.md)

플레이어 `CharacterBody2D`의 이동, 대시, 스태미나, 피격·무적 게이트를 정리한다. 체력·경험치·무기 컨테이너·버프 컨트롤러는 이 문서에서 **대시·스태미나·피해 수신**과 맞닿는 부분만 다룬다.

**구현 상태**

| 기능 | 코드 |
|------|------|
| 부활(revive)·부활 후 무적(`REVIVE_INVINCIBILITY_SEC`) | 구현됨 — `is_damage_immune()` |
| 스태미나·대시(쿨다운 없음)·대시 중 무적·`invincibility_after_dash_sec` | 구현됨 — `player.gd`, `LoadoutStatApply`, `CharacterStats` |
| 피격 후 무적 `invincibility_after_damage_sec` | 구현됨 — HP 실감(`taken>0`) 후 `_gear_invincibility_remaining` |
| `dash_duration_mult` | 구현됨 — 예: `shinobi_suit` ×1.2 (버프·장비 합산) |
| F6 스태미나·대시 튜닝 | **후속** |

## Overview

플레이어 이동은 `Player._physics_process`에서 WASD 방향과 `CharacterStats`의 이동 배율을 적용한다. **대시는 스태미나를 소모**하며, 별도 **대시 쿨다운은 두지 않는다** — 마지막 소모 이후 **회복 시작 대기 시간**과 **회복 속도**가 다음 대시까지의 실질 간격이 된다.

대시가 **실제로 시작된 경우에만** 스태미나가 차감되고 `grant_on_dash`·`dash_haste` 같은 연동이 발동한다. 대시 **진행 중**에는 피해를 받지 않는다(무적). 일부 장비의 `invincibility_after_dash_sec`는 대시 **종료 후** 추가 무적 구간이다.

장비 `invincibility_after_damage_sec`(예: 슈퍼 히어로 슈트)는 **방패·방어 적용 후 실제 HP가 줄어든 피격** 직후에만 무적 타이머를 켠다. 방어로 0이 된 피격·무적 중 추가 피격은 타이머를 갱신하지 않는다. 여러 장비는 `GearStatMerge` **max** 병합이다.

부활 직후 무적은 장비 키와 별도 상수(`REVIVE_INVINCIBILITY_SEC`)이며, 구현 시 장비 무적 타이머와 **max**로 합쳐 `is_damage_immune()` 한곳에서 판정한다.

스태미나 회복은 **전투가 켜진 구간**(`set_contact_damage_enabled(true)` 이후, `HurtBox.monitoring`)에서만 진행하며, 트리 `paused` 중에는 버프 tick과 같이 멈춘다. 스태미나를 쓰면 **회복 대기 타이머가 0으로 리셋**되어, 회복 중이어도 진행이 처음부터 다시 시작된다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 이동 | WASD, `BASE_MOVE_SPEED`, 장비·버프 `move_speed_mult` |
| 대시 | 방향·속도·지속시간, 스태미나 비용, 무적 구간 |
| 스태미나 | 현재/최대, 소모, 회복 대기·회복 tick, 소모 시 대기 리셋 |
| 피해 수신 게이트 | 접촉·투사체·burst 진입 전 무적·사망 여부 |
| **부활(revive)** | 체력 0 시 장비 차지 소비·`health_depleted` 대신 생존(인벤 `revive_*` → [`Architecture_Inventory.md`](Architecture_Inventory.md)) |
| 장비 스탯 반영 | `stamina`, `stamina_recovery_mult`, `dash_duration_mult`, `invincibility_after_dash_sec`, `invincibility_after_damage_sec` |
| 피격 후 무적 | HP 실감 후 `invincibility_after_damage_sec`만큼 추가 무적(장비 max) |
| UI | `%DashCooldownBar`(스태미나 잔량), `%StaminaRegenWaitBar`(회복 시작 대기 진행) |

### Out of Scope

| 제외 | 비고 |
|------|------|
| `grant_on_dash` 상세 | `Architecture_Passives.md`, `loadout_grant_passive.gd` |
| `dash_haste` 등 런타임 버프 정의 | `Architecture_Buffs.md`, `buff_catalog.gd` |
| 무기 피해·APS·장착 | `Architecture_Weapons.md`, `Gun` |
| 몹 피해·투사체 이동 | `Architecture_Mobs.md`, `Architecture_Projectiles.md` |
| Space 바인딩·리맵 | `Architecture_Input.md` (`ACTION_DASH`) |
| 몹 상태이상 | `Architecture_StatusEffects.md` |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `entities/player/player.gd` | 이동·대시·스태미나 tick·피해 진입·`grant_on_dash` 호출 |
| `entities/player/stats/character_stats.gd` | 장비·패시브·버프 modifier source, 최대 스태미나·대시·회복 배율 조회(확장) |
| `inventory/loadout_stat_apply.gd` | `stamina` 합산, `stamina_recovery_mult`·`dash_duration_mult` 곱 |
| `inventory/gear_stat_merge.gd` | `stamina` add, `stamina_recovery_mult` mult, `invincibility_after_dash_sec`·`invincibility_after_damage_sec` max |
| `inventory/inventory_combat_bridge.gd` | loadout → `refresh_stats_from_loadout()` |
| `passive/passive_resolver.gd` | `on_dash` → `LoadoutGrantPassive.apply_on_dash` |
| `buff/buff_trigger_router.gd` | `grant_on_dash: haste` → `dash_haste` 버프 |
| `game/attack/damage_resolver.gd` | 몹 투사체·burst → `apply_mob_projectile_damage` |
| `game/game.gd` | `_ensure_game_started()` → `set_contact_damage_enabled(true)` (전투·회복 구간 기준) |

```text
ActionManager ACTION_DASH + stamina >= cost + 방향 유효
  -> spend_stamina (regen_idle_time = 0)
  -> _dash_time_remaining = get_effective_dash_duration()
  -> PassiveResolver.on_dash / grant_on_dash

매 physics frame (전투·unpaused):
  -> _tick_stamina: regen_idle_time += delta; delay 경과 후 stamina 회복
  -> 대시 중: velocity = dash_dir * DASH_SPEED, is_damage_immune

피해원
  -> Player.is_damage_immune()? skip  (대시 중·장비 무적·부활 무적)
  -> _resolve_incoming_damage (방패·방어; 부활 무적 시 taken=0)
  -> _apply_damage_taken(taken>0)
  -> invincibility_after_damage_sec > 0 이면 _gear_invincibility_remaining = max(remaining, sec)
```

## Flow

### Runtime — 대시

1. `ActionManager.is_just_pressed(ACTION_DASH)`이고 이동 방향(또는 `_last_move_direction`)이 유효하다.
2. `stamina >= get_dash_stamina_cost()`이면 대시 시작; 아니면 일반 이동만 처리한다.
3. 스태미나를 차감하고 `_regen_idle_time = 0`으로 리셋한다.
4. `_dash_time_remaining`에 `get_effective_dash_duration()`을 넣는다 (`BASE_DASH_DURATION × dash_duration_mult`, 장비·버프).
5. `_apply_loadout_on_dash()` → `PassiveResolver.on_dash` (다트, haste 등).
6. 대시 진행 중 매 프레임 `velocity = _dash_direction * DASH_SPEED`이며 `is_damage_immune()`은 true.
7. `_dash_time_remaining`이 0이 되면 일반 이동으로 복귀. `invincibility_after_dash_sec > 0`이면 별도 타이머로 **대시 후** 무적을 이어 간다.

### Runtime — 스태미나 회복

1. `HurtBox.monitoring == true`이고 `get_tree().paused == false`일 때만 `_tick_stamina(delta)`를 호출한다.
2. `_regen_idle_time`을 증가시킨다.
3. `_regen_idle_time >= get_stamina_regen_delay()`이면 `stamina += get_stamina_regen_rate() * delta` (최대치 클램프).
4. 대시 등으로 `spend_stamina()`가 호출되면 `_regen_idle_time = 0` — **부분 회복 중이어도 동일**.

### Runtime — 피해

1. `_apply_contact_damage` / `apply_mob_projectile_damage` 맨 앞에서 `is_damage_immune()`이면 return(대시 진행 중·`_gear_invincibility_remaining`·부활 무적).
2. `_resolve_incoming_damage` → `_apply_damage_taken`: 체력 **0 이하 클램프**·HP 바 갱신.
3. `_apply_damage_taken`에서 **`taken > 0`일 때만** `invincibility_after_damage_sec`를 읽어 `_gear_invincibility_remaining = max(remaining, sec)` (장비 미착용·0이면 스킵).
4. `_try_emit_health_depleted`: physics 프레임당 1회만 lethal 판정.
5. `revive` 차지·`get_revive_charges_max() > 0`이면 `_try_consume_revive()` — `_revive_invincible_remaining`·`_gear_invincibility_remaining`에 `REVIVE_INVINCIBILITY_SEC` 반영 → 최대 체력 × `REVIVE_HP_RATIO`(0.5) → `FloatingInfoText` `combat.revived` → **`health_depleted` 미발행**.
6. 부활 불가 시 `_health_depleted_emitted` 후 `health_depleted` → `game.gd` 패배.
7. **죽음 거부(defy_death)** — 미구현(2단계).

### Runtime — 피격 후·대시 후 무적(장비)

1. 매 `_physics_process`(unpaused)에서 `_gear_invincibility_remaining`을 `delta`만큼 감소한다. 부활 무적은 동일 타이머에 max로 합치거나, 현행처럼 `_revive_invincible_remaining`을 `is_damage_immune()`에 OR한다.
2. 대시 종료 시 `invincibility_after_dash_sec > 0`이면 `_gear_invincibility_remaining = max(remaining, sec)` (팬텀 스텝 등).
3. 무적 중 접촉·투사체·burst는 HP·플로팅·피격 깜박임 없이 스킵한다.
4. pause 중 무적 타이머도 감소하지 않는다(버프 tick과 동일).

### Editor / Data

1. 장비 `stat_modifiers`에 `stamina`(flat 합), `stamina_recovery_mult`(곱), `dash_duration_mult`(곱), `invincibility_after_dash_sec`·`invincibility_after_damage_sec`(max) 추가·변경 시 `gear_stat_merge.gd`·`gear_stat_display.gd`·본 문서·`Architecture_Inventory.md` 링크를 함께 본다.
2. 대시 연장 버프는 `BuffData.stat_modifiers`에 `dash_duration_mult`를 두고 `CharacterStats` 버프 source로 합산한다.
3. F6 튜닝(후속): 스태미나 최대·비용·회복 딜레이·회복 속도·대시 지속을 `test_arena` 스냅샷으로 노출할 수 있다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| **대시 전용 쿨다운(`DASH_COOLDOWN`)을 두지 않는다.** | 재사용 간격은 스태미나 회복 딜레이·속도만으로 표현한다. |
| 스태미나 소모 시 `_regen_idle_time`을 항상 0으로 리셋한다. | “회복 중 사용 시 진행 초기화” 요구사항. |
| `grant_on_dash`·`dash_haste`는 대시 **시작 성공 시**만 호출한다. | 스태미나 부족·방향 무효 시 패시브가 켜지면 안 된다. |
| `get_tree().paused` 또는 `_is_combat_input_blocked()` 중에는 새 대시를 시작하지 않는다. | 일시정지·무기 선택·인벤·상자 UI 중 Space 대시·스태미나 소모 방지. |
| 무적 판정은 `_apply_contact_damage`·`apply_mob_projectile_damage` **양쪽**에 동일하게 적용한다. | burst·접촉·투사체 경로 누락 방지. |
| 대시 **중** 무적과 `invincibility_after_dash_sec`(**후**)를 분리한다. | 팬텀 스텝 등 장비와 기본 대시 무적이 겹쳐도 의미가 다르다. |
| `invincibility_after_damage_sec`는 **HP 실감(`taken>0`) 후**에만 타이머를 켠다. | 방어 0·무적 중 피격으로 무한 연장·오발동 방지. |
| 장비 무적·대시 후 무적·부활 무적은 `_gear_invincibility_remaining`(및 필요 시 revive)으로 **max** 합산·단일 `is_damage_immune()` 판정. | 접촉·투사체·burst 경로 누락 방지. |
| 무적 중 추가 피격은 타이머를 **연장하지 않는다**. | 표준 i-frame; 만료 후 `tick_contact_attack` 등 재개. |
| 회복 tick은 pause·비전투(접촉 피해 off)에서 진행하지 않는다. | 로비·무기 선택·웨이브 대기 중 충전 방지. |
| `refresh_stats_from_loadout` / 버프 변경 시 스태미나 **최대만** 클램프; 현재값은 초과 시 `min(current, max)` | `_sync_health_bar_max`와 동일 패턴. |
| `%DashCooldownBar`는 스태미나 잔량, `%StaminaRegenWaitBar`는 `regen_idle_time / regen_delay`(회복 시작 전)만 표시한다. | 만충이면 둘 다 숨김. |
| `/root/Game`·`%Player`·`PhysicsLayers` 계약은 `godot-core.mdc`를 따른다. | 대시는 이동 레이어만 사용, 별도 layer 추가 금지(필요 시 문서·규칙 동시 갱신). |
| 부활 무적은 `_resolve_incoming_damage`에서 `taken=0`으로 통일한다. | 접촉·투사체 경로 누락 방지. |
| `_try_emit_health_depleted`는 physics 프레임당 1회만 처리한다. | 동프레임 다중 치명타·이중 패배 방지. |
| 패배는 `health_depleted`만 사용한다. 부활 성공 시 emit 금지. | `Game._on_player_health_depleted` 단일 진입. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 스태미나·대시 구현 | `player.gd`, `DASH_COOLDOWN` 제거, `Wiki/Combat.md`, F5/F6 수동 QA |
| 새 장비 스태미나 키 | `gear_stat_merge.gd`, `gear_catalog_entries.gd`, `gear_stat_display.gd`, `LoadoutStatApply` |
| `grant_on_dash` 추가 | `loadout_grant_passive.gd`, `Architecture_Passives.md`, 대시 성공 조건 |
| 대시 연장 버프 | `buff_catalog.gd`, `GearStatMerge`/`CharacterStats`, 대시 지속 계산 한 곳 |
| 피해 경로 추가 | `is_damage_immune()` 게이트, `_apply_damage_taken`, `DamageResolver` 호출부 grep |
| 피격 후 무적 | `invincibility_after_damage_sec`, `_gear_invincibility_remaining`, `super_hero_suit`, `gear_stat_merge` max |
| 대시 후 무적 | `invincibility_after_dash_sec`, 대시 종료 hook, `phantom_steps` |
| revive·사망 | `_try_emit_health_depleted`, `_sync_revive_charges_from_stats`, `Architecture_Inventory.md` |
| UI 게이지 | `player.tscn` `%DashCooldownBar`, `%StaminaRegenWaitBar`, `AGENTS_Display_UI.md` |
| 문서 | `Wiki/Combat.md`, `Wiki/GameRules.md`, 본 문서, `Architecture_Buffs`/`Passives`/`Inventory` 링크 |

**최소 검증:** F5 전투 시작 후 스태미나 소모 대시 → 대시 중 몹·투사체 무적 → 스태미나 고갈 시 대시 불가 → 대기 후 회복 → 회복 중 대시 시 대기 리셋. `geta` 장착 시 대시 후 haste만 발동·스태미나 없을 때 미발동. `phantom_steps` 대시 **후** 추가 무적. `super_hero_suit` — 1회 피격(HP 감소) 후 약 4초 무적, 무적 중 연속 피격 무시, 만료 후 재피격 가능. 방어만으로 0 피해 시 무적 미발동. pause·무기 선택 중 회복·무적 tick 정지.

## 설계 상수 (기본값·튜닝 후보)

구현 시 `player.gd` 또는 전용 상수 블록에 둔다. F6에서 덮어쓸 수 있게 할 경우 스냅샷 문서는 `Architecture_TestArena.md`에 추가한다.

| 상수 | 기본값 | 비고 |
|------|--------|------|
| `BASE_MAX_STAMINA` | 3 | 장비 `stamina` flat 합산 |
| `DASH_STAMINA_COST` | 1 | 대시 1회 |
| `BASE_STAMINA_REGEN_DELAY` | 2.0 s | 소모 후 회복 **시작**까지 |
| `BASE_STAMINA_REGEN_RATE` | 1.0 / s | delay 이후 초당 회복량 × `stamina_recovery_mult` |
| `BASE_DASH_DURATION` | 0.18 s | × `dash_duration_mult` |
| `DASH_SPEED` | 1400 | 기존과 동일 |
| `REVIVE_HP_RATIO` | 0.5 | 부활 시 최대 체력 비율 |
| `REVIVE_INVINCIBILITY_SEC` | 2.0 | 부활 직후 무적(`_process`에서 감소) |

다음 대시까지 대략적인 체감 간격: `regen_delay + cost / regen_rate` (최대 스태미나 > 1이면 연속 대시 버스트 가능).
