# Phase 2.9 — Battlefield Production Convergence

最終更新: 2026-09-23
目的: Phase 2.7 で完成した gameplay loop と Phase 2.8 で移植した
production buildings を維持したまま、canonical match を「平坦な
Prototype Map」から「Aether Crown らしい Production Battlefield」へ
収束させる。新規モデリングは一切行わず、main に統合済みの
**Gearforge Map Production Kit 01** のみを使用。

## 使用した既存 Map Kit assets

- `gearforge_bridge_heavy.glb` (Heavy Aether Bridge, 9,528 tris)
- `gearforge_fortress_gate.glb` (Fortress Gate, 3,176 tris)
- `gearforge_wall_straight.glb` (Wall Straight ×2)
- `gearforge_wall_tower.glb` (Wall Tower)
- `gearforge_defensive_bastion.glb` (Defensive Bastion)
- `gearforge_cliff_straight.glb` (Cliff Straight ×4)
- `gearforge_cliff_large.glb` (Cliff Large ×2)
- `gearforge_trench_industrial.glb` (Industrial Trench ×5)
- `gearforge_road_straight.glb` (Road Straight ×8)

いずれも既存 GLB の再利用のみ。新規 modeling なし。

## Map layout 変更

Gameplay topology (5 cities / 7 territories / 2 HQs / 3 routes) は
不変のまま、視覚・空間構造を強化:

- **Central ravine (industrial trench)**: Central Nexus (0,0) を南北に
  縦断する掘削塹壕を2列配置 (visual x=-0.5 / 15.5, z=±8)。gameplay
  wall は x=-3 (西) / x=14 (東) の2バンドで、唯一の越境点が橋。
- **Heavy Bridge**: Central→East ルート上 (6.5, 0) に実配置
  (yaw 90、deck 14m幅、Titan 通行可能)。両端の橋脚のみ collision、
  deck は歩行可能 (walkable deck collision y=-1.5)。
- **Fortress Gate**: 敵接近路 (21, -4) に実配置 (開口10m、Titan 直立
  通過可能)。両翼に Wall Straight ×2、北に Wall Tower、南に
  Defensive Bastion。gate 開口は通過可能、柱・壁は collision。
- **Cliffs**: 南西 (West/South approach の背後 (-22,20)) と北東
  (enemy base 背面 (28,-20)) に Cliff Large、さらに両側の map
  silhouette として Cliff Straight を配置。高低差が RTS 距離で読める。
- **Roads**: 既存の dirt strip は維持しつつ、Player HQ→West→Central→
  bridge deck→East→gate→enemy base の主ルートに Map Kit の
  Road Straight slabs を重ねて配置。

## Traversal 結果

- **Infantry**: navmesh 経由で橋を渡り東側へ到達 (probe で
  (2,0,0)→(11,0,0) OK)。nav obstacle は trench 両バンドのみで、
  bridge deck は walkable。
- **Walker (直進+slide)**: 同一ルートで橋 deck を通過
  (probe で (2,0,0)→(12,0,0) OK)。bridge 進入路の Central City
  collider との衝突を、bridge/trench を +2m east シフトして解消。
- **Enemy AI**: 同じ nav/collision で city capture / production /
  bridge traversal を継続 (enemy-win で AI が橋を渡って侵攻することを
  phase27_playtest enemy-win で確認、sim 12:09、AI walker ×4)。

## Gameplay loop 維持

phase2d_test / phase27_test / phase27_playtest (player-win sim 4:30,
enemy-win sim 12:09) / phase26_test / prototype_battlefield_test /
phase25d1_test を含む regression 全 PASS。Victory / Defeat / Restart
は変更なし。production / city capture / district / walker production /
enemy AI / camera は Phase 2.7/2.8 仕様のまま。

## Performance (Iris Xe, 1080p)

- strategic match 90s idle: **min 39 / p50 42 / max 46** (19 samples)。
  目標の sustained 30fps+ を維持。Map Kit 15 assets (約22k tris) は
  再利用のため draw call 増加は最小限。

## Screenshots (`docs/screenshots/phase29/` 9枚)

p29_01_strategic_overview / p29_02_player_base / p29_03_west_city /
p29_04_central_battlefield / p29_05_heavy_bridge / p29_06_fortress_gate /
p29_07_mixed_battle / p29_08_victory / p29_09_enemy_base。

## Screenshot Visual Review

pixel 検証済 (全 1920×1008、unique colors 4.1k–11.5k、空白なし):
- 01: ravine が Central を縦断し、bridge が唯一の越境点として読める。
  cliffs が map の両端に高低差を作り、flat green ではなくなった。
- 04/05: trench + cliffs + bridge deck が同じ画角にあり、中央戦場の
  choke が視覚的に成立。walker が bridge deck 上にいる。
- 06: Fortress Gate + walls + tower が enemy approach の境界として
  読める (gate 全高21m、Titan 階層と整合)。
- 07: 混成軍 (歩兵+walker) が gate/HQ 方面へ進軍している。
- faction (青/赤) とも検出 (blue_px/red_px)、camera obstruction なし。

## Known Issues

- Infantry model は primitive のまま (新規 model は scope 外)。
- Walker は直進+obstacle slide (navmesh 非使用、Phase 2.7 仕様)。
  bridge deck の薄い collision の上を通るが、密集市街では歩兵ほど
  回り込まない。
- Titan / Airship は canonical match へ未配置 (showcase のまま)。
- Map Kit の city 敷地 dressing (yard/pipes) は最小限 (今回は choke
  構造と主要 route を優先)。
- bridge deck collision は薄い box (y=-1.5) で、visual deck と完全には
  一致しない (walker/infantry の ground snap 用の gameplay floor)。
- phase1_5_playtest は既存の乱数揺らぎで稀に NG (本 Phase 無関係)。

## 次候補 (最大3)

1. City 敷地 dressing (Map Kit props で各都市の個性を強化)。
2. Map Kit 追加エリア (Fortress Gate を起点とする enemy 要塞線の
   拡張、cliff ramp を使った多層 route)。
3. Walker RTSUnit 正式化 (navmesh pathing + separation 一本化)。
