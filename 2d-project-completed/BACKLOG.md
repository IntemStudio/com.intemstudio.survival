# BACKLOG — Godot 2D Survival

**용도:** 다음에 손댈 작업·아이디어를 모아 두는 살아 있는 목록입니다.  
**규칙:** 여기 적혀 있다고 반드시 구현하지 않습니다. 개발 중 기각·완료·범위 변경 시 항목을 **삭제·수정**해도 됩니다.

**관련 문서:** 진입 [`AGENTS.md`](AGENTS.md) · 도메인 상세 [`Docs/AGENTS_MapArena.md`](Docs/AGENTS_MapArena.md), [`Docs/AGENTS_Display_UI.md`](Docs/AGENTS_Display_UI.md) · 설계 [`Docs/Architecture_Inventory.md`](Docs/Architecture_Inventory.md) · 에이전트 must [`.cursor/rules/`](.cursor/rules/)

---

## 현재 구현된 것 (기준선)

한 판 생존 루프가 동작하는 상태입니다. 아래는 “이미 있다”는 기준으로, 백로그와 구분합니다.

| 영역 | 구현 요약 |
|------|-----------|
| 게임 루프 | 시작 무기 선택 → 스폰 타이머 → 레벨업 3택1 → **30분 클리어** 또는 패배 게임오버(무기별 피해·합계)·재시작 |
| 일시정지 | Esc, **설정**(소나무 밀도), 무기 선택·게임오버·클리어 중 일시정지 차단 |
| 밸런스 (VS형 A·B·C) | `default_balance_table.tres` VS 키프레임(11분 피크·16~20 호흡·25분 보스)·`balance_pace_multiplier` · `default_balance_timeline.tres`(9·11·25·28분 이벤트) · 30분 `die_from_stage_clear()` 클리어 |
| 몹 | basic / fast / elite / special_a·b / boss — 공용 `mob.gd`; **ranged** — 8분+ 스폰(VS형 A); **dummy** — 테스트 전용 |
| 테스트 아레나 | F6, 몹 8종 Spawn(플레이어+280px·Dummy 500HP/그 외 10×), 무기 필터+Equip, 3초 리스폰, 몹 리스폰 옵션 |
| 무기 | Ranged·Melee·Magic 카탈로그 + `gun.gd` — **근접 관통 탄**(`melee_projectile`), **영역 존**(`area_damage_zone`/연금 착지), 탄환·마법·투척·궤도; **F** 자동 공격 HUD |
| 무기 선택 UI | 3택1 + 설명 패널 + **리롤·버리기 각 3회/판** + 버린 목록 + 자동 선택·우선순위 |
| 상태이상 | 독(연금), 쐐기(nettles), 피격·독 데미지 플로팅 텍스트 |
| 피격 연출 | `HitFlash` — 몹 `%Slime`·플레이어 `HappyBoo/Colorizer` modulate 깜박임; 몹은 무기/독 피해 + `play_hurt()` 애니 병행 |
| 오브젝트 풀 | `ScenePool` + `PoolUtil` — 무기 발사체, 경험치 오브, 몹 7종+더미 prewarm, **몹 투사체·공격 예고 마크** (`prewarm_mob_projectiles` 32, `prewarm_mob_attack_marks` 20) |
| 픽업·경험치 | 오브(`ScenePool`, `exp_orbs`, `pickup_range` 자동 자석·가속·`MagnetTrail` 꼬리); `%PickupRangeRing`; 자석 1%·체력 1% 드랍(오프셋 스폰) |
| 플레이어 피격 | 근접: 범위 내 `contact_attack_interval`/`contact_attack_damage` + HurtBox 겹침 진입 시 1; 원거리: `mob_projectile`만; `GameplaySettings` 범위 링; `HitFlash` |
| 무기 조준 | `gun.gd` 사거리 내 최근접 몹 — `%TargetIndicator` 속 빈 링+브래킷(`target_indicator_ring.gd`, 펄스·회전), 몹 루트 기준 고정 오프셋 |
| 무기 피해 통계 | `WeaponDamageTracker` → 게임오버 `%WeaponDamageList` · 일시정지 `%PauseOwnedWeaponsList`(타입별 색·합계) |
| 몹 스폰(메인) | `%MapArena.get_random_spawn_position(플레이어 위치)` — 플레이어 근처 금지 반경(`mob_spawn_player_clear_extra` 130) |
| 맵 경계 | `%MapArena` — 벽(레이어 1)·내부 몹 스폰. **메인 3×** (`survivors_game.tscn` 오버라이드 6336×4104), **F6 1×** (`ARENA_RECT_1X`) |
| 소나무 | Poisson(`sparse` 960 / `dense` 50, 기본 밀도 50%), **Esc → 설정** 슬라이더(`tree_density_settings.gd`). 수동 `PineTree*` 없음 |
| 기타 | 몹 분리, 처치 수·시간 HUD |

