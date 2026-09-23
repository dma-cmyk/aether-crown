# Phase 2.10 — Gemini Terrain Merge + Canonical Terrain Integration

最終更新: 2026-09-23
目的: `origin/gemini-terrain-foundation` (140m×140m Production Terrain) を
main へ安全に merge し、canonical match (phase2d_strategic_match) を旧
Flat Prototype Map から Gemini Production Terrain へ移行する。Phase 2.7
gameplay loop と Phase 2.8 production buildings、Phase 2.9 Map Kit を
全て維持したまま、地形本体・collision・navigation を新地形上で成立
させた。Terrain Generator の変更は行っていない (Gemini terrain GLB /
heightmap は merge したものをそのまま使用)。

## Merge

- pre-merge main HEAD: `e22f623` (Phase 2.9)
- Gemini branch HEAD: `9e5ebb3` (feat: add production terrain surface materials)
- merge commit: `7bde306` (`merge: integrate Gemini terrain foundation`,
  --no-ff、conflict 0件。diff は 81ファイル全て terrain 関連の追加のみ、
  既存 gameplay 変更ゼロを事前確認)
- 破壊的操作なし (reset --hard / clean -fd / branch -D / force push 不使用、
  gemini branch / worktree は残存)

## Terrain asset

- GLB: `game/assets/models/map/aether_crown_terrain_foundation.glb`
  (140m×140m, 19,881 verts, 39,200 tris, PBR 4セット埋込)
- heightmap: `blender/exports/map/aether_crown_terrain_heightmap.png`
  (141×141, 16bit, 0-26m)
- textures: `game/assets/textures/terrain/{dark_grass,industrial_dirt,
  charcoal_rock,industrial_slag}/*_{albedo,normal,roughness}.png`
  (import warning 0、missing 0)

## Architecture (新規)

### `game/scripts/terrain/production_terrain.gd` (ProductionTerrain)
- heightmap を bilinear サンプリングする `get_height(x,z)` — 地形高さの
  single source of truth (Blender generator と同一の 1m グリッド)。
- 2m ステップの concave collision を height 関数から生成
  (**教訓: `SurfaceTool.add_triangle_fan` は ConcavePolygonShape3D で
  衝突しない三角形を生成する。`add_vertex` 3連のみ有効。MapNav 旧
  ground と同じ winding を使用**)。
- MapNav の navmesh を heightfield + slope gate (0.60 rise/run) で構築:
  崖・渓谷壁は unpathable、橋 deck・整備された ramp は walkable。

### `game/scripts/navigation/map_nav.gd` 拡張
- `height_source` (ProductionTerrain) + **height overrides**:
  - `register_height_override(center,size,y,feather)` — 橋 deck / terrace pad
    の walkable 面。get_ground_height は override を terrain に優先 (max)。
  - `register_height_ramp(origin,dir,grade,run,width_neg,width_pos,feather)` —
    崖帯を切り崩す勾配 corridor (replace セマンティクス)。
- `get_collision_height()` — collision 専用。override 境界を feather
  (3m) してカーテン状の鋭角三角形を消す。**get_ground_height (sharp) と
  collision (feather) は override 内部で必ず一致させる (max-of-overrides
  ルールを共有)。ここを乖離させると unit が浮いて slide solver が
  暴走する (今回 72m の ejection 事故が発生)**。

### Map integration (`phase2d_strategic_match.gd`)
- 旧 flat green ground / prototype ground / MapNav analytic ground は
  削除 (ProductionTerrain に置換)。
- Phase 2.9 の重複構造を整理: **trench ×5 全撤去** (真の ravine がある
  ため)、kit cliff ×6 全撤去 (地形の cliff が存在)、road slab は主要
  進軍路のみ 8枚に削減。
- 配置 (Gemini design pad に snap):
  - Player HQ (-32,-32) y12 / Enemy HQ (34,36) y15.5
  - West Foundry (-22,4) / North Relay (0,-18) / Central Nexus (-8,0) /
    South Works (-2,20) / East Bastion (26,-8)
  - Heavy Bridge (18, 8.0, 0) — ravine (谷底 y0) を跨ぐ唯一の central
    crossing。deck override で walkable (y=8)。
  - Fortress Gate (38,20) on plateau y11.8+ — gate 開口を両軍が通行。
    壁の回転 collision box が enemy plateau 西出口 corridor を物理封鎖
    していた問題を解消 (南西壁は terrain cliff が天然の防壁のため撤去、
    柱は nav obstacle のみとし物理衝突を外して開口を確保)。
  - **Fortress approach ramp**: 地形 authored の東 abutment (y8) と
    fortress terrace (y13+) の間に >45° の段差がありユニットが登れない
    ことを 1m グリッド Dijkstra で特定。勾配 0.5 (約24°) の corridor
    override で cut。さらに gate forecourt の 15.3 spike / 12.0 dip を
    第二 corridor (13.8→12.4) で平滑化。

## Traversal 結果

