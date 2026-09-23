# Aether Crown — Production Terrain Foundation 01 Specification & Technical Report

## 1. 概要 (Overview & Visual Direction)

本ドキュメントは、3DクォータービューRTS『Aether Crown』向けに制作された、完全オリジナルの **Production Terrain Foundation 01** の仕様・構造・技術仕様および検証結果をまとめた技術レポートである。

* **プロジェクト**: Aether Crown（産業ファンタジー・スチームパンク・重工業クォータービューRTS）
* **担当**: Gemini (Environment Designer / Terrain Production Artist / Blender Technical Artist)
* **ブランチ**: `gemini-terrain-foundation`
* **作業ディレクトリ**: `/home/dma/プロジェクト/aether-crown-gemini-terrain` (隔離worktree)
* **対象ハードウェア**: Intel Iris Xe（統合グラフィックス環境における高品質かつ超高効率な60fps動作）

### Visual Reference の解釈と設計への反映
添付のリファレンスコンセプト画像 (`/home/dma/画像/85613608-72a5-4801-a430-5746fe932ec5.png`) を精緻に分析し、単なるコピーではなくAether CrownのRTSゲームプレイに即した実用的な3D戦場地形として再設計した：

1. **RTS Camera Readability**: 遠景クォータービュー（アイソメトリック）から一目で「自軍拠点」「3大進行ルート」「中央主戦場」「巨大渓谷」「架橋地点」「敵要塞門」「敵高台本拠地」の空間関係が把握できる高低差構成。
2. **High Ground Plateaus**: 平面上に拠点を置くのではなく、プレイヤー側 (Y=12.0m) および敵軍側 (Y=15.5m) を明確な高台（Plateau）に配置。
3. **Three Strategic Routes**: 北（山稜防御ルート）、中央（大軍正面衝突ルート）、南（低地工業迂回路）の3ルートが地形の高低・幅員・地質変化だけで明確に誘導される。
4. **Central Battlefield**: 中央 Nexus 付近に大軍同士が陣形を展開できる広大な平坦戦場（Y=8.0m、約45m×35m）を確保。
5. **Industrial Ravine & Heavy Military Bridge**: 既存の Gearforge Map Kit 01（スパン32m、幅18m、高さ8m）がツライチで架かる深さ8.0mの巨大渓谷（谷底 Y=0.0m）を地形側に精密造成。
6. **Fortress Approach & Fortress Gate**: 橋頭堡から敵要塞へ向けて徐々に地形が狭まり登攀していくアプローチと、要塞門（幅24m、奥行8m、開口部10m×12.5m）および城壁・防壁タワー群が平坦に展開できる専用プラトー (Y=11.8m) を造成。

---

## 2. マップ寸法と標高階層 (Dimensions & Elevation Hierarchy)

### 基本寸法
* **全体サイズ**: 140.0m × 140.0m（Godot X: -70.0m 〜 +70.0m, Z: -70.0m 〜 +70.0m）
* **グリッド解像度**: 1.0m ステップ（141 × 141 グリッド）
* **外周境界境界壁**: マップ外周縁は標高 Y=22.0m まで切り立つ山岳フェード壁となっており、ユニットの画面外離脱を防ぎつつ工業盆地の没入感を演出。

### 標高階層 (Elevation Tiers)
既存の Gearforge Map Kit 01 が採用する **8.0m モジュール規格** に厳密に整合させ、各拠点や施設パッドを設計：

