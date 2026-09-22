# Phase 2C 完了報告 (District Growth)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Intel Iris Xe (TigerLake-LP GT2)
基準: Phase 2B feat 6bf1968、作業開始時 main 6bf1968

目的: 都市×3に2スロット、Industry / Military / Aether Works を建設し、
「取る→得る→育てる」のループを完成させる。Phase 2Dには着手しない。

## 実装概要

- DistrictDefinition + 3 tres (cost・time・bonus データ駆動)
- DistrictController (検証・支払い・タイマー・継承・敵AI・集計、Autoloadなし)
- DistrictVisual (primitive静的ビルダー、所有色切替、影OFF)
- Phase 2Cマップ (2B継承 + District + 敵貯蓄則 + pop再計算)
- Phase 2C HUD (City Management パネル + 都市アイコン行)
- 領土border軽微polish (細く・暗く、前線strip不変)
- 自動テスト24項目 + 回帰全PASS + 実プレイ2回 + スクリーンショット4枚

## 新規/変更ファイル

新規:
- game/core/district_definition.gd (+.uid)
- game/resources/districts/{industry,military,aether_works}.tres
- game/scripts/district/district_controller.gd (+.uid)
- game/scripts/district/district_visual.gd (+.uid)
- game/scenes/maps/phase2c_district_war.tscn / phase2c_district_war.gd (+.uid)
- game/scenes/ui/phase2c_hud.tscn / game/scripts/ui/phase2c_hud.gd (+.uid)
- game/tests/phase2c_test.gd (+.uid)
- docs/phase2c.md, docs/screenshots/phase2c/×4
- game/tests/phase2b_test.gd.uid (2B時に生成漏れ分を同梱)

変更 (2件のみ):
- game/scripts/ai/enemy_strategist.gd (district_saving フラグ + _produce抑止。旧マップはfalseで不変)
- game/scripts/territory/territory_region.gd (通常border 0.25→0.18・×0.8暗化のみ。ロジック不変)

不変: phase1_5 / phase2a / phase2b マップ・outpost・rts_city・economy・camera・GameManager。

## District architecture

- preset slot方式 (2/都市、最大6)。自由配置・Tier・upgrade・売却・破壊なし。
- plotは都市南 (±8.5, 7.5)、visual-only (collisionなし)。
- 建設は開始時一括支払い、1都市1件並行まで、12s。
- bonus再計算は districts_changed / 所有変更時のみ (毎フレームなし)。

## Slot仕様

- EMPTY / BUILDING (進捗%をHUD表示) / COMPLETE。
- 同一都市の重複禁止。満杯で3件目不可。資源不足・非所有は拒否コード。

## Industry仕様

- 140M / 25A、12s、+0.75 M/s。工場+煙突+炉光で識別可。

## Military仕様

- 130M / 30A、12s、pop cap +6。兵舎+所有色軍旗+アンテナ。
- 生産速度変更なし (生産はHQのみ)。超過popは許容。

## Aether Works仕様

- 120M / 40A、12s、+0.20 A/s。塔+cyan結晶+リング。
- 3独占+0.60 < 領土満額+1.50 を維持。

## cost / build time

- 上表通り。実プレイで到達可能性を確認 (Industry 1:27着手)。

## Economy変化

- Material: HQ 2.0 + 都市1.5 + Industry 0.75。Aether: 領土 + Works 0.20。
- Pop cap: 40 + Military 6 (所有側ごと、奪取で移行)。

## Population変化

- Military完成で 40→46 をHUD・テストで確認。奪取で 40/46 が移行。
- 超過時は新規生産のみ制限 (testでは未超過、コード上は許容設計)。

## Enemy AI

- 7s tick、1件まで、utility (収入/pop/Central/Aether) + 固定priority、非random。
- 同一支払い (aether減少をテストでassert)。貯蓄則でunit生産を一時停止。
- 実プレイで Industry+Military (run1: pop 46) / 全6 District (run2) を確認。

## Capture inheritance

