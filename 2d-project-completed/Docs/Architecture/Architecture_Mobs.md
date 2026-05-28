# Architecture — Mobs (몹)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이 규칙: [`Wiki/Mobs.md`](../Wiki/Mobs.md), [`Wiki/Combat.md`](../Wiki/Combat.md) · 스폰/밸런스: [`Architecture_GameLoop_Balance.md`](Architecture_GameLoop_Balance.md) · 상태이상: [`Architecture_StatusEffects.md`](Architecture_StatusEffects.md)

몹 공통 스크립트, 변종 씬, 이동·공격, 상태이상, 사망·보상, 풀링 계약을 정리한다. 몹의 기획 역할, 데모 우선순위, 보스/특수몹 최종 패턴은 Wiki와 Backlog에서 관리한다.

## Overview

플레이 몹은 대부분 `entities/mob/mob.gd`를 공유하고, 각 변종 씬은 export 값으로 속도, 체력, 색상, `mob_kind`, 원거리 공격 여부를 바꾼다. `Game.spawn_mob()`은 `MobSpawnSelector`가 고른 프리팹을 `ScenePool`에서 acquire하고, 현재 `BalancePhase.hp_multiplier`로 `initialize_spawn_health()`를 호출한다.

근접 몹은 플레이어 발밑 그림자 중심을 추적하고, standoff 거리 안에서 접촉 공격 주기 피해를 제공한다. 원거리 몹은 사거리 안에서 멈추고 머리 위 예고 마크를 띄운 뒤 `mob_projectile`을 발사한다. `charge_attack_enabled` 변종(특수 B)은 `charge_trigger_distance` 안에서 **경로 레인·`!` 예고**(`charge_lane_display_duration`) 후 직선 돌진하고, 종료 시 반경 피해를 1회 적용한다. `death_burst_enabled` 변종(특수 A 등)은 일반 사망 시 `death_burst_delay`만큼 지난 뒤 사망 위치에서 범위 피해를 주며(0이면 즉시), 지연 중에는 `death_burst_warning` 링이 커진다. 몹 상태이상은 `status/` 런타임 컨트롤러가 DoT, 받는 피해 배율, 이동속도 배율을 처리하고, 몹이 일반 사망하면 처치 수, XP, 골드, 낮은 확률 픽업을 만들고 풀로 반환된다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 변종 데이터 | `mob_kind`, HP, 속도, tint, 이동/전투 활성 여부, 원거리 공격 export |
| 스폰 초기화 | 풀 acquire, 그룹 등록, 물리 레이어 적용, HP 배율 적용, 상태 초기화 |
| 이동 | 플레이어 추적, standoff 거리 유지, 몹 분리, 플레이어 쪽 밀림 보정 |
| 근접 피해 | 원거리 몹을 제외한 접촉형 몹의 범위 주기 피해와 HurtBox 초기 충돌 연동 |
| 원거리 공격 | 공격 거리, 예고 마크, windup delay, 투사체 스폰, 쿨다운 |
| 피격·상태이상 | weapon 피해, 독 tick, nettles, 피격 깜박임, 체력바 표시 |
| 사망·보상 | 일반 사망 보상, 클리어 사망, `died` 시그널, 풀 반환, (선택) 지연 사망 폭발 |
| 전투 피드백 | 조준 링, 공격 범위 링, 체력바, 상태이상 아이콘(체력바 상단), 플로팅 데미지/상태 텍스트, (fast) 이동 속도 트레일 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 특수몹/보스 고유 패턴 설계 | 현재 문서는 확장 지점만 다루고, 기획은 Wiki/Backlog에서 결정한다. |
| 스폰 곡선과 등장 타이밍 | `Architecture_GameLoop_Balance.md` 범위다. |
| 무기 피해 공식 | `Architecture_Weapons.md`와 인벤 loadout 스탯 경로에서 관리한다. |
| 몹 아트·애니메이션 다양화 | 콘텐츠 폴리시로 관리한다. |
| 동시 생존 몹 상한 UX | Backlog의 HUD/디버그 표시 후보로 둔다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `entities/mob/mob.gd` | 모든 플레이 몹의 공통 상태, 이동, 공격, 피격, 사망 로직 |
| `entities/mob/mob_*.tscn` | basic/fast/ranged/elite/special/boss/dummy 변종 export 설정 |
| `entities/mob/mob_projectile.gd` | 원거리 몹 투사체, sweep 보정, 플레이어 피해 적용 |
| `entities/mob/mob_attack_mark.gd` | 접촉·원거리·돌진 windup 중 머리 위 예고 `!` |
| `entities/mob/mob_charge_lane.gd` | 돌진 직선 구간·화살표 예고(풀링, 표시 후 자동 release) |
| `effects/death_burst/death_burst_warning.gd` | 사망 폭발 지연 중 사망 위치 범위 링 예고 |
| `entities/mob/target_indicator_ring.gd` | 플레이어 무기의 현재 조준 대상 표시 |
| `status/status_effect_data.gd` | 몹 상태이상 정의, DoT/피해 증폭/둔화 수치 |
| `status/active_status_effect.gd` | 적용 중인 상태이상의 남은 시간, 중첩, tick 상태, source weapon |
| `status/status_effect_controller.gd` | 몹별 상태이상 적용, tick, 만료, 피해/이동 배율 계산 |
| `status/status_effect_catalog.gd` | 출혈, 화상, 독, 냉기, 번개 등 기본 상태이상 카탈로그 |
| `characters/shared/ground_shadow_footprint.gd` | 발밑 그림자 기준 중심·충돌·거리 계산 |
| `game/balance/mob_spawn_selector.gd` | 현재 phase 비율로 몹 프리팹 선택 |
| `game/pool/scene_pool.gd` | 몹, 몹 투사체, 공격 마크 prewarm/acquire |
| `game/balance/kill_rewards.gd` | `mob_kind` 기준 XP·골드 보상 계산 |
| `effects/exp_orb/exp_orb.gd` | 일반 사망 XP 보상 |
| `effects/gold_coin/gold_coin.gd` | 일반 사망 골드 보상 |
| `effects/hit_flash/hit_flash.gd` | 피격 시 몹 sprite modulate 깜박임 |
| `entities/mob/mob_speed_trail.gd` | fast 변종 전용 이동 속도 피드백(Line2D 꼬리 + CPUParticles2D). `mob.gd` 밖 변종 씬 자식 |