| エリア / 施設パッド | Godot 座標 (X, Z) | 標高 (Y) | 特徴と役割 |
| :--- | :--- | :--- | :--- |
| **Industrial Ravine (谷底)** | X: 10.0 〜 26.0, Z: -40 〜 +40 | **0.0m** | 濃度の高いエーテル汚泥・工業廃液が流れる深谷。橋脚が接地。 |
| **South Lowland Route / South Works** | (-2.0, 18.0) 付近 | **4.5m** | 南部低地迂回路。起伏が緩やかで重工業土壌が広がる。 |
| **Central Battlefield / Central Nexus** | (-12.0, 0.0) 付近 | **8.0m** | 主戦場。Heavy Military Bridge デッキ高さ (8.0m) と完全ツライチ。 |
| **East Bastion (橋頭堡テラス)** | (26.0, -8.0) 付近 | **9.0m** | 橋を渡った先の防衛拠点テラス。峡谷を見下ろす高台。 |
| **West Foundry (西工廠テラス)** | (-22.0, 4.0) 付近 | **9.8m** | 自軍側から中央戦場・南ルートへの中継工業テラス。 |
| **Fortress Gate Plateau** | (38.0, 20.0) 付近 | **11.8m** | Fortress Gate / Wall / Tower が平坦に展開する要塞前庭。 |
| **Player Industrial Plateau (自軍HQ)** | (-32.0, -32.0) 付近 | **12.0m** | HQ、工場、兵舎、Walker集結エリアを擁する広大な平坦高台。 |
| **North Mountain Route / North Relay** | (2.0, -18.0) 付近 | **13.5m** | 北部山稜ルート。中央戦場を見下ろす要衝。 |
| **Enemy Industrial Plateau (敵軍HQ)** | (34.0, 36.0) 付近 | **15.5m** | マップ最高位の敵本拠地。多段崖に守られた難攻不落の高台。 |
| **Perimeter Mountain Rim** | 外周半径 R > 52m | **22.0m** | 画面端を覆う境界岩壁。自然な盆地シルエットを形成。 |

---

## 3. 3大戦略ルートと戦場レイアウト (Strategic Spatial Layout)

```text
              [NORTH MOUNTAIN ROUTE (Y=13.5m)]
               /                             \
[PLAYER PLATEAU] ---- [CENTRAL BATTLEFIELD] ---- [HEAVY BRIDGE] ---- [FORTRESS GATE] ---- [ENEMY PLATEAU]
  (Y=12.0m)    \           (Y=8.0m)               (Y=8.0m)              (Y=11.8m)          (Y=15.5m)
                \                             /        |
              [SOUTH LOWLAND ROUTE (Y=4.5m)]       [RAVINE]
                                                   (Y=0.0m)
```

### 1. Player Industrial Plateau (西〜北西高台: Y=12.0m)
* **寸法**: 半径約22mの広大な平坦地。
* **特徴**: Player HQ（司令部）、Factory（重工廠）、Barracks（兵舎）を複数配置してもWalkerが旋回・整列できる十分なステージングエリアを確保。
* **アクセス**: 北ルート (Y=13.5m) への緩やかな登り、中央戦場 (Y=8.0m) への幅18m以上の緩傾斜スロープ、南ルート (Y=4.5m) への迂回スロープが自然に接続。

### 2. North Route (北ルート / 山稜ルート: Y=13.5m)
* **寸法**: 幅 12.0m 〜 16.0m のしっかりした稜線通路。
* **特徴**: 北側の外周崖に沿った高所ルート。中央戦場 (Y=8.0m) を右手に崖越しに見下ろす有利な射撃・監視位置を持つ。North Relay 中継都市パッドを配置可能。

### 3. Central Battlefield (中央主戦場: Y=8.0m)
* **寸法**: 約 45.0m × 35.0m の広大な開けた戦場。
* **特徴**: Central Nexus を中心に、複数部隊のWalkerや歩兵大隊が正面衝突・陣形展開（Flanking / Frontal charge）できる広さを確保。
* **峡谷との接続**: 東側で Industrial Ravine に直面し、Heavy Military Bridge の西側アプローチへと直結する。

### 4. South Route (南ルート / 工業低地ルート: Y=4.5m)
* **寸法**: 幅 16.0m 〜 22.0m のワイドな低地回廊。
* **特徴**: 標高が低く、重工業の汚泥や土壌が広がる迂回路。谷の南端を回り込んで敵要塞の側面（East Bastion・要塞南斜面）へアプローチできるオルタナティブルート。

### 5. Industrial Ravine & Heavy Military Bridge Slot
* **峡谷寸法**: 幅 16.0m（崖間ギャップ）、深さ 8.0m（デッキ標高 8.0m、谷底標高 0.0m）、長さ約 70m。
* **橋スロット整合**: Gearforge Heavy Military Bridge (`gearforge_bridge_heavy.glb`: 全長32m、幅18m、高さ8m) が完全に隙間なく渡れるよう、地形側で X: 10.0m 〜 26.0m を直線的な断崖としてくり抜き、西岸 (X=10.0m, Y=8.0m) と東岸 (X=26.0m, Y=8.0m) を精密に水平成形。橋脚が谷底 (Y=0.0m) に自然に着地。

