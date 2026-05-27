# Core Constraints — 핵심 제약

**역할:** 프로젝트 전역에서 자주 깨지는 게임·구조 제약을 모아 둡니다.

- **실행 must / must not** → [`.cursor/rules/`](../../.cursor/rules/) (`godot-core.mdc` 등). 겹치면 `.mdc`가 우선합니다.
- **도메인별 Invariants** → [`Docs/Architecture/`](../Architecture/) 각 문서의 `Invariants & Gotchas` 섹션.

**진입:** [`AGENTS.md`](../../AGENTS.md)

---

- Unity `.meta` 파일이 아니라 Godot 프로젝트입니다. Godot 리소스/씬의 참조를 깨지 않도록 씬·리소스 경로를 보존합니다.
- `.cursor/rules/*.mdc`의 must / must not이 이 문서보다 우선합니다.
- F5 메인과 F6 테스트 아레나는 목적이 다릅니다. 테스트 편의를 위해 F6 `test_arena.tscn`을 아레나 모드와 섞지 않습니다.
- 서바이벌 모드는 시간 밸런스, 아레나 모드는 웨이브 번호가 난이도 축입니다. 아레나 변경 시 30분 클리어·타임라인 이벤트가 다시 켜지지 않게 확인합니다.
- `/root/Game` 계약을 쓰는 스크립트가 많습니다. 씬 루트 이름과 자식 노드 계약을 바꾸면 관련 경로를 함께 점검합니다.
- UI는 FHD 좌표를 기준으로 만들고 `UiViewportLayout`이 스케일합니다. HD 픽셀에 맞춰 이중 축소하지 않습니다.
- 메인 맵 크기 변경은 `survivors_game.tscn`의 `%MapArena` 인스턴스 오버라이드를 확인합니다. `map_arena.gd` 기본값만 바꾸면 F6 기준만 바뀔 수 있습니다.
- 무기 피해는 `Mob.apply_weapon_damage(amount, weapon)` 경로를 우선 사용해 `WeaponDamageTracker` 귀속을 유지합니다.
- 몹 일반 사망과 클리어 사망을 섞지 않습니다. 서바이벌 30분 클리어와 아레나 10웨이브 클리어 모두 클리어 사망은 드랍·처치 집계를 만들지 않습니다.
- 인벤토리는 데모 기준 런 한정 장비 빌드 시스템입니다. 가방·장비 세트·상자 보상·골드는 클리어, 패배, 로비 복귀, 새 런 시작 시 영구 저장하지 않고 초기화합니다.
- 장비 획득은 먼저 런 인벤토리에 넣고 빈 장착 슬롯이 있으면 자동 장착합니다. weapon/offhand는 활성 세트 빈 슬롯 → 비활성 세트 빈 슬롯 → 가방 순서이고, offhand는 같은 세트 weapon이 양손이 아닐 때만 장착할 수 있습니다(`offhand 1`은 `weapon 1`, `offhand 2`는 `weapon 2`). 공유 방어구는 대상 슬롯이 비어 있으면 바로 장착합니다. weapon 전투 적용은 활성 세트 weapon만 `Player.add_weapon()` 경로로 처리합니다.
- 모든 장비 효과는 장착된 슬롯에서만 적용합니다. 가방 장비와 비활성 세트 weapon/offhand는 스탯, 패시브, 비주얼, 공격 효과를 만들지 않습니다.
- 풀링 대상은 `pool_reset()` / `pool_on_acquire()` / `PoolUtil.release_node()` 계약을 지킵니다.
