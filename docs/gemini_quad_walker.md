# Gearforge Ironbastion (Medium Quad-Walker Prototype)

- **作成日**: 2026-09-22
- **ステータス**: 未統合の独立モデリング試作 (Standalone Prototype — LOD0 / Visual Asset)
- **対象アセット**: Gearforge Medium Quadruped Walker (Class: `medium_quad_support_walker`)
- **機体名**: **Gearforge Ironbastion** (アイアンバスティオン)

---

## 1. 概要 (Overview & Role)

### 機体の位置付けと役割
**Ironbastion** は、Gearforge 陣営における「量産型中型4脚支援歩行戦車 (Heavy Support Quad-Walker)」です。
Titan `Crownpiercer` (11.4m) のような国家級の一点物攻城超兵器ではなく、また二脚の `Ironstride` (4.54m) よりも重厚で安定した射撃プラットフォームとして、前線の要塞化・拠点防衛・重火力支援（連装重反動機関砲による弾幕形成および重装甲目標の粉砕）を担う量産配備機体を想定しています。

命名規則も既存の設計方針（`phase25d.md`）を踏襲し、超兵器固有の `Crown*` ではなく、量産兵器を示すクラス名 `Ironbastion` と命名しています。

### スケール感と階層
| 対象 | 全高 (H) | 全幅 (W) | 全長 (D) | 位置付け |
|---|---:|---:|---:|---|
| Infantry | 1.80m | 0.80m | 0.60m | 前線歩兵 |
| Walker `Ironstride` | 4.54m | 3.54m | 4.20m | 俊敏な前線支援二脚機 |
| **Quad-Walker `Ironbastion` (本機)** | **5.23m** | **6.50m** | **8.30m** | **中型4脚重支援砲台 (小要塞)** |
| Titan `Crownpiercer` | 11.39m | 6.80m | 8.90m | 決戦用巨大攻城二脚兵器 |
| Airship `Crownhammer` | 11.38m | 14.80m | 35.45m | 巨大戦略航空旗艦 |

全高 5.23m は、推奨サイズ要件（5m〜8m級）に合致し、歩兵の約3倍、二脚 Walker より一回り大きく、Titan の半分以下のサイズ感です。全幅 6.50m で四方に力強く踏ん張る4脚スタンスにより、低重心で圧倒的な安定感と存在感を誇ります。

---

## 2. デザイン特徴とシルエット (Visual Language & Silhouette)

### RTS俯瞰での視認性 (Readability)
- **四点接地の重低重心シルエット**: 四方に大きくハの字・X字状に開いた頑丈な4脚と大型ラムパッドにより、二脚機 `Ironstride`（Z字・縦長）や Titan（長身の直立二脚）と遠景カメラでも瞬時に区別可能。
- **連装重反動砲 (Twin Heavy Recoil Cannons)**: 砲塔前面から突き出す2門の重厚な段付きスチール砲身と真鍮マズルブレーキ、連結クロスブレースが強力な前進火力を一目で伝達。
- **ボイラーとツイン排気煙突**: 後方に斜め16度で立ち上がるGearforge伝統の双発煙突（内部に炉のオレンジ発光）と、真鍮バンドで締結された横置き大型銅製ボイラー。

### マテリアル言語と Gearforge 整合性
`blender/scripts/material_lib.py` の公式パレットを使用し、テクスチャ不要の Principled BSDF のみで構成：
1. **Dark Iron (約65%)**: 鋳鉄製メインシャーシ、脚部箱桁ビーム、砲身中間スリーブ、砲塔キャビン
2. **Steel (約20%)**: 傾斜前面装甲、砲身ベース/先端、可動ピストンロッド、足部デッキ、Faction Plate
3. **Brass (約8%)**: 砲塔旋回リング、マズルブレーキ、関節ピボット、キューポラ、ボイラー補強バンド、クロー先端
4. **Copper (約5%)**: 横置き蒸気ボイラー、高圧蒸気配管、上下リコイルバッファー、油圧シリンダー
5. **Aether Cyan (約2%)**: 前面センサースリット、照準光学ポッド、キューポラスリット、背面レギュレーターコア
6. **Furnace Orange (<1%)**: ツイン排気煙突内部の燃焼熱源発光

### 参考画像 (Visual Reference) との調和
スチームパンク工業の密度感（exposed hydraulic pistons, high-pressure copper steam conduits, rivet flanges, heavy trunnion joints）を取り入れ、過度に細かすぎて潰れるボルト等は避けつつ、RTSカメラの陰影で面と機構が浮き彫りになる面取り（Bevel）と部品階層を徹底しています。

---

## 3. 作成アセット仕様 (Technical Specifications)

- **メッシュ数 (Meshes)**: 6 Functional Groups
  - `leg_fl_lod0` (左前脚)
  - `leg_fr_lod0` (右前脚)
  - `leg_rl_lod0` (左後脚)
  - `leg_rr_lod0` (右後脚)
  - `hull_lod0` (中央シャーシ、ボイラー、煙突、前面装甲)
  - `turret_lod0` (旋回砲塔、連装砲、照準ポッド、スモークラック)
- **頂点数 (Vertices)**: 9,088
- **ポリゴン数 (Polygons)**: 8,434
- **三角形数 (Triangles)**: 17,316 tris (LOD0)
- **マテリアル数 (Materials)**: 6 (Dark Iron, Steel, Brass, Copper, Aether Glow, Furnace Glow)
- **バウンディングボックス**:
  - 幅 (X): 6.500m (`[-3.25, 3.25]`)
  - 奥行 (Y): 8.295m (`[-5.03, 3.27]`)
  - 高さ (Z): 5.228m (`[0.01, 5.24]`)
