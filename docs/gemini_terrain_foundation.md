# Aether Crown — Production Terrain Foundation 01 Specification & Technical Report (Final Polish)

## 1. 概要 (Overview & Visual Direction)

本ドキュメントは、3DクォータービューRTS『Aether Crown』向けに制作された、完全オリジナルの **Production Terrain Foundation 01** の最終Polish仕様・構造・技術仕様および検証結果をまとめた技術レポートである。

* **プロジェクト**: Aether Crown（産業ファンタジー・スチームパンク・重工業クォータービューRTS）
* **担当**: Gemini (Environment Designer / Terrain Production Artist / Blender Technical Artist)
* **ブランチ**: `gemini-terrain-foundation`
* **作業ディレクトリ**: `/home/dma/プロジェクト/aether-crown-gemini-terrain` (隔離worktree)
* **対象ハードウェア**: Intel Iris Xe（統合グラフィックス環境における高品質かつ超高効率な60fps動作）
* **設計目標**: 「建物をすべて非表示にしても、地形ジオメトリと地盤マテリアルだけでRTSの戦場構造（高台・3大戦略ルート・中央主戦場・峡谷・架橋地点・要塞アプローチ）が一瞬で理解できる」状態の確立。

---

## 2. Final Polish における主要改善点

コミット `51d5ef0`（v1）の優れた基盤（Bridge接地、Ravine落差、Fortress Gate整合、Walkerスケール、標高階層、39,200 tris予算）を100%保持した上で、以下の重点改善を実施した：

### 1. Three Routes Continuous Readability (3大ルートの連続性と可読性)
* **課題**: 以前は中央の橋の存在感が強く、北ルートと南ルートが背景の地形・岩盤に溶け込みやすかった。また坂道部分でマテリアルが途切れていた。
* **改善**:
  * **North Route (北ルート / 山稜高所ルート: Y=13.5m)**: Player Base (-32, -32) から North Relay (0, -18) を経由し、Enemy Base (34, 36) 北翼へ至る連続した稜線回廊を確立。中央戦場を見下ろす南縁を落差5.5mの垂直断崖として切り立たせ、稜線のシルエットを劇的に強調。
  * **Central Route (中央ルート / 主戦場大通り: Y=8.0m)**: West Foundry (-22, 4) 〜 Central Nexus (-8, 0) 〜 Heavy Bridge (X: 10〜26) 〜 Fortress Gate (38, 20) を直結する広大な交戦プラットフォーム。市松模様を排除し、有機的な進軍痕跡（battle-worn earth）として再成形。
  * **South Route (南ルート / 工業低地迂回路: Y=4.5m)**: West Foundryから南下し、South Works (-2, 20) を経て、峡谷の南端（Z > 24m）を完全に回り込んで敵要塞南斜面へ登攀する幅16mの低地回廊。中央戦場（Y=8.0m）との間に落差3.5mの段差崖を配置。
  * **スロープ優先マテリアル**: 進軍路判定（`min_route_dist < 6.8m`）を緩斜面判定より優先させることで、高台から中央・低地へ下りるスロープ上でも茶色い工業土壌（`dirt`）が途切れず、端から端まで一本の道としてくっきりと読めるように改善。

### 2. Perimeter Mountain Basin (外周山岳のボウル感・アリーナ壁感の解消)
* **課題**: 以前の外周は円形距離判定により、四隅にある Player Base と Enemy Base が山岳に飲み込まれやすく、また一様なすり鉢（Arena wall）に見えていた。
* **改善**:
  * 矩形ボックスディスタンス（`max(abs(gx), abs(gz))`）に適応する非対称な境界生成を導入。
  * これにより、対角線上にある Player Base (-32, -32) および Enemy Base (34, 36) の広大な高台テラス（半径32m以上）が山岳から完全に解放され、堂々たる高台として露出。
  * 外周山岳はマップ外縁（52m〜65m）のみで立ち上がり、多重波形のノイズと鋭い岩稜（crags & ridges: 標高 18m〜27m）によって、不自然な円形壁ではなく「過酷な工業山岳盆地（Industrial Basin Rim）」としての景観を実現。

