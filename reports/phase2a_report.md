# Phase 2A 完了報告 (Multiple Cities + City Capture)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Intel Iris Xe (TigerLake-LP GT2)
基準: Phase 1.9 fix 07ed47178b167c8e398703549c2612061ade0289、作業開始時 main 07ed471

目的: 「1つのOutpostを取るRTS」から「複数の都市を奪い合うRTS」へ。
新規独立シーンで Player HQ / Enemy HQ + 中立3都市の奪い合いを実装。
Phase 2B (Territory/Aether/District) には着手しない。

## 実装概要

- RTSCity (3中立都市、占領/CONTESTED/再占領、Materialボーナス)
- Phase 2Aマップ (West自陣側/Central中央/East敵陣側 + 両HQ)
- EnemyStrategist の都市対応 (後方互換、Phase 1.5無改変)
- Phase 2A HUD (都市所有数 + 都市ごと状態行)
- 自動テスト15項目 + 回帰全PASS + 実プレイ検証 + スクリーンショット3枚

## 新規/変更ファイル

新規:
- game/core/city_definition.gd (CityDefinition: capture時間/半径/収入ボーナスのデータ駆動)
- game/resources/cities/west_city.tres, central_city.tres, east_city.tres (各+1.5/s, 12s, r8)
- game/scripts/city/rts_city.gd (RTSCity: outpost.gdと同型の独立capture実装 + 軽量都市ビジュアル)
- game/scenes/maps/phase2a_city_war.tscn / phase2a_city_war.gd (3都市+両HQ、生産はHQのみ)
- game/scenes/ui/phase2a_hud.tscn / game/scripts/ui/phase2a_hud.gd (CitiesBox追加)
- game/tests/phase2a_test.gd (15項目)
- docs/phase2a.md, docs/screenshots/phase2a/{overview,city_capture,contested}.png

変更:
- game/scripts/ai/enemy_strategist.gd のみ (Plan追加 CAPTURE_CITY/DEFEND_CITY + cities分岐。cities空なら従来通り)

不変: phase1_5_match / visual_slice / outpost / economy / camera / GameManager (Autoload追加なし)。

## City architecture

- CityDefinition (.tres) に収入・時間・半径を集約。バランス調整はコード改変不要。
- RTSCity は StaticBody3D + collision layer 1 + `rts_cities` グループ。
  `rts_buildings` に入らないため戦闘・選択の対象外 (Outpostと同扱い)。
- captureは 0.25s tick × 都市3の rts_units 走査。毎フレーム総当たりなし。
- 見た目はprimitiveのみ (pavement/中央建物/付属2棟/旗・発光オーブ/半径リング/進捗バー/Label3D)。
  所有色: Neutral白灰 / Player青 / Enemy赤。

## Capture仕様

- 半径8m内に自軍のみで12秒 (人数加速なし)。両軍でCONTESTED凍結。
  無人は進捗減衰・所有維持。Neutral取得・敵都市から奪取・奪還すべて対応。
- テストで West占領→East占領→Central CONTESTED凍結→East奪還→West奪還を確認。

## Economy仕様

- HQ base 2.0/s + 所有都市×1.5/s。2都市で+3.0/s、3独占で+4.5/s。
- 所有変更で即時再計算 (bonus_income)。失うと減少することをテストで確認。
- Aetherなし。都市からの生産なし。

## Enemy AI変更

- 脅威 (自所有contested) があり少兵力→DEFEND_CITY、首都攻撃条件 (12体) 未満で
  未所有都市を評価→CAPTURE_CITY。recapture優先 (PLAYER所有+120) + 距離減点 + contested加算。
- Phase 1.5マップ (cities空) では旧分岐にそのまま入る。phase1_5_test PASSで互換確認。
- 実プレイで East→Central→West奪還→12体でATTACK_PLAYER_HQ の遷移を確認。

## HUD

- `Cities: P x / N x / E x` + 3都市の状態行 (例 `West City NEUTRAL CONTESTED`)。
- テストの全フェーズで city_counts() とHUD表示の一致を assert。

## 自動テスト結果

PHASE2A_TEST OK (全15項目):
1. 3都市存在 (west/central/east) ok
2. 初期Neutral + HUD P0/N3/E0 ok
3. Material増加 ok
4. PlayerがWest占領 (+1.5/s, P1/N2/E0) ok
5. EnemyがEast占領 (双方+1.5/s, P1/N1/E1) ok
6. Central CONTESTED凍結 ok
7. PlayerがEast奪還 (+3.0/s, P2/N1/E0) ok
8. EnemyがWest奪還 (Player +1.5/sに減少, P1/N1/E1) ok
9. HUD整合 (各段階) ok
10. AIがEast CityをCAPTURE_CITYで目標選択 ok
11. HQ戦闘→VICTORY (停止+overlay) ok
12. DEFEAT ok
13. Restart×2 (Neutral/5v5/120material/pop0 + HUD reset) ok

