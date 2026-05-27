# Architecture — Projectiles (발사체)

**진입:** [`AGENTS.md`](../../AGENTS.md) · 공격 시스템 목표: [`Architecture_AttackSystem.md`](Architecture_AttackSystem.md) · 플레이 규칙: [`Wiki/Projectiles.md`](../Wiki/Projectiles.md), [`Wiki/Combat.md`](../Wiki/Combat.md) · 무기 연동: [`Architecture_Weapons.md`](Architecture_Weapons.md)

발사체 시스템은 `WeaponData`의 delivery와 movement를 실제 이동, 충돌, 피해 귀속으로 바꾸는 계층이다. 무기 획득, 장착, 자동 공격 타이머는 `Architecture_Weapons.md`에서 다루고, 이 문서는 `Gun.shoot()` 이후 생성되는 탄환, 근접 관통 탄, 마법 탄, 투척체, 영역 존, 궤도 companion의 런타임 계약을 정리한다.

## Overview

플레이어 공격은 대부분 `Gun`이 `ScenePool`에서 피해 오브젝트를 획득하고, 해당 오브젝트에 `WeaponData`와 시작 위치를 넘기면서 시작된다. 발사체와 영역 존은 몹에게 직접 HP를 깎지 않고 `Mob.apply_weapon_damage(amount, weapon)` 경로로 피해를 전달해 `WeaponDamageTracker` 집계를 유지한다. 플레이어 발사체는 환경 레이어에 막히며, movement별 종료 조건에서 `PoolUtil.release_node()`로 반환된다.

근접 무기는 이름은 melee지만 대부분 `MeleeProjectile` 발사체 모델을 사용한다. `StraightPierce`, `Return`, `CurvedReturn`, `Decelerate` movement로 직선 관통, 직선 왕복, 타원형 곡선 왕복, 감속 직선을 구분하고, 검기형 비주얼로 총알과 다른 체감을 만든다. `Spiky Flail`처럼 `Orbit` movement를 쓰는 근접 무기는 왕의 성경과 같은 궤도 companion을 사용한다.

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 발사체 생성 | `Gun`이 weapon type/delivery에 맞는 씬을 풀에서 획득 |
| movement 실행 | 직선, 관통, 왕복, 곡선 왕복, 유도, 포물선, 궤도 이동 |
| 충돌 처리 | 몹, 환경 장애물, 영역 overlap 판정 |
| 피해 전달 | `Mob.apply_weapon_damage()`와 `LoadoutStatApply`/`Player.roll_weapon_damage()` 사용 |
| 수명 종료 | 사거리, 귀환 도착, 충돌, lifetime 종료 시 풀 반환 |
| F6 튜닝 | `TestArenaWeaponSnapshot`의 movement/발사체 수치 튜닝 지원 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| 무기 획득과 장착 | `Architecture_Weapons.md`, `Architecture_Inventory.md`에서 관리한다. |
| 몹 원거리 투사체 | `Architecture_Mobs.md`의 몹 공격 흐름에서 관리한다. |
| 플레이어-facing 설명 | `Docs/Wiki/Projectiles.md`에서 관리한다. |
| 무기 성장·진화 | Wiki/Plan/Backlog의 성장 기획 범위다. |

## Key Types & Relationships

| 타입/파일 | 역할 |
|-----------|------|
| `weapons/data/weapon_data.gd` | `projectile_movement`, delivery helper, 사거리·관통·movement 선택지의 단일 소스 |
| `weapons/core/gun.gd` | weapon type/delivery에 따라 발사체·영역·궤도 씬 생성 |
| `weapons/core/bullet_2d.gd` | 일반 탄환, 원거리 폭발, 관통 카운트, 환경 충돌 |
| `weapons/melee/melee_projectile.gd` | 근접 관통 탄, `StraightPierce`/`Return`/`CurvedReturn`/`Decelerate`, 다중 hit, 부채꼴·병렬 발사 |
| `weapons/magic/magic_bolt.gd` | 마법 탄, 유도 이동, 폭발 마법 처리 |
| `weapons/magic/king_bible_orb.gd` | `Orbit` movement companion, 왕의 성경·가시 철퇴 등 플레이어 주변 궤도 피해 |
| `weapons/throwing/throwing_projectile.gd` | 기본 투척체, 왕복 투척체, 환경 충돌 |
| `weapons/boomerang/boomerang.gd` | 부메랑 전용 왕복 투척체 |
| `weapons/concoction/concoction.gd` | 포물선 투척 후 착지 지점에 영역 존 생성 |
| `weapons/area/area_damage_zone.gd` | 원형/사각 영역 피해, poison 적용, 짧은 lifetime |
| `game/pool/scene_pool.gd` | 발사체, 영역 존, 궤도 companion prewarm과 재사용 |
| `game/test_arena_weapon_snapshot.gd` | F6 발사체 수치와 movement 튜닝 |

관계는 아래처럼 유지한다.