관계는 아래처럼 유지한다.

```text
Game.spawn_mob()
  -> MobSpawnSelector.pick_scene()
  -> ScenePool.acquire(mob_scene)
  -> Mob.pool_on_acquire()
  -> Mob.initialize_spawn_health()
  -> Mob movement / attack / damage
  -> Mob._die()
  -> Game.register_kill() + KillRewards
  -> pickup acquire/instantiate
  -> PoolUtil.release_node(mob)
```

## Flow

### Runtime

1. `Game.spawn_mob()`이 현재 phase로 몹 프리팹과 HP 배율을 결정한다.
2. `ScenePool.acquire()`가 몹을 활성화하면 `pool_on_acquire()`가 물리 레이어, 그룹, 속도, 애니메이션, 공격 링, 상태를 초기화한다.
3. `initialize_spawn_health()`가 `base_max_health * hp_multiplier`를 현재 HP와 최대 HP에 반영하고 체력바를 숨긴다.
4. 매 physics tick에서 이동 가능 몹은 플레이어 발밑 중심을 향해 이동하되 standoff 거리 안에서는 멈춘다.
4b. `mob_fast`의 `SpeedTrail`(`mob_speed_trail.tscn`)이 부모 `velocity`·풀 비활성 상태를 보고 Line2D 꼬리(≥70)와 파티클(≥140)을 켠다. 정지·풀 반환 시 자체 정리.
5. 근접 몹은 `Player` 쪽 접촉 피해 루프가 `is_player_in_contact_attack_range()`와 `tick_contact_attack()`을 통해 주기 피해를 받는다.
6. 원거리 몹은 사거리 안에서 windup을 시작하고, `mob_attack_mark`를 표시한 뒤 delay가 끝나면 `mob_projectile`을 발사한다.
6b. 돌진 몹은 트리거 거리 안에서 `_begin_charge_attack` → `mob_charge_lane` 스폰·제자리 windup → `_start_charge_movement`로 가속 이동 → `charge_end_burst_*` 범위 피해·쿨다운.
7. 무기/장판 피해는 `apply_weapon_damage()`로 들어와 상태이상 받는 피해 배율, HP 감소, hit flash, health bar, floating text, weapon damage 등록을 처리한다.
8. 무기가 가진 `status_effects`는 `StatusEffectController`에 적용되고, 신규 적용 시에만 상태이상 플로팅 텍스트를 표시한다(갱신/중첩은 미표시).
9. 매 physics tick마다 DoT/만료/둔화 배율을 갱신하고, 활성 상태 목록을 체력바 상단 `StatusEffectIcons`에 동기화한다.
10. HP가 0 이하가 되면 `_request_die()`가 중복 사망을 막고 `_die()`를 deferred 호출한다.
11. 일반 사망은 `died` 시그널, (선택) `schedule_mob_death_burst`, 연기, `Game.register_kill()`, `KillRewards`, XP/골드/자석/체력 픽업을 처리한 뒤 풀로 반환한다. 지연 폭발은 몹 풀 반환 후에도 사망 좌표에서 이어진다.
12. 클리어 사망은 `_stage_clear_death`를 켜고 드랍·처치 집계 없이 풀로 반환한다.

### Editor / Data

