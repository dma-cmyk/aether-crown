# Phase 2.8 — Canonical Match Visual Convergence

最終更新: 2026-09-23
目的: Phase 2.7 で完成したゲームループ (Start→Expand→Produce→Fight→
Win/Lose→Restart) を100%維持したまま、canonical match
(`phase2d_strategic_match`) の見た目を Prototype/Blockout から
Production Asset 中心へ収束させる。新規モデリング・新 gameplay は
一切行わず、main に存在する既存 Asset の再利用のみ。

## 使用した既存 Production Assets

- `gearforge_hq_command.glb` (HQ Command Core, Phase 2.6A)
- `gearforge_factory.glb` (West Foundry city)
- `gearforge_aether_well.glb` (North Relay city + 各HQの Factory 表示)
- `gearforge_boiler_works.glb` (South Works city)
- `gearforge_barracks.glb` (East Bastion city)
- `gearforge_hq_command.glb` (Central Nexus city)
- 既存 `_banner` (pole + faction flag、prototype_battlefield から流用)
- 既存 terrain / road visual / 都市 pavement / beacon は不変

## HQ 改善内容

- `HqVisual.build()` (Godot primitive blockout: base pad + prism roof +
  手製 chimney/gear) を廃止し、`gearforge_hq_command.glb` (15.2×13.2m,
  13m, 1,908 tris) へ置換。
- Gameplay 不変: RTSBuilding node / HP / collision / targeting /
  MatchManager / `_spawn_hq` の signal 配線はそのまま。collision は
  15×13×13 box に更新し、navmesh obstacle rect も 8×7 → 15×13 に追従。
- faction 区別: 両 HQ に `_banner` ×2 (青=player / 赤=enemy、
  emissive flag)。既存手段のみ、新 tint shader なし。
- Victory / Defeat は変更なし (phase2d_test の HQ 戦系 assert 全 PASS)。

## City 改善内容

- 5都市の primitive blockout (stone box + brass roof + tower) を
  production building GLB へ置換 (city_id マッピング、未知 id は
  旧 primitive へ fallback):
  West Foundry=Factory (0.82) / North Relay=Aether Well (0.85) /
  Central Nexus=HQ Command (0.72) / South Works=Boiler Works (0.85) /
  East Bastion=Barracks (0.9)。
- 都市 pavement + ownership beacon (pole/flag/glow orb) + capture bar は
  維持。capture 判定・collision (cylinder r1)・capture_radius は
  一切不変。ownership_changed も不変。

## Factory / Walker Production Readability

- 各 HQ の隣に `gearforge_aether_well.glb` を1棟配置 (player は右、
  enemy は左、±12° yaw)。Walker 生産の目印として「工場」を画面から
  読み取れるようにするための配置で、Production logic (queue/spawn/
  rally) は一切変更していない。

## Terrain / Roads

- 既存の `_build_roads` (HQ→West→Central→East→HQ + North/South spur)
  と terrain は不変。map topology は触っていない。

## Capture / Territory 表示改善

- Capture ring: 太さを薄く (inner = radius - 0.10) し、
  **owner 色連動 + alpha 0.34** に変更 (旧: 固定 gray alpha 0.5)。
  占領状態が ring 色で読めるが、巨大な白円盤には見えない。
- City label: font 48 → 30、alpha 0.92。複数都市 label が画面上で
  重なっても圧迫しないサイズに。
- Capture 判定・progress bar ロジックは変更なし。

## HUD 整理

- `DebugBox` (FPS / Units / AI plan / Overview / Mode) を **F3 トグル
  で非表示 default** に変更。通常画面は TopBar (Material/Aether/Pop/
  Time) + CitiesBox + TerritoryBox + DistrictBox + SelPanel + Toast の
  gameplay 情報のみ。
- OverviewLabel は gameplay 情報 (frontline read) なので、debug box
  が隠れていても `_refresh_debug()` は継続 (表示のみ F3 依存)。
  phase2d_test の overview assert は PASS を維持。
- 新 HUD framework なし、機能削除なし。

## Gameplay Regression

- phase2d_test / phase27_test / phase27_playtest (player-win sim 5:55)
  / phase26_test / prototype_battlefield_test: 全 PASS。
- Regression 21 suite (cli_smoke, camera, phase1_5, 1_5_playtest,
  2a/2b/2c, 25a, 25b, 25b1, 25c, 25c1, 25d, 25d1, 26a, visual_slice,
  skirmish): 全 PASS。phase1_5_playtest は初回乱数変動で NG=1 の
  ことがあるが再実行で OK (既知の既存揺らぎ)。
- ERROR 0 / SCRIPT ERROR 0 (import 時・起動時・全テスト)。

## Performance (Iris Xe, 1080p)

- strategic match 90s idle: **min 43 / p50 46 / max 54** (19 samples)。
- Phase 2.7 baseline (min 32 / p50 41) から悪化なし・むしろ改善
  (production GLB は primitive 群より draw call が少なく、debug box
  非表示で UI 負荷も低下)。sustained 30fps 以上を維持。

## Screenshots (`docs/screenshots/phase28/` 7枚)

p28_01_player_base / p28_02_strategic_overview / p28_03_city_capture /
p28_04_walker_production / p28_05_army_battle / p28_06_victory /
p28_07_enemy_base。

## Screenshot Visual Review

pixel 検証済 (全 1920×1008、unique colors 4.9k–12.2k、空白なし):
- 01/07: production HQ + banner + factory plant が読める。青 (player)
  と赤 (enemy) の banner 色が明確に分離 (blue_px / red_px とも検出)。
- 02: 5都市が production building として俯瞰で認識可能、HQ 位置と
  city ルートが読める。
- 03: 占領中 city (Factory) + 自軍歩兵 + capture 表示が自然。
- 04: walker + factory plant が同一画角にあり、production の意味が
  見た目で分かる。walker が周囲から浮かない (production 建物と
  同じ言語)。
- 05: 混成軍 (歩兵+walker) と enemy HQ への突撃が読める。
- 06: VICTORY overlay + 画面全体が見える。
- HUD は gameplay 情報のみで画面を圧迫しない。world label 重なり・
  capture ring 過剰表示・camera obstruction は確認されなかった。

## Known Issues

- Infantry は依然 primitive (新規 model は今回の scope 外)。
- Titan / Airship は canonical match へ未配置 (showcase のまま)。
- Map Kit 01 (bridge/fortress/cliff/trench) は未配置 (別 Phase の
  map redesign で扱う)。
- City visual は production building の単体配置であり、都市ごとの
  敷地内装飾 (yard / pipes / props) は未追加 (visual polish は後続)。
- Walker は直進ステアリングのまま (navmesh 非使用、Phase 2.7 仕様)。
- phase1_5_playtest は既存の乱数揺らぎで稀に NG になる (本 Phase 無関係)。

## 次候補 (最大3)

1. City 敷地 dressing (既存 props/pipes/yard で各都市の個性を強化)。
2. Map Production Kit 本格配置 (bridge/fortress/cliff を使った正式
   マップ設計 + collision/navmesh 実装)。
3. Infantry visual 更新 (既存 Gearforge 歩兵 asset への置換検討)。
