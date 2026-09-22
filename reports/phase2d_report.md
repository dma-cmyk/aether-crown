# Phase 2D 完了報告 (Strategic Match)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Intel Iris Xe (TigerLake-LP GT2)
基準: Phase 2C feat bc0c98e、作業開始時 main bc0c98e

目的: 全システムを8〜12分マッチに統合。新巨大システムなし。
5都市・7領土・Aether消費生産・敵予算配分・HUD整理・バランス実測。

## 実装概要

- 2Dマップ (5都市3ルート、7領土、HQ 8000)
- 2D専用Unit tres (Aether 0/8/15、生産時間延長) + Queue両資源支払い
- 2D都市収入0.75 (旧マップ不変) + 敵turtle・貯蓄則 + district評価
- HUD clipping修正 + Strategic Overview行 + border polish
- 自動テスト24項目 + 回帰全PASS + Full Match A/B決着 + 撮影6枚

## 新規/変更ファイル

新規:
- game/resources/units/2d_{infantry,marksman,heavy_guard}.tres
- game/resources/cities/{west_foundry,north_relay,central_nexus,south_works,east_bastion}.tres
- game/resources/territories/2d_{player_base,west,north,central,south,east,enemy_base}.tres
- game/scenes/maps/phase2d_strategic_match.tscn / .gd (+.uid)
- game/scenes/ui/phase2d_hud.tscn / game/scripts/ui/phase2d_hud.gd (+.uid)
- game/tests/phase2d_test.gd (+.uid)
- docs/phase2d.md, docs/screenshots/phase2d/×6

変更 (3件):
- game/scripts/production/production_queue.gd (Aether check・支払い・no_aether。cost 0定義は不変)
- game/scripts/ai/enemy_strategist.gd (city_districts加点・is_city_threatened・turtle・district_saving説明。旧マップ不変)
- game/scripts/territory/territory_region.gd (border 0.14・×0.65暗化・SOFT 1.5・HARD 3.0。ロジック不変)

不変: 全既存Scene・outpost・rts_city・economy・district controller・camera・GameManager。

## Map構造 / City数 / Territory数 / adjacency

- 5都市 (West/North/Central/South/East) + 両HQ。北・中央・南ルート。
- 7領土。隣接: base↔west↔{north,central,south}、north↔central↔{south,east}、east↔base。

## Resource design / Aether用途 / Unit Aether cost

- Aether: 0.25/0.35/0.70/0.35/0.25 (計1.90/s)。N+S=Central。
- 用途競合: District建設 vs Marksman 8A / Heavy 15A (Infantry 0A)。
- Queue追加時両資源支払い。不足は no_aether。

## District balance

- 2C継承。2D都市収入0.75でDistrict比率を維持。最大10。
- 実プレイで両軍が複数建設 (A: P5、 B: E10)。

## AI

- Plan維持。都市score +district×8、turtle (劣勢・弱軍は最寄り自都市固め)、
  貯蓄 (建設見込み・非脅威・2体以上で生産停止、脅威で即解除)。
- 旧マップは空辞書・falseで挙動不変 (回帰PASSで確認)。

## HUD / Border polish / clipping

- Overview行、建設ボタン縦積み、下端アンカー、右端-16px。
- 通常border主役化をやめHARD前線が主役 (細・暗 vs 発光3.0)。
- 構造test + 1920・1280目視で切れなし確認。

## Full Match A結果 (Player win)

- 8:06 VICTORY。W→C→N→E→HQ、District 5、kills 24/13、15v0。
- FPS平均43・min 33。ERROR 0。
- 調整前は3:13即勝ち → 収入・時間・HQ・turtle調整で8:06へ。

## Full Match B結果 (Enemy win)

- 13:17 DEFEAT。敵5都市+10 District+21体で締め。FPS平均41・min 28単発。
- 目標8〜12を1:17超過。原因: 受動プレイヤー相手の敵massingが緩慢
  (生産16〜32s + District支出 + 8000HQ約4.5分)。
- A下限 (8:06) を守るため追加短縮は見送り。3分以下・15分以上には非該当。
  一方的だが敵勝利パターンとして成立 (弱プレイヤー想定)。

## Match duration

- A 8:06 (目標内)、B 13:17 (目標超過、hard bounds内)。

## FPS / Unit count

- A: 平均43、39〜51、min 33。B: 平均41、34〜48、min 28単発。
- 実測最大25 units (40〜70の想定 textual には未達だが継続30割れなし)。
- 最大10 District + overlay + 前線描画を含む。

## automated tests

PHASE2D_TEST OK (全24項目):
5都市/7領土/初期所有・前線/連動・Aether率/District建設・継承/
0・8・15 cost/生産支払い・拒否/敵支払い・敵建設・敵生産/
saving・緊急生産/前線更新・HARD/HUD・clipping構造・overview/
pop46/Victory/Defeat/Restart×2 (5中立・7領土・District消去・pop40)。

## regression tests

- cli_smoke / skirmish / camera PASS
- phase1_5_test OK、phase1_5_playtest OK
- visual_slice_test OK、phase2a/b/c OK

## ERROR / SCRIPT ERROR

- phase2d/2c/2b/1.5/visual: 0 / 0。Full Match A/B: 0 / 0。
- 開発中2件 (test期待値・//コメント、即修正)。

## Known issues

- カメラドリフト未対応 (撮影側固定)。
- B超過 (上記分析)。人工catch-upは不採用 (仕様通り)。
- overview端黒背景、起動dip、戦闘単発dip (継続割れなし)。
- 実測最大25 units (40〜70想定の上限側は未観測)。

## 未完了事項

- Art Production全般 (都市GLB・FX・Audio・minimap・Tutorial等)。
- Aether備蓄の膨張 (消費はDistrict+上位Unitのみ)。
- 敵AIは簡易版 (Squad化は将来)。

## commit hash / push状態 / git status

- `feat: integrate phase 2d strategic match` を参照。
- origin/mainへpush済み。local main = origin/main、working tree clean。

## Phase 2Dを完成扱いにできるか

- 概ね可。5都市・7領土・Aether生産・District・継承・前線・HQ勝敗・
  Restart・回帰・ERROR 0・撮影・文書が成立。Aは目標内。
- 留保: Bが目標を1:17超過、実測unitsが想定上限未達。
  要求の hard bounds (3分以下・15分以上) には抵触せず、
  B超過の原因分析と調整見送り理由を本reportに記録した。

## Art Productionへ進める状態か

- 進める。Strategic Matchのロジック・バランス基盤が成立。
  残作業は見た目・コンテンツ量産のみ。数値はtres集約済み。

## ChatGPTに確認してほしい点

- A 8:06 / B 13:17 の受容可否。B短縮には HQ 8000→7000等が必要だが
  A下限割れリスクあり。このトレードオフの判断を求む。
- 都市収入0.75・生産時間延長・HQ 8000・turtle AIの調整方向は妥当か。
- 敵貯蓄則 (2体以上・非脅威で生産停止) は「同一wallet」の範囲内か。
- Aether配分 (N+S=C) と district加点×8・Aether加点×20の重みは妥当か。
- 実測25 unitsでのFPS (平均41〜43) から40〜70時をどう見積もるか。
  Phase 1で100体31FPSの実績あり。
