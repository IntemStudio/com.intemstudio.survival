# Architecture — Weapons (무기)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 플레이 규칙: [`Wiki/Weapons.md`](../Wiki/Weapons.md), [`Wiki/Projectiles.md`](../Wiki/Projectiles.md), [`Wiki/Combat.md`](../Wiki/Combat.md) · 발사체 구조: [`Architecture_Projectiles.md`](Architecture_Projectiles.md) · 버프 구조: [`Architecture_Buffs.md`](Architecture_Buffs.md) · 인벤 연동: [`Architecture_Inventory.md`](Architecture_Inventory.md)

무기 시스템의 데이터, 장착, 발사 트리거, 피해 기록 흐름을 정리한다. `Gun.shoot()` 이후의 발사체 이동·충돌·풀링 세부 구조는 `Architecture_Projectiles.md`에서 관리한다. 무기별 데모 선정, 성장 기획, 아이콘 정책은 `Docs/Wiki/Weapons.md`와 `BACKLOG.md`에서 관리한다.

## Overview

무기는 `WeaponData` 리소스를 중심으로 동작한다. 메인 루프에서는 무기 획득 UI가 카탈로그에서 후보를 뽑고, 선택된 `WeaponData`의 `weapon_id`를 런 인벤토리에 넣는다. 인벤토리는 빈 weapon 슬롯 자동 배치 규칙을 적용하고, 활성 전투 세트의 weapon만 `Player.add_weapon()`과 `Gun` 경로로 전투에 반영한다.

피해는 발사체나 장판이 몹에 닿을 때 `Mob.apply_weapon_damage(amount, weapon)`로 들어간다. 이 경로는 `Game.register_weapon_damage()`를 통해 `WeaponDamageTracker`에 누적되어 게임오버와 일시정지 피해 목록에 표시된다. 플레이어 발사체는 환경 레이어 장애물에 막히며, 일반 발사체는 반환되고 폭발/연금 투척체는 충돌 지점에서 효과를 만든다. 비활성 세트나 가방에 있는 weapon은 보유 중이어도 `Gun`을 만들지 않고 피해 통계에 직접 참여하지 않는다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 무기 데이터 | `WeaponData`의 id, 타입, 손잡이, 피해, APS, 사거리, delivery, 원소, 특수 필드 |
| 카탈로그 | Ranged/Melee/Magic 카탈로그의 `WeaponData` 생성과 획득 UI 후보 공급 |
| 전투 장착 | 활성 전투 세트 weapon이 바뀔 때 `Player.add_weapon()`이 `Gun`을 생성하고 `%Weapons` 아래 배치 |
| 조준·발사 | `Gun`이 최근접 몹 조준, 자동 공격/수동 공격, burst, delivery 분기 처리 |
| 피해 전달 | 발사체·장판·궤도 스크립트가 weapon 귀속 피해를 적용하도록 연결 |
| 피해 통계 | `WeaponDamageTracker`가 `WeaponData.get_unique_key()` 기준으로 누적 피해 표시 |
| 장비 스탯 연동 | 장착된 loadout 장비의 피해·APS 배율만 `Player` 계산 경로에서 반영 |
| 무기 조건부 버프 | wave start 같은 런 이벤트에서 `BuffTriggerRouter`가 weapon id를 보고 런타임 버프 부여 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 보유 무기 강화 단계 | 현재는 신규 무기 획득 중심이며 성장 정책은 Wiki/Backlog에서 결정한다. |
| 무기 합성·진화 | 별도 성장 Epic으로 분리한다. |
| 데모 무기 풀 선정 | 플레이 감각과 콘텐츠 정책 문제이므로 Wiki/Plan에서 관리한다. |
| 아이콘·고유 아트 정책 | 콘텐츠·아트 폴리시로 관리한다. |
| 발사체 이동·충돌·풀링 세부 구현 | `Architecture_Projectiles.md`에서 관리한다. |
| 강화 선택지와 획득 선택지의 장기 공존 정책 | `Architecture_Inventory.md`와 별도 Epic에서 다룬다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `weapons/data/weapon_data.gd` | 무기 데이터와 툴팁, 사거리·관통·delivery helper의 단일 소스 |
| `weapons/catalogs/ranged_weapon_catalog.gd` | 원거리·투척·폭발·연금 투척 계열 `WeaponData` 생성 |
| `weapons/catalogs/melee_weapon_catalog.gd` | 근접 무기를 관통 발사체 모델로 생성 |
| `weapons/catalogs/magic_weapon_catalog.gd` | 마법 탄, 유도, 궤도 계열 `WeaponData` 생성 |
| `ui/weapon_select_menu.gd` | 무기 획득 후보 표시, 리롤·버리기·자동 선택, 툴팁 표시 |
| `entities/player/player.gd` | 활성 weapon의 `Gun` 생성, 장비 스탯 기반 damage/APS 계산 |
| `weapons/core/gun.gd` | 조준, 자동 공격, 수동 공격, burst, delivery별 스폰 |
| `weapons/core/bullet_2d.gd` | 일반 탄환, 관통 카운트, 폭발형 원거리, 환경 충돌 처리 |
| `weapons/melee/melee_projectile.gd` | 근접 관통 발사체, 검기형 비주얼, 직선/곡선 왕복, 다중 hit, 부채꼴 발사, 환경 충돌 처리 |
| `weapons/magic/magic_bolt.gd` | 마법 투사체, 유도 이동, 폭발 마법의 환경 충돌 처리 |
| `weapons/magic/king_bible_orb.gd` | 플레이어 주변 궤도 무기, overlap 기반 반복 피해 |
| `weapons/throwing/throwing_projectile.gd` | 기본 투척체와 환경 충돌 처리 |
| `weapons/concoction/concoction.gd` | 포물선 투척 후 독 장판 생성, 장애물 충돌 지점 착지 처리 |
| `weapons/area/area_damage_zone.gd` | 원형/사각 영역 피해, poison 적용, 짧은 lifetime |
| `entities/mob/mob.gd` | weapon 귀속 피해 수신, 상태이상 적용, 피해 통계 등록 |
| `game/weapon_damage_tracker.gd` | weapon key별 누적 피해와 표시 행 생성 |
| `buff/buff_trigger_router.gd` | `rapier`의 wave start `en_garde` 같은 무기 조건부 버프 연결 |

