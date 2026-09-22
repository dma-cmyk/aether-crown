# Phase 1.9 完了報告 (City Asset Cleanup)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe (TigerLake-LP GT2)
基準: Phase 1.8 本体 81dec690fe1df64fdd90ec65288f59f115a00699、作業開始時 main ad211fc

目的: Visual Slice の都市アセットの明確な崩れ (Y/Z取り違え・垂直壁化・地下埋没・浮き) を修正し、Gearforge都市が RTS カメラからひとつの都市区画として自然に読める状態へ整える。新システムなし。Phase 2 着手なし。

## 修正内容

- Gearforge Civic Hall モデル修正 + 再生成 (向き・接地・接続)
- Gearforge Boiler House モデル修正 + 再生成 (向き・接地・接続)
- 都市配置調整 (スポーンの建物内包解消・道路始点・小物めり込み・街灯位置・舗装拡大)
- Lighting / Fog 軽調整 (重いPPなし)
- 回帰テスト + スクリーンショット更新

## Civic Hall の修正内容

`blender/scripts/make_gearforge_hall.py` (Blender Z-up → Godot Y-up の変換理解に基づく):

- pad: サイズ (13.0,0.3,11.0) → (13.0,11.0,0.3)。Godot で垂直壁 (Y=11m) だったものが水平スラブ (Y=0.3m、Y 0〜0.3 接地) へ。
- pad_trim: (13.2,0.12,11.2) → (13.2,11.2,0.12)。同上、水平化。
- hall: (8.0,3.6,6.4) → (8.0,6.4,3.6)。Godot で高さ 6.4m・奥行 3.6m・1.1m 地下埋没だったものが、高さ 3.6m・奥行 6.4m・Y 0.3〜3.9 (pad上に接地) へ。位置 Z=2.1 は維持 (pad天 0.3 + 1.8)。
- annex: (3.4,2.6,4.6) → (3.4,4.6,2.6)。同上、Y 0.25〜2.85 で pad 上に接地 (0.05 沈み込みで安定)。
- roof: (8.6,0.35,7.0) → (8.6,7.0,0.35)。垂直壁 (Y=7m) だったものが水平スラブ (Y 3.88〜4.23、hall天 3.9 上に着座、0.3m オーバーハング) へ。
- ridge/tower/cap/top/dial/stack/lip: 既に正しかったため無改変 (Godot dump で垂直・接地・接続を確認)。
- tank: 位置 Z 1.4 → 1.28。底面 1.28-0.9=0.38 が pad trim 天 0.38 に着座 (0.12m 浮き解消)。annex北壁に 1.1m 埋め込み・1.7m 突出で接続。
- windows: 無改変。hall修正後に hall南壁 (Godot Z=3.2) に対し Y=-3.22→Godot Z=3.17〜3.27 で半埋め込み・半突出の正しい付着へ (1.42m 浮きが自動解消)。
- pipe (北壁沿い): 無改変。hall修正後に壁面に 0.01m gap で接触 (付着)。
- poles: 位置 (px,0,-4.2) → (px,-4.2,2.88)。Godot で Y -6.7〜-1.7 完全地下だったものが、Y 0.38〜5.38 (pad trim天 0.38 上に接地、高さ 5m) へ。Y=-4.2 は hall南 (壁 -3.2 の 1m 南、pad内)。
- banners: 位置 (px,0,6.2) → (px,-4.2,4.6)。ポール頂上 (5.38) 直下に吊下 (Y 3.85〜5.35、ポール貫通で接続)。6.2m 上空の浮き解消。
- vent 高さは変更不要 (hall stack lip天 6.55 に対し vent 6.6、0.05m 上で維持)。

Godot dump で全主要パーツの正立・水平・接地・接続を確認。

## Boiler House の修正内容

`blender/scripts/make_gearforge_boiler.py`:

