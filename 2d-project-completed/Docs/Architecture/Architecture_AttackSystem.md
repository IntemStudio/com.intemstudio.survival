# Architecture — Attack System (공격 시스템)

**역할:** 공격 시스템 **목표 아키텍처**와 **기능 개발 명세**를 한 문서에 둔다. 현재 구현(`WeaponData`, `Gun`, 발사체 씬, `Mob.apply_weapon_damage`)과의 대응·마이그레이션 경로를 포함한다.

**진입:** [`AGENTS.md`](../../AGENTS.md) · 관련 구현: [`Architecture_Weapons.md`](Architecture_Weapons.md), [`Architecture_Projectiles.md`](Architecture_Projectiles.md), [`Architecture_Mobs.md`](Architecture_Mobs.md) · 플레이 규칙: [`Wiki/Combat.md`](../Wiki/Combat.md)

**문서 상태:** 1차 인프라 + P1 Resolver 확장 + P2 특수몹 사망 burst 완료. `AttackEntity`·`TargetAttack`·`chain_on_end`는 2차.

### QA (공격 시스템)

| 확인 | 항목 |
|------|------|
| [ ] | **CLI:** [`scripts/verify/run_smoke.ps1`](../../scripts/verify/run_smoke.ps1) — 파싱·헤드리스 로드·정적 검사·gdUnit4 `test/` (F6 전투 QA **대체 아님**) |
| [ ] | **F6:** revolver, 연금, king bible, club(근접), ranged mob |
| [ ] | **F6:** 자동공격 G / 조준 F |
| [ ] | **F6:** Special A 처치 — 지연 링 예고 → 플레이어 피해·폭발 연출(반경 튜닝 반영) |

CLI 실행·옵션: [`AGENTS.md` § 변경 후 확인](../../AGENTS.md). 공격·무기 회귀는 F6 `test_arena.tscn`에서 수동 확인한다.

### 1차 인프라 구현 경로 (현재)

| 파일 | 역할 |
|------|------|
| [`game/attack/attack_services.gd`](../../game/attack/attack_services.gd) | `Game`/`test_arena` 직계 `AttackServices` 노드, Factory 진입 |
| [`game/attack/attack_context.gd`](../../game/attack/attack_context.gd) | 발동 시점 스냅샷 (`WeaponData` 유지) |
| [`game/attack/attack_factory.gd`](../../game/attack/attack_factory.gd) | 풀 acquire + spawn + `schedule_mob_death_burst` / `spawn_mob_death_burst` |
| [`game/attack/damage_resolver.gd`](../../game/attack/damage_resolver.gd) | `apply_weapon_to_mob` → `Mob.apply_weapon_damage` 위임 |
| [`game/attack/attack_delivery.gd`](../../game/attack/attack_delivery.gd) | delivery 상수·`WeaponData` 매핑 helper |
| [`weapons/core/gun.gd`](../../weapons/core/gun.gd) | 트리거 — `AttackFactory`만으로 스폰 |
| [`weapons/core/bullet_2d.gd`](../../weapons/core/bullet_2d.gd) | `DamageResolver` 경유(1종) |
| [`survivors_game.tscn`](../../survivors_game.tscn), [`test_arena.tscn`](../../test_arena.tscn) | `%AttackServices` 노드 |

---

## Overview

공격 시스템은 **정의(Definition) / 트리거(Trigger) / 전달(Delivery) / 해결(Resolution)** 네 계층으로 나눈다. Godot에서는 정의를 `Resource`, 트리거를 플레이어·몹 컨트롤러, 전달을 **공격 독립체(Attack Entity)** `Scene`/`Node`, 해결을 대상별 **단일 피해 API**로 둔다.

전달 계층만 **공통 개념 `AttackEntity`** 로 통합한다. 독립체는 피해의 소유자가 아니라 **월드에 존재하며 명중을 보고하는 전달자**이고, HP 감소·상태이상·통계·사망은 해결 계층에서만 처리한다.

목표 흐름:

