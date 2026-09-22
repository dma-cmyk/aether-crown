# Phase 1.75 スクリーンショット報告 (ChatGPT引き継ぎ用)

撮影日: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Intel Iris Xe (TigerLake-LP GT2) / 描画あり
対象コード: 9e59f04 (feat: phase 1.75 visual vertical slice)
スクリーンショットcommit: 30ab3df (docs: add phase 1.75 gameplay screenshots)

## 撮影方法

- Godotを描画ありで起動し、一時SceneTreeスクリプトでカメラのみ操作
  (`root.get_texture().get_image().save_png()`)
- ゲーム本体 (visual_slice / units / titan / airship / FX / HUD) は無改変
- シェーダ温まり後に撮影。黒画面・ロード途中・UI崩れは不採用
- 一時スクリプト5本は撮影後に削除済み
  (screenshot_capture / titan_diag / titan_portrait / titan_visdiag / titan_shot)
- ウィンドウ 1920x1080 指定、実viewport 1920x1008 (ウィンドウ装飾分)

## 画像一覧 (docs/screenshots/phase1_75/)

| ファイル | サイズ | 解像度 | 撮影時FPS (HUD) | 内容 |
|---|---|---|---|---|
| overview.png | 279,211 B | 1920x1008 | 35 (P8/E6, FX 26) | 議事堂+ボイラー2棟+煙突蒸気/煙、赤分隊+青歩兵、飛行船気嚢(右下)、tracer、道路、HUD全表示。開戦直後 |
| battle.png | 285,986 B | 1920x1008 | 34 (P8/E3, FX 19) | 両軍交戦、青tracer、爆発火炎、煙/蒸気、HPバー、都市、HUD |
| titan_airship.png | 308,527 B | 1920x1008 | 26 (P8/E5, FX 34) | 飛行船(右、気嚢+発光帯+フィン+ゴンドラ)、Titan(中央、銅ボイラー+船体+砲撃煙)、赤青歩兵、都市、爆発、HUD |

合計約 874KB。3枚のみをGit管理。

## ゲーム画面の問題有無

- 黒画面・UI崩れ・クラッシュなし。全撮影セッション ERROR / SCRIPT ERROR 0
- 色味は fog + sky ambient で全体に淡い (製品ルックとしては要調整、Phase 2課題)

## 撮影中に判明した既知の問題 (Phase 2への申し送り、今回は未修正)

1. Titanのパトロール経路が議事堂Annexに近接 (約1m) し、建物と視覚的に一体化
   して単体シルエットが読みづらい。配置か経路の見直し要
2. `blender/scripts/make_gearforge_titan.py`: 主砲が脚部高さ (z=1.6) に配置され、
   muzzle空オブジェクトが地下 (z=-0.9)。muzzle FXが地中に埋もれる。
   主砲は船体高さ (~5.6m) が意図値
3. 同: ボイラーが回転指定ミスで垂直タンク化 (意図は水平)。外観上は許容範囲
4. `blender/scripts/make_gearforge_airship.py`: keel gunがゴンドラ下2.2mに浮き
5. いずれもスクリーンショット作業では修正していない (禁止事項のため)

## 回帰確認 (一時スクリプト削除後)

- `godot --headless --path game --import`: ERROR 0
- `tests/visual_slice_test.gd`: PASS (OK)
- 本番コードの差分なし (docs/ と images/ のみ追加・更新)

## Git

- 撮影対象の実装: 9e59f04 (本番コードは無改変であることを削除後に検証)
- 画像追加commit: 30ab3df (画像3枚 + phase1_75.md Screenshots節)
- 本報告は同ブランチ main 上の後続commitに含まれる
- push先: origin/main。local main = origin/main、working tree clean を確認