### 6. Fortress Approach & Fortress Gate Plateau
* **アプローチ**: 橋を渡った東岸から、敵要塞へ向けて標高が 8.0m → 9.0m (East Bastion) → 11.8m (Gate Plateau) へと緩やかに登攀。両側が岩崖に挟まれ、防衛側に有利なチョークポイントを形成。
* **要塞門プラトー (Y=11.8m)**: Fortress Gate (`gearforge_fortress_gate.glb`: 幅24m、奥行8m、開口10m×12.5m) を設置した上で、左右に Straight Wall や Wall Tower、Defensive Bastion を連続配置できる十分な造成幅（半径20m以上）を平坦化。

### 7. Enemy Industrial Plateau (東〜南東高台: Y=15.5m)
* **寸法**: 半径約24m、マップ最高峰の高台。
* **特徴**: 要塞門を突破した奥に鎮座する敵軍の最終拠点。プレイヤー側よりも要塞感・防衛密度の高いシルエットを持ち、HQや重工業施設を配置可能。

---

## 4. 既存 Map Kit 01 モジュールとの整合仕様

本地形は、既存の `Gearforge Map Production Kit 01` アセットを直接配置することを前提として寸法・標高が設計されている：

1. **Heavy Military Bridge (`gearforge_bridge_heavy.glb`)**
   * モデル寸法: スパン 32m、幅 18m、デッキ高さ 8.0m、全高 12m。
   * 地形側スロット: ギャップ幅 16m（X=10.0m 〜 26.0m）、デッキ架橋面 Y=8.0m。
   * 整合性: アプローチ道路とデッキ上面がツライチ（段差 0.0m）で接続。Walkerや大型ユニットが引っかかりなく通行可能。
2. **Fortress Gate (`gearforge_fortress_gate.glb`)**
   * モデル寸法: 幅 24m、奥行 8m、全高 16m、ゲート開口部 10m × 12.5m（Titan通行可能規格）。
   * 地形側造成: Y=11.8m にて幅 40m 以上のフラットテラスを造成。城壁左右延長用アラインメントを確保。
3. **Wall Straight / Wall Corner / Wall Tower**
   * モジュール寸法: 8mグリッド。
   * 地形側造成: 門の両翼に段差なくスナップ配置可能。
4. **Defensive Bastion (`gearforge_defensive_bastion.glb`)**
   * 橋東岸の East Bastion (26.0, -8.0, Y=9.0m) に配置され、橋および中央戦場全域に射線を確保。

---

## 5. メッシュ統計とジオメトリ仕様 (Geometry & Technical Specs)

| 項目 | 実測値 / 仕様 | 備考 |
| :--- | :--- | :--- |
| **頂点数 (Vertices)** | **19,881** | 141 × 141 レギュラーグリッド |
| **面数 (Polygons / Quads)** | **19,600** | クアッドメッシュ |
| **三角面数 (Triangles)** | **39,200** | Iris Xe ターゲット（予算 50,000 tris 以下）に余裕で適合 |
| **バウンディングボックス** | 幅 140.0m × 奥行 140.0m × 高さ 22.0m | 原点中心 (-70〜+70) |
| **GLB ファイルサイズ** | **約 790 KB** | 高速ロード、メモリ消費最小 |
| **Heightmap 出力** | 141 × 141, 16-bit Grayscale PNG | 将来の NavMesh / Physics / Minimap 用 |
| **外部テクスチャ枚数** | **0 枚 (完全プロシージャル PBR マテリアル)** | VRAM・テクスチャサンプラー負荷ゼロ |

---

## 6. マテリアル構成 (Materials & Surface Distribution)

外部画像テクスチャを一切使用せず、GPU負荷の極めて低い 6 種類のプロシージャル PBR マテリアルを、傾斜角（Slope）・標高（Height）・ゾーン距離（Zone）の三元条件判定によって各頂点・面にプロシージャル割り当てを実施：

1. **`mat_terrain_grass` (山岳疎生草地 / 表土)**
   * Base Color: `#5A6B48`（彩度を抑えたスチームパンク調の工業緑土）
   * Roughness: `0.85`, Metallic: `0.02`
   * 分布: 傾斜角 < 28° の自然平坦地・緩斜面。