---


---

## 갭 — 데이터·이름만 있고 gameplay가 부족한 것

프리팹·카탈로그·밸런스 테이블에는 있으나, 플레이 체감이 이름과 맞지 않거나 필드가 미사용인 항목입니다.

- [ ] **특수 몹 A/B** — HP·속도·색만 다름. `design_intent`의 “패턴”에 해당하는 행동 없음.
- [ ] **보스** — 체력·크기만 큼. 페이즈·고유 스킬·등장 연출·처치 보상 차별 없음.
- [ ] **엘리트** — 스탯·비주얼·`%TargetIndicator`만. 전용 기믹·등장 연출 없음.
- [ ] **`BalancePhase.threat`** — 키프레임·보간만 되고, 스폰·피해·플레이어 데미지 등 어디에도 미반영.
- [ ] **`mob_kind`** — 씬 export만 있고, AI·보상·UI 분기에 미사용.
- [ ] **레이피어 “En Garde”** — 카탈로그 `effect` 문구만 있고, 전투 시작 버프 미구현.
- [ ] **무기 `rarity`** — 카탈로그는 대부분 Common. 메인 선택 UI에는 등급 미표시; **테스트 아레나**에만 등급 필터 UI 있음. 드롭 가중치·성장 연동 없음.

---

## 기능 — 서바이버류로 흔히 기대되는 시스템

- [ ] **보유 무기 강화(레벨업)** — 레벨업 시 “신규 무기만” 3택1. 이미 가진 무기의 데미지·APS·범위 상승 없음.
- [ ] **무기 합성·진화** — 두 무기 조합, 최대 레벨 후 상위 무기 등 없음.
- [ ] **패시브·액세서리** — 이동속도·픽업 범위·최대 체력·재생 등 레벨업 외 성장 슬롯 없음.
- [ ] **인벤토리 Epic** — [`Docs/Architecture_Inventory.md`](Docs/Architecture_Inventory.md)
  - [x] Phase 0~2 — 데이터·`InventoryService`·`GearData`
  - [x] Phase 4~5 — UI v2(4칸 전투 슬롯)·드래그·`InventoryGameBridge`·**I**
  - [x] Phase 3 (최소) — `InventoryCombatBridge` · F6 `use_inventory_loadout`
  - [x] Phase 6 — W·RMB 스왑·HUD `%CombatSetLabel`·가방 RMB/더블클릭 장착·`try_equip_from_bag_smart`·편집 탭 분리·`UiLocale`
  - [ ] Phase 3 (잔여) — F5+레벨업 무기 공존 정책
  - [ ] Phase 7 — `sum_stat_modifiers_for_set`→Player·offhand 비주얼·퀵슬롯 4칸
- [ ] **승리 조건** — 생존 시간 목표·웨이브 클리어·보스 처치 승리 없음(현재는 사망만).
- [ ] **경험치 보상 스케일** — `exp_orb` 기본값 1 고정. 몹 종류·페이즈·엘리트/보스별 차등 없음.
- [ ] **캐릭터 선택** — HappyBoo 고정. 시작 전 캐릭터·스탯 프리셋 없음.
- [ ] **메타 진행** — 런 간 영구 해금·통화·업그레이드 없음(의도적 미구현일 수 있음).
- [ ] **보스/특수 등장 연출** — 25분 보스 플래그 등은 수치만; 경고 UI·BGM·스폰 이펙트 없음.

---

## 밸런스·디자인

**VS형 Epic (A·B·C)** — 구현 완료. 상세·체크리스트: [`Docs/Plan_Balance_VS_Curve_Alignment.md`](Docs/Plan_Balance_VS_Curve_Alignment.md) · 요약: [`AGENTS.md`](AGENTS.md) 밸런스 모델.