- スロットは都市に紐付き、bonusごと新ownerへ (テスト + 実プレイで確認)。
- 実プレイrun2: PlayerのIndustryを敵が継承し2件目を追加。
- CONTESTED中は維持。visualは所有色で再構築 (赤軍旗への切替を撮影)。

## HUD

- City Management: 都市ボタン/所有/スロット/建設ボタン (コスト表記)。
- 都市上 `I | M | A` + 建設中 `...`。拒否理由toast。

## automated tests

PHASE2C_TEST OK (全24項目):
スロット6・初期空・Neutral拒否・所有後 exact支払い (140M/25A)・
重複・busy・no_material・no_aether・タイマー完了・Industry 2.25・
Military pop46・no_slot・HUD表示・Aether Works 1.35・CONTESTED維持・
East敵所有・敵AI建設+支払い・West奪還継承 (bonus減・pop移行)・
VICTORY・DEFEAT・Restart×2 (全消去・pop40・Aether0・領土reset)。

## regression tests

- cli_smoke / skirmish / camera PASS
- phase1_5_test OK、phase1_5_playtest OK
- visual_slice_test OK、phase2a_test OK、phase2b_test OK

## playtest

- run1 (弱script): Player全滅も敵がIndustry+Military (pop46) → VICTORY。
  平均44 / min 33。
- run2 (貯蓄script): PlayerがWest Industry 1:27着手 → 敵が奪還継承 →
  敵全6 District → DEFEAT。平均44 / min 28単発。
- 両runで territory/frontline 維持、HQ戦へ収束、ERROR 0。

## FPS

- 実プレイ平均44 (2B同日値42、前回54は別セッション値)。
- 通常41〜49、戦闘中単発dip (28〜33、即回復、2A/2Bと同特性)。
- フル6 District描画を含む。継続30割れなし。
- 1080p撮影時 34〜46。

## ERROR

- phase2c/2b/2a/1.5/visual: すべて 0。実プレイ2回: 0。
- 開発中1件: testの変数スコープ (即修正、本番影響なし)。

## SCRIPT ERROR

- 0 (最終コード・全テスト・実プレイ)。

## known issues

- カメラドリフト件は本題外のため未対応 (撮影側で固定)。
- overview端の黒背景 (カメラ仕様)。起動直後dip。
- 敵は敗勢でも貯蓄則で建設継続 (仕様通り)。
- Maturity表示なし・District破壊なし (仕様)。

## 未完了事項

- District Tier/upgrade・Research/Tech・Titan/Airship生産・城壁・
  破壊・修理・売却・補給線・Squad AI・新文明・新ユニット・本格ミニマップ・
  procedural配置・都市GLB化は未着手。

## commit hash

- Phase 2C feat: (下記 `feat: add city district growth system` を参照)

## push状態

- origin/mainへpush済み。local main = origin/main、working tree clean を確認。

## git status (完了時)

- working tree clean。

## Phase 2Dへ進める状態か

- 進める。3種District・支払い・タイマー・bonus・継承・敵AI (建設+貯蓄)・
  HUD・HQ勝敗・Restartが自動テスト+実プレイで成立。回帰全PASS、ERROR 0。
  Aether備蓄は膨張継続のため2Dで用途設計が必要。

## ChatGPTに確認してほしい点

- District cost (120〜140M / 25〜40A、12s) と bonus (+0.75M / +6pop / +0.20A)
  の初版バランスは妥当か。実プレイでは Industry 1:27着手が目安。
- 敵貯蓄則 (unit生産の一時停止、同財布の繰延) は「同一ルール」の範囲内か。
  なしでは敵が140Mを貯められず建設が発火しなかった実測あり。
- Aether Works +0.20 (3独占+0.60 < 領土+1.50) の抑制度は妥当か。
  run2で敵備蓄452まで膨張。2Dの消費先設計への示唆があれば知りたい。
- Militaryがpop capのみ (生産速度不変) で十分か。2Dでの軍事拡張余地の意見歓迎。
