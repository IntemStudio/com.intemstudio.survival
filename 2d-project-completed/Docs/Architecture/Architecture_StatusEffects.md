# Architecture — Status Effects (상태이상)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 몹: [`Architecture_Mobs.md`](Architecture_Mobs.md) · 무기: [`Architecture_Weapons.md`](Architecture_Weapons.md) · 버프: [`Architecture_Buffs.md`](Architecture_Buffs.md)

몹 대상 상태이상(`status/`)의 데이터 정의, 런타임 적용/중첩, DoT tick, 피해 배율/이동속도 배율 반영 경로를 정리한다. 플레이어 버프 계층(`buff/`)과 몹 상태이상 계층을 분리해 수명, 통계, 리셋 규칙이 섞이지 않게 유지한다.

## Overview

상태이상 시스템은 `StatusEffectData`(정의)와 `ActiveStatusEffect`(런타임)로 구성되고, 몹마다 `StatusEffectController` 하나가 활성 효과 목록을 관리한다. 무기 피격 시 `mob.gd`가 `weapon.status_effects`를 확률(`status_chance`)로 적용하고, 이어서 장비/런 패시브 `grant_on_hit` 태그도 상태이상으로 반영한다. 매 physics tick에서 컨트롤러가 만료/DoT tick을 처리한다. DoT 피해는 `Mob.apply_status_tick_damage()`로 들어와 일반 무기 피해와 동일하게 `Game.register_weapon_damage()` 통계를 기록한다. 냉기 둔화는 이동속도 배율, scorch/zap/toxic/frostbite는 속성별 받는 피해 배율로 반영된다. `sticky_goo`는 4초 동안 이동속도 30% 감소(배율 0.7)로 동작한다. 독(`poison`)은 예외적으로 무기별 지속시간/틱 스펙을 우선 사용해 source weapon 귀속이 유지된다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 상태이상 정의 | `status_id`, 표시명, category, duration, stacking, DoT/배율 필드 |
| 카탈로그 | 출혈/화상/독/냉기/번개 계열 기본 상태이상 등록과 조회 |
| 런타임 적용 | 몹별 활성 상태이상 append, 중첩/갱신 정책 적용 |
| 만료/틱 처리 | physics tick 기준 남은 시간 감소, due tick 반복 처리, 만료 제거 |
| 전투 반영 | 받는 피해 배율(`damage_taken_mult`), 이동속도 배율(`move_speed_mult`) 제공 |
| 통계 귀속 | DoT 포함 피해를 source weapon 기준으로 게임 통계에 연결 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 플레이어 버프/스탯 | `buff/`, `CharacterStats` 계층 범위다. |
| 장비 상시 modifier | 인벤토리/로드아웃 스탯 병합 경로에서 처리한다. |
| 상태이상 HUD 상세 UI | 현재는 적용 텍스트 위주이며 아이콘/패널은 별도 범위다. |
| 몹 이동/공격 AI 자체 | 상태이상은 배율/피해만 제공하고 행동 로직은 `mob.gd`가 담당한다. |
| 스폰 곡선/웨이브 밸런스 | `game.gd`, `BalanceTable` 범위다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `status/status_effect_data.gd` | 상태이상 `Resource` 정의(지속시간, 스택, DoT, 배율) |
| `status/active_status_effect.gd` | 적용 중 효과 1개의 남은 시간, stacks, tick 상태, source weapon |
| `status/status_effect_controller.gd` | 몹 1개 기준 활성 목록, apply/apply_statuses, tick, 배율 계산 |
| `status/status_effect_catalog.gd` | 기본 상태이상 코드 카탈로그와 localized 표시명 조회 |
| `entities/mob/mob.gd` | 무기 피격 시 상태이상 적용, DoT 피해 처리, 이동속도/피해 배율 사용 |
| `game/test_arena_status_effect_snapshot.gd` | F6 상태이상 튜닝 세션/저장(`user://`)과 카탈로그 즉시 반영 |
| `data/weapons/weapon_data.gd` | `status_effects`, `status_chance`, poison 전용 수치의 source |
| `game/game.gd` | `register_weapon_damage()`를 통한 전투 로그/게임오버 통계 집계 |

관계는 아래처럼 유지한다.

```text
WeaponData.status_effects + status_chance
  -> Mob._apply_weapon_status_effects()
  -> StatusEffectController.apply_status()
  -> ActiveStatusEffect (per mob)
  -> StatusEffectController.tick(delta, mob)
  -> Mob.apply_status_tick_damage()
  -> Game.register_weapon_damage()
```

## Flow

### Runtime