관계는 아래처럼 유지한다.

```text
WeaponSelectMenu
  -> run inventory weapon acquisition
  -> InventoryCombatBridge
  -> Player.add_weapon(active weapon)
  -> Gun.equip_weapon()
  -> projectile / area / orbit
  -> Mob.apply_weapon_damage()
  -> Game.register_weapon_damage()
  -> WeaponDamageTracker
```

## Flow

### Runtime

1. `WeaponSelectMenu`가 Ranged/Melee/Magic 카탈로그를 합쳐 후보 풀을 만든다.
2. 플레이어가 무기를 고르면 `Game.on_weapon_chosen()`은 무기를 즉시 추가하지 않고 런 인벤토리에 `weapon_id` 획득을 요청한다.
3. 인벤토리는 활성 세트 `weapon`이 비어 있으면 활성 슬롯, 활성 슬롯이 차 있고 비활성 세트 `weapon`이 비어 있으면 비활성 슬롯, 둘 다 차 있으면 가방 순서로 배치한다.
4. 활성 전투 세트 weapon이 바뀌면 `InventoryCombatBridge`가 플레이어의 기존 weapon 적용을 정리하고 활성 `WeaponData`를 `Player.add_weapon()`으로 적용한다.
5. `Player.add_weapon()`은 `gun.tscn`을 인스턴스화해 `%Weapons` 아래에 추가한다.
6. `Gun.equip_weapon()`은 스프라이트, 공격 속도, 양손 스케일, 궤도 companion을 초기화한다.
7. 활성 일반 무기는 자동 공격 on 또는 `attack` 액션(기본 좌클릭) 유지 상태에서 timer에 맞춰 `shoot()`를 호출한다. 활성 궤도 무기는 별도 companion이 physics tick에서 overlap 피해를 처리한다.
8. 비활성 세트나 가방의 weapon은 `Gun`을 만들지 않으며 자동 공격 on이어도 발사하지 않는다.
9. `Gun.shoot()`는 `weapon_type`과 delivery helper에 따라 탄환, 근접 발사체, 마법 탄, 투척체, 장판을 스폰한다. 카탈로그 Melee는 대부분 판정상 발사체지만 `melee_projectile.tscn`의 검기형 폴리곤 비주얼로 총알과 구분한다. 근접 movement는 직선 관통(`StraightPierce`), 직선 왕복(`Return`), 타원형 곡선 왕복(`CurvedReturn`), 감속 직선(`Decelerate`), 궤도(`Orbit`)로 나뉜다.
10. 각 피해 오브젝트는 `LoadoutStatApply.roll_combat_damage()` 또는 플레이어의 `roll_weapon_damage()`를 통해 장착 장비 배율을 반영한 피해를 굴린다.
11. 플레이어 발사체가 환경 레이어 장애물에 닿으면 막힌 것으로 처리한다. 일반/관통/투척/부메랑은 풀로 반환하고, 폭발형 탄·마법과 연금 투척체는 충돌 지점에서 폭발 또는 장판을 만든 뒤 반환한다.
12. 몹에 닿으면 `Mob.apply_weapon_damage()`가 HP 감소, 피격 연출, 상태이상, 피해 통계 등록을 처리한다.
13. 게임오버·일시정지 UI는 `WeaponDamageTracker.build_display_rows()`로 활성화되어 피해를 낸 무기와 누적 피해를 표시한다.

### Editor / Data