- pad: (9.0,0.3,7.0) → (9.0,7.0,0.3)。垂直壁 (Y=7m、3.35m 地下) → 水平 (Y 0〜0.3 接地)。
- hall: (6.4,3.0,5.0) → (6.4,5.0,3.0)。Y -0.7〜4.3 (0.7m 埋没) → Y 0.3〜3.3 (pad上に接地)。
- roof: (6.8,0.3,5.4) → (6.8,5.4,0.3)。垂直壁 (Y 0.75〜6.15) → 水平 (Y 3.3〜3.6、hall天上に着座)。
- roof_trim: (7.0,0.18,5.6) → (7.0,5.6,0.18)。同上、Y 3.11〜3.29 で roof底面に接触。
- chimney/bands/lip: 無改変 (既に垂直・正立、Y 3.0〜9.0、hall/roof貫通で接続)。
- tanks: 全面再配置。旧 (tx,1.8,1.2) 軸Y (北壁外 0.3m、底 0.35m 浮き、半分hall内埋没) → 新 (3.0,±1.0,1.15) 軸X (東壁貫通: X 1.8〜4.2 で壁 2.6 に 0.8m 埋め込み・1.6m 突出、底 0.3 が pad天に着座、2基 Y分離で干渉なし、pad内に収まる)。回転 (90°X) → (90°Y)。
- furnace mouth/frame: 無改変。hall修正後に南壁 (Godot Z=2.5) に対し Z=2.47〜2.62 で半埋め込み付着へ (1.05m 浮きが自動解消)。
- pipe_v: (-3.2,1.0,1.8) 深さ3.2 → (-3.9,0,2.0) 深さ3.6。hall内埋没 → 西壁面に接触 (X -4.03〜-3.77 に対し壁 -3.8)、Y 0.2〜3.8 (基部は pad に 0.1 沈み、頂部は roof pipe と接続)。
- pipe_h: (-1.0,1.0,3.3) 深さ5.5 → (-0.6,0,3.73) 深さ6.5。hall天内埋没 → roof天 3.6 上に着座 (底 3.6)、西端は pipe_v 頂部と接続、東端は chimney (X 1.65〜2.75) 内に到達し接続。
- lamp poles: (px,0,-3.0) → (px,-3.0,1.6)。Y -4.3〜-1.7 完全地下 → Y 0.3〜2.9 (pad天上に接地)。Y=-3.0 は hall南 (壁 -2.5 の 0.5m 南、pad内)。
- lamp heads: (px,0,2.9) → (px,-3.0,3.075)。ポールから 4.6m 分離浮き → ポール天 2.9 上に着座 (Y 2.9〜3.25、接続)。
- vent 高さは変更不要 (chimney lip天 9.25 に対し vent 9.3)。

## 配置変更

`game/scripts/visual/visual_slice.gd` (建物3棟の位置・回転は維持、周辺のみ):

- PLAYER_BASE (-16,0,-12) → (-26,0,-16)。旧スポーン (-10,-8) と旧ベースが hall内 (X -18.5〜-5.5、Z -15.5〜-4.5) に内包されていた問題を解消。新スポーン (-20,-12) は hall西 1.5m の舗装上、nav が hall を迂回。ENEMY_BASE・CITY_CENTER・建物位置・obstacle rects・Titan patrol・vent は無改変。
- pavement (-12,-10) 20x16 → (-10,-8) 30x24。全市街 (hall + boiler2棟) をカバー。旧舗装は boiler1東 2m・boiler2北 2m がはみ出し半浮きだった。draw call 増なし (1 box)。
- roads 始点 (-12,-10) → (-8,-4)。旧始点は hall中心 (建物下から道路が飛び出し) だった。新始点は hall南壁 0.5m 南の入口。経路 (2,2)→ENEMY_BASE は維持、boiler1 と干渉なし。
- props 2点修正: (-5.5,-4.5) hall角上 → (-4.5,-3.5) hall南東 1m 外。(-18,-6) hall内 → (-19.5,-3.5) hall南西外。残り4点は建物外のため維持。
- Godot lamps 1点修正: (-6,-12) hall内 → (-4,-3) hall南東外。残り4点は建物外のため維持。
- Titan配置・カメラ構図は無改変 (Titanモデルではなく配置優先の方針通り、現配置で hall/boiler と融合せず読めることを screenshots で確認)。

