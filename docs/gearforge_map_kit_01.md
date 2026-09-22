# Gearforge Map Production Kit 01: Bridge, Cliff & Fortress Modular Set (Polished Edition)

本ドキュメントは、Aether Crown 本線開発から完全に独立したブランチ上で制作・ブラッシュアップされた「Gearforge Map Production Kit 01」の設計仕様、アセット構成、寸法・統計、マテリアル構成、および視覚的検証結果をまとめたレポートです。

> [!IMPORTANT]
> **本線未統合の独立試作・モジュラー環境アセット**
> 本キットは、別エージェントによる本線（ゲームプレイ／戦場プロトタイプ／カメラ／ユニット選択／テスト等）の開発と衝突しないよう、独立した新規ファイルのみで構築されています。既存の `prototype_battlefield.tscn` やゲームプレイ関連スクリプトへの変更は一切加えていません。

---

## 1. 概要とデザインコンセプト

### 1.1 背景と目的
これまでのプロトタイプ戦場が持っていた「平坦感」を解消し、スチームパンク×Aether文明の圧倒的な工業密度、高低差、要塞防衛線、巨大兵器が激突する戦場の臨場感を実現するための正式プロダクション対応モジュラー環境キットです。

### 1.2 デザイン言語 (Gearforge Visual Language)
- **重工業・城塞構造**: 粗削りの石材・重コンクリート基礎（Stone/Concrete）、高張力黒鋼トラスフレーム（Dark Steel）、真鍮・砲金のリベット接合部（Machinery Brass/Bronze）。
- **Aether動力導管 & 水路**: 橋梁梁下、要塞ゲート上部、城壁要所に走る青白く脈動するエーテルコンジット（Aether Cyan Emissive）、およびキャニオン底の軍用水路。
- **立体的な高低差（Elevation & Choke Points）**: 8.0m級の垂直岸壁（Cliff）、スロープ（Ramp）、巨岩（Large Cliff）、そして掘削軍用塹壕（Industrial Trench）により、キャニオン・高原・要塞アプローチ・隘路（チョークポイント）を自在に構築可能。
- **Titan通行保証と兵器スケール階層（Scale Hierarchy）**: Gearforgeの超大型兵器「Crownpiercer Titan (11.4m)」がゆとりを持って渡れる幅14mの橋梁デッキ、高さ12.5m×幅10mの要塞ゲート開口部を厳密に設計。

### 1.3 前版からの主要ブラッシュアップ内容
1. **Fortress Gate の要塞感強化**:
   - 全高を 16.0m から **21.0m** へ大幅拡大。Titan（11.4m）を見下ろす圧倒的な威容を確立。
   - 傾斜型重装甲バットレス（控え壁）および外装リベット装甲板の追加。
   - 左右門柱への大型油圧昇降ラムピストン（Hydraulic Rams）および重装甲マウント。
   - 上部アーチリブ帯と斜めクロスブレース付き落とし格子（Portcullis）。
   - 中央最上部に八角形指令室キューポラ（Command Cupola）、エーテルスリットバイザー、真鍮ドーム屋根、双発スチーム排気筒（Twin Steam Exhaust Stacks）。
   - 巨大真鍮スパーギア付きウインチドラムおよび中央エーテル動力レギュレータコア。
2. **Bridge の工業ディテール強化**:
   - 橋脚（Piers）に重装甲鋳鉄バンド（Lower/Upper Bands）、垂直補強リブ、真鍮締結ボルト、蒸気配管バルブ機構を追加。
   - 橋脚間中央スパン下にアーチタイビームおよびV字型斜材ストラット（Under-bridge Arch Trusses）とガセットプレートを追加。
   - 橋床路面に Titan 進軍用の埋め込みエーテルパワーレール（Twin glowing cyan power rails）と真鍮集電接触帯を追加。
   - 左右両側に歩兵用外装張り出しキャットウォーク（Cantilever Inspection Catwalks）と片持ち梁サポートアームを追加。
3. **Trench & Ravine の新設 (`gearforge_trench_industrial.glb`)**:
   - 橋梁下やキャニオン底の掘削塹壕・防衛用水路モジュールを新設。
   - 垂直鋼製矢板（Steel Sheet Piling）、補強H鋼リブ、エーテル水路（Aether Waterway）、点検歩廊、配管群を完全一体化。