2. **`mat_terrain_dirt` (重工業土壌 / 踏み固められた進軍路)**
   * Base Color: `#6E563B`（赤錆と泥の混ざった行軍路）
   * Roughness: `0.90`, Metallic: `0.05`
   * 分布: 3大ルート上、スロープ遷移区間、交通頻度の高い接地帯。
3. **`mat_terrain_stone` (露出岩盤 / 垂直断崖)**
   * Base Color: `#4A4540`（無骨な玄武岩・花崗岩質）
   * Roughness: `0.75`, Metallic: `0.10`
   * 分布: 傾斜角 ≥ 28° の急峻な崖面、峡谷両壁、外周境界壁。
4. **`mat_terrain_industrial` (造成工業地盤 / 基礎テラス)**
   * Base Color: `#383533`（アスファルト・スラグ砕石・重工業舗装）
   * Roughness: `0.70`, Metallic: `0.20`
   * 分布: Player HQ、Enemy HQ、Fortress Gate、West Foundry、East Bastion などの拠点平坦面。
5. **`mat_terrain_sludge_water` (工業廃液 / 汚濁水流)**
   * Base Color: `#233830`（深緑のヘドロ状廃液）
   * Roughness: `0.20`, Metallic: `0.15`
   * 分布: 標高 Y < 1.0m の峡谷最深部。
6. **`mat_terrain_aether_seep` (凝縮エーテル鉱脈 / 発光染み出し)**
   * Base Color: `#1E6B7A`（抑制されたシアン・エーテル発光）
   * Emission: `#0D4855` (微小発光強度), Roughness: `0.35`, Metallic: `0.40`
   * 分布: 峡谷底の一部鉱脈露出部、要塞深部の裂け目。

---

## 7. Intel Iris Xe 向け最適化設計 (Hardware Optimization)

統合GPU（Intel Iris Xe）環境において、60fpsを安定維持するための徹底的なパフォーマンスチューニングを実施：

* **ポリゴンバジェット厳守**: 全体で 39,200 三角面。画面全体をカバーするメイン地形としては極めて軽量であり、多数のWalkerや建造物が画面内に密集しても頂点パイプラインがボトルネックにならない。
* **ゼロ・テクスチャ仕様**: アルベド・ノーマル・ラフネス等の外部テクスチャを一切排し、定数PBRマテリアルパラメータのみで描画。テクスチャキャッシュミスやVRAM帯域の逼迫を完全に防止。
* **低ドローコール**: マテリアル数はわずか6スロット。Godot 4のForward+ / Mobileレンダラーで極小のドローコールにバッチ化。
* **高低差オクルージョン**: 中央の巨大渓谷や高台の崖面が自然なオクルージョンカリング（視錐台外・遮蔽カリング）として機能し、奥のユニットやモデルの描画負荷を低減。

---

## 8. スクリーンショット検証とイテレーション (Review & Iterations)

Godot Showcase シーン（`terrain_foundation_showcase.tscn`）および自動撮影スクリプト（`capture_terrain_foundation.gd`）を用いて、1920×1080解像度で全12プリセット視点のスクリーンショットを撮影・目視検証した。

### 撮影画像一覧 (`docs/screenshots/gemini_terrain_foundation/`)
1. `01_full_isometric_overview.png`: 全体アイソメトリック俯瞰。高台・3ルート・峡谷・要塞の完璧な視認性を確認。
2. `02_top_view.png`: 正面真上（Top-down）視点。全体の対称性の排除、自然なルート配置、マテリアル分布を確認。
3. `03_player_plateau.png`: 自軍高台拠点。HQ・重工廠・兵舎・Walkerがゆったり収まる平坦スペースを確認。
4. `04_three_routes.png`: 3大進行ルートの分岐点。北の高所、中央の平原、南の低地が直感的に識別可能。
5. `05_central_battlefield.png`: 中央主戦場。大軍同士の衝突に耐えうる広大な交戦面と視界の抜けを確認。
6. `06_industrial_ravine.png`: 工業峡谷の深さと断崖絶壁。谷底のエーテル廃液と落差8.0mの迫力を確認。
7. `07_heavy_bridge_reference.png`: Heavy Military Bridgeの架橋ディテール。東西デッキのツライチ接地を確認。
8. `08_fortress_approach.png`: 敵要塞への登攀アプローチ。絞り込まれたチョークポイントと防衛的威圧感を確認。
9. `09_fortress_plateau.png`: Fortress Gateおよび防壁・タワー群の配置プラトー。平坦かつ自然な造成を確認。
10. `10_enemy_plateau.png`: 敵軍最高峰拠点。多段崖に囲まれた要塞都市のシルエットを確認。
11. `11_low_angle_elevation.png`: ローアングル見上げ視点。垂直方向の高低差が生むダイナミックなスケール感を確認。
12. `12_walker_traversal_scale.png`: Walker通行スケール視点。急斜面でのスタックがなく、快適な移動が可能であることを確認。

