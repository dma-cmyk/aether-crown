# Phase 2B 設計 (Territory + Aether)

目的: 「都市を取るゲーム」から
「都市を取ることで領土が変化し、その領土から第二資源Aetherを得るゲーム」へ。
新規独立シーン `res://scenes/maps/phase2b_territory_war.tscn`。
Phase 1 / 1.5 / Visual Slice / 2A は無改変で残す。

作らないもの (Phase 2C+):
District / 都市建設・成長 / Research / Tech Tree / Aether消費 /
Titan・Airship生産 / Squad AI / 新文明・新ユニット / 本格ミニマップ /
procedural生成 / runtime Voronoi / 重いterrain shader。

## Territory architecture

- `game/core/territory_definition.gd` (TerritoryDefinition, Resource):
  id / display_name / linked_city_id / fixed_owner (-1=都市追従、0/1/2=固定) /
  aether_income_bonus / center・size (事前定義quad) / neighbor_ids。
- `game/resources/territories/*.tres` ×5 (下表)。
- `game/scripts/territory/territory_region.gd` (TerritoryRegion):
  静的ビジュアル (overlay quad + 境界4辺 + frontline発光4辺 + Aether結晶)。
  構築は1回のみ。所有・前線変更は色更新と表示切替だけ (毎フレーム処理なし、
  影OFF、unshaded、低alpha)。
- `game/scripts/territory/territory_controller.gd` (TerritoryController):
  シーン内通常ノード (Autoloadなし)。
  City ownership_changed → _recalc (所有→前線) → territories_changed →
  mapがAether収入適用。所有変化時のみ再計算。

## Region一覧

| id | 連動 | Aether/s | 初期所有 |
|---|---|---|---|
| player_base | 固定PLAYER | 0.0 | PLAYER |
| west | west_city | 0.35 | NEUTRAL |
| central | central_city | 0.80 | NEUTRAL |
| east | east_city | 0.35 | NEUTRAL |
| enemy_base | 固定ENEMY | 0.0 | ENEMY |

合計 +1.50/s。Centralが戦略的高価値。

## adjacency graph

player_base ↔ west ↔ central ↔ east ↔ enemy_base (一直線)。
neighbor_ids で明示。将来的に補給・経路・戦略AIから参照可能。

## ownership rules

- 都市領土は対応Cityの所有に追従。CONTESTED中は既存所有を維持。
- 占領完了の瞬間に切り替わる。領土内侵入だけでは変わらない。
- Base領土は固定 (HQ破壊が勝敗、領土全占領は勝利条件にしない)。

## frontline rules

- 隣接owner差のある境界が前線。SOFT (対Neutral) / HARD (P対E)。
- 各regionが自周回に発光strip表示 (SOFT 1.2 / HARD 2.5)。
- 所有変化時のみ再計算。frontline_pairs() が [id_a, id_b, hard] を返す。

## Aether economy

- RTSEconomy に aether / base_aether / bonus_aether + aether_per_sec() を追加。
  setup() 引数は既定値付きで Phase 1.5/2A 呼び出しは無改変 (Aetherは0のまま)。
- 収入は所有Territoryの合計。Neutralは誰にも入らない。
- 消費先は作らない (Phase 2CでDistrictと接続)。
- Material仕様は維持 (HQ 2.0/s + 都市×1.5/s)。

## HUD

- TopBarに `Aether: x.x (+x.xx/s)` を追加 (Materialと別資源明示)。
- TerritoriesBox: `Territories: P x / N x / E x` + 5領土の状態行。
- CitiesBoxは Phase 2A 継承。

## AI変更

- Plan維持 (CAPTURE_CITY/DEFEND_CITY/BUILD_FORCE/ATTACK_PLAYER_HQ)。
- `_pick_city_target` に `city_aether × 20` の軽加点のみ
  (Central 0.8→+16)。辞書空の旧マップでは挙動不変。

## performance

- 追加描画は約35 MeshInstance (大半は小物・非表示strip)。
  透明overlay 5枚のみ。毎フレーム更新なし。
- 実プレイ (1280x720): 平均42、通常38〜54。2A比の低下は同日A/Bで
  2A=44・2B=42と環境差範囲内 (前回54は別セッション値)。
  戦闘中の単発dipあり (25前後、即回復、2Aも同特性)。継続30割れなし。

## tests

- `tests/phase2b_test.gd`: 21項目 (5領土/固定base/連動切替×3方向/
  CONTESTED維持/Neutral 0/Aether率×3/喪失減/Material維持/HUD×3/
  前線生成・更新/Victory/Defeat/Restart×2 incl. Aether 0・領土・前線reset) PASS。
- 回帰: cli_smoke / skirmish / camera / phase1_5_test /
  phase1_5_playtest / visual_slice_test / phase2a_test すべて PASS。

## known issues

- カメラドリフト (Phase 2A報告の件) は本題外のため未対応・コード無改変。
  撮影用一時スクリプト側で固定。今 Phase でも同条件で発生したかは
  未検証 (free-play中はカメラ操作なし、FPSログのみ取得)。
- 1080p distance 60 の overview 端に黒背景 (カメラ仕様)。
- 起動直後の単発FPS dip (シェーダ温まり、2Aと同傾向)。

## Phase 2Cへの申し送り

- Aether消費先は未実装。aether stockpile は蓄積のみ。
- frontline_pairs()・neighbor_ids・ownership_changed をDistrict/AI基盤に流用可。
- Territory数値は .tres 集約済み。都市GLB化は未着手。
- 中央価値は現状 AI加点+16のみ。2Cで本格評価へ。