4. **Wall & Watchtower の強化**:
   - 直線城壁の外側に大型傾斜バットレス3基および真鍮装甲帯トリムを追加。
   - 監視塔（Watchtower）の全高を 14.0m から **16.5m**（アンテナ頂上17.5m）へ延伸し、真鍮円錐キューポラ屋根、高利得エーテルアンテナマストを追加。
5. **RTS視認性（Readability）とマテリアルの洗練**:
   - 石材マテリアル（`gearforge_stone_map`）の明度を調整し、直射日光下での白飛びを抑制。
   - RTSプレイ視点距離（65m+）でも暗鉄フレーム・真鍮エッジ・青白発光ラインが明瞭なシルエットを形成。

---

## 2. モジュラーアセット一覧（全15種）

本キットは全15種類の独立したモジュラーGLBモデルで構成され、Godotのグリッド配置（8m / 16m / 32m）に整合します。

### カテゴリ 1: 大型軍用橋梁 (Heavy Aether Bridge)
| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Heavy Aether Bridge** | `gearforge_bridge_heavy.glb` | 18.1m × 32.5m × 10.5m | 9,528 | 道路幅14m、スパン32m。Titan/Walker/Infantry同時通行可能。石造橋脚、鋼鉄アーチトラス、左右キャットウォーク、埋め込みエーテル給電レール、配管バルブ機構を完全一体化。 |

### カテゴリ 2: モジュラー崖・掘削塹壕セット (Modular Cliff & Trench Set)
*基準高さ: 8.0m / 塹壕深度: 6.0m*

| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Cliff Straight** | `gearforge_cliff_straight.glb` | 16.0m × 8.0m × 8.2m | 1,068 | 16m幅の標準崖。岩肌、鉄骨補強アンカープレート、上部舗装エッジ、リベット補強。 |
| **Cliff Corner In** | `gearforge_cliff_corner_in.glb` | 16.0m × 16.0m × 8.0m | 256 | 凹型（内角90度）コーナー崖。谷や湾曲地形の形成用。 |
| **Cliff Corner Out** | `gearforge_cliff_corner_out.glb` | 16.0m × 16.0m × 8.2m | 556 | 凸型（外角90度）コーナー崖。高台の角、岬状地形の形成用。 |
| **Cliff Ramp** | `gearforge_cliff_ramp.glb` | 16.0m × 24.4m × 9.4m | 684 | 高度0mから8mへ登る軍用スロープ。TitanやWalkerの昇降路。両側擁壁。 |
| **Cliff Large** | `gearforge_cliff_large.glb` | 32.0m × 15.9m × 12.6m | 876 | 32m幅×高さ12mの巨大岸壁。複数の段差、鉄骨サポート、重厚な岩塊。 |
| **Industrial Trench** | `gearforge_trench_industrial.glb` | 16.0m × 12.0m × 6.0m | 2,408 | 橋梁下・キャニオン底の掘削軍用モート／運河。鋼製矢板壁、エーテル水路、点検歩廊、パイプライン。 |

### カテゴリ 3: 要塞ゲート・防衛壁セット (Fortress Gate & Wall Set)
*基準壁高: 8.5m / ゲート全高: 21.0m / 塔全高: 16.5m*

| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Fortress Gate** | `gearforge_fortress_gate.glb` | 24.0m × 8.8m × 21.0m | 3,176 | 開口部 幅10.0m×高12.5m（Titan直立通過可能）。重装甲傾斜バットレス、油圧昇降ラム、八角形指令室キューポラ、双発蒸気煙突、巨大ウインチスパーギア、動力コア。 |
| **Wall Straight** | `gearforge_wall_straight.glb` | 16.0m × 6.6m × 9.3m | 1,072 | 16m直線城壁。歩兵歩廊（胸壁・銃眼）、外装傾斜バットレス3基、真鍮装甲帯トリム。 |
| **Wall Corner** | `gearforge_wall_corner.glb` | 9.0m × 9.0m × 9.6m | 256 | 90度コーナー壁。直線壁とシームレスに結合。 |
| **Wall Tower** | `gearforge_wall_tower.glb` | 9.3m × 9.3m × 17.5m | 556 | 全高16.5m（アンテナ頂上17.5m）の監視・防衛塔。キューポラベース、真鍮円錐屋根、高利得通信アンテナマスト、サーチライトポッド。 |
| **Defensive Bastion** | `gearforge_defensive_bastion.glb` | 12.0m × 10.0m × 9.8m | 280 | 壁から前方に突出する稜堡（砲座）。十字砲火・側防射撃ポジション。 |

