# Phase 2.6 — Walker Gameplay Integration (Playable Prototype Slice)

最終更新: 2026-09-23
目的: Phase 2.5D.1 で統合した Ironstride production walker を、
prototype battlefield 上で「遊べる状態」にする。新規モデリングは行わず、
既存アセット + 既存システム (RTSUnit/OrderManager/ProductionQueue/
VisualFX) の統合・安定化に限定。

## Walker gameplay統合

- `VisualWalker` に実戦闘を追加 (2.5D.1 の「take_damage不在」を解消):
  - HP/damage API: `take_damage` / `is_alive` / `died` / `damaged`、
    死亡時は explosion FX + 傾倒沈下 tween (VisualTitan pattern)。
  - order API: `order_move` / `order_attack` / `order_attack_move`
    (RTSUnitと同名。OrderManagerがduck-typeでそのまま投げられる)。
  - 移動: 直進ステアリング + move_and_slide (navmesh非依存)。
    stuck 2秒 fallback はRTSUnitと同規則。
  - 戦闘: 0.25s staggered scan → sight_range内の最近敵を auto-engage、
    range内でmuzzle flash + tracer FX + attack_intervalクールダウン。
  - `rts_buildings` グループ参加 (VisualTitanと同じ手法): 歩兵の
    auto-scanがwalkerを敵として拾う。`rts_units` には入れない
    (box-select cast前提のコードを守るため)。
- 数値は `game/resources/units/gf_walker.tres` (新規 UnitDefinition):
  HP 700 / speed 3.6 / damage 34 / range 17 / interval 2.2s / sight 26 /
  cost 150M+20A / build 18s / supply 3。スクリプト直書き値なし。
- `unit.gd`: `take_damage`/`_die` の attacker 型を `RTSUnit` → `Node`
  に緩和。bloodied/kill credit は `attacker is RTSUnit` ガード付きで
  従来通り。既存caller全て後方互換。
- `order_manager.gd`: `as RTSUnit` cast 3箇所を `_orderable()`
  (has_method + is_alive) によるduck-type判定に置換。
- `selection_manager.gd`: box-select が `rts_units` + `visual_walkers`
  を走査 (Titan/Airshipは従来通りclick-only)。click-select /
  force-attack は walker の take_damage 追加で自動的に有効化。

## 生産フロー (prototype sandbox)

- 青: Factory選択不要、`R`キー (新InputMap action `produce_walker`) で
  `ProductionQueue.try_enqueue(gf_walker)`。共有 `RTSEconomy` (400M+6M/s,
  60A) を使用。prototype独自ルールは新設していない。
- 完成後は Factory南レーンの gate (-64, 0, 17.5) に出現し、
  rally (-46, 0, 15) へ自動 `order_move`。gate/rally は全建物
  footprintを避けたレーン上 (直進ステアリングで壁抜けしない)。
- 赤: 28秒間隔timerが `visual_walkers` の赤生存数を数え、cap 4未満なら
  赤queueへenqueue (経由は同一のProductionQueue)。完成walkerは
  青midfield (-13, 0, 2) へ `order_attack_move`。
- 生産walkerは `$UnitsRoot` 配下 (Midfieldの手配置5体構成は
  prototype_battlefield_test の assert を守るため不変)。

## 戦場スライス

- `prototype_battlefield.tscn` に SelectionManager / OrderManager /
  SelectionBox (HUD) を追加。click/box選択とRMB orderが実際に効く。
- 地面に world-layer (1) の `GroundBody` を追加: `_pick_ground` raycast
  が着地し move/attack-move が発行可能に。
- `PrototypeNav` (新規、NavigationRegion3D): MapNavと違い地面
  visual/heightfieldを持たない平地版。建物9 footprintを obstacle
  としてnavmeshから切除 (3432 quads)。`clamp_inside`/`is_blocked`/
  `get_ground_height` を提供し OrderManager slot clamp も有効。
- 歩兵の `PROCESS_MODE_DISABLED` を解除: 青赤前線が sight_range で
  自動交戦し、walker混成の skirmish が成立する。