- [ ] **VS D — 몹 HP × 플레이어 레벨** — `initialize_spawn_health`에 `player.level` 계수(예: `1 + (L-1)*0.05`). VS “빌드 강하면 적도 단단” 체감. Plan §단계 D.
- [ ] **VS E — 하이퍼 모드 (25분)** — 25분부터 전역 배율(스폰·HP 등)·`BalanceNoticeBanner` “HYPER” 표시. B 보스 이벤트와 연동. Plan §단계 E.
- [ ] **VS F — 플레이테스트·튜닝** — 11분 피크·16~24 호흡·25분 보스·30분 클리어 체감 검증; 키프레임·`density_mult`·이벤트 수치 조정. (선택) `.cursor/rules/godot-balance.mdc`.
- [ ] **VS Q2 — 31~40분 구간** — plateau 유지 vs 클리어 후 하드 모드 확장. Plan §9.
- [ ] **접촉 피해 미세 튜닝** — 범위 주기 공격·충돌 1 피해·원거리 접촉 제거 반영됨. 남음: i-frame·변종별 `contact_attack_interval`/`attack_distance`·고속 탄 터널링. (`AGENTS.md` 접촉 피해)
- [ ] **`threat` 활용 설계** — 예: 플레이어 접촉 데미지 배수, 스폰 밀도와 분리한 “압박도” 지표로 쓸지 결정 후 연결.
- [ ] **동시 생존 몹 상한 UX** — `max_alive_mobs` 도달 시 스폰 스킵만 함. HUD·디버그 표시 없음.
- [ ] **난이도 프리셋** — Easy/Normal/Hard용 `BalanceTable` 리소스 분리.

---

## UX / UI

- [ ] **무기 선택 UI 정리** — `CHOICE_COUNT = 3`인데 버튼 4개·노드명(`RevolverButton` 등)이 초기 예제 잔재. 동적 버튼 생성 또는 이름 통일.
- [ ] **현재 페이즈·위협 HUD** — 생존 시간만 표시. “지금 구간 의도”·`threat`·주요 스폰 비율 요약(디버그용이라도).
- [ ] **게임오버 통계 (추가)** — 생존 시간·도달 레벨·처치 수를 **게임오버 패널**에 표시. (무기별 피해·합계는 게임오버·**Esc 일시정지** 모두 구현 — `AGENTS.md` 무기별 피해 집계)
- [ ] **쐐기·독 디버프 비주얼** — 로직은 있으나 몹 위 상태 아이콘·지속 틴트 약함(확인 후 보강). 일반 피격 `modulate` 깜박임은 `HitFlash`로 구현됨(`AGENTS.md`).
- [ ] **로컬라이제이션 정리** — `display_name_ko`는 선택 UI에 사용 중. `weapon_subtype`·`effect`는 `build_select_tooltip_bbcode()`에서 부분 치환(`_effect_ko`); 카탈로그 `effect_ko`·분류 한글 필드는 미도입.

---

## 콘텐츠·폴리시

- [ ] **무기 아이콘** — 카탈로그 대부분 `art/shared/pistol.png` 공용. 무기별 스프라이트·틴트 규칙 정리.
- [ ] **무기 수 vs 품질** — 카탈로그 약 47종, 고유 비주얼·밸런스 검증은 소수에 집중된 상태. 우선순위 무기 목록을 두고 나머지는 보류/삭제 검토 가능.
- [ ] **몹 비주얼 다양화** — Slime 변종만. ranged/special/boss 전용 실루엣·애니 없음.
- [ ] **사운드** — `default_bus_layout.tres`(Master·BGM·SFX)·일시정지 볼륨 UI·`user://audio_settings.cfg` 적용됨. BGM·타격·레벨업·보스 SFX **재생 노드**(`AudioStreamPlayer.bus = "BGM"`/`"SFX"`) 미연결.
- [ ] **UI 다국어 2차** — `UiLocale` 1차: 일시정지·설정·HUD·게임오버·**무기 선택 UI**(제목·리롤·버리기·자동선택·툴팁 구조). 남음: 밸런스 공지·레벨/EXP·`WeaponData` 효과 문장 한→영 변환.
- [ ] **프로젝트 표기** — `project.godot` 앱 이름이 GDQuest 튜토리얼명. 배포용 이름·아이콘 변경.
- [ ] **맵·장식 (추가)** — Poisson 소나무·일시정지 설정 밀도·3×/1× 씬 분리는 구현됨([`Docs/AGENTS_MapArena.md`](Docs/AGENTS_MapArena.md) §소나무). 남음: `pine_tree` 파괴, 카메라 클램프, 바닥 체커를 `arena_rect`에 맞춤, (선택) BFS 막힘 재시드

---

## 기술 부채·구조