### カテゴリ 4: 道路・工業プロップ (Road & Industrial Edge Props)
| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Road Straight** | `gearforge_road_straight.glb` | 12.0m × 16.0m × 0.4m | 176 | 重装甲舗装道路スラブ。中央エーテルインジケータライン、縁石。 |
| **Road Barrier** | `gearforge_road_barrier.glb` | 0.6m × 8.0m × 1.4m | 388 | 道路・橋梁進入路用の工業用防護柵。警告ビーコンライト付き。 |
| **Industrial Pipe Straight** | `gearforge_industrial_pipe_straight.glb` | 1.4m × 16.0m × 1.8m | 920 | 峡谷底や壁面に這わせる大型配管トラスガントリー（3連配管構造）。 |

- **全15アセット合計ポリゴン数**: 約 **22,198 三角面 (Tris)**
  - 1アセットあたり平均約1,480面。ディテール密度を大幅に向上させつつ、RTS画面で多数配置しても 60〜120+ FPS を余裕で維持できる理想的なバジェットです。

---

## 3. スケール検証と兵器階層 (Scale Hierarchy)

各アセットは、Aether Crown のユニット階層に基づいて厳密にスケール調整されています。

```
[Fortress Gate Opening]   幅 10.0m × 高さ 12.5m (全高 21.0m)
  └─ [Titan Crownpiercer] 全高 11.4m / 幅 7.5m  ==> 直立状態で余裕の通過可能（クリアランス 1.1m）
[Bridge Roadway Deck]     幅 14.0m (全幅 18.1m)
  ├─ [Titan Crownpiercer] 全高 11.4m / 幅 7.5m  ==> 中央エーテル給電レール沿いに堂々進軍
  ├─ [Medium Quad-Walker] 全高  5.2m / 幅 5.8m  ==> 橋上・ゲート前ですれ違い・防衛展開可能
  ├─ [Light Biped Walker] 全高  4.5m / 幅 3.8m  ==> 側道・スロープを容易に機動可能
  └─ [Infantry Platoon]   全高  1.8m            ==> 左右外装キャットウォーク・城壁銃眼から射撃可能
```

---

## 4. マテリアル・テクスチャ設計

本キットは Gearforge の統一シェーダーパレットを採用し、ドローコール削減と視認性の向上を図っています。

1. **GF_DarkSteel** (`#2E3238`, Metallic 0.90, Roughness 0.35): トラス骨組み、装甲板、梁。
2. **GF_MachineryBrass** (`#B8863A`, Metallic 0.88, Roughness 0.32): ギア接合部、リベット帯、油圧ダンパー、ウインチギア、キューポラ屋根。
3. **GF_StoneFoundation (stone_map)** (`#474542` / `(0.28, 0.27, 0.26)`, Metallic 0.08, Roughness 0.88): 橋脚、岩肌、擁壁コンクリート。直射日光での白飛びを抑え、コントラストを最適化。
4. **GF_AetherCyan** (`#2AD4FF`, Emissive Strength 4.0): エーテル動力導管、パイロットランプ、ゲート動力核、路面給電レール、塹壕底水路。
5. **GF_ReinforcedIron** (`#24262A`, Metallic 0.82, Roughness 0.45): 道路プレート、踏板、防護柵、矢板壁。
6. **GF_IndustrialPipe** (`#554D45`, Metallic 0.80, Roughness 0.40): 蒸気・オイル配管、油圧シリンダー。

---

## 5. 視覚的検証（スクリーンショット一覧）

`docs/screenshots/map_kit_01/` に保存された9枚の高解像度レンダリング（Cycles / PBRライティング）にて品質と構図を検証しました。