```text
AttackDefinition (Resource)
  → Trigger Controller
  → AttackEntity (Scene/Node)
  → DamageResolver / 대상 API
```

현재 프로젝트는 전달 계층이 씬 타입별로 분산되어 있다(`bullet_2d`, `melee_projectile`, `area_damage_zone`, `king_bible_orb`, `mob_projectile`). 본 명세는 이들을 **동일 계약의 Attack Entity** 로 점진 정리하는 것을 1차 목표로 한다.

---

## Responsibilities & Boundaries

### In Scope

| 책임 | 설명 |
|------|------|
| 4계층 분리 | 정의·트리거·전달·해결 책임 경계 |
| 공격 독립체 4종 | `TargetAttack`, `AreaAttack`, `ProjectileAttack`, `OrbitAttack` |
| 실행 컨텍스트 | `AttackContext` — 발동 시점 수치 스냅샷 |
| 복합 공격 | 종료·명중 시 후속 공격 생성(`chain_on_end` 등) |
| 1차 공격 행동 7종 | 근접 단일·근접 범위·직선 발사·돌진·자폭·사망 AoE·연쇄/복합 (아래 **Attack Behaviors** 참고) |
| 팩토리 | `AttackFactory` — 트리거가 씬 생성 세부를 몰라도 되게 함 |
| 해결 관문 | 플레이어→몹, 몹→플레이어 피해의 단일/대칭 API |
| 풀링·물리 | `ScenePool`, `PhysicsLayers` 계약 유지 |
| 마이그레이션 | `WeaponData`·`Gun`·기존 발사체와의 어댑터 경로 |

### Out of Scope

| 제외 | 비고 |
|------|------|
| UI 연출 상세 | HUD·게임오버 레이아웃은 `Architecture_Weapons`·Display UI |
| 최종 밸런스 수치 | 카탈로그·`BalanceTable`에서 별도 확정 |
| 네트워크 동기화 | 미계획 |
| 무기 획득·인벤 장착 | [`Architecture_Inventory.md`](Architecture_Inventory.md) |
| 플레이어 능력치 버프 | [`Architecture_Buffs.md`](Architecture_Buffs.md) — 몹 상태이상은 `status/` |
| 영구 성장·세이브 | 런 한정 전투 범위 |

---

## Key Types & Relationships

### 계층 정의

| 계층 | 책임 | 목표 구현 단위 | 현재 프로젝트 대응 |
|------|------|----------------|-------------------|
| 정의 | 공격 종류, 수치, delivery, 상태이상, 연쇄 | `AttackDefinition` (`Resource`) | `WeaponData` + 몹 export |
| 트리거 | 쿨다운, 타겟, 자동/수동, AI windup | `PlayerAttackController`, `MobAttackController` | `Gun`, `Player`, `mob.gd` |
| 전달 | 생성·이동·충돌·lifetime | `AttackEntity` (`Scene`) | `AttackFactory` + 기존 씬(`bullet_2d` 등) |
| 해결 | 피해·상태·사망·통계 | `DamageResolver` / 대상 API | 플레이어→몹·몹→플레이어 발사체·사망 burst 모두 `DamageResolver` 경유 |

### 목표 타입 관계

```text
AttackDefinition
  → AttackContext (발동 시 스냅샷)
  → AttackFactory.spawn_attack(context)
  → AttackEntity
        ├─ TargetAttack
        ├─ AreaAttack
        ├─ ProjectileAttack (+ MovementStrategy)
        └─ OrbitAttack
  → resolve_hit(target) → DamageResolver / Mob·Player API
```

### 현재 코드 매핑 (전달 계층)

| 목표 Attack Entity | 현재 씬·스크립트 | 비고 |
|--------------------|------------------|------|
| `ProjectileAttack` | `bullet_2d`, `magic_bolt`, `throwing_projectile`, `boomerang`, `melee_projectile`, `concoction` | movement는 `WeaponData.projectile_movement` |
| `AreaAttack` | `area_damage_zone` | `setup_circle` / `setup_rectangle` |
| `OrbitAttack` | `king_bible_orb` | `Gun` companion, 자동공격 off 시 판정만 정지 |
| `TargetAttack` | *(없음)* | 신규 — 즉시 타격·체인용 |