- Infantry (navmesh): North / Central / South 3経路とも Player→Enemy 両
  方向に通行可 (nav 連結成分が全主要地点を1つに統合することを BFS で
  検証)。bridge deck → ramp → gate forecourt → enemy plateau まで到達。
- Walker (直進+slide): **bridge routing hint 追加** (`_route_target`:
  直線が渓谷帯と交差する時だけ橋端 waypoint に置換、全面 rewrite では
  ない)。legs collision bottom を 0.15m 持ち上げ deck の 0.05m lip を
  踏破。deck 横断 → east abutment → ramp まで到達確認。
- Enemy AI: gate → ramp → bridge → central → player plateau まで進軍し
  player HQ を破壊 (playtest enemy-win で検証)。
- RTSUnit にも wall slide 追加 (walker と同型) + **move_and_slide
  displacement guard**: teleport (test/spawn) の physics ghost による深い
  penetration recovery で body が任意距離に飛ばされる事故を防ぐ
  (横方向の変位が speed×delta×4 を超えたら水平成分を巻き戻す)。

## Full Game Loop

- Start → Capture → Economy → District → Production → Walker → Battle →
  Route Push → Bridge Crossing → Fortress Breakthrough → Enemy HQ →
  Victory: 成立 (phase27_playtest player-win sim 5:59 / 7:21 / 9:57 /
  14:52, 全都市制圧 + walker 生産)。
- Enemy Production → Expansion → Route traversal → Bridge → Player HQ →
  Defeat: 成立 (enemy-win sim 10:43 / 11:23 / 15:30, enemy walker 複数)。
- Restart: fresh state 復帰 (phase2d_test restart ×2 assert 済)。
- regression: 20 suite (cli_smoke, camera, phase1_5(_playtest), 2a/2b/2c,
  25a, 25b, 25b1, 25c, 25c1, 25d, 25d1, 26a, 26, 2d, 27_test,
  27_playtest 両方向, prototype, visual_slice, skirmish) 全 PASS。
- ERROR 0 / SCRIPT ERROR 0 (import + startup + match startup)。

## Performance (1080p, Iris Xe)

- Phase 2.9 baseline: min 39 / p50 42 / max 46
- Phase 2.10: **min 110 / p50 142 / max 145** (21 samples, ~4分実測、
  戦闘中を含む)。terrain 単一 mesh (39.2k tris, 圧縮 texture) + kit 削減
  で大幅改善。sustained 30fps+ を十分に満たす。

## Map Size 140m 評価 (実戦データ)

| 計測 | 値 |
|---|---|
| Player HQ → Central (32m直線) | 5.0s (infantry 6.0m/s) |
| Player HQ → North Relay (27m) | 4.8s |
| Player HQ → South Works (52m) | 9.3s |
| Player HQ → Enemy HQ (nav ~100m) | infantry 単体 ~17-25s (混雑で変動) |
| Walker HQ → Enemy (deck+ramp) | deck 横断 ~10s + ramp ( choke で変動) |
| 実戦 match 時間 | player-win 6-15分, enemy-win 11-16分 |

- North / Central / South は別戦線として読める (ridge / battlefield /
  lowland の標高差が明確)。
- 10 units 混成: 問題なく橋・ramp を通過。20 units: ramp choke で流れは
  遅くなるが到達する。60+ units: 単一の橋+ramp choke で渋滞が発生
  (現行 movement model の限界)。
- City 間隔 (25-35m, infantry 4-6s) は攻防のテンポとして適切。
- Fortress siege space (gate plateau ~25m 幅) は army が展開可能。
- 最大 zoom-out (dist 60+) で 140m 全体が見渡せ、小さすぎない。

**判断: 現行の 8-15分 match / 60-70 pop 規模では 140m 維持で成立する。**
拡張検討が必要になる条件: 100+ unit の大規模軍運用、4+ 同時戦線、
または choke を複数にしたい設計変更時。その場合は 180-200m 級を
Generator 側で検討する (今回は Generator 不変更のため 140m で確定)。

## Known Issues

- Infantry model は primitive のまま (scope 外)。
- Walker は直進+slide+橋 hint (navmesh 非使用、Phase 2.7 仕様維持)。
  大軍の choke 通過は infantry より遅い。
- Ramp corridor は terrain の cliff を gameplay cut で貫くため、通過中の
  unit が岩肌に浅く食い込んで見える箇所がある (RTS 距離では目立たない)。
- East Bastion pad は街の obstacle circle により nav 上は小さな pocket
  だが、capture radius 8m で周辺から占拠可能 (挙動確認済)。
- South route 東端は fortress plateau 崖で行き止まり (設計上の要塞性)。
- Titan / Airship は canonical match 未配置 (showcase のまま)。

## 次候補 (最大3)

1. Walker の正式 navmesh 化 (RTSUnit 統合 + separation 一本化)。
2. South route 東端の要塞側面に第二の攻城経路 (攻城兵器との組合せ)。
3. City 敷地 dressing (Map Kit props で各都市の個性強化)。
