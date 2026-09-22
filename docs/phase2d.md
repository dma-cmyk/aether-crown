# Phase 2D 設計 (Strategic Match)

目的: 2Cまでの全システムを1つの8〜12分マッチに統合。
開始→都市争奪→領土拡張→Aether確保→District建設→軍拡→前線形成→
敵都市奪取→HQ攻略→Victory/Defeat。新巨大システムは増やさない。
新規独立シーン `res://scenes/maps/phase2d_strategic_match.tscn`。

## Strategic Match loop

都市 (Material) → 領土 (Aether) → District (経済・人口) ⇄
上位Unit (Aether消費) → 都市防衛・奪取・HQ攻略。
Aetherの使い道 (District vs Marksman/Heavy) がプレイヤー判断になる。

## Map

- Player HQ (-32,-32) / Enemy HQ (32,32)、HQ 8000 HP。
- 5都市: West Foundry (-22,4) 自陣側 / North Relay (2,-18) 北 /
  Central Nexus (0,0) 中央 / South Works (-2,18) 南 / East Bastion (22,-4) 敵陣側。
- 北・中央・南の3ルート。Central偏重防止:
  North+South (0.35+0.35) = Central (0.70) のAether価値。
- 道路は本線 + West→North/South→Central支線。

## City graph / Territory graph

- 領土7: player_base ↔ west ↔ {north, central, south}、
  north ↔ central ↔ {south, east}、south ↔ central、
  east ↔ enemy_base。
- TerritoryDefinition neighbor_ids で明示 (2d_*.tres)。

## Aether

- West 0.25 / North 0.35 / Central 0.70 / South 0.35 / East 0.25、
  合計 +1.90/s。Central最高、North+Southで対抗可。

## Unit Aether cost

- 2D専用tres (旧マップ保護): Infantry 70M/0A、
  Marksman 100M/8A、Heavy 150M/15A。Material既存維持。
- ProductionQueue.try_enqueue で両資源チェック・開始時支払い
  (cost 0の旧定義は挙動不変、新コード no_aether)。

## District

- 2C継承 (Industry/Military/Aether Works、2スロット/都市、最大10)。
- 2D都市収入は 0.75/s (2Cの1.5から調整、旧マップ不変)。
- 2D生産時間は Infantry 16s / Marksman 24s / Heavy 32s (テンポ調整)。

## Enemy AI

- Plan維持。都市評価に district数×8 を加算 (旧マップは空辞書で不変)。
- 貯蓄則: 建設見込み・非脅威・2体以上防御でunit生産を一時停止。
  脅威 (自都市CONTESTED) や1体以下では即時生産 (緊急優先)。
- 同一wallet、無料なし。7s tick、1件まで。

## Match tempo (実測)

- A (competent player): 8:06 VICTORY。都市→District×5→軍拡→HQ。
- B (passive player): 13:17 DEFEAT。敵が5都市+10 District+21体で締め。
- Bは目標8〜12を超過 (分析はreport)。3分以下・15分以上には非該当。
- 調整履歴: 都市収入1.5→1.0→0.75、HQ 3200→4800→6500→8000、
  生産時間延長、敵防御集中 (turtle) 追加。A 3:13→6:17→8:06。

## Balance

- Snowballは都市concentrateで発生するが、敗勢AIはturtle+貯蓄で延命。
- 人工catch-upなし。調整は収入・コスト・時間・AI・HQのみ。
- Pop cap: 40 + Military 6 (最大5都市all-military=100、現実的には60前後)。

## HUD

- TopBar (Material/Aether/Pop/Time)、Cities 5行、Territories 7行、
  Overview 1行 (`W:P N:N C:P* S:E E:N`)、City Management (常時)。
- clipping修正: 建設ボタン縦積み、パネル下端アンカー、
  右端 -16px統一。1280x720・1920x1080で目視確認。
- 本格ミニマップは未実装 (overview行で代替)。

## Performance

- event-driven維持 (bonus再計算・前線・AI tickは変更時のみ)。
- Full match (1280x720): A 平均43・min 33、B 平均41・min 28単発。
  40〜70 units相当なし (実測最大25) でも継続30割れなし。
- 追加描画は2C同等 + 領土2面 (最大10 District、静的primitive)。

## Tests

- `tests/phase2d_test.gd`: 24項目 (5都市/7領土/初期所有/連動/
  Aether率/District建設・継承/0・8・15 cost/生産支払い・拒否/
  敵支払い・敵建設・敵生産/saving・緊急/前線/HUD・clipping構造/
  pop/Victory/Defeat/Restart完全reset) PASS。
- 回帰: cli_smoke / skirmish / camera / phase1_5_test /
  phase1_5_playtest / visual_slice_test / phase2a_test / phase2b_test /
  phase2c_test すべて PASS。

## Known issues

- カメラドリフト件は本題外のため未対応 (撮影側で固定)。
- B (13:17) が目標超過。受動プレイヤーパターンのためで、
  A (8:06) 下限を守るための調整は見送り (report詳述)。
- overview端の黒背景 (カメラ仕様)。起動直後dip。
- 戦闘中単発dip 28〜33 (即回復、継続割れなし)。

## Art Productionへの申し送り

- 全ロジック成立。残りは見た目 (都市GLB化・District差別化・
  minimap・FX・Audio) のみ。数値はtres集約済み。
- Aether備蓄は膨張継続 (消費はDistrict+上位Unitのみ)。
- 敵AIはturtle・貯蓄・utilityの簡易版。Squad化時に再設計。