---

## Target Data — AttackDefinition

모든 공격 스펙의 **목표 단일 Resource**. 1차 마이그레이션에서는 `WeaponData`가 사실상 `AttackDefinition` 역할을 하며, 필드는 점진 이전한다.

### 필수 필드 (목표)

```gdscript
class_name AttackDefinition
extends Resource

@export var attack_id: StringName
@export var display_name: String
@export var delivery_type: int          # Target / Area / Projectile / Orbit
@export var targeting_type: int         # nearest, cone, random, fixed, aimed_position
@export var attack_scene: PackedScene
@export var cooldown: float
@export var windup: float
@export var active_time: float
@export var recovery: float
@export var min_range: float
@export var max_range: float
@export var max_targets: int
@export var hit_interval: float
@export var pierce_count: int
@export var lifetime: float
@export var move_speed: float
@export var movement_type: int          # Straight, Pierce, Return, Homing, Arc, Orbit
@export var damage_base: float
@export var damage_multiplier: float
@export var status_effects: Array[Resource]
@export var chain_on_end: Array[Resource]
@export var telegraph_vfx: PackedScene
@export var impact_vfx: PackedScene
@export var sfx_event: StringName
```

### WeaponData 대응 (현재 → 목표)

| AttackDefinition | 현재 `WeaponData` / 기타 |
|------------------|---------------------------|
| `attack_id` | `weapon_id` |
| `delivery_type` | `attack_delivery` + `is_orbit_attack()` |
| `movement_type` | `projectile_movement` |
| `pierce_count` | `projectile_pierce_count` |
| `damage_base` / multiplier | `min_damage`/`max_damage` + `Player.roll_weapon_damage` |
| `cooldown` | `attacks_per_second` (역수) |
| `chain_on_end` | 연금: `concoction` → `AreaDamageZone` (코드 연쇄, 아직 Resource 배열 아님) |
| `attack_scene` | `Gun` 내부 `PackedScene` 상수 또는 `projectile_scene` |

---

## AttackContext

발동 시점 스냅샷. **독립체는 읽기만** 하고 공격력·치명타를 재계산하지 않는다.

```gdscript
class_name AttackContext
extends RefCounted

var owner: Node
var instigator_team: int
var attack_def: AttackDefinition      # 1차: WeaponData 어댑터 허용
var origin: Vector2
var direction: Vector2
var locked_target: Node
var rolled_damage: float              # 트리거에서 확정 후 전달
var crit_chance: float
var crit_multiplier: float
var element_tags: Array[StringName]
var runtime_flags: Dictionary
```

요구사항:

- `rolled_damage`는 `AttackFactory.spawn_attack()` **이전**에 `Player.roll_weapon_damage()` 등으로 확정.
- 연쇄 공격 시 `origin`/`direction`/`locked_target` 일부 상속·일부 오버라이드.
- 몹 공격 컨텍스트는 `weapon` 대신 `mob_damage`·`mob_kind` 필드 확장(플레이어 API 분리 유지).

---

## Attack Entity (전달 계층)

### 공통 인터페이스

```gdscript
class_name AttackEntity
extends Node2D

var context: AttackContext
var elapsed: float = 0.0
var is_finished: bool = false

func setup(p_context: AttackContext) -> void
func activate() -> void
func tick(delta: float) -> void
func resolve_hit(target: Node) -> void
func finish() -> void
func pool_reset() -> void
func pool_on_acquire() -> void
```

공통 요구:

- `ScenePool` + `pool_reset` / `pool_on_acquire` / `PoolUtil.release_node`.
- `setup()` 이후 외부가 내부 상태 직접 수정 금지.
- `resolve_hit` → 해결 API만 호출 (`target.health -=` 금지).
- `PhysicsLayers.apply_*()` — 레이어 정수 하드코딩 금지.

### 6.1 TargetAttack