## Lighting / Fog変更

`game/scenes/maps/visual_slice.tscn` (重いPP追加なし):

- fog_density 0.008 → 0.006 (淡い洗い出しを軽減)
- fog_light_color (0.62,0.60,0.58) → (0.55,0.53,0.50) (やや締める)
- ambient_light_energy 0.7 → 0.6 (フラット感を軽減)
- DirectionalLight energy 1.2 → 1.35 (キー光でシルエット readable へ)
- tonemap_exposure 1.05 → 1.0 (白飛び軽減)
- sky_horizon (0.72,0.66,0.58) → (0.68,0.62,0.54) (やや深く、世界観維持)
- shadow距離 50m・MSAA・その他は Phase 1.8 のまま (性能維持)。

## Blender再生成結果

- `blender --background --python blender/scripts/make_gearforge_hall.py` → SAVE_BLEND_OK、EXPORT_GLB_OK。GLB 45,468 B → 45,404 B (-64 B)。
- `blender --background --python blender/scripts/make_gearforge_boiler.py` → SAVE_BLEND_OK、EXPORT_GLB_OK。GLB 42,132 B → 42,104 B (-28 B)。
- `blender/source/*.blend` 更新 (追跡対象)。`blender/exports/*.glb` は gitignore 中間物。`game/assets/models/*.glb` へコピー後 `godot --headless --path game --import` (ERROR 0)。
- メッシュ/マテリアル数・ポリゴン予算・命名・Principled BSDF のみ・原点接地中心は維持。新規建物種なし。

## 色とマテリアル

既存 Principled BSDF の iron/brass/copper/stone/brick/glow/furnace/glass を維持。hall (brass壁+白窓+青dial+銅annex/tank) と boiler (brick壁+鉄roof+銅tank/pipe+炉glow+青lamp) で鉄・真鍮・銅・暖光・青アクセントが分離し、全灰色化なし。RTS距離で無意味な微差追加なし。新規テクスチャなし。

## FPS

- 1280x720 visual_slice `--quit-after 1500`: t=5s 51、t=10s 52、t=15s 52、t=20s 52、t=25s 53。ERROR 0。Phase 1.8 (43〜47) と同等以上、改善。戦闘時30割らず。
- 1920x1080 visual_slice `--quit-after 1200`: t=5s 48、t=10s 49、t=15s 48、t=20s 48、t=25s 49。Phase 1.8 (40/49) と同等。初回1回のみ t=5-10s 24 を記録したが再走で 48-49 安定 (シェーダ温まり・フォーカスのばらつき、Phase 1.8 報告と同傾向)。
- phase1_5_match 1280x720 400f: 52 FPS (1回目 30、再走 52。Phase 1.8 46 と同等、回帰なし。visual_slice 無関係のため環境ばらつき)。
- 新規ライト・FXなし。draw call 増なし (pavement 1 box のみ拡大、props/lamps 数維持)。

## テスト結果

| テスト | 結果 |
|---|---|
| godot --headless --path game --import | PASS (ERROR 0) |
| tests/cli_smoke.gd | PASS |
| tests/skirmish_test.gd (Phase 1) | PASS |
| tests/camera_test.gd (Phase 1) | PASS |
| tests/phase1_5_test.gd (Phase 1.5) | PASS (全項目 OK) |
| tests/phase1_5_playtest.gd player-win | PASS (5:14 sim, won=true) |
| phase1_5_match 起動 (headless 120f) | PASS, ERROR 0 |
| tests/visual_slice_test.gd | PASS (15体/titan/airship/都市48子/FX) |
| visual_slice 起動 (headless 150f) | PASS, ERROR 0 / SCRIPT ERROR 0 |
| phase1_5_match 描画あり実走 (400f) | PASS (52 FPS)、ERROR 0 |
| visual_slice 描画あり実走 (400f + 1500f + 1080p 1200f) | PASS (720p 51〜53 / 1080p 48〜49)、ERROR 0、クラッシュなし |

