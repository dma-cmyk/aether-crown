# Phase 2B 完了報告 (Territory + Aether)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Intel Iris Xe (TigerLake-LP GT2)
基準: Phase 2A feat 4ddad7e、作業開始時 main e32aa52 (chore後)

目的: 都市所有に連動する5領土 + 第二資源Aether (取得・管理・表示基盤のみ)。
Phase 2C (District) には着手しない。

## 実装概要

- Territory Region ×5 (所有連動・色表示・境界・前線・Aether結晶マーカー)
- Territory ownership visualization + Frontline (SOFT/HARD)
- 第二資源 Aether (+1.50/s 満額、Central 0.80/s 戦略価値)
- Material + Aether HUD、Territory HUD
- 自動テスト21項目 + 回帰全PASS + 実プレイ検証 + スクリーンショット4枚

## 新規/変更ファイル

新規:
- game/core/territory_definition.gd (fixed_owner/linked_city/aether/quad/neighbors のデータ駆動)
- game/resources/territories/{player_base,west,central,east,enemy_base}.tres
- game/scripts/territory/territory_region.gd (静的軽量ビジュアル、所有・前線は色/表示切替のみ)
- game/scripts/territory/territory_controller.gd (city連動・前線再計算・Aether集計、Autoloadなし)
- game/scenes/maps/phase2b_territory_war.tscn / phase2b_territory_war.gd
- game/scenes/ui/phase2b_hud.tscn / game/scripts/ui/phase2b_hud.gd (Aether行+TerritoriesBox)
- game/tests/phase2b_test.gd (21項目)
- docs/phase2b.md, docs/screenshots/phase2b/{overview,territory_shift,frontline,aether_control}.png

変更 (2件のみ):
- game/scripts/economy/rts_economy.gd (aether/base_aether/bonus_aether/aether_per_sec追加、setup引数は既定値付きで旧呼び出し無改変)
- game/scripts/ai/enemy_strategist.gd (city_aether辞書 + スコア加点×20のみ。旧マップは空辞書で挙動不変)

不変: phase1_5_match / phase2a_city_war / visual_slice / outpost / rts_city / camera / GameManager。

## Territory architecture

- TerritoryDefinition (.tres) に所有・Aether・形状・隣接を集約。
- TerritoryRegion: overlay (alpha 0.09, unshaded) + 境界4辺 + 前線発光4辺 (表示切替) + Aether結晶 (中央3・他1)。
  影OFF、毎フレーム更新なし、z-fight回避の層別高さ。
- TerritoryController: City ownership_changed → _recalc → territories_changed → mapがbonus_aether適用。
  変更検出は署名比較 (無駄なemitなし)。

## Territory一覧

- player_base: 固定PLAYER, 0.0/s
- west: west_city連動, +0.35/s
- central: central_city連動, +0.80/s (戦略 region、結晶3・明るめ)
- east: east_city連動, +0.35/s
- enemy_base: 固定ENEMY, 0.0/s

## adjacency

player_base ↔ west ↔ central ↔ east ↔ enemy_base。neighbor_ids明示。

## ownership仕様

- 都市占領完了で即時切替。CONTESTED中は維持。領土内侵入では不変。
- Base固定。領土・Aether量は勝利条件にしない (HQ破壊のみ)。

## frontline仕様

- 隣接owner差で生成。SOFT (対Neutral, 発光1.2) / HARD (P対E, 発光2.5)。
- 初期: player_base|west + east|enemy_base の2 SOFT。
- 例: Central(P)-East(E) で HARD を確認 (テスト+スクリーンショット)。

## Aether仕様

- 初期0。所有Territory合計/sで蓄積。消費先なし (2Cで接続)。
- Neutralは誰にも入らない。喪失で減少 (West奪還でPlayer 1.15→0.80を確認)。

## Material仕様

- 維持 (HQ 2.0/s + 都市×1.5/s)。テストで全段階 assert。

## AI変更

- Plan・閾値維持。都市スコアへ linked Aether×20 のみ加算。
- 実プレイで East→Central→West奪還→ATTACK_PLAYER_HQ の遷移を確認。
- 自動テストで Central を目標選択 (plan=CAPTURE_CITY) を確認。

## HUD