- [ ] **오브젝트 풀 확장** — `FloatingDamageText`(우선), `smoke_explosion`, `poison_explosion`, `magnet_pickup`(저빈도·선택); `concoction`은 `gun` 풀 spawn만 되고 `pool_reset`/`PoolUtil.release` 미완.
- [ ] **`/root/Game` 하드코딩** — Autoload 없음. `mob.gd`, `gun.gd`, `player.gd`, `exp_orb.gd` 등 경로 일괄 의존. 리네임·씬 분리 시 grep 필수.
- [ ] **HUD 노드 경로** — `player.gd`가 `/root/Game/HUD/HUDRoot/...` 문자열로 직접 접근. `%` 또는 시그널로 완화 검토.
- [ ] **카탈로그 vs `.tres`** — `revolver.tres` 등 개별 리소스와 카탈로그 중복 가능성. 단일 소스(카탈로그만 또는 리소스만) 정리.
- [ ] **근접 무기 무대상** — `gun.gd` 근접은 유효 타겟 없으면 스윙 자체를 안 함. 범위 내 적이 없을 때도 공격 모션/쿨만 도는지 정책 결정.
- [ ] **몹 분리 루프 비용** — 매 프레임 `get_nodes_in_group("mobs")` 전체 순회. 몹 수 증가 시 공간 분할·캐시 검토(필요할 때만).

---

## 아이디어 — 우선순위·범위 미정

구현 여부·난이도·재미 기여는 플레이 테스트 후 결정. 기각해도 됩니다.

- 플레이어 주변 **링/오프스크린** 스폰(현재는 내부 균일 랜덤 + 플레이어 근처 **410px** 금지 — `player_clear_radius` 280 + `mob_spawn_player_clear_extra` 130), 밀집 웨이브
- `arena_rect` 밖 **카메라 클램프**·바닥 체커를 플레이 영역에만 그리기
- 보스 처치 시 일시 무적·전체 경험치·상자 드롭
- 무기 선택 리롤·버리기 **골드/레벨 비용** (횟수 상한 3회/판은 구현됨 — `AGENTS.md` 무기 선택 UI)
- 시간 제한 이벤트(예: 5분마다 30초 고밀도)
- `pine_tree` 파괴·불 장판 등 환경 상호작용
- 플레이어 넉백·무적 프레임 (대시는 구현됨 — `AGENTS.md` 플레이어 이동·대시)
- 몹 투사체 **B안**(전용 physics layer) — 현재 A안(mask 1, 나무 차단). 레이어 분리 시 `godot-core.mdc` 일괄 수정
- 에디터에서 `BalanceTable` 프리뷰(현재 분·비율 그래프)
- 간단한 런 종료 리포트 JSON 저장(밸런스 튜닝용)

---

## 작업할 때 체크 (항목 추가·완료 시)