- 대상 또는 대상 목록에 **즉시** 해결 요청. 장시간 월드 오브젝트 불필요.
- 사용 예: 즉시 타격, 체인 라이트닝, 보스 지정 공격, 딜레이 예약 타격.
- 요구: 단일/다중, 시야 옵션, 대상 소실 시 취소, VFX만 별도 스폰 가능.

**현재:** 미구현. 신규 시 `AttackFactory` + `DamageResolver` 경로로만 추가.

### 6.2 AreaAttack

- `Area2D` 기반 overlap, 단발·틱(`hit_interval`) 지원.
- 원형·사각 최소; 부채꼴은 후속.
- 사용 예: 독 장판, 착지 폭발, 근접 원형 베기.

**현재:** `AreaDamageZone` — `_collect_hit_bodies()` 패턴 유지(풀 직후 overlap만 믿지 않음).

### 6.3 ProjectileAttack

- 이동 전략 분리: Straight, Pierce, Return, CurvedReturn, Homing, Arc, Bounce(선택).
- 관통·lifetime·환경 충돌·`chain_on_end`.
- 사용 예: 리볼버, 마법탄, 부메랑, 투척병(→ Area 연쇄).

**현재:** 타입별 스크립트에 movement 하드코딩 — 목표는 `MovementStrategy` 또는 `WeaponData.projectile_movement` 매핑 유지.

### 6.4 OrbitAttack

- 기준점(owner) 주위 궤도, overlap 또는 주기 판정.
- 자동 공격 off: **판정만 정지**, 궤도 유지 옵션(현 `king_bible_orb`와 동일).

**현재:** `king_bible_orb.gd` + `Gun._spawn_orbit_companion()`.

---

## Attack Behaviors — 1차 공격 행동 설계 범위

본 시스템으로 구현할 **1차 공격 행동 세트**이다. 각 행동은 정의·트리거·전달·해결 계층에 매핑하며, 모두 `AttackDefinition` / `AttackContext` / `AttackEntity` / `DamageResolver`(또는 동등 API)를 사용한다. **새 행동을 추가할 때도 동일 계층 구분을 유지**한다.

