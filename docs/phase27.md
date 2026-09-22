# Phase 2.7 — Playable Match Convergence

最終更新: 2026-09-23
目的: バラバラに存在していた機能 (City/Territory/Economy/District/
Production/Combat/Walker/Enemy AI/Victory/Defeat/Restart) を1つの
Playable Match へ収束させる。新規アセット制作・新システムは行わず、
既存の接続と安定化のみ。

## Canonical match

`res://scenes/maps/phase2d_strategic_match.tscn` を本線とする。
Prototype Battlefield は regression / asset showcase として保持
(本線にはしない)。

## Phase 2D / 2.6 の統合方法

- Walker 生産: Phase 2.6 の `VisualWalker` + `gf_walker.tres` を、
  prototype 専用の「Rキー即時生産」ではなく、Strategic Match の既存
  `ProductionQueue` (material+aether+supply+build time) へ正式接続。
  `spawn_walker()` を map に追加し、died/damaged/fired を MatchFX /
  pop返却 / selection cleanup へ配線。`_produce_ready` で
  `def.id == gf_walker` を分岐。
- HUD: 既存 ProdRow に `BtnWal` (Walker 150M/20A) + KEY_4 を追加。
  選択パネルは `VisualWalker` も unit としてカウント (mixed selection
  で表示が消えない)。大規模UI改修なし。
- Enemy AI: `EnemyStrategist.walker_def` を配線。`_pick_production` に
  walker 分岐 (1/6 cap、material+aether+supply チェック、都市保有
  ゲート)。`army()` に enemy walker を含め、plan 再命令も duck-type で
  walker へ届く。`_infantry_count` で walker を plan 閾値から除外し、
  重walker1-2体が「大軍」を偽装しないようにする。

## 実プレイで発見した問題と修正

1. **Walker が都市を capture できない**: RTSCity の capture は
   `rts_units` のみを数えていた → `visual_walkers` もカウント (walker
   単独でも占領・ contested になる)。
2. **Enemy AI が完全に生産停止していた**: `_pick_production` が
   can_afford (material) のみ見て aether コストを無視。aether 0 で
   marksman/heavy を優先選択 → `try_enqueue` が常に `no_aether` で
   失敗。`_can_pay()` で material+aether+supply を全ライン統一チェック。
3. **Walker が障害物に永久 stuck**: 直進ステアリングが city/HQ の縁に
   張り付く → `is_on_wall()` + wall normal から tangential slide を
   追加 (最小の obstacle avoidance、navmesh 全面改修なし)。
4. **2D unit が弱すぎて match が成立しない**: 2D tres は combat stat が
   UnitDefinition デフォルト (HP100/dmg10) のまま → Phase 1.5 実績値
   (HP200/dmg11 等) をコピー。build time も 12/18/24s へ揃えた。
5. **HQ が瞬殺でループが回らない**: HQ_HP 8000 → 14000 (siege が
   数分かかり、expand→economy→walker→push の loop が成立)。
6. **AI が walker を生産しない / しても spam**: walker 生産に
   force>=7 + 都市保有ゲート + 1/6 cap。army/plan 閾値は
   infantry-equivalent (`_infantry_count`) で評価。
7. **Enemy walker が plan 命令を受けない**: `_execute_plan` が
   `as RTSUnit` cast で walker を捨てていた → VisualWalker 分岐を追加。

## Balance anchors (最小、data-driven)

- `gf_walker.tres` は Phase 2.6 値を維持 (150M/20A, 18s, pop3,
  HP700, speed 3.6, dmg 34, range 17)。
- MAX_POP 40 → 60 (walker pop3 混成軍が cap に触えない範囲)。
- base_aether 0 → 0.1/s (aether unit が territory なしでも緩慢に
  研究可能、試合が枯渇で停まらない)。
- phase2d_test の pop/aether assert を新値に追従。

## Tests

- `phase27_test.gd` (新規): match load / WalkerDef+HUD+strategist配線 /
  walker payment (150M/20A) / supply予約 / queue / spawn / rally /
  move / combat kill / death (supply返却) / box+mixed selection /
  enemy walker production (no free spawn) / victory / restart。PASS。
- `phase27_playtest.gd` (新規): time_scale 3 の full-match driver。
  通常 gameplay 操作 (queue/attack-move/city capture/district) のみ、
  debug damage/wallet cheat/直接victory なし。
  - **player-win**: sim 5:09、walker×2 混成軍で enemy HQ 破壊 → VICTORY。
  - **enemy-win**: sim 9:20、AI が 5 都市支配 → walker×3 混成軍で
    player HQ 破壊 → DEFEAT。
- `phase27_capture.gd` (新規): screenshot driver (後述)。
- `phase2d_test.gd` 更新: pop 60 / base aether 0.1 に追従。全項目 PASS。
- Regression 22 suite 全 PASS。ERROR 0 / SCRIPT ERROR 0
  (import 時・起動時・1800 フレーム稼働・全テストで確認)。

## Performance (Iris Xe, 1080p)

- strategic match 90s idle: min 32 / p50 41 / max 43 (19 samples)
- full match 中も sustained 30fps 以上を維持。Phase 2.6 比で
  明確な回帰なし (walker は GLB 再利用、FX も既存)。

## Screenshots (`docs/screenshots/phase27/` 5枚)

p27_01_match_start (base+HUD) / p27_02_city_capture (West占領) /
p27_03_walker_production (walker spawn) / p27_04_army_battle
(混成軍戦闘) / p27_05_victory (VICTORY overlay)。
pixel検証: 全枚 1920×1008、空白/異常色なし、UI clipping なし、
faction (青/赤)・selection・walker・capture状態・Victory が判読可能。

## Known Issues

- Walker は直進ステアリング + obstacle slide (navmesh 非使用)。
  密集市街では歩兵ほど回り込まない。本格 pathing は RTSUnit 化時に。
- Enemy AI は plan threshold が infantry-equivalent。walker-only の
  敵残軍は plan が保守的になる (spam 防止とのトレードオフ)。
- 2D unit の combat stat は 1.5 値の流用。marksman/heavy の対 walker
  相性は未調整 (competitive balance は対象外)。
- Titan / Airship は showcase のまま (正式 gameplay 化していない)。
- Map Kit (bridge/fortress/cliff) は未配置 (次 Phase 以降)。
- Prototype Battlefield は Phase 2.6 状態のまま保持 (本線 match への
  波及なし)。

## 次候補 (最大3)

1. Walker RTSUnit 正式化 (専用 .tscn + NavigationAgent3D pathing +
   separation + MatchManager 統合の一本化)。
2. Map Production Kit 本格配置 (bridge/fortress/cliff/trench を使った
   正式マップ設計 + collision/navmesh 実装)。
3. HUD/UX 改善 (walker 生産の進行表示強化、minimap、army 編成 UI)。