- `Aether: x.x (+x.xx/s)` + `Territories: P x / N x / E x` + 5領土行。
- CitiesBox継承。全段階で counts と表示一致を assert。

## automated tests

PHASE2B_TEST OK (全21項目):
初期5領土・固定base・初期前線2SOFT・Aether 0 / HUD初期 /
West占領 (領土P・Material+1.5・Aether+0.35・前線更新・HUD) /
Central占領 (Aether 1.15・備蓄増加・中央高価値) /
East敵占領 (敵Aether+0.35・HARD前線) /
CONTESTED維持 (所有・収入不変) / West敵奪還 (P 0.8・E 0.7・HUD) /
AI都市目標 / VICTORY / DEFEAT / Restart×2 (Aether 0・領土・前線・HUD reset)。

## regression tests

- cli_smoke / skirmish_test / camera_test PASS
- phase1_5_test OK、phase1_5_playtest OK (5:47勝利)
- visual_slice_test OK、phase2a_test OK

## playtest

- 描画あり 1280x720 約2分45秒 (AI有効、PlayerはWestへ3体のみ):
  West(P)→East(E)→Central(E)→West(E) の TERRITORY_SHIFT をログ確認。
  敵Aether 1.5/sで161蓄積、Playerは全喪失後25.6で凍結 (収入0の正当動作)。
  AIは CAPTURE_CITY→BUILD_FORCE→ATTACK_PLAYER_HQ (15体) へ。
  最終 frontlines=1 (player_base|west のHARD)。クラッシュ・停滞なし。

## FPS

- 実プレイ: 平均42、通常38〜54。
- 同日A/B: 2Aマップ=44、2Bマップ=42 (環境差範囲内。前回2Aの54は別セッション値)。
- 単発dip: 25前後 (戦闘時、即回復。2Aも同特性)。継続30割れなし。
- 1080p撮影時: 43〜60。
- 結論: Territory overlayによる継続5FPS以上の低下なし。

## ERROR

- phase2b_test / phase2a_test / phase1_5_test / visual_slice_test: 0
- SCRIPT ERROR: 同上すべて 0 (実プレイ含む)
- 開発中1件: TerritoryRegion.set_owner が Node.set_owner と衝突
  → set_region_owner に改名して解消 (本番影響なし)。

## SCRIPT ERROR

- 0 (上記の開発中エラーを除き、最終コードでは発生なし)。

## known issues

- カメラドリフト件は本題外のため未対応 (コード無改変、撮影側で固定)。
- overview端の黒背景 (カメラ仕様)。起動直後dip (シェーダ温まり)。
- 敵部隊は戦闘で半径外へ移動し得る (仕様通り、撮影時は直前配置)。

## 未完了事項

- Aether消費先・District・Research・TechTree・Titan/Airship生産・Squad AI・
  新文明・新ユニット・本格ミニマップ・procedural/Voronoi・都市GLB化は未着手。
- 通し決着 (7〜12分) の実プレイ観測は未実施 (2:45でHQ戦突入まで確認)。

## commit hash

- Phase 2B feat: (下記 `feat: add territory and aether systems` を参照)

## push状態

- origin/mainへpush済み。local main = origin/main、working tree clean を確認。

## git status (完了時)

- working tree clean。

## Phase 2Cへ進める状態か

- 進める。5領土・所有連動・前線・Aether取得/表示・AI加点・HUD・HQ勝敗・
  Restartが自動テスト+実プレイで成立。回帰全PASS、ERROR 0。
  neighbor_ids・frontline_pairs()・ownership_changed・Aether備蓄が2C基盤。

## ChatGPTに確認してほしい点

- Aether配分 (0.35/0.80/0.35、合計1.50/s) と AI加点 (×20、Central+16) の
  初版バランスは妥当か。2CのDistrict消費設計への示唆があれば知りたい。
- Territory overlay (alpha 0.09 + 所有色境界) の視認性とRTS可読性の両立は
  スクリーンショット4枚で確認済み。濃度・境界太さの推奨があれば知りたい。
- RTSCity同様にTerritoryを独立実装 (outpost系と非共通化) した判断は妥当か。
- 実プレイで敵が3都市独占しても2:45で決着せず (Aether未消費のため当然)。
  2Cで消費先ができた際の雪球化の抑止案があれば知りたい。
