# Phase 2A 設計 (Multiple Cities + City Capture)

目的: 「1つのOutpostを取るRTS」から「複数の都市を奪い合うRTS」へ。
新規独立シーン `res://scenes/maps/phase2a_city_war.tscn` で
Player HQ / Enemy HQ + 中立3都市 (West / Central / East) を奪い合う。
Phase 1.5 (`phase1_5_match`) と Visual Slice は無改変で残す。

作るもの (Phase 2A のみ):
複数都市 / 都市占領 / 所有 (NEUTRAL/PLAYER/ENEMY) / CONTESTED /
再占領 / 都市Materialボーナス / 敵AIの都市判断 / 都市状態HUD。

作らないもの (Phase 2B+):
Territory / 領土線 / Aether / District / Research / Tech Tree /
都市成長 / 新文明 / Titan・Airshipゲームシステム / Squad AI / 大規模本格マップ。

## City アーキテクチャ

- `game/core/city_definition.gd` (CityDefinition, Resource):
  id / display_name / capture_time_sec (12.0) / capture_radius (8.0) /
  income_bonus (1.5 Material/s)。数値はデータ駆動。
- `game/resources/cities/{west,central,east}_city.tres`: 3都市定義。
- `game/scripts/city/rts_city.gd` (RTSCity, StaticBody3D):
  `outpost.gd` と同じ小規模captureステートマシン
  (owner/challenger/progress/contested, 0.25s tick) を**独立実装**。
  Phase 1.5 を壊さないため outpost.gd のリファクタリングはしない。
  `rts_buildings` に入らない + collision layer 1 のため、
  戦闘ターゲット・選択の対象外 (Outpostと同扱い)。
- 見た目 (軽量primitiveのみ、GLBなし):
  pavement + 中央建物 (body/roof/tower, Gearforge真鍮・石材色) +
  付属2棟 + ポール・旗・発光オーブ (所有色) + capture半径リング +
  進捗バー (billboard) + 状態Label3D (都市名・所有・進捗/CONTESTED)。
  Neutral=白灰 / Player=青 / Enemy=赤。

## Capture ルール

- 半径8m内に自軍のみ: 12秒で占領 (人数加速なし)。
- 両軍: CONTESTED で進行凍結。
- 無人: 進捗は減衰、所有は維持。
- Neutral取得・敵都市からの奪取・奪い返し (recapture) 対応。

## Economy

- HQ base income 2.0/s (既存維持) + 所有都市 × 1.5/s。
- 3都市独占で +4.5/s (baseの2倍以上、明確な優位だが即死級ではない)。
- Aetherなし。生産はHQのみ (都市から生産しない)。

## Map

- Player HQ (-30,-30) / Enemy HQ (30,30)。
- West (-20,4) 自陣側 / Central (0,0) 等距離 / East (20,-4) 敵陣側。
- 道路は HQ→West→Central→East→HQ を結ぶ。複数ルート選択可。
- 初期軍は Phase 1.5 と同じ 5v5 (infantry×4 + marksman)。
- 勝利条件は HQ破壊のみ (都市全占領は条件にしない)。

## Enemy AI (EnemyStrategist 拡張、後方互換)

- Plan に CAPTURE_CITY / DEFEND_CITY を追加 (既存値は renumber なし)。
- `cities` が空 (Phase 1.5) なら従来ロジック、そのまま動作。
- 都市選択: 自分の contested 都市は守る (少兵力ならDEFEND)。
  未所有都市は recapture(PLAYER所有) > neutral を優先し距離で減点。
  敵は東から、西は奪い返し対象になるため中央一点張りにならない。
- 12体以上で Player HQ 攻撃 (既存 ATTACK_ARMY 維持)。

## HUD

- `phase2a_hud.tscn` + `phase2a_hud.gd` (match_hud の複製改変、1.5無改変)。
- TopBar (Material/Income/Pop/Time)、選択・生産パネル・終了画面は継承。
- CitiesBox: `Cities: P x / N x / E x` + 都市ごとの状態行
  (例 `West City PLAYER`、`Central City NEUTRAL CONTESTED`)。

## Performance

- Capture判定は 0.25s tick × 都市3の `rts_units` 走査 (Outpostと同オーダー)。
  毎フレーム総当たりなし。都市装飾はprimitiveのみ。
- 目標: Intel Iris Xe で戦闘中30FPSを継続して割らない。

## Test results

- `tests/phase2a_test.gd`: 15項目 (3都市存在/初期Neutral/Player占領/
  Enemy占領/CONTESTED凍結/両方向recapture/収入増減/HUD整合/
  AI都市目標/HQ戦闘/Victory/Defeat/Restart×2) PASS。
- 回帰: cli_smoke / skirmish / camera / phase1_5_test /
  phase1_5_playtest / visual_slice_test すべて PASS。
- 実プレイ (描画あり 1280x720, 約2分):
  PlayerがWest、敵がEast→Central→Westを占領し、
  AIが CAPTURE_CITY→BUILD_FORCE→ATTACK_PLAYER_HQ へ遷移。
  FPS 47〜57 (平均54)、ERROR 0 / SCRIPT ERROR 0。

## Known issues

- レンダリング実行時、無入力でもカメラリグが南へゆっくりドリフトする
  環境依存現象を確認 (headlessでは発生せず、ゲームロジック無関係)。
  スクリーンショット撮影時は一時スクリプト側でカメラを固定して対処。
  本番カメラコードは無改変。
- 1080p distance 60 の overview ではマップ端に黒背景が入る
  (カメラ仕様、ゲーム不具合ではない)。
- FPSは起動直後の1サンプルのみ10を記録 (シェーダ温まり)。
  継続値は47〜57で30割れなし。

## Phase 2Bへの申し送り

- 都市ボーナス・capture時間・半径は CityDefinition (.tres) に集約済み。
  バランス調整は tres のみで可能。
- RTSCity は Territory/District の基盤に使える
  (city_id / ownership_changed シグナルを流用)。
- EnemyStrategist の都市スコア式は距離一次式のみ。
  Squad AI 導入時に置き換え前提。
- 都市GLB化 (Phase 1.9 資産流用) は未着手。3都市分のdraw callに注意。