```text
WeaponData
  -> Gun.shoot()
  -> projectile / area zone / orbit companion
  -> movement + collision
  -> Mob.apply_weapon_damage()
  -> Game.register_weapon_damage()
  -> PoolUtil.release_node()
```

## Flow

### Runtime

1. `Gun.shoot()`가 현재 `WeaponData`의 type/delivery를 확인한다.
2. `Gun`은 `/root/Game/ObjectPools`의 `ScenePool`에서 필요한 씬을 획득한다.
3. 발사체는 `setup()` 또는 `setup_weapon()`에서 `WeaponData`, 시작 transform, owner/player를 저장한다.
4. `pool_on_acquire()`는 `PhysicsLayers.apply_player_projectile()` 또는 `apply_player_area_zone()`로 레이어/마스크를 복원한다.
5. 이동 스크립트는 physics tick에서 movement별 위치와 회전을 갱신한다.
6. 환경 장애물에 닿으면 일반 발사체는 반환되고, 폭발/연금 계열은 충돌 지점에서 효과를 만든 뒤 반환된다.
7. 몹에 닿거나 영역 판정에 들어오면 장착 장비 배율이 반영된 피해를 굴린 뒤 `Mob.apply_weapon_damage()`로 전달한다.
8. 사거리, 귀환 도착, lifetime, 관통 한도에 도달하면 `PoolUtil.release_node()`로 풀에 반환한다.

### Editor / Data

1. 새 movement는 `WeaponData` 상수, 라벨, `get_projectile_movement_options()`, side effect helper에 추가한다.
2. 실제 이동 구현은 해당 발사체 스크립트에 추가한다.
3. F6에서 튜닝해야 하면 `TestArenaWeaponSnapshot`의 movement 옵션과 필드 정의를 확인한다.
4. 플레이어에게 보이는 규칙은 `Docs/Wiki/Projectiles.md`, 구현 계약은 이 문서와 `Architecture_Weapons.md`에 반영한다.

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 플레이어 발사체는 `PhysicsLayers.apply_player_projectile()`를 사용한다. | 환경 + mobs 마스크 계약을 유지한다. |
| 영역 존은 `PhysicsLayers.apply_player_area_zone()`를 사용한다. | 장판은 mobs만 감지해야 한다. |
| 피해는 `Mob.apply_weapon_damage(amount, weapon)` 경로를 우선 사용한다. | 피해 통계와 상태이상 귀속을 보존한다. |
| `projectile_pierce_count == 0`은 유효하지 않다. | 0은 설정 실수로 보고 발사체가 에러 후 반환한다. |
| 풀링 대상은 `pool_reset()`과 `pool_on_acquire()`를 구현하고 `PoolUtil.release_node()`로 끝난다. | 재사용 시 이전 spawn 상태가 새 공격에 섞이지 않게 한다. |
| `Return`/`CurvedReturn`은 귀환 시작 시 hit chain과 관통 카운트를 초기화한다. | 왕복 경로에서 재타격 가능한 무기 체감을 유지한다. |
| `CurvedReturn`은 `Return`과 별도 movement 타입으로 유지한다. | 실제 충돌 경로가 달라지므로 단순 비주얼 옵션이 아니다. |
| `Decelerate`는 속도 감쇠로 체류감을 만든다. | 별도 lifetime 튜닝보다 탄속 조정으로 자연스러운 정지감을 만든다. |
| `Orbit` companion은 무기 타입과 무관하게 `is_orbit_attack()` 경로를 사용한다. | 마법 궤도와 근접 궤도 무기를 같은 런타임 계약으로 다룬다. |
| 궤도 companion은 자동 공격 off일 때 피해 판정을 멈춘다. | 자동 공격 토글의 의미를 모든 공격 전달 방식에 맞춘다. |

## Change Guidelines

| 변경 | 확인할 것 |
|------|-----------|
| 새 발사체 씬 추가 | `ScenePool` prewarm, `pool_reset()`, `pool_on_acquire()`, `PoolUtil.release_node()` |
| 새 movement 추가 | `WeaponData`, 발사체 이동 코드, F6 movement 튜닝, Wiki/Architecture 문서 |
| 근접 movement 변경 | `MeleeProjectile`, 카탈로그 movement 값, 관통 수, 왕복 재타격 체감, 병렬 오프셋 |
| 환경 충돌 변경 | 플레이어 발사체 마스크, 장애물 충돌 반환/폭발/장판 생성 |
| 피해 공식 변경 | `Player.roll_weapon_damage()`, `LoadoutStatApply`, 독/장판/궤도 피해 경로 |
| 자동 공격 변경 | `Gun.refresh_auto_attack()`, `king_bible_orb.gd`, HUD 토글 상태 |

최소 검증은 F6 테스트 아레나에서 `StraightPierce`, `Return`, `CurvedReturn`, `Decelerate`, 일반 탄환, 유도 마법, 연금 영역 존, 궤도 무기를 각각 Equip하고, 더미/기본 몹 피해, 벽·나무 충돌, 자동 공격 on/off, 게임오버 피해 목록을 확인하는 것이다.