1. 새 변종은 `mob_*.tscn`에서 `mob.gd` export를 설정한다.
2. 메인 스폰에 넣으려면 `MobSpawnSelector`와 `ScenePool` prewarm 목록을 함께 갱신한다.
3. 보상 차이가 필요하면 `mob_kind`와 `KillRewards.BASE_XP_BY_KIND`를 같이 확인한다.
4. 원거리 공격을 켤 때는 `ranged_attack_enabled`, `combat_enabled`, `attack_distance`, cooldown, damage, projectile speed/range를 함께 튜닝한다.
5. 더미처럼 테스트 전용 몹은 메인 `MobSpawnSelector.pick_scene()`에 포함하지 않는다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 활성 몹은 `mobs` 그룹에 있어야 하고 풀 reset 시 그룹에서 빠져야 한다. | 스폰 상한, 피해 탐색, 몹 분리가 그룹을 사용한다. |
| 몹은 `/root/Game/Player` 경로를 전제로 한다. | 테스트 씬도 루트 이름과 Player 자식 계약을 맞춰야 한다. |
| 스폰 HP는 `initialize_spawn_health()`에서만 phase 배율을 적용한다. | 프리팹 기본 HP와 시간 배율을 분리한다. |
| 원거리 몹은 접촉 피해를 주지 않는다. | 원거리 압박과 근접 압박의 역할을 분리한다. |
| 접촉 거리 계산은 발밑 그림자와 플레이어 HurtBox 크기를 반영한다. | 시각적 충돌과 피해 범위가 어긋나지 않게 한다. |
| 원거리 투사체는 sweep으로 이동 구간 충돌을 보강한다. | 빠른 탄이 플레이어를 통과하는 터널링을 줄인다. |
| 일반 사망과 클리어 사망을 섞지 않는다. | 클리어 시 대량 드랍과 처치 수 인플레를 막는다. |
| 풀링 대상은 `pool_reset()`에서 상태, 타이머, 예고 마크, 물리 레이어를 정리해야 한다. | 재사용 시 이전 몹의 상태가 새 몹에 남지 않게 한다. |
| 상태이상 DoT도 source `WeaponData`를 통해 `Game.register_weapon_damage()`에 기록해야 한다. | 게임오버·일시정지 피해 목록에서 DoT 피해 귀속이 누락되지 않게 한다. |
| `StatusEffectIcons` 노드는 변종 씬에 없을 수 있으므로 null-safe로 접근한다. | `mob_fast.tscn`처럼 경량 변종 prewarm/pool_reset에서 null 참조를 방지한다. |
| `mob_kind`를 바꾸면 보상, Wiki, 테스트 아레나 라벨을 함께 확인한다. | 보상과 UI가 다른 종류로 표시되는 것을 막는다. |
| `mob_speed_trail`은 `mob.gd`의 `pool_reset`을 호출받지 않는다. | 부모 `collision_layer == 0`·`POOL_STORAGE_POSITION`·저속으로 트레일을 끈다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 몹 변종 추가 | 씬 export, `mob_kind`, `MobSpawnSelector`, `ScenePool`, `KillRewards`, F6 테스트 옵션 |
| 원거리 공격 수정 | 예고 마크, windup 취소, projectile sweep, 플레이어 피해 경로, 환경 충돌 |
| 접촉 피해 수정 | `Player` 접촉 루프, standoff 거리, 공격 범위 링, 고속 몹 overlap |
| 보스/특수 패턴 추가 | 공통 `mob.gd`에 무리하게 넣을지, 전용 스크립트로 분리할지 먼저 결정 |
| 사망 보상 변경 | 일반 사망과 클리어 사망 분리, XP/골드 풀링, 자석/체력 저확률 드랍 |
| 풀링 변경 | `ScenePool` prewarm, `pool_reset()`, `pool_on_acquire()`, `mob_attack_mark`·`mob_charge_lane` release |
| F6 몹 튜닝 | `TestArenaMobSnapshot`, `test_arena.gd` MOB_OPTIONS, 접촉/원거리/폭발(특수 A)/돌진 거리(특수 B, charge 우선), **적용/저장** |
| 피드백 UI 변경 | 체력바 설정, 상태이상 아이콘(`StatusEffectIcons`) 유무, target indicator, attack range ring, floating damage/status text, hit flash |
| 변종 이동 FX | `mob_speed_trail.tscn`을 변종 씬에만 인스턴스. AI·피해·풀 로직은 `mob.gd`에 넣지 않음. `trail_color`는 `slime_tint`와 맞출 것 |
| 상태이상 변경 | `StatusEffectCatalog`, `Mob.apply_weapon_damage()`, DoT 피해 통계, 풀 reset, F6 테스트 아레나 |

최소 검증은 F6 테스트 아레나에서 basic/fast/ranged/dummy를 각각 스폰하고, 이동·공격·피격·사망·리스폰·풀 반환이 정상인지 확인하는 것이다. fast는 달릴 때 꼬리·파티클이 보이고 정지·사망·풀 반환 시 사라지는지 추가로 본다. 메인 F5에서는 현재 밸런스 표에서 8분 이후 원거리 몹과 25분 보스 이벤트가 정상 스폰되는지도 확인한다.
