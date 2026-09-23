# Aether Crown — Production Terrain Foundation 01 Specification & Technical Report (Final Material & Surface Production Pass)

## 1. 概要 (Overview & Visual Direction)

本ドキュメントは、3DクォータービューRTS『Aether Crown』向けに制作された、完全オリジナルの **Production Terrain Foundation 01** の最終仕様・テクスチャマテリアル・UV展開・地形構造および検証結果をまとめた技術レポートである。

* **プロジェクト**: Aether Crown（産業ファンタジー・スチームパンク・重工業クォータービューRTS）
* **担当**: Gemini (Environment Designer / Terrain Production Artist / Blender Technical Artist)
* **ブランチ**: `gemini-terrain-foundation`
* **作業ディレクトリ**: `/home/dma/プロジェクト/aether-crown-gemini-terrain` (隔離worktree)
* **対象ハードウェア**: Intel Iris Xe（統合グラフィックス環境における高品質かつ超高効率な60fps動作）
* **設計目標**: 「ベタ塗りのプロトタイプ地形から脱却し、完全オリジナルのシームレスPBRテクスチャと崖面プロジェクションによって、実際の製品版RTSクオリティの重厚な工業戦場サーフェスを実現する」。

---

## 2. Final Material & Surface Production Pass における主要成果

地形ジオメトリ（39,200 tris、140m×140m、3大ルート、橋接地Y=8.0m等）を完全保持した上で、以下のサーフェスマテリアル刷新を実施した：

### 1. 完全オリジナル PBR テクスチャパック (Original Procedural Texture Pack)
外部素材・ストックテクスチャを一切使用せず、Python (NumPy + PIL) による **Fourier Spectral Synthesis（フーリエ空間周波数フィルタリングによるフラクタル・ブラウン運動場）** を用いて、100%数学的シームレス（周期境界）かつ完全等方性（isotropic: 45度クロスハッチや方向性ストライプが一切存在しない）の 1024×1024 PBR テクスチャセット（全12枚）を独自生成した。