1. **몹 추가** → `mob_*.tscn` + `mob_spawn_selector.gd` + `default_balance_table.tres` + `ScenePool.MOB_SCENES` (`.mdc` 필수)
2. **무기 추가** → 카탈로그 + `gun.gd` 타입 처리 + `weapon_id` 고유 + 선택 UI 풀. 새 투사체는 `pool_reset`/`PoolUtil.release`. 툴팁에 새 스탯·특수 규칙이 보이면 `weapon_data.gd`의 `build_select_tooltip_bbcode()`도 같이 갱신
3. **풀 대상 이펙트 추가** → `ScenePool.acquire` + `pool_reset`/`pool_on_acquire` + `PoolUtil.release_node`, prewarm 수치
4. **자석·픽업 변경** → `mob.gd` 드랍 확률·`magnet_pickup`·`exp_orb`·`player.gd` `collect`/`start_magnet`·`pickup_range`·`_sync_pickup_range_visual`·`player.tscn` `%PickupRangeRing`; `AGENTS.md` 픽업 섹션 동기화
4b. **대시·게이지 변경** → `player.gd` 상수·`_update_dash_cooldown_gauge`·`player.tscn` `%DashCooldownBar`; `AGENTS.md` 플레이어 이동·대시 섹션 동기화
4c. **자동 공격 토글·HUD 변경** → `player.gd` (`auto_attack_enabled`, `toggle_auto_attack`), `gun.gd` (`refresh_auto_attack`, `_is_auto_attack_enabled`), `king_bible_orb.gd`, `survivors_game.tscn` `%AutoAttackLabel`, `project.godot` `toggle_auto_attack`; `AGENTS.md` 자동 공격 토글 섹션 동기화
4d. **무기 피해 집계·게임오버·일시정지 표시 변경** → `mob.gd` `apply_weapon_damage`/`apply_poison`, `weapon_damage_tracker.gd`, `game.gd` (`populate_weapon_damage_list`, `get_weapon_damage_display_rows`), `ui/pause_menu.gd`, `survivors_game.tscn` `%WeaponDamageList`·`%PauseOwnedWeaponsList`; `AGENTS.md` 무기별 피해 집계
4k. **몹 스폰·플레이어 근처 금지** → `map_arena.gd` `get_random_spawn_position`·`mob_spawn_player_clear_extra`, `game.gd` `spawn_mob`; `godot-core.mdc`·[`Docs/AGENTS_MapArena.md`](Docs/AGENTS_MapArena.md) 동기화
4e. **원거리 몹·투사체·예고 마크** → `mob.gd` export·`mob_ranged.tscn`·`mob_projectile.*`·`mob_attack_mark.*`·`player.apply_mob_projectile_damage`·`scene_pool` prewarm·`ranged_spawn_ratio`; `AGENTS.md` 원거리 몹 섹션
4f. **테스트 아레나·더미 몹** → `test_arena.tscn`·`test_arena.gd`·`mob_dummy.tscn`·`mob.gd` `movement_enabled`/`combat_enabled`·`MobSpawnSelector.MOB_DUMMY_SCENE`·`scene_pool` prewarm·`player.gd` `clear_weapons`/`reset_health_depleted_state`; `AGENTS.md` 테스트 아레나 섹션
4g. **피격 깜박임 변경** → `effects/hit_flash/hit_flash.gd` (`FLASH_MULTIPLIER`, `BLINK_COUNT`, on/off 시간), `mob.gd` (`_play_hit_flash`, `pool_reset`·`HitFlash.cancel`), `player.gd` (`_play_hit_flash`, `Colorizer`); `AGENTS.md` 피격 깜박임 섹션 동기화
4h. **맵 경계·스폰 영역 변경** → `map_arena.gd`, **`survivors_game.tscn` `%MapArena` 오버라이드(메인 3×)**, `test_arena.tscn`(1×·`spawn_trees`), `game.gd` `spawn_mob`; [`Docs/AGENTS_MapArena.md`](Docs/AGENTS_MapArena.md)·`godot-core.mdc`
4j. **소나무 Poisson·밀도 UI 변경** → `poisson_sampler.gd`, `map_arena.gd`(`tree_spacing_dense`/`sparse`, `tree_min_spacing`, `get/set_tree_density_normalized`, 기본 밀도 50%), `ui/settings/tree_density_settings.gd`, `survivors_game.tscn` `%PauseMenu` `%SettingsPanel`; [`Docs/AGENTS_MapArena.md`](Docs/AGENTS_MapArena.md) §소나무·`AGENTS.md` §일시정지
4l. **일시정지·설정 UI 변경** → `ui/pause_menu.gd`, `survivors_game.tscn` (`%PauseMainContent`, `%SettingsPanel`, `SettingsButton`, `SettingsBackButton`); `AGENTS.md` §일시정지 메뉴
4i. **무기 선택·리롤·버리기 UI 변경** → `ui/weapon_select_menu.gd` (`present_random_choices`, `reroll_choices`, `discard_weapon_at_index`, `_owned_weapons`, `_discarded_weapons`, `_build_selectable_weapon_pool`), `survivors_game.tscn` (`DiscardSlot0~2`, `RerollButton`, `RightColumnVBox/DiscardedPanel`, `AutoSelectRow`, `AutoPriorityPanel`); `AGENTS.md` 무기 선택 UI·`.cursor/rules/godot-weapons.mdc`
5. **접촉 피해·충돌 정렬 변경** → `ground_shadow_footprint.gd`, `player.gd` (`_apply_contact_damage`, `HurtBox`, `set_contact_damage_enabled`), `mob.gd` (`contact_attack_interval`/`contact_attack_damage`, standoff, `is_contact_damage_active`), `mob_projectile` (`collision_mask` 9); `AGENTS.md` 접촉 피해·원거리 몹·게임 플레이 설정
5b. **조준 링·경험치 자석 연출** → `gun.gd` `_set_targeted`, `mob.gd` `set_targeted`·`target_indicator_ring.gd`·`%TargetIndicator`, `exp_orb.gd`/`exp_orb.tscn` (`MagnetTrail`, 가속 상수); `AGENTS.md` 조준 표시·픽업 섹션
6. **이 항목 완료** → 위 목록에서 해당 줄 삭제 또는 “완료(날짜)” 한 줄로 축약
7. **기각** → 이유 한 줄 남기고 삭제하거나 “기각” 섹션으로 이동(선택)

---

*마지막 갱신: 2026-05-24 — 근접 접촉(범위 주기 공격·충돌 1)·원거리 발사체-only·`GameplaySettings` 근/원 거리 링·`mob_projectile` mask 9. 구현이 바뀌면 이 문서도 함께 맞춥니다.*