| # | 행동 | 정의(Definition) | 전달(Delivery) | 트리거(Trigger) | 해결(Resolution) | 현재 구현 |
|---|------|------------------|----------------|-----------------|------------------|-----------|
| 1 | **근접 대상 공격** (Melee Single Target) | 단일 대상 근접 피해 스펙 | `TargetAttack` 또는 짧은 lifetime `AreaAttack`(소형 원/사각) | 근접 무기, 몹 접촉 공격, 보스 근접 패턴 | 단일 대상 피해·상태이상 | 플레이어 근접 무기: `MeleeProjectile`(발사체형). 몹: `tick_contact_attack` + HurtBox 1회 |
| 2 | **근접 범위 공격** (Melee Area / AoE) | 주변·전방 부채꼴/원형 범위 스펙 | 원형·부채꼴 `AreaAttack` (`setup_circle` / `setup_rectangle`) | 플레이어 스킬, 보스 광역 베기, 몹 충격파 | 범위 내 다수 대상, 대상별 `hit_interval` | 연금 착지 `AreaDamageZone`. 부채꼴 `setup_rectangle`은 API만 존재, 카탈로그 미사용 |
| 3 | **원거리 직선 발사체** (Linear Projectile) | 직선 궤도·속도·관통·사거리 | `ProjectileAttack` + Straight / StraightPierce | 총기류, 마법 탄환, 몹 원거리(`mob_projectile`) | 명중 피해, 관통·멀티 히트 | `bullet_2d`, `magic_bolt`, `mob_projectile` |
| 4 | **돌진 근접 범위** (Charge + Area) | `charge_*` export(트리거 거리·배율·지속·쿨다운·종료 피해·`charge_lane_display_duration`) | `Mob` windup(레인·`!`) → 직선 이동, 종료 시 반경 피해 1회 | 특수몹 돌진 패턴 | `DamageResolver.apply_burst_damage_to_player_in_radius` | **`mob_special_b`**: 트리거 거리 내 **경로 예고 후** 돌진 → 도착 범위 피해 |
| 5 | **자폭 공격** (Self-Destruct) | `self_destruct_*` export(HP 임계) | 임계 도달 시 `_request_die()` + 기존 사망 burst | 특수 몹 체력 임계 | 사망 처리 + `death_burst_*` 반경 피해 | **`mob_special_b`**: HP 임계 자폭(클리어 사망 제외) |
| 6 | **사망 시 범위** (Death AoE / On-Death) | `death_burst_*` + `death_burst_delay` export | `schedule_mob_death_burst` → (지연) `death_burst_warning` + `spawn_mob_death_burst` | `Mob._die()` (일반 사망만) | `DamageResolver.apply_burst_damage_to_player_in_radius` | **`mob_special_a`**: 사망 위치에서 지연(기본 3s) 후 반경 피해. 몹은 즉시 풀 반환, 예고 링은 사망 좌표에 유지. `_stage_clear_death`에서는 미발동 |
| 7 | **연쇄/복합** (Chained / Composite) | 선행 공격 + 후속 `AttackDefinition` 목록 | OnEnd/OnHit: `Projectile`→`Area`, `Target`→`Target` 체인 | 특정 무기·스킬, 보스 페이즈 | 전 과정 `DamageResolver`·통계 귀속 유지 | 연금: `concoction`→`AreaDamageZone`. 체인 번개·OnDeath 체인은 **미구현** |
| 8 | **추격 기술(점프) + 착지 burst** | `jump_chase_*` export(발동 거리·windup·이동·쿨·burst 반경/피해) | `MobChaseSkillJump` — windup(`!`) → lerp 이동(전달) | `mob.gd` `_process_chase_skill` — 직선/포위 추격 **도중** 쿨다운 기술 | `MobChaseSkillEffectLandingBurst` → `DamageResolver.apply_burst_damage_to_player_in_radius` | **`mob_fast`**: `chase_mode=0` + `jump_chase_enabled`. burst 0이면 이동만 |

### 행동별 구현 메모

**1. 근접 대상** — 목표는 `TargetAttack`이지만, 현재 카탈로그 Melee는 **짧은 `ProjectileAttack`**(`melee_projectile`)로 체감을 만든다. `TargetAttack` 도입 시에도 발사체형 근접을 유지할지(비주얼·관통) 기획과 함께 결정한다. 몹 접촉은 `Mob` 트리거 + `Player` 피해 API이며 Attack Entity를 쓰지 않는다.

**2. 근접 범위** — `AreaAttack`이 정본. 부채꼴은 `AreaDamageZone.setup_rectangle`로 전달; 트리거는 스킬·보스 Director에서 `AttackFactory` 호출.

**3. 원거리 직선** — `ProjectileAttack` + `movement_type = Straight`. 몹 탄은 동일 전달 타입이나 **해결 API가 플레이어 전용**(`apply_mob_projectile_damage`)이므로 `AttackContext.instigator_team`으로 분기한다.

**4. 돌진 + 범위** — `Mob._begin_charge_attack`: `mob_charge_lane` + `mob_attack_mark`로 `charge_lane_display_duration` 동안 제자리 예고 → `_start_charge_movement`로 가속 이동 → `_end_charge_attack`에서 `charge_end_burst_*` 반경 피해. F6 튜닝은 `TestArenaMobSnapshot` **돌진 거리**(`charge_travel_distance`→`charge_duration`); `charge_attack_enabled`면 사망 폭발 튜닝 UI는 숨김.

**5. 자폭** — `AreaAttack` spawn 직후 또는 동시에 해결 계층에서 공격자 사망 처리. **일반 사망 보상·풀 반환**과 순서를 명시한다(`register_kill` 전/후). 클리어 사망 경로와 분리한다.

