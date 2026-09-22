# Phase 2C 設計 (District Growth)

目的: 「都市を取る→領土とAetherを得る→資源で都市を成長させる」の完成。
新規独立シーン `res://scenes/maps/phase2c_district_war.tscn`。
Phase 1 / 1.5 / Visual Slice / 2A / 2B は無改変で残す (2B領土borderの
軽微polishのみ共有ファイルに適用、ロジック不変)。

作らないもの (Phase 2D+):
District upgrade/Tier/Research/Tech/Hero/Titan・Airship生産/城壁・タレット/
破壊・修理・売却・返金/補給線/Squad AI/新文明・新ユニット/
procedural配置・自由配置建築。

## District architecture

- `game/core/district_definition.gd` (DistrictDefinition, Resource):
  id / display_name / material_cost / aether_cost / build_time_sec (12.0) /
  material_income_bonus / aether_income_bonus / population_bonus / visual_type。
- `game/resources/districts/{industry,military,aether_works}.tres`。
- `game/scripts/district/district_controller.gd` (DistrictController):
  シーン内通常ノード (Autoloadなし)。2スロット×3都市の状態管理、
  建設検証・支払い、BUILDINGタイマー (≤6スロットの軽量_process)、
  完成・占領時のvisual再構築、敵AI utility、HUD用集計。
  ボーナス計算は event-driven (districts_changed + 所有変更でmapが再計算)。
- `game/scripts/district/district_visual.gd` (DistrictVisual):
  static primitive builder。foundation枠 / Industry (工場+煙突+炉光) /
  Military (兵舎+軍旗+アンテナ、所有色) / Aether Works (塔+結晶+リング)。
  影OFF。Gearforge色 (鉄・真鍮・銅・暖光・Aether cyan) 維持。

## District Slot

- 占領可能3都市に各2スロット (HQには付けない)。最大6 District。
- plot位置は都市南側 (±8.5, 7.5)、visual-only (collisionなし、進路不干渉)。
- 状態 EMPTY / BUILDING / COMPLETE。建設中は1都市1件まで。
- 同一都市の同タイプ重複禁止。

## District一覧

| type | cost | time | bonus |
|---|---|---|---|
| industry | 140M / 25A | 12s | +0.75 M/s |
| military | 130M / 30A | 12s | pop cap +6 |
| aether_works | 120M / 40A | 12s | +0.20 A/s |

Aether Works 3独占でも +0.60/s < Territory満額 +1.50/s。
マップコントロール > District量産の関係を維持。

## ownership rules

- 建設条件: City所有=自軍、空き、重複なし、建設中なし、両資源充足。
  開始時一括支払い。Cancel/Refundなし。負数化なし。
- 奪取でDistrictは破壊されず新ownerへ継承 (bonusごと移行)。
  Militaryのpop capも移行。超過popは殺さず、新規生産のみ制限。
- CONTESTED中は既存ownerのbonus維持 (Territoryと同思想)。

## Enemy AI

- 7s strategic tick (map駆動、毎フレーム禁止)。1 tick 1件まで。
- Utility: Material収入低→Industry、pop逼迫→Military、
  Central所有/Aether不足→Aether Works、同点は固定priority。非random。
- 同一ルール・同一支払い (無料建設なし)。
- 貯蓄則: 建設見込み時にunit生産を一時停止 (同財布の繰延、無料化なし)。
  `district_saving` フラグでstrategist._produceを抑止。
  旧マップは false のため挙動不変。

## HUD

- City Management パネル (常時コンパクト表示):
  3都市ボタン + 所有表示 + スロット2行 (例 `[Industry]` `[Military 45%]`) +
  3建設ボタン (コスト付き)。拒否はtoastで理由表示。
- World側: 都市Label上の `I | M | A` アイコン行 (完成のみ、建設中は `...`)。
- Unit Selection (world click) は無改変。District操作はHUD完結。

## Economy

- Material: HQ 2.0 + 都市×1.5 + Industry×0.75。Aether: 領土 + Works×0.20。
- Pop cap: 40 + Military×6 (所有側ごと再計算)。
- 再計算は district/所有イベント時のみ (毎フレーム走査なし)。

## Snowball方針

- District bonusはTerritory bonusより弱く (catch-up systemなし)。
- 実プレイで敵3独占+6 Districtでも即決着せず、HQ戦へ収束を確認。

## Performance

- 追加は最大6 District × (1 main + 少数props) の静的primitive。
- 実プレイ (1280x720): playtest#1 平均44 (min 33)、playtest#2 平均44 (min 28単発)。
  2B同日値 42、前回54は別セッション値。継続30割れなし。
- フル6 District状態を含む (#2終盤)。draw call増の影響は誤差範囲。

## Tests

- `tests/phase2c_test.gd`: 24項目 (スロット/初期空/所有制限/ exact支払い/
  重複・busy・資源・満杯拒否/タイマー完了/3種bonus/CONTESTED維持/
  継承+bonus・pop移行/敵AI建設+支払い/HUD/Victory/Defeat/Restart×2
  incl. 全消去・pop40・Aether0・領土reset) PASS。
- 回帰: cli_smoke / skirmish / camera / phase1_5_test /
  phase1_5_playtest / visual_slice_test / phase2a_test / phase2b_test PASS。

## Known issues

- カメラドリフト件は本題外のため未対応 (撮影側で固定)。
- overview端の黒背景 (カメラ仕様)。起動直後dip (シェーダ温まり)。
- 戦闘中の単発FPS dip (28前後、即回復。2A/2Bと同特性)。
- 敵は敗勢でも貯蓄則で建設を継続する (仕様通り、無料化なし)。

## Phase 2Dへの申し送り

- Aether消費先は District cost のみ。備蓄は膨張し続ける (2Dで用途設計を)。
- pop超過・収入内訳は districts_changed / map再計算に集約済み。
- 敵AIの貯蓄則・utilityは簡易版。Squad AI導入時に再設計前提。
- 都市GLB化は未着手。District plotは固定offset (GLB化時は再調整)。