## ERROR / SCRIPT ERROR

- 全回帰・実走で ERROR = 0、SCRIPT ERROR = 0。

## Screenshots

保存先: `docs/screenshots/phase1_9/`。PNGを実際に確認して採用 (一時SceneTreeスクリプトでカメラのみ操作、ゲーム本体無改変、一時スクリプトは repo に残さず)。

- overview.png (310,853 B、1920x1080): 都市全景 (hall + boiler2棟 + 舗装 + 街灯 + 小物) + Titan (砲撃中) + Airship (右上) + 青軍/赤軍 + 道路 (都市→敵陣) + smoke/steam + HUD。FPS 48。
- city_closeup.png (251,918 B、1920x1080): Civic Hall (屋根・壁面密着窓・銅annex/tank・煙突) + Boiler House (屋根・炉口・配管・煙突・タンク・ランプ) + 舗装・街灯・crate/barrel が建物外で接続・接地。FPS 36 (近接のためやや低下も30以上)。
- titan_airship.png (325,904 B、1920x1080): Airship (ゴンドラ・keel gun・発光帯) + Titan (主砲・脚・青装甲) + 歩兵 + 都市 + 道路のスケール差。FPS 41。

## 既知の問題

- デフォルト RTS カメラ (rig -10,-4) は都市中心より 20m以上北を向く (Phase 1.75 からの仕様)。プレイには支障なし (パンで対応)。screenshots は一時カメラで撮影、本番コードのカメラは無改変。
- FPS はシェーダ温まり・ウィンドウフォーカスでばらつく (Phase 1.75/1.8 と同傾向)。固定条件ハーネスなし。
- 色味は fog+sky でやや淡い残りあり (Phase 1.9 で締めたが極端な変更は禁止のため)。Phase 2 で District 別に調整余地。
- Titan patrol が boiler1北 6.5m・hall東 5.5m の開放地で、overview では boiler1手前に見えるが融合せず読める (配置優先の方針通り、モデル無改変)。

## 未修正事項

- Phase 2 システム (占領/Territory/District/Aether/Research/TechTree/新AI・経済・勝利条件・Titan/Airship本格AI・Squad AI・LOD本格実装) は一切未着手。
- Titan/Airship モデルは無改変 (Phase 1.8 で成立済み)。
- 建物数・ユニット数・ゲームルールは無改変。

## commit hash

- Phase 1.8 本体: 81dec690fe1df64fdd90ec65288f59f115a00699
- 作業開始時 main: ad211fc
- Phase 1.9 fix: this commit (`git log --oneline -3` で確認)

## push状態

- origin/mainへpush済み。local main = origin/main、working tree clean を確認。

## git status (完了時)

- working tree clean。

## Phase 2へ進める状態か

- 進める。Civic Hall / Boiler House の主要パーツが正立・水平・接地・接続し、浮き/地下埋没/軸取り違えが見た目上解消。都市がひとつの区画として読め、Titan/Airship/歩兵とのスケール差が読める。Phase 1 / 1.5 回帰PASS、Visual Slice PASS、ERROR 0、FPSは Phase 1.8 同等以上。新システム未追加。

## Phase 2で気を付ける点

- 都市GLB拡大時 (District/Territory) は vent 本数×amount 予算を先に決める (現状 4 vents 常時稼働)。
- 影距離 50m・MSAA 2x相当 (値1) で目標達成中。都市拡大で draw call が増えたら City GLB のマテリアル統合・メッシュ結合を検討 (Phase 1.8 送り)。
- Titan 遠景LOD (`_lod1`) は命名規則通り追加 (model_rules準拠)。
- FPS計測は HUD+VISUAL_PERF ログのみの方針を維持。固定条件ハーネスは作らない。
- デフォルトカメラの注視点 (都市北振り) は District 配置時に再検討。