### 3. Material & Color Palette Polish (プロトタイプ感の完全排除)
* **課題**: 明るい黄緑（light lime green）と明るい灰色（light gray）の比率が高く、プロトタイプ感が残っていた。
* **改善**: Aether Crownの公式ビジュアルディレクションに厳密に適合させた重厚なプロシージャルPBRパレットへ刷新：
  * **`terrain_grass_dark`**: 工業地帯の彩度を抑えたダークオリーブグリーン（`rgb(0.06, 0.08, 0.05)`, Roughness 0.92, Metallic 0.02）。
  * **`terrain_dirt_worn`**: 赤錆と油分を含んだ重厚なインダストリアルブラウン土壌（`rgb(0.22, 0.15, 0.08)`, Roughness 0.82, Metallic 0.05）。
  * **`terrain_stone_cliff`**: 無骨で引き締まった玄武岩・チャコール断崖（`rgb(0.08, 0.08, 0.09)`, Roughness 0.92, Metallic 0.10）。
  * **`terrain_industrial_ground`**: 重厚なスラグ砕石・アスファルト造成地盤（`rgb(0.11, 0.11, 0.12)`, Roughness 0.70, Metallic 0.28）。
  * **`terrain_water_ravine`**: 峡谷底の工業廃液・暗緑ヘドロ（`rgb(0.02, 0.04, 0.05)`, Roughness 0.16, Metallic 0.22）。
  * **`terrain_aether_rock`**: 抑制された深いシアンのエーテル鉱脈（`rgb(0.03, 0.12, 0.18)`, Emission `(0.10, 0.35, 0.45)`, Strength 1.5）。

### 4. Cliff Visual Quality & Strata (崖の質感と地層表現)
* 垂直面に対して微細な水平層状ノイズ（horizontal rock strata: `0.18 * sin(h * 1.57)`）を付与し、遠景から見ても「つるんとした壁」ではなく、地層の重なりを感じさせる説得力のある岩崖シルエットを実現。

---

## 3. マップ寸法と標高階層 (Dimensions & Elevation Hierarchy)

### 基本寸法
* **全体サイズ**: 140.0m × 140.0m（Godot X: -70.0m 〜 +70.0m, Z: -70.0m 〜 +70.0m）
* **グリッド解像度**: 1.0m ステップ（141 × 141 グリッド）
* **総頂点数**: **19,881**
* **総三角面数**: **39,200 tris**（Intel Iris Xe 予算 50,000 tris 以下を余裕でクリア）
* **GLBファイルサイズ**: **約 787 KB**

### 標高階層 (Elevation Tiers)
| エリア / 施設パッド | Godot 座標 (X, Z) | 標高 (Y) | 特徴と役割 |
| :--- | :--- | :--- | :--- |
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

## 4. 全14枚の検証スクリーンショット一覧

Godot Showcase シーン（`terrain_foundation_showcase.tscn`）および自動キャプチャスクリプト（`capture_terrain_foundation.gd`）を用いて、1920×1080解像度で全14アングルのスクリーンショットを撮影・検証完了：

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
| **13** | **`13_terrain_only_isometric.png`** | **地形単体アイソメトリック俯瞰** | **建物を非表示にし、純粋な地形ジオメトリとマテリアルだけで戦場構造が読めることを実証。** |
| **14** | **`14_three_routes_top_debug.png`** | **3ルート可読性トップダウン** | **真上視点からPlayer→3ルート（North/Central/South）→Enemyの構造が一目で読めることを実証。** |

---

## 5. 実行検証とログサマリー

* **Blender Generator**: Clean run（Error: 0, Warning: 0）。
* **Godot Reimport**: `aether_crown_terrain_foundation.glb` 正常再インポート完了。
* **Godot Windowed Capture**: Vulkan 1.4.354 Forward+（Intel Iris Xe TGL GT2）にて正常実行。
* **エラー件数**: **ERROR: 0, SCRIPT ERROR: 0**。全14枚のPNGを正常保存。

---

## 6. ファイル構成と成果物パス

* **Blender 生成スクリプト**: [`blender/scripts/make_aether_crown_terrain_foundation.py`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/blender/scripts/make_aether_crown_terrain_foundation.py)
* **Blender ソースファイル**: [`blender/source/aether_crown_terrain_foundation.blend`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/blender/source/aether_crown_terrain_foundation.blend)
* **中間 GLB エクスポート**: [`blender/exports/map/aether_crown_terrain_foundation.glb`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/blender/exports/map/aether_crown_terrain_foundation.glb)
* **ゲーム用 GLB アセット**: [`game/assets/models/map/aether_crown_terrain_foundation.glb`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/game/assets/models/map/aether_crown_terrain_foundation.glb)
* **16-bit Heightmap**: [`blender/exports/map/aether_crown_terrain_heightmap.png`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/blender/exports/map/aether_crown_terrain_heightmap.png)
* **Godot Showcase シーン**: [`game/scenes/showcase/terrain_foundation_showcase.tscn`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/game/scenes/showcase/terrain_foundation_showcase.tscn)
* **Godot Showcase スクリプト**: [`game/scripts/showcase/terrain_foundation_showcase.gd`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/game/scripts/showcase/terrain_foundation_showcase.gd)
* **自動キャプチャスクリプト**: [`game/tests/capture_terrain_foundation.gd`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/game/tests/capture_terrain_foundation.gd)
* **スクリーンショット保存先**: [`docs/screenshots/gemini_terrain_foundation/`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/docs/screenshots/gemini_terrain_foundation/) (全14枚)
* **技術仕様書**: [`docs/gemini_terrain_foundation.md`](file:///home/dma/%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/aether-crown-gemini-terrain/docs/gemini_terrain_foundation.md)
