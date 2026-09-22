# Phase 1.8 完了報告 (Visual Slice Polish)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe (TigerLake-LP GT2)
基準: Phase 1.75 実装 9e59f04、作業開始時 main d79ea11

目的: Phase 1.75 で判明した明確なビジュアル不具合の修正と、Iris Xe 向け軽量描画最適化のみ。新ゲームシステムなし。Phase 2 着手なし。

## 修正内容

- Gearforge Titan モデル修正 + 再生成
- Gearforge Airship モデル修正 + 再生成
- Titan パトロール配置修正 (議事堂融合の解消)
- 軽量パフォーマンス調整 (shadow距離、MSAA)
- 回帰テスト + スクリーンショット更新

## Titan修正内容

`blender/scripts/make_gearforge_titan.py`:

- 主砲を脚部高さ (Blender Z 1.6m) から船体上部 (Z 5.6m) へ移動。Godot Y 5.28〜5.92。
- muzzle Empty を地下 (0,0,-0.9) から砲口先端 (0,-5.1,5.6) へ移動。Godot (0,5.6,+5.1)。muzzle flash / TitanShell が砲口から出ることを確認。
- ボイラーを垂直タンクから水平 (fore-aft、rot 90deg X) へ修正。Godot Y 6.5〜8.3、Z ±1.1。
- 足を接地へ (Y 0〜0.5、Z ±1.2 フラット)。従来は Y -0.9〜1.5 で 0.9m 地下に埋没。
- Hips/Hull/Trim/Prow の Y/Z 入れ替わりを修正し、フラットな hips (Y 4.1〜5.1)、hull (Y 4.9〜7.1) へ。
- Sponson を船体側面へ接続 (X ±2.0) し、前方へ突出 (Z -0.1〜+1.7)。
- Breech を船体内前部へ (Y 5.0〜6.2、Z -0.3〜+1.3)。Barrel 後端が Breech 内、前方へ 3.4m 突出。
- Rings/Muzzle brake を barrel 沿いへ配置。
- 全高 ~9.1m (stack lip)。歩兵 1.8m とのサイズ差 5x で明確。
- メッシュ/マテリアル数は変更なし (25 mesh、6 mat)。Blender Python 再生成可能を維持。

## Airship修正内容

`blender/scripts/make_gearforge_airship.py` (デザイン作り直しなし、接続・姿勢のみ):

- Envelope を垂直卵 (Blender Z -1.7〜7.3、高さ 9m) から水平 (X ±2.0、Y ±4.5、Z 0.8〜4.8、長さ 9m) へ修正。Godot X ±2.0、Y 0.8〜4.8、Z ±4.5。
- Nose を地下 (0,0,-1.7) から前方 (0,-4.5,2.8) へ。Godot 前方 +Z に接続。
- Tail spike を上方 (0,0,7.6) から後方 (0,+5.0,2.8) へ。Godot 後方 -Z に接続。
- Bands を水平リングから垂直リング (Y軸周り、rot 90deg X) へ。Z -2.5/0/+2.5 に配置。
- Fins を浮き (Z 6.2〜6.6) から尾部 (Y +3.8、Z 3.0〜4.5) へ接続。
- Gondola を縦長 (1.6,1.2,3.6) から扁平 (1.6,3.6,1.2、Y ±0.6、Z ±1.8) へ。
- Windows を垂直積みから長手方向 3Strip へ。
- Keel gun をゴンドラ下 2.2m 浮き (0,0,-2.2) から前下部接続 (0,-2.0,-0.3) へ。Godot Z +1.3〜+2.7、前方へ 0.9m 突出、船体に接続。
- Engine glow を上方浮き (0,0,1.6) から後部 (0,+1.9,0.0) へ接続。
- Props を上方浮きから側面後部へ (hubs X ±1.0、Y 0、Z -1.5、axis X; blades 垂直)。
- Rigging を envelope-bottom→gondola-top 接続 (Y 0.15〜1.35) へ。
- 原点はゴンドラ中心のまま (飛行物例外、注記維持)。メッシュ数変更なし。

## Blender再生成結果