### 検証に基づくイテレーション内容
初期生成版のスクリーンショットレビューから以下の調整・修正を実施し、完成版へ反映した：
* **Bridge接地部のツライチ化**: 初版で東西アプローチに生じていた約0.4mの微小な段差を解消し、アプローチ地盤を正確に Y=8.0m へフラット化。
* **East Bastion の配置位置オフセット**: 橋東側のBastionが橋脚デッキと干渉しないよう、(26.0, -8.0, Y=9.0m) の高台テラスへ移動し、峡谷を見下ろす自然な砲台陣地へ変更。
* **Fortress Gate 前庭造成の拡大**: Fortress Gate の両翼に Wall Straight や Wall Tower を連続配置できるよう、テラスの造成半径を 15m から 20m へ拡大し、完全な水平面を確保。

---

## 9. 将来の Canonical Gameplay 統合に向けた技術メモ (Future Integration)

本地形基盤を将来の Canonical Match（`phase2d_strategic_match` 等）へ組み込む際の技術指針：

1. **NavigationRegion3D (NavMesh Baking)**
   * 本メッシュは1mグリッドの滑らかな連続面で構成されており、Godot 4 の `NavigationRegion3D` で極めて容易にベイク可能。
   * エージェントの登攀可能勾配（Max Slope）を **30°〜35°** に設定することで、平坦地およびスロープ（勾配 12°〜22°）のみが歩行可能領域としてベイクされ、垂直断崖や峡谷壁（勾配 50°〜90°）が自動的に進入不可（Chokepoint）となる。
2. **静的衝突判定 (StaticBody3D / CollisionShape3D)**
   * `ConcavePolygonShape3D`（Trimesh Static Body）をメッシュから1クリックで生成可能。39,200面と軽量なため、物理判定負荷は無視できるレベルに収まる。
3. **Territory / City Pad の位置整合**
   * 本地形の各テラスは既存の Canonical 5大都市 (`West Foundry`, `North Relay`, `Central Nexus`, `South Works`, `East Bastion`) の座標と完全にスケール一致させているため、マーカー位置をそのまま流用可能。
4. **Heavy Military Bridge の動的開通ギミック**
   * ゲーム開始時は橋が存在せず北・南ルートのみ利用可能とし、工兵による橋梁建設イベントで `gearforge_bridge_heavy.glb` を出現させてNavMeshを動的接続する等のRTSゲームプレイ拡張が地形構造上きれいに成立する。

---

## 10. ファイル構成と成果物パス

* **Blender 生成スクリプト**: `blender/scripts/make_aether_crown_terrain_foundation.py`
* **Blender ソースファイル**: `blender/source/aether_crown_terrain_foundation.blend`
* **中間 GLB エクスポート**: `blender/exports/map/aether_crown_terrain_foundation.glb`
* **ゲーム用 GLB アセット**: `game/assets/models/map/aether_crown_terrain_foundation.glb`
* **16-bit Heightmap**: `blender/exports/map/aether_crown_terrain_heightmap.png`
* **Godot Showcase シーン**: `game/scenes/showcase/terrain_foundation_showcase.tscn`
* **Godot Showcase スクリプト**: `game/scripts/showcase/terrain_foundation_showcase.gd`
* **自動キャプチャスクリプト**: `game/tests/capture_terrain_foundation.gd`
* **スクリーンショット成果物**: `docs/screenshots/gemini_terrain_foundation/` (全12枚)
* **本仕様書**: `docs/gemini_terrain_foundation.md`