**6. 사망 AoE** — `Mob._trigger_death_burst()` → `AttackFactory.schedule_mob_death_burst`. `death_burst_delay > 0`이면 `death_burst_warning`이 반경 링을 키운 뒤 피해·`poison_explosion` 연출(피해 반경 ×1.35 시각만 확대). delay 0이면 즉시 burst. **클리어 사망**에서는 미발동. F6에서 특수 A 등 `death_burst_*`·지연 튜닝(`TestArenaMobSnapshot`; 돌진 몹 제외).

**7. 연쇄/복합** — `chain_on_end: Array[Resource]`(목표) 또는 현행처럼 전달 스크립트 내 spawn. 연쇄마다 **새 `AttackContext`**(피해·origin 상속 규칙 문서화). DoT·장판도 source weapon 유지.

**8. 추격 기술(점프) + 착지 burst** — `MobChaseSkillJump`가 windup·lerp 이동만 담당(전달). 착지 피해는 `_on_chase_skill_completed` → `MobChaseSkillEffectLandingBurst.apply` → `DamageResolver.apply_burst_damage_to_player_in_radius`. `chase_mode`와 분리 — STRAIGHT/ORBIT 추격 중에도 발동. F6 튜닝: `TestArenaMobSnapshot` **추격 기술** 섹션(`jump_chase_travel_distance`→`jump_chase_duration` 환산).

```text
[행동 7 예시 — 연금]
Trigger: Gun.shoot()
  → ProjectileAttack (Arc) … OnEnd
  → AreaAttack (circle, poison tick)
  → Resolution: Mob.apply_weapon_damage (동일 weapon 귀속)
```

### 1차 행동 ↔ Attack Entity 요약