- `blender --background --python blender/scripts/make_gearforge_titan.py` → SAVE_BLEND_OK、EXPORT_GLB_OK。Titan GLB 57,168 B (旧 57,552 B)。
- `blender --background --python blender/scripts/make_gearforge_airship.py` → SAVE_BLEND_OK、EXPORT_GLB_OK。Airship GLB 134,164 B (旧 130,204 B)。
- `blender/source/gearforge_titan.blend`、`gearforge_airship.blend` 更新 (追跡対象)。
- `blender/exports/*.glb` は gitignore 中間物。`game/assets/models/*.glb` へコピー後 `godot --headless --path game --import`。Godot dump で muzzle (0,5.6,+5.1)、barrel Y 5.6、boiler水平、envelope水平、keel gun接続を確認。

## 変更前FPS (Phase 1.75 測定)

- 1280x720: 通常 32〜45、戦闘最低 29 (概ね30以上維持)。
- 1920x1008 screenshot: Titan/Airship場面 26 FPS。
- 条件: Forward+、MSAA project値 2、shadow 80m、fog 0.008。

## 変更後FPS (Phase 1.8、描画あり)

- 1280x720 visual_slice `--quit-after 1500`: t=5s 44 (P8/E6 FX23 戦闘中)、t=10s 47、t=15s 45、t=20s 43、t=25s 44、t=30s 45。ERROR 0。
- 1280x720 `--quit-after 400` 複数回: 41〜43 (戦闘時)、36〜45 (待機時、ばらつきあり)。戦闘時30割らず。
- 1920x1080 `--quit-after 600`: t=5s 40、t=10s 49。30以上。Phase 1.75 の 26 から改善。
- phase1_5_match 描画あり 400f: 46 FPS。回帰なし。

目標 (1280x720 通常40前後 / 戦闘時30継続割らない) を満たす。1080p 30以上も参考値として満たすが、絶対条件としない方針通り、見た目を犠牲にしていない。

## 採用した最適化

- DirectionalLight shadow distance 80m → 50m (`game/scenes/maps/visual_slice.tscn`)。プレイエリア (city ~20m、Titan ~10m、戦闘 ~20m、map_limit 40) をカバーし、遠方シャドウを削減。単体では大きなFPS差なし (36〜39 vs 36〜45) だが、視覚差なしのため採用。Phase 2 方針 (40〜60m) と一致。
- MSAA project値 2 → 1 (`game/project.godot` `anti_aliasing/quality/msaa_3d`)。実測で値2は4x相当の重さ (36〜43 FPS)、値1で2x相当 (41〜42 FPS 安定)、値0 (OFF) で74〜91 FPS だがジャギー大。Phase 1.75 記録は「MSAA 2x」とあるため、値1で文書通りの2xに合わせ、画質を保ちつつ改善。2x→4xの視覚差はRTS距離で微小。

## 採用しなかった最適化と理由

- MSAA OFF: 74〜91 FPS と大幅改善だが、エッジのジャギーが目立ち「見た目を犠牲にしない」に反するため不採用。
- Fog OFF: コストはあるが、世界観の空気感を損なうため不採用。現状 fog 0.008 で問題なし。
- City GLB の draw call削減 (マテリアル統合・メッシュ結合): 現状 CityRoot 48子 + GLB内30超メッシュだが、MSAA/shadowで目標達成のため、大改造リスクを避け不採用。Phase 2 課題として残す。
- Titan GLB の mesh/material分割削減: 25 mesh / 6 mat のまま。修正で形状のみ正し、分割は変えず。遠景LOD (`_lod1`) は Phase 2 で命名規則通り追加予定のため今回は作らない。
- 不要な shadow caster削減: 既に hall/boiler/titan のみ ON、小物・FX・airship OFF の最小構成のため追加削減なし。
- VFX削減: 戦闘時 (FX 20〜30) と待機時 (FX 0) でFPS大差なし (44 vs 45)。Phase 1.75 結果通り VFXは主因でないため、理由なく削減しない。一度に複数変更せず、MSAA/shadowのみ変更。

## 1280x720前後の結果

- 通常 (待機、FX 0): 43〜47 FPS。目標40前後以上を満たす。
- 戦闘時 (開戦、FX 20〜30): 44 FPS前後。30を継続して割らない。
- ばらつきあり (36〜45)。ウィンドウフォーカス・シェーダ温まり・vsync絡み。1500f実走では43〜47安定。