1. `01_map_kit_overview.png`: 峡谷を渡る大橋、北岸の要塞防衛線、掘削軍用トレンチ、中央を進軍する Titan Crownpiercer を捉えたパノラマ鳥瞰。
2. `02_fortress_gate_front.png`: 全高21m Fortress Gate の斜め正面。傾斜バットレス、銃眼、サーチライト、巨大ウインチスパーギア、指令室キューポラ、蒸気煙突、そしてゲート前に展開する Quad-Walker を捉えた威容。
3. `03_bridge_roadway.png`: 幅14mの橋梁デッキ上空からの眺望。床板リブ、青白く光るエーテル給電レール、左右のキャットウォーク、進軍する Titan と護衛 Walker。
4. `04_bridge_side.png`: 橋梁の真横プロファイル。石造橋脚の装甲バンド、トラスアーチ構造、スチーム配管バルブ機構、橋下を横切る掘削塹壕。
5. `05_trench_ravine.png`: 橋梁下を走る Industrial Trench のクローズアップ。鋼製矢板、配管、エーテル水路。
6. `06_scale_hierarchy.png`: 11.4m Titan Crownpiercer、5.2m Quad-Walker Ironbastion、4.5m Walker Ironstride のスケール階層比較。
7. `07_fortress_approach.png`: 橋梁を渡りながらそびえ立つ21mの要塞ゲートを見上げるローアングル・タクティカルビュー。
8. `08_rts_distance.png`: 実際のRTSゲームプレイ視線距離（カメラ距離65m+）におけるシルエットと視認性の検証。高コントラストな明暗と発光ラインによりユニットと地形が明瞭に分離。
9. `09_road_and_props_detail.png`: 道路スラブ、警告ビーコン付き防護柵、擁壁スロープ、配管ガントリーの詳細。

---

## 6. 作成・更新ファイル一覧

### Blender & スクリプト資産
- `blender/source/gearforge_map_kit_01.blend` (マスターモデリングBlendファイル - 15オブジェクト配置済み)
- `blender/scripts/make_gearforge_map_kit_01.py` (完全自動モデリング＆GLBエクスポートスクリプト)
- `blender/scripts/render_map_kit_01_screenshots.py` (ジオラマ構築＆Cycles 9アングル撮影スクリプト)

### GLBモデル資産 (`game/assets/models/map/` & `blender/exports/map/`)
1. `gearforge_bridge_heavy.glb` (9,528 tris)
2. `gearforge_cliff_straight.glb` (1,068 tris)
3. `gearforge_cliff_corner_in.glb` (256 tris)
4. `gearforge_cliff_corner_out.glb` (556 tris)
5. `gearforge_cliff_ramp.glb` (684 tris)
6. `gearforge_cliff_large.glb` (876 tris)
7. `gearforge_trench_industrial.glb` (2,408 tris) - **NEW**
8. `gearforge_fortress_gate.glb` (3,176 tris)
9. `gearforge_wall_straight.glb` (1,072 tris)
10. `gearforge_wall_corner.glb` (256 tris)
11. `gearforge_wall_tower.glb` (556 tris)
12. `gearforge_defensive_bastion.glb` (280 tris)
13. `gearforge_road_straight.glb` (176 tris)
14. `gearforge_road_barrier.glb` (388 tris)
15. `gearforge_industrial_pipe_straight.glb` (920 tris)

### Godot 独立展示シーン
- `game/scenes/showcase/gearforge_map_kit_01_showcase.tscn` (展示シーン - 15アセット・約22k tris対応)
- `game/scenes/showcase/gearforge_map_kit_01_showcase.gd` (カメラ切替・パレット＆ジオラマ生成ロジック)

### ドキュメント & 画像
- `docs/gearforge_map_kit_01.md` (本仕様書)
- `docs/screenshots/map_kit_01/01_map_kit_overview.png` 〜 `09_road_and_props_detail.png` (計9枚)

---

## 7. 今後の本線統合に向けた推奨タスク

1. **NavigationMesh (NavigationRegion3D) の設定**:
   - 橋梁上面（Y=8.0）、道路スラブ、崖スロープにナビゲーションメッシュをベイク。
   - 塹壕底および城壁外周にナビゲーションブロッカーを設定。
2. **静的コリジョン (StaticBody3D + CollisionShape3D)**:
   - 橋床・道路・スロープ: BoxShape3D による正確な走行床コリジョン。
   - ゲート柱・胸壁・トラス: 射撃および視線を遮蔽する遮蔽コリジョン。
3. **破壊可能ゲート / インタラクション (Gameplay Hooks)**:
   - `gearforge_fortress_gate.glb` の落とし格子（Portcullis）部分を別ノード化し、昇降・破壊アニメーションを接続。
4. **マップレベルデザインへの配置**:
   - `prototype_battlefield.tscn` または新規対戦マップへのモジュラー配置。