* **生成スクリプト**: [`blender/scripts/make_aether_crown_terrain_textures.py`](file:///home/dma/プロジェクト/aether-crown-gemini-terrain/blender/scripts/make_aether_crown_terrain_textures.py)
* **格納先**: `game/assets/textures/terrain/`

| テクスチャセット | マップ種別 | 解像度 | 視覚特徴・RTS向けチューニング |
| :--- | :--- | :---: | :--- |
| **Dark Industrial Grass** | Albedo / Normal / Roughness | 1024×1024 | 産業地帯の乾いたダークオリーブ芝生。健康な草地（rgb 44,58,30）、重機の往来で露出した黒土（rgb 64,48,32）、乾燥パッチが有機的に混在。ファンタジー調の鮮やかさを排した重厚な色彩。 |
| **Worn Industrial Dirt** | Albedo / Normal / Roughness | 1024×1024 | 踏み固められた褐色土（rgb 96,66,40）、キャタピラ・脚部通行による硬化黒土（rgb 64,44,26）、酸化鉄・鉱物ダスト（rgb 116,62,30）のブレンド。方向性のない自然な起伏。 |
| **Charcoal Cliff Rock** | Albedo / Normal / Roughness | 1024×1024 | 暗灰色玄武岩（rgb 48,48,52）、亀裂影（rgb 26,26,28）、鉱物脈（rgb 66,52,40）。スペクトル異方性フィルタにより、自然な水平地層（strata layers）が走る岩壁。 |
| **Industrial Slag Ground** | Albedo / Normal / Roughness | 1024×1024 | 工業造成地・基地周辺のスラグ砕石。暗色アスファルト基盤（rgb 52,52,58）、石炭灰微粉（rgb 30,30,34）、金属鉱滓粒子（rgb 76,78,86）による重工業テクスチャ。 |

### 2. UV / Mapping 方式 (World-Scale UV & Tangential Cliff Projection)
* **平坦面・緩斜面 (Top-down Planar Mapping)**:
  * ワールド座標に基づく 12.0m タイルスケール（`u = vgx / 12.0`, `v = vgz / 12.0`）を採用。
  * RTSカメラの俯瞰距離（約40m〜100m）において、タイリングの繰り返し感が目立たず、かつ適度な中規模ディテール（medium-scale breakup）が美しく知覚されるスケールに調和。
* **急峻な崖面 (Tangential Cliff Projection)**:
  * 法線傾斜角が急な岩壁（`norm_z < 0.70`）に対して、ポリゴンの水平接線ベクトル（tangent: `tx = -ny / len`, `ty = nx / len`）を動的に算出し、`u = (vx*tx + vy*ty)/12.0`, `v = vz/9.6` として展開。
  * 垂直崖面でテクスチャが縦に伸びるストレッチ現象（UV stretching）を完全に防止し、玄武岩の水平地層が岩壁の輪郭に沿って自然に流れる地質学的表現を実現。

### 3. マテリアル境界の有機的ブレンド (Organic Boundary Jitter)
* 1mメッシュのポリゴン単位マテリアルスロット分けにおいて生じやすい「市松模様・階段状ギザギザ（stair-step grid artifacts）」を解消するため、低周波の波長（約12m〜20m）を持つ有機的ジッター関数（`2.4 * sin(gx*0.32 + gz*0.25) + 1.2 * cos(gx*0.68 - gz*0.58)`）を適用。
* これにより、直線的・格子状の境界が自然な地質侵食の蛇行（meandering geological transition）へと改善。

### 4. Aether 表現の抑制とアクセント調和
* 峡谷底の Aether 鉱脈は、彩度の高すぎる発光を避け、深みのあるエメラルドシアン（Emission: `(0.10, 0.35, 0.45)`, Strength 1.5）としてアクセント配置。
* 戦場全体の95%以上を土・岩・草・スラグの重工業アースカラーで構成し、ユニットや重要拠点の視認性を最優先。

---

## 3. マップ寸法と標高階層 (Dimensions & Elevation Hierarchy)

### 基本寸法
* **全体サイズ**: 140.0m × 140.0m（Godot X: -70.0m 〜 +70.0m, Z: -70.0m 〜 +70.0m）
* **グリッド解像度**: 1.0m ステップ（141 × 141 グリッド）
* **総頂点数**: **19,881**
* **総三角面数**: **39,200 tris**（Intel Iris Xe 予算 50,000 tris 以下を余裕でクリア）
* **GLBファイルサイズ**: **約 6.6 MB**（1024px PBRテクスチャ埋め込み済み）

### 標高階層 (Elevation Tiers)
| エリア / 施設パッド | Godot 座標 (X, Z) | 標高 (Y) | 特徴と役割 |
| :--- | :--- | :---: | :--- |
| **Industrial Ravine (谷底)** | X: 10.0 〜 26.0, Z: -40 〜 +24 | **0.0m** | 廃液が澱む深谷。橋脚が接地。 |
| **South Lowland Route / South Works** | (-2.0, 20.0) 付近 | **4.5m** | 南部低地迂回路。ワイドな工業土壌回廊。 |
| **Central Battlefield / Central Nexus** | (-8.0, 0.0) 付近 | **8.0m** | 主戦場。Heavy Military Bridge デッキ面と完全ツライチ。 |
| **East Bastion (橋頭堡テラス)** | (26.0, -8.0) 付近 | **9.0m** | 橋を渡った先の防衛陣地テラス。 |
| **West Foundry (西工廠テラス)** | (-22.0, 4.0) 付近 | **9.8m** | 自軍側から各ルートへの中継工業テラス。 |
| **Fortress Gate Plateau** | (38.0, 20.0) 付近 | **11.8m** | Fortress Gate / Wall / Tower が平坦に展開する要塞前庭。 |
| **Player Industrial Plateau (自軍HQ)** | (-32.0, -32.0) 付近 | **12.0m** | HQ、重工廠、兵舎、Walker集結エリアを擁する広大な高台。 |
| **North Mountain Route / North Relay** | (0.0, -18.0) 付近 | **13.5m** | 北部山稜ルート。中央戦場を見下ろす要衝。 |
| **Enemy Industrial Plateau (敵軍HQ)** | (34.0, 36.0) 付近 | **15.5m** | マップ最高位の敵本拠地高台。 |
| **Perimeter Mountain Rim** | 外周境界部 | **18.0m 〜 27.0m** | 盆地を囲む峻険な外周岩山連峰。 |

---

## 4. 全20枚の検証スクリーンショット一覧

Godot Showcase シーン（`terrain_foundation_showcase.tscn`）および自動キャプチャスクリプト（`capture_terrain_foundation.gd`）を用いて、1920×1080解像度で全20アングルのスクリーンショットを撮影・検証完了（Vulkan Forward+ / Intel Iris Xe）：

| 番号 | ファイル名 | 視点・対象 | 検証内容・結果 |
| :---: | :--- | :--- | :--- |
| **01** | `01_full_isometric_overview.png` | 全体アイソメトリック俯瞰 | 高台・3ルート・主戦場・峡谷・要塞門の完璧な全体構成を確認。 |
| **02** | `02_top_view.png` | 全体真上トップダウン（全体） | dist 185mで140m全体を俯瞰。対称性の排除と有機的な外周を確認。 |
| **03** | `03_player_plateau.png` | 自軍高台拠点（Player Base） | HQ・工廠・兵舎・Walkerが余裕で収まる平坦造成を確認。 |
| **04** | `04_three_routes.png` | 3大ルート分岐点 | 北の高台、中央の主戦場、南の低地への明確な分岐を確認。 |
| **05** | `05_central_battlefield.png` | 中央主戦場（Central Nexus） | 大軍同士が陣形展開できる広大な戦闘空間と自然な土壌を確認。 |
| **06** | `06_industrial_ravine.png` | 工業峡谷・断崖絶壁 | 落差8.0mの垂直玄武岩断崖と谷底のエーテル廃液を確認。 |
| **07** | `07_heavy_bridge_reference.png` | Heavy Military Bridge架橋部 | 東西デッキがY=8.0mで完全ツライチ接地し、隙間がないことを確認。 |
| **08** | `08_fortress_approach.png` | 要塞登攀アプローチ | 橋から要塞門へ向けて登攀・絞り込まれるチョークポイントを確認。 |
| **09** | `09_fortress_plateau.png` | Fortress Gateプラトー | 要塞門・城壁・タワー群が水平に整列する造成面を確認。 |
| **10** | `10_enemy_plateau.png` | 敵軍最高峰拠点（Enemy Base） | 多段崖に守られた最高峰要塞都市のシルエットを確認。 |
| **11** | `11_low_angle_elevation.png` | ローアングル見上げ | 垂直落差が生み出すダイナミックなスケール感を確認。 |
| **12** | `12_walker_traversal_scale.png` | Walker通行・スケール | Walkerがスロープや橋をスタックなく走破できる道幅を確認。 |
| **13** | `13_terrain_only_isometric.png` | 地形単体アイソメトリック俯瞰 | 建物を非表示にし、純粋な地形ジオメトリとマテリアルだけで戦場構造が読めることを実証。 |
| **14** | `14_three_routes_top_debug.png` | 3ルート可読性トップダウン | 真上視点からPlayer→3ルート（North/Central/South）→Enemyの構造が一目で読めることを実証。 |
| **15** | **`15_material_overview.png`** | **マテリアル全体俯瞰** | **地形全体に適用された4種PBRテクスチャの調和とプロトタイプ感脱却を確認。** |
| **16** | **`16_grass_dirt_transition.png`** | **芝生と土壌の境界** | **芝生・土壌・スラグの有機的ブレンドと自然な地質境界を確認。** |
| **17** | **`17_cliff_surface.png`** | **峡谷・岩壁テクスチャ** | **崖面プロジェクションによる玄武岩水平地層と無ストレッチを確認。** |
| **18** | **`18_central_surface.png`** | **中央戦場サーフェス** | **踏み固められた褐色土と鉄錆ダストの戦場ディテールを確認。** |
| **19** | **`19_fortress_surface.png`** | **要塞プラトー周辺地盤** | **要塞門周辺のスラグ地盤と急峻な防壁岩盤の調和を確認。** |
| **20** | **`20_rts_distance_material.png`** | **標準RTSカメラ距離** | **標準プレイ距離でユニット・建物が背景に埋もれず視認可能であることを確認。** |

---

## 5. 技術検証とパフォーマンス (Performance & Pipeline)

* **Blender Generator**: `blender -b -P blender/scripts/make_aether_crown_terrain_foundation.py`
  * エクスポート時間: 約0.7秒（GLB）
  * 警告・エラー: 0件
* **Godot Import**:
  * Godot 4.7.2 Forward+ (Vulkan 1.4, Intel Iris Xe)
  * 自動VRAMテクスチャ圧縮（BPTC / RGTC）、Mipmaps生成、Roughness Limiter 正常動作
  * 読み込みエラー・警告: 0件
* **フレームレート**:
  * 1080p フルスクリーンレンダリング時: **60fps 安定動作**
  * ドローコール: 地形メッシュ1オブジェクト（6マテリアルプリミティブ）に集約、極めて軽量。

---

## 6. Git Safety 及び非干渉の遵守

* **本線 worktree への接触**: 0件（`/home/dma/プロジェクト/aether-crown` に一切変更なし）
* **既存ゲームプレイ・アセットの変更**: 0件（新規ファイルおよび前回追加のTerrain Foundation関連ファイルのみ）
* **ブランチ**: `gemini-terrain-foundation` 専用