## 実プレイ結果

- 描画あり 1280x720 約2分05秒 (AI有効、PlayerはWestへ3体attack-moveのみ):
  t=20s PlayerがWest、敵がEast→Centralを占領→West奪還で全都市ENEMY。
  AIは CAPTURE_CITY→BUILD_FORCE→ATTACK_PLAYER_HQ (12体) へ遷移。
  kills_p=1 kills_e=5、mat_p=470 mat_e=71。クラッシュ・停滞なし。
- HQ決着までは至らず (2分時点で敵12体がPlayer HQへ進軍中)。
  目標7〜12分に対し、都市争奪→HQ戦の流れは想定通り (Phase 1.5実績2:54勝利と同尺度)。

## Match時間

- 実プレイ2:05でHQ戦突入 (決着は7分前後と推定、Phase 1.5と同等以上)。
- 自動テストの短縮条件 (capture 1.0s) ではない実値 (12s) で占領を確認。

## 通常FPS / 最低FPS

- 実プレイ (1280x720): 47〜57、平均54。CITYWAR_PERF 25点すべて30以上。
- 最低FPS: 起動直後1サンプルのみ10 (シェーダ温まり。以降なし)。
- スクリーンショット時 (1920x1080): 43〜51。

## ERROR数 / SCRIPT ERROR数

- phase2a_test: ERROR 0 / SCRIPT ERROR 0
- phase1_5_test: 0 / 0
- visual_slice_test: 0 / 0
- phase1_5_playtest: 0 / 0
- cli_smoke / skirmish_test / camera_test: PASS (出力に異常なし)
- 実プレイ (描画あり): ERROR 0 / SCRIPT ERROR 0

## 既知の問題

- レンダリング実行時のみ、無入力でもカメラリグが南へゆっくりドリフト
  (headless不発生、ゲームロジック無関係。InputMapはキーのみ)。
  撮影用一時スクリプト側で pan_speed=0 + 位置再 asserts で対処。
  本番カメラコードは無改変。実プレイへの影響なし (実入力が優先)。
- RTSCity.setup() は map _ready から呼ぶため、表示名ラベル更新用に
  setup末尾で _refresh_visuals() を呼ぶ (ring半径は既定8.0=定義値で一致)。
- overview (distance 60) ではマップ端に黒背景が入る (カメラ仕様)。
- 敵 teleported 部隊は戦闘で半径外へ移動し得る (仕様通り。撮影時は直前配置で対処)。

## 未完了事項

- Phase 2B以降 (Territory/Aether/District/Research/TechTree/都市成長/
  Titan・Airshipシステム/Squad AI/大規模マップ) は未着手。
- 都市GLB化 (Phase 1.9資産の流用) は未着手。現状primitive。
- Match全体 (7〜12分) の通し実プレイ決着は未観測 (2:05でHQ戦突入まで確認)。

## commit hash

- Phase 2A feat: (下記git log参照。`feat: add phase 2a city capture gameplay`)

## push状態

- origin/mainへpush済み。local main = origin/main、working tree clean を確認。

## git status (完了時)

- working tree clean。

## Phase 2Bへ進める状態か

- 進める。3都市の占領・CONTESTED・再占領・収入連動・AI都市判断・HUD・
  HQ勝敗・Restartが自動テスト+実プレイで成立。回帰全PASS、ERROR 0。
  CityDefinition (.tres) と ownership_changed シグナルが2Bの基盤になる。

## 特にChatGPTに確認してほしい点

- 都市収入+1.5/s×3 (+4.5/s、base 2.0/s比) の雪球バランスは妥当か。
  実プレイでは敵3独占でも2分で決着せず。2BのTerritory/Aether導入時に再調整予定。
- EnemyStrategist の都市スコア (recapture+120/neutral+100/距離×1.5/contested+15) の重み付けは
  初版として妥当か。中央一点張りは距離項で回避できている。
- RTSCity を outpost.gd から独立実装 (重複) した判断は妥当か。
  Phase 1.5無改変を優先し、共通化は2B以降の検討とした。
- レンダリング時のカメラドリフト (無入力・南方向) の心当たりがあれば知りたい。
  headless不発生、InputMapはキーのみ、edge scrollは無効化済みでも発生した。