## 1920x1008前後の参考結果

- 1920x1080 (実viewport 1920x1008相当): t=5s 40、t=10s 49。30以上で望ましい水準。Iris Xeで1080p 30を絶対条件としない方針のもと、参考値として記録。Phase 1.75 の26から改善。

## テスト結果

| テスト | 結果 |
|---|---|
| godot --headless --path game --import | PASS (ERROR 0) |
| tests/cli_smoke.gd | PASS |
| tests/skirmish_test.gd (Phase 1) | PASS |
| tests/camera_test.gd (Phase 1) | PASS |
| tests/phase1_5_test.gd (Phase 1.5) | PASS (全16項目 OK) |
| tests/phase1_5_playtest.gd player-win | PASS (4:44 sim, won=true) |
| phase1_5_match 起動 (headless 120f) | PASS, ERROR 0 |
| tests/visual_slice_test.gd | PASS (15体/titan/airship/都市/FX) |
| visual_slice 起動 (headless 150f) | PASS, ERROR 0 / SCRIPT ERROR 0 |
| phase1_5_match 描画あり実走 (400f) | PASS (46 FPS)、ERROR 0 |
| visual_slice 描画あり実走 (400f + 1500f) | PASS (43〜47 FPS)、ERROR 0、クラッシュなし |

合格条件 ERROR=0 / SCRIPT ERROR=0 / Phase1回帰PASS / Phase1.5回帰PASS / Visual Sliceクラッシュなし / 既存Match遊戯可 / FPS測定可 — すべて満たす。

## ERROR / SCRIPT ERROR

- 全回帰・実走で ERROR = 0、SCRIPT ERROR = 0。

## 既知の問題 (Phase 2 送り、今回は修正なし)

- `make_gearforge_hall.py` / `make_gearforge_boiler.py` にY/Z取り違え残存の疑い: pad/roofが垂直壁化、poleが地下、window/furnaceが前面浮き。Godot dumpで確認。Phase 1.8対象外 (Titan/Airship/配置のみ) のため未修正。 screenshotsでは舗装・建物本体で読めるが、近接で不自然。Phase 2で都市GLB統合時に修正。
- TitanパトロールをHall東の開放地 (0,0,-4)-(4,0,2) へ移動したため、旧配置より敵に近く殲滅が速い (t=10sでE0)。デモバランスの変更意図なし。軽量配置修正の範囲内。
- FPSはウィンドウフォーカス・シェーダ温まりでばらつく (36〜45)。固定条件ハーネスなし。Phase 1.75と同傾向。
- 色味はfog+sky ambientで淡い (Phase 1.75から継続、Phase 2調整)。

## Screenshots

保存先: `docs/screenshots/phase1_8/`。PNGを実際に確認して採用。

- overview.png (286,251 B、1920x1080): 都市全景 + 赤青両軍 + Titan (開放地で砲撃) + Airship (右上) + tracer/explosion + HUD。FPS 43。
- titan_airship.png (378,198 B、1920x1080): Airship (水平気嚢+発光帯+ゴンドラ+keel gun接続) + Titan (主砲+マズルフラッシュ+砲撃) + 歩兵 + 都市を同時確認。スケール差 readable。FPS 43。

撮影は一時SceneTreeスクリプトでカメラのみ操作 (ゲーム本体無改変)。一時スクリプトは /tmp に置き、repoに残さず。

## commit hash

- Phase 1.75実装: 9e59f04
- 作業開始時main: d79ea11
- Phase 1.8 commit: (push後に記録)

## push状態

- origin/mainへpush済み。local main = origin/main、working tree clean を確認。

## git status (完了時)

- working tree clean。

## Phase 2へ進める状態か

- 進める。Visual Sliceは回帰PASS、FPS目標達成、ERROR 0。Titan/Airshipのシルエット・砲撃基点・接続が正しく、RTSカメラからスケール差が読める。都市GLBの残存不具合とLOD、 vent予算、計測ハーネスはPhase 2課題として分離済み。新システム未追加。Phase 2着手は別タスクで。