| Attack Entity | 담당 행동 (#) |
|---------------|----------------|
| `TargetAttack` | 1 (목표), 4 (도착 접촉 옵션), 7 (체인) |
| `AreaAttack` | 1 (짧은 범위 옵션), 2, 4 (도착), 5, 6, 7, **8 (착지 burst)** |
| `ProjectileAttack` | 3, 7 |
| `OrbitAttack` | *(1차 행동 표 외 — 지속 궤도 무기, `Architecture_Projectiles` 참고)* |

---

## Trigger 계층

트리거는 공격을 **시작**만 한다. HP를 깎지 않는다.

요구사항:

- 입력(`ActionManager.ACTION_ATTACK`), 자동 사격(`Player.is_auto_attack_enabled()`), 몹 AI(windup·쿨다운) 통합 인터페이스.
- 사거리·타겟 유효성·일시정지·게임 시작 전 스폰 금지(`_ensure_game_started`) 준수.
- **현재:** 플레이어 자동 사격은 `Gun._has_enemy_in_attack_range()`가 true일 때만 `shoot()`·timer·버스트 진행. 수동 `ACTION_ATTACK`은 타겟 없이 발사 가능.
- 공격 가능 시 `AttackFactory.spawn_attack(context)` 호출.

| 목표 컴포넌트 | 현재 |
|---------------|------|
| `PlayerAttackController` | `Gun` + `Player` APS·자동공격·조준 |
| `MobAttackController` | `mob.gd` 접촉·원거리 windup |
| `TargetingService` | `Gun._get_current_target`, `_has_enemy_in_attack_range`, `mobs` 그룹 |
| `AttackSelector` | `WeaponData` + `Gun.shoot()` 분기 |

---

## Resolution 계층 (DamageResolver)

모든 피해는 **단일 관문**을 통과한다.

```gdscript
class_name DamageResolver
extends Node

func apply_attack(target: Node, context: AttackContext, hit_info: Dictionary) -> void
```

처리 항목(목표):

- 최종 피해량·원소·받는 피해 배율
- 상태이상 적용
- 사망·피드백(hit flash, floating text)
- 전투 통계(`Game.register_weapon_damage`)
- on_hit / on_kill 후속(선택)

### 현재 API (1차 — 이 경로 유지)

| 방향 | API | 금지 |
|------|-----|------|
| 플레이어 → 몹 | `Mob.apply_weapon_damage(amount, weapon)` | 발사체에서 `register_weapon_damage` 직접 호출 |
| 몹 → 플레이어 | `Player.apply_mob_projectile_damage` 등 | `apply_weapon_damage` 혼용 |
| DoT | `Mob.apply_status_tick_damage` + source weapon | weapon 없는 tick |

`DamageResolver`는 **얇은 래퍼**로 도입 가능: 내부에서 위 API만 호출.

---

## AttackFactory

```gdscript
class_name AttackFactory
extends Node

func spawn_attack(context: AttackContext) -> AttackEntity
```

요구:

- `ScenePool.acquire` 우선, `delivery_type`과 `attack_scene` 타입 일치 검증.
- 잘못된 설정 시 `attack_id` 포함 에러 로그.
- 월드 부모: `/root/Game` 또는 기존 `Gun._spawn_from_pool` 계약.

**현재:** `Gun._spawn_from_pool` + `setup()` / `setup_weapon()` — Factory로 흡수하는 것이 1차 리팩터 목표.

---

## 복합 공격

| 트리거 시점 | 예시 |
|-------------|------|
| OnSpawn | (선택) 스폰 시 보조 이펙트 |
| OnHit | 명중 시 추가 판정 |
| OnEnd | 투척병 착지 → `AreaAttack` |
| OnDeath | (선택) 처치 시 폭발 |

예시 매핑:

| 무기/스킬 | 전달 | 비고 |
|-----------|------|------|
| 리볼버 | `ProjectileAttack` | Straight |
| 샷건 | `ProjectileAttack` | 다발 |
| 독 폭탄(연금) | `ProjectileAttack` → `AreaAttack` | `concoction` → `AreaDamageZone` |
| 체인 번개 | `TargetAttack` | 다중 체인 — **신규** |
| 왕의 성경 / 가시 철퇴 | `OrbitAttack` | companion |
| 근접 관통 | `ProjectileAttack` | `MeleeProjectile` — 비주얼만 검기형 |

`chain_on_end: Array[Resource]` 도입 전에는 기존 스크립트 내 연쇄(`concoction`)를 Factory 콜백으로 점진 이전.

---

## Flow

### Runtime (목표)

1. 트리거가 `AttackDefinition` 사용 가능 여부·쿨다운·타겟 검사.
2. `AttackContext` 생성, `rolled_damage` 확정.
3. `AttackFactory.spawn_attack(context)` → `AttackEntity.setup` → `activate`.
4. Entity가 이동·overlap·tick 수행, 명중 시 `resolve_hit`.
5. `DamageResolver` → `Mob.apply_weapon_damage` / 플레이어 피해 API.
6. lifetime·OnEnd → 연쇄 spawn 또는 `PoolUtil.release_node`.

### 마이그레이션 단계 (권장)

| 단계 | 작업 | 기존 동작 |
|------|------|-----------|
| 0 | 본 문서·불변조건 합의 | 현행 유지 |
| 1 | `AttackContext` + Factory가 `Gun` spawn 경로 래핑 | **완료** — `WeaponData` 유지 |
| 2 | `AreaDamageZone`·`bullet_2d`를 `AttackEntity` 베이스 상속 | API 동일 — **2차** |
| 3 | `DamageResolver` thin wrapper | **완료** — `bullet_2d` + `DamageResolver` |
| 4 | `TargetAttack` + 샘플 1종 | F6 검증 |
| 5 | `AttackDefinition` 필드 이전(선택) | `WeaponData` deprecated 점진 |

---

## Non-Functional Requirements

### 성능

- 발사체·영역·이펙트 풀링 기본 (`ScenePool`, `pool_reset` generation 패턴).
- 히트 대상 `Dictionary`는 generation으로 무효화(`AreaDamageZone._setup_generation` 패턴).
- 디버그: 활성 Attack Entity 수, `attack_id` 필터 로그.

### 디버깅 (목표)

- 활성 독립체 수 HUD/오버레이(선택).
- 범위·궤적 gizmo(에디터 또는 F6).
- 명중 시 context 덤프 옵션.

---

## Completion Criteria (1차 인프라 — Week02)

- [x] `AttackContext`, `AttackFactory`, `AttackServices` 구현
- [x] `DamageResolver` — 플레이어 발사체·장판·궤도·투척·부메랑 + `mob_projectile` + 사망 burst
- [x] `bullet_2d.setup(..., pre_rolled_damage)` — `AttackContext.rolled_damage` 전달, Factory 누락·acquire 실패 경고
- [ ] `ProjectileAttack`·`AreaAttack` **기존 무기 5종 이상** F6/F5 회귀 — 에디터 수동 확인
- [x] `Gun`이 `AttackFactory`만으로 플레이어 공격 오브젝트 스폰
- [x] 연금 `concoction` → `AttackFactory.spawn_area_circle` 경유
- [ ] `OrbitAttack` 자동공격 on/off — 에디터 수동 확인
- [ ] `AttackEntity` 베이스 — **2차**
- [ ] `TargetAttack` — **2차**
- [x] 1차 행동 6(OnDeath) — `mob_special_a` 지연 burst + 예고 링 + F6 튜닝 (F6 수동 확인)
- [ ] 1차 행동 4~5(돌진·자폭) — **2차**
- [x] Attack Entity 내부 직접 HP 수정 없음(기존 계약 유지)
- [x] `%AttackServices` on `survivors_game` + `test_arena`

---

## Invariants & Gotchas

| 규칙 | 이유 |
|------|------|
| 독립체는 전달만 | 통계·상태이상·사망 중복 방지 |
| 플레이어→몹은 `apply_weapon_damage` | `WeaponDamageTracker` 귀속 |
| 트리거가 HP 직접 수정 금지 | 계층 분리 |
| Melee 카탈로그는 `melee_projectile` 유지 | `melee_swipe` 정적 히트박스 금지(프로젝트 규칙) |
| 원거리 몹은 접촉 피해 없음 | `Architecture_Mobs` |
| 활성 weapon만 `Player.add_weapon()` | 비활성/가방 무기 공격 금지 |
| 일시정지 시 스폰·밸런스 시계 정지 | `game.gd` |
| UTF-8 without BOM on `.tscn` | 파싱 에러 방지 |

---

## Change Guidelines

| 변경 | 확인 |
|------|------|
| 새 Attack Entity 종류 | `AttackFactory`, `PhysicsLayers`, `ScenePool` prewarm, Architecture_Projectiles |
| `AttackDefinition` 필드 추가 | `WeaponData`·카탈로그·툴팁·F6 스냅샷 |
| Trigger 통합 | `Gun` 자동공격·수동 `attack`·궤도 companion |
| 해결 API 변경 | `mob.gd`, `player.gd`, `game.gd` grep, 게임오버 피해 목록 |
| 보스 패턴 | `MobAttackController` 또는 Director — `mob.gd` 비대화 방지 |

최소 검증: F6에서 리볼버·연금·왕의 성경·대표 근접·원거리 몹 투사체, F5 자동공격 on/off, 벽 충돌, 게임오버 피해 목록.

---

## Implementation Priority

1. `AttackContext` + `AttackFactory` (`Gun` spawn 래핑)
2. `AttackEntity` 베이스 + `pool_*` 계약
3. `DamageResolver` thin wrapper → 기존 Mob/Player API
4. `ProjectileAttack` / `AreaAttack` — 기존 씬 상속·이름 정리
5. `OrbitAttack` — `king_bible_orb` 정리
6. `TargetAttack` + 샘플 1종
7. `chain_on_end` Resource 배열 + 복합 공격 일반화
8. 디버그 도구

---

## Related Documents

- 구현 상세(현행): [`Architecture_Weapons.md`](Architecture_Weapons.md), [`Architecture_Projectiles.md`](Architecture_Projectiles.md), [`Architecture_Mobs.md`](Architecture_Mobs.md)
- 작업 규칙: `.cursor/rules/godot-weapons.mdc`, `godot-pool.mdc`, `godot-mobs.mdc`
- 플레이어 규칙: [`Wiki/Combat.md`](../Wiki/Combat.md)