1. 무기가 몹에 명중하면 `Mob.apply_weapon_damage()`가 호출된다.
2. `_apply_weapon_status_effects()`가 `weapon.status_effects`를 순회하며 확률 체크 후 `apply_status()`를 호출한다.
3. 같은 적중에서 `Player.apply_loadout_on_hit()` → `PassiveResolver.on_hit()` → `LoadoutGrantPassive.apply_on_hit()` 경로로 `grant_on_hit` 상태이상을 추가 적용한다.
4. `StatusEffectController.apply_status()`는 카탈로그에서 정의를 가져오고, 기존 효과가 있으면 stack/refresh를 적용한다.
5. 새 효과면 `ActiveStatusEffect.create()`로 source weapon, tick 프로필, duration을 초기화해 목록에 추가한다.
6. 매 physics tick마다 `StatusEffectController.tick(delta, owner_mob)`가 모든 활성 효과의 tick timer/remaining time을 갱신한다.
7. DoT tick due 상태면 `owner_mob.apply_status_tick_damage()`를 호출해 속성/색상/무기 귀속으로 피해를 준다.
8. `Mob.apply_status_tick_damage()`는 상태이상 피해 배율, nettles 추가 배율, 피격 피드백, 피해 통계를 처리하고 사망 여부를 판정한다.
9. 이동 속도 계산 시 `Mob._get_effective_speed()`가 `get_move_speed_mult()`를 곱해 둔화를 반영한다.
10. 풀 반환(`pool_reset`) 시 `StatusEffectController.clear()`로 활성 효과를 모두 제거한다.
11. F6 상태이상 탭에서 수치를 적용하면 카탈로그 값이 갱신되고, 활성 몹은 `refresh_status_effect_profiles()`로 tick profile을 즉시 재계산한다.

### Editor / Data

1. 새 상태이상은 `StatusEffectCatalog`에 등록하거나 `StatusEffectData` 자산으로 정의한다.
2. `status_id`는 고유해야 하며, 무기 `status_effects`와 정확히 동일 문자열을 사용한다.
3. 중첩 정책은 `STACK_REFRESH`/`STACK_STACK`, `max_stacks` 조합으로 결정한다.
4. poison은 무기 스펙 override 규칙이 있으므로 duration/tick 변경 시 무기 필드와 같이 검토한다.
5. 새 `damage_element`를 추가하면 무기 element/색상/피해 통계 표시와 함께 검증한다.
6. F6 상태이상 탭은 장비 `grant_on_hit`의 상태이상만 대상으로 하며, 장비 탭에서 직접 상태이상 수치 편집은 허용하지 않는다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 몹 상태이상은 `StatusEffectController`만이 소유/만료한다. | 몹 스크립트 각 지점에서 임의 배열 조작 시 만료/중첩 불일치가 생긴다. |
| DoT 피해도 반드시 source weapon으로 `register_weapon_damage`에 귀속한다. | 게임오버 피해 목록에서 상태이상 기여 무기가 누락되지 않아야 한다. |
| poison은 `source_weapon` 기준으로 duration/tick profile을 재계산한다. | 무기별 독 정체성을 유지하고, 카탈로그 기본값과 충돌하지 않게 한다. |
| F6 상태이상 탭에서 `poison`의 duration/tick 필드는 잠금 처리한다. | 무기 source 우선 규칙과 상충하는 UI 기대를 사전에 차단한다. |
| 받는 피해 배율은 element 일치 시 스택 수만큼 곱연산한다. | scorch/toxic/frostbite 같은 디버프 설계가 additive로 바뀌지 않게 한다. |
| 이동속도 배율은 0 이하가 되지 않도록 데이터 값을 제한해 운용한다. | 몹 정지/역이동 같은 비정상 동작을 막는다. |
| 풀 reset에서 상태이상 clear를 생략하지 않는다. | 재사용 몹에 이전 런타임 상태가 남는 회귀를 방지한다. |
| pause 처리 정책은 mob physics tick 의존이다. | 트리 pause 중 상태이상 시간이 흐르지 않도록 현재 tick 경로를 유지한다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 상태이상 추가 | `status_id`, 표시명(ko/en), category, duration, stack 정책, 색상, 무기 연결 |
| DoT 수치 수정 | tick interval, min/max, stack 시 총량, 플로팅 텍스트 체감, 사망 속도 |
| poison 규칙 수정 | `ActiveStatusEffect._refresh_tick_profile`, `_get_duration_seconds`, 무기 poison 필드 |
| 배율형 디버프 추가 | `get_damage_taken_mult`/`get_move_speed_mult` 곱연산 의도, element 키 일치 |
| 적용 확률 변경 | 무기 `status_chance`, 다중 상태이상 동시 적용 시 체감, DPS 변동 |
| 풀링/리셋 변경 | `Mob.pool_reset`, `_status_effects.clear`, 재스폰 즉시 상태 초기화 |
| 통계 경로 변경 | `Mob._register_weapon_damage`, Game 게임오버 피해 목록, DoT 귀속 |

최소 검증은 F6 테스트 아레나에서 독/화상/냉기 계열 무기를 각각 사용해 적용 텍스트, DoT tick, 둔화 체감, 사망 처리, 피해 통계 귀속이 유지되는지 확인하는 것이다. 이어서 풀 재사용 이후 상태이상이 남지 않는지와 F5 메인 런에서도 동일 규칙이 유지되는지 회귀 확인한다.