- Airship (bombard off) / Titan (装飾GLB) / 建物配置は不変。

## カメラ

- 問題: ズームアウト時に南下すると map_limit + (d-28)*0.75 で頭打ち
  になり、画面中心がマップ南端から最大36m手前で止まっていた
  (必要量は 0.44d〜1.0d なのに対し供給が 0.75(d-28))。
- 修正: `south_extra := distance` (camera_controller.gd)。画面中心が
  ちょうど map_limit まで rig を南下可能。北・x境界・pan速度は不変。
- camera_test / camera_probe は south clamp を assert していないため
  影響なし (実測PASS)。

## Tests

- `phase26_test.gd` (新規): 実prototype sceneで
  managers存在 / 地面collision / 歩兵解凍 / walker定義値 /
  camera south clamp (zoom60で limit+40〜+61) /
  try_produce_walker→queue進行→強制完成→gate出現→rally接近 (d≤7) /
  OrderManager経由 move (移動≥4m) / force-attack (敵HP減少 700→632) /
  box-selectがwalkerを拾う / 赤wave自動enqueue。全PASS。
- `phase25d1_test.gd` 更新: 「take_damage不在」assert を反転し
  take_damage/order API/def HPの存在を確認。LOD/anchor/collision
  系assertは温存。PASS。
- `prototype_battlefield_test.gd` 無改修: PASS (Midfield 5体維持)。
- 回帰: cli_smoke / camera_test / phase1_5 / phase2a-d / phase25a /
  25b / 25b1 / 25c / 25c1 / 25d / 25d1 / 26a / prototype / visual_slice /
  skirmish / phase1_5_playtest。全PASS。ERROR 0 / SCRIPT ERROR 0
  (1800フレーム稼働確認済み)。

## Performance (Iris Xe)

- prototype 1080p: min 22-31 / avg 31-36 (3run。戦闘乱数で変動)
- prototype 720p: min 12-25 / avg 28-34 (3run)
- 2.5D.1時点の 35/35 と比較して avg はほぼ同等。min の瞬間低下は
  前線歩兵の開戦バースト + 計測環境の変動 (720p>1080pの逆転が
  出ることから fill-rate 以外が支配的)。sustained avg は 28+ を維持。
- walker/FX/queue増加に対し draw call 構造は不変 (GLB再利用)。

## Screenshots (`docs/screenshots/phase26/` 6枚)

production_spawn (gate出現) / rally_move (rally移動+基地) /
selection_mixed (walker+歩兵の混成選択ring) / walker_combat
(前線walker交戦) / camera_south (最南端の到達確認) /
battle_overview (全体skirmish)。
`--capture-26` で再撮影可能。既存 `--capture-proto` /
`--capture-proto-polish` セットは不変。

## Known issues

- Walker の移動は直進ステアリング (navmesh非使用)。建物には
  collisionで滑るが、密集市街では歩兵と違い回り込まない。
  本格pathingは RTSUnit化 (walker専用scene + NavigationAgent) 時に。
- Walker は separation を持たない (歩兵は rts_units 基準の分離力を
  持つがwalkerは対象外)。密集spawn時はcollision押し出しのみ。
- 赤AIは wave 生産 + attack_move のみ (strategist非搭載)。
  青 base への本格攻勢・奪取・勝敗は MatchManager 統合時に。
- Prototype経済は sandbox (収支は共有RTSEconomyだが勝敗・supply運用なし)。
- benchmarkの fps_min は開戦バーストで瞬間的に 30 を割ることがある。
- Airship は従来通り攻撃不可 (bombard off)。

## 次候補 (最大3)

1. Walker の RTSUnit 正式化 (専用 .tscn + NavigationAgent3D pathing +
   separation + MatchManager 勝敗ライン統合)。
2. Match系mapへの walker 生産統合 (HUDボタン + supply運用 +
   EnemyStrategist への walker 編成)。
3. Walker walk/traverse/recoil animation (2.5D pivot構造を駆動)。