- **座標軸**: 前方 `-Y` (Blender) → `+Z` (Godot), 上方 `+Z` (Blender) → `+Y` (Godot)
- **原点 (Origin)**: 接地中心 (`0.0, 0.0, 0.0`)
- **ピボット構造 (Pivots & Hierarchy)**:
  - 6つの機能グループはそれぞれ実際の回転軸に配置された Empty (`*_pivot`) を親として親子付け済み。
  - 将来のリグ作成や Godot 側でのプログラム制御（砲塔旋回、反動リコイル、4脚IK歩行）が容易。
- **ランタイムアンカー (Runtime FX / Socket Anchors)**:
  - `muzzle_l`, `muzzle_r`: 左右砲口（発砲マズルフラッシュ・砲弾射出位置）
  - `center_anchor`: ユニット中心
  - `turret_mount`: 砲塔旋回マウント基部
  - `exhaust_l`, `exhaust_r`: 左右煙突頂部（蒸気・排煙エフェクト発生位置）
  - `sensor_anchor`: 照準センサー部
  - `foot_fl`, `foot_fr`, `foot_rl`, `foot_rr`: 4脚それぞれの接地位置（砂塵・踏みつけFX位置）

---

## 4. スクリーンショット (Screenshots)

`docs/screenshots/gemini_quad_walker/` に 1920×1080 解像度で 6 枚出力：

| ファイル名 | 視点 / 内容 | 目的 |
|---|---|---|
| `01_isometric_rts.png` | RTS戦術俯瞰視点 (3/4 Isometric) | ゲームプレイ画面におけるシルエットと存在感の確認 |
| `02_front_view.png` | 正面ビュー (Front View) | 傾斜装甲、センサースリット、連装砲の迫力と4脚スタンス |
| `03_side_profile.png` | 側面プロファイル (Side Profile) | 低重心シャーシ、前後重量配分、油圧シリンダー機構 |
| `04_rear_quarter.png` | 後方クォーター (Rear Quarter) | ボイラー、真鍮バンド、ツイン排気煙突、Aetherレギュレーター |
| `05_top_down.png` | 真上見下ろし (Top-Down) | 4脚フットプリント、砲塔旋回ベース、連装砲レイアウト |
| `06_detail_turret_closeup.png` | 砲塔近接クローズアップ (Detail Closeup) | マズルブレーキ、リコイルバッファー、真鍮キューポラ、配管 |

---

## 5. 新規ファイル一覧 (Created Files)

本タスクでは本線作業との衝突を防ぐため、既存ファイルの上書きを一切行わず、以下の新規ファイルのみを作成しました：

1. `blender/scripts/make_gearforge_medium_quad_walker.py` (3Dモデル自動生成スクリプト)
2. `blender/scripts/render_quad_walker_screenshots.py` (展示用6視点スクリーンショット撮影スクリプト)
3. `blender/source/gearforge_medium_quad_walker.blend` (Blender ソースファイル)
4. `game/assets/models/gearforge_medium_quad_walker.glb` (Godot 向け本番 GLB モデルアセット)
5. `docs/screenshots/gemini_quad_walker/01_isometric_rts.png`
6. `docs/screenshots/gemini_quad_walker/02_front_view.png`
7. `docs/screenshots/gemini_quad_walker/03_side_profile.png`
8. `docs/screenshots/gemini_quad_walker/04_rear_quarter.png`
9. `docs/screenshots/gemini_quad_walker/05_top_down.png`
10. `docs/screenshots/gemini_quad_walker/06_detail_turret_closeup.png`
11. `docs/gemini_quad_walker.md` (本レポート)

*(中間生成物: `blender/exports/gearforge_medium_quad_walker.glb` は `.gitignore` 管理下)*

---

## 6. 次に本線へ統合する場合に必要な作業 (Future Integration Roadmap)

本モデルは未統合のプロトタイプです。正式にゲーム内に投入・量産配備する場合は、以下の作業が想定されます：

1. **LODモデルの作成**:
   - `_lod1` (約50% tris: 8,000 tris 程度) および `_lod2` (約25% tris: 4,000 tris 程度) の自動生成スクリプト作成。
2. **アニメーション & リグ (Rig & Animations)**:
   - 4脚歩行 (`walk`)、待機 (`idle`)、主砲発射反動 (`attack`)、撃破 (`die`) のアクション作成。
   - または Godot 側のプロシージャルIKによる4脚接地制御の実装。
3. **ゲームプレイ統合 (Godot / RTSUnit)**:
   - `RTSUnit` クラスとしての定義（HP、装甲値、移動速度、射程、コストなど）。
   - コリジョン形状 (`CollisionShape3D` / Box / Capsule) の作成。
   - セレクションボックス・リングの定義。
   - `visual_quad_walker.gd` の作成（砲塔の目標追従旋回、砲身リコイル、アンカーへのFXアタッチ）。
4. **ファクションカラー (Faction Tint)**:
   - 左右の `gearforge_medium_quad_walker_faction_plate_*` メッシュにプレイヤー/陣営カラーシェーダーを適用。
5. **テスト & バランス調整**:
   - showcase マップでの動作検証と単体・集団テストの追加。