1. 새 무기는 `weapon_id`를 반드시 고유하게 지정한다.
2. 카탈로그 생성 필드는 `WeaponData` helper가 이해하는 타입과 delivery 값만 사용한다.
3. 새 delivery나 projectile movement를 만들면 `WeaponData` helper, `Gun.shoot()` 분기, 실제 피해 오브젝트, 테스트 아레나 필터/스냅샷을 함께 확인한다. F6 스냅샷은 현재 지원하지 않는 movement 값을 기본 지원값으로 보정한다.
4. 새 발사체나 이펙트는 `ScenePool` 대상이면 `pool_reset()`과 `pool_on_acquire()` 계약을 구현한다.
5. 툴팁에 표시되는 새 수치는 `WeaponData.build_select_tooltip_bbcode()` 양 언어 경로를 함께 갱신한다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| `weapon_id`는 비어 있지 않고 고유해야 한다. | 피해 통계, 인벤 `item_id`, 세이브 해석의 키가 된다. |
| 무기 피해는 `Mob.apply_weapon_damage(amount, weapon)` 경로를 우선 사용한다. | 독·장판·발사체 피해가 모두 같은 통계 키에 귀속되어야 한다. |
| `WeaponData.get_unique_key()` 기준이 바뀌면 피해 통계와 인벤 해석을 같이 확인한다. | 표시 이름보다 안정적인 id가 필요하다. |
| 무기 획득은 `Player.add_weapon()`을 직접 호출하지 않는다. | 획득과 장착을 분리해 빈 슬롯 자동 배치와 가방 보관을 지킨다. |
| `Player.add_weapon()`은 활성 전투 세트 weapon 적용 경로에서만 호출한다. | 비활성 weapon이 발사체, 궤도, 피해 통계를 만들지 않게 한다. |
| 카탈로그 Melee는 기본적으로 `MeleeProjectile` 발사체 판정을 유지하되, `Orbit` movement는 궤도 companion을 사용한다. | 근접 스윙감은 비주얼과 movement로 표현하고, 궤도형 근접 무기는 왕의 성경과 같은 런타임 계약을 쓴다. |
| 일반 발사체는 풀 반환 또는 수명 종료 경로가 있어야 한다. | 피크 구간에서 노드 누수와 성능 저하를 막는다. |
| 플레이어 발사체는 환경 레이어 장애물에 막혀야 한다. | 발사체 마스크가 환경을 포함하므로, 충돌 시 반환 또는 충돌 지점 효과로 끝나야 한다. |
| `projectile_pierce_count == 0`은 유효하지 않다. | 0은 설정 실수로 보고 발사체가 에러 후 반환한다. |
| 궤도 무기는 자동 공격 off일 때 피해 판정을 멈추지만 회전 위치 갱신은 유지한다. | 자동 공격 토글의 의미와 비주얼 연속성을 함께 지킨다. |
| `Gun`은 `/root/Game`과 `ObjectPools`를 전제로 스폰한다. | 씬 분리나 테스트 씬 변경 시 루트 계약을 맞춰야 한다. |
| loadout damage/APS 배율은 발사체가 직접 계산하기보다 `Player`/`LoadoutStatApply` 경로를 사용하고, 가방 장비는 제외한다. | 인벤 장착 장비 스탯 반영 위치를 한 곳으로 모은다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 무기 추가 | 카탈로그, `weapon_id`, `weapon_type`, hand, damage element, 툴팁, F6 Equip |
| 새 공격 방식 추가 | `WeaponData` helper, `Gun.shoot()` 분기, 풀링, 몹 피해 경로, 피해 통계 |
| 새 projectile movement 추가 | 이동 스크립트, 사거리 종료, 관통/왕복/유도 규칙, 환경 충돌 처리, 테스트 아레나 옵션/스냅샷 |
| 피해 공식 변경 | `Player.roll_weapon_damage()`, `LoadoutStatApply`, 독/장판/궤도 피해가 장착 장비만 같은 규칙으로 쓰는지 |
| 자동 공격 변경 | `Gun.refresh_auto_attack()`, 궤도 무기, HUD 라벨, 수동 `attack` 액션과 timer 충돌 여부 |
| 무기 조건부 버프 변경 | `WeaponData.effect` 표시 문구, `BuffTriggerRouter`, `BuffCatalog`, APS 타이머 갱신 |
| 무기 획득 변경 | 인벤 자동 배치, 활성/비활성 weapon 슬롯, 가방 가득 참, `Player.add_weapon()` 직접 호출 제거 |
| 피해 통계 변경 | `WeaponDamageTracker`, `Mob._register_weapon_damage()`, 게임오버·일시정지 UI |
| 풀링 대상 변경 | `ScenePool`, `PoolUtil.release_node()`, `pool_reset()`, `pool_on_acquire()` |

최소 검증은 F6 테스트 아레나에서 각 타입의 대표 무기를 Equip하고, 더미/기본 몹에게 피해가 들어가며, 장애물 충돌 시 반환/폭발/장판이 기대대로 처리되고, 자동 공격 on/off와 게임오버 피해 목록이 기대대로 동작하는지 확인하는 것이다.
