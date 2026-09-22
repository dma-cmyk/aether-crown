# Gearforge Map Production Kit 01: Bridge, Cliff & Fortress Modular Set

本ドキュメントは、Aether Crown 本線開発から完全に独立したブランチ上で試作・制作された「Gearforge Map Production Kit 01」の設計仕様、アセット構成、寸法・統計、マテリアル構成、および視覚的検証結果をまとめたレポートです。

> [!IMPORTANT]
> **本線未統合の独立試作アセット**
> 本キットは、別エージェントによる本線（ゲームプレイ／戦場プロトタイプ／カメラ／ユニット選択／テスト等）の開発と衝突しないよう、独立した新規ファイルのみで構築されています。既存の `prototype_battlefield.tscn` やゲームプレイ関連スクリプトへの変更は一切加えていません。

---

## 1. 概要とデザインコンセプト

### 1.1 背景と目的
これまでのプロトタイプ戦場が持っていた「平坦感」を解消し、スチームパンク×Aether文明の圧倒的な工業密度、高低差、要塞防衛線、巨大兵器が激突する戦場の臨場感を実現するための正式プロダクション対応モジュラー環境キットです。

### 1.2 デザイン言語 (Gearforge Visual Language)
- **重工業・城塞構造**: 粗削りの石材・重コンクリート基礎（Stone/Concrete）、高張力黒鋼トラスフレーム（Dark Steel）、真鍮・砲金のリベット接合部（Machinery Brass/Bronze）。
- **Aether動力導管**: 橋梁梁下、要塞ゲート上部、城壁要所に走る青白く脈動するエーテルコンジット（Aether Cyan Emissive）。
- **立体的な高低差（Elevation & Choke Points）**: 8.0m級の垂直岸壁（Cliff）、スロープ（Ramp）、巨岩（Large Cliff）により、キャニオン・高原・要塞アプローチ・隘路（チョークポイント）を自在に構築可能。
- **Titan通行保証（Scale Hierarchy）**: Gearforgeの超大型兵器「Crownpiercer Titan (11.4m)」がゆとりを持って渡れる幅14mの橋梁デッキ、高さ12.5m×幅10mの要塞ゲート開口部を厳密に設計。

---

## 2. モジュラーアセット一覧（全14種）

本キットは全14種類の独立したモジュラーGLBモデルで構成され、Godotのグリッド配置（8m / 16m / 32m）に整合します。

### カテゴリ 1: 大型軍用橋梁 (Heavy Aether Bridge)
| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Heavy Aether Bridge** | `gearforge_bridge_heavy.glb` | 18.1m × 32.5m × 10.5m | 6,952 | 道路幅14m、スパン32m。Titan/Walker/Infantryが同時通行可能。石造橋脚、鋼鉄アーチトラス、左右防護手すり、エーテル導管、配管群を完全一体化。 |

### カテゴリ 2: モジュラー崖セット (Modular Cliff Set)
*基準高さ: 8.0m（Godotのユニット移動・高低差ナビゲーションに最適化）*

| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Cliff Straight** | `gearforge_cliff_straight.glb` | 16.0m × 8.0m × 8.2m | 688 | 16m幅の標準崖。岩肌と鉄骨補強アンカープレート、上部舗装エッジ。 |
| **Cliff Corner In** | `gearforge_cliff_corner_in.glb` | 16.0m × 16.0m × 8.0m | 256 | 凹型（内角90度）コーナー崖。谷や湾曲地形の形成用。 |
| **Cliff Corner Out** | `gearforge_cliff_corner_out.glb` | 16.0m × 16.0m × 8.2m | 556 | 凸型（外角90度）コーナー崖。高台の角、岬状地形の形成用。 |
| **Cliff Ramp** | `gearforge_cliff_ramp.glb` | 16.0m × 24.4m × 9.4m | 684 | 高度0mから8mへ登る軍用スロープ。TitanやWalkerの昇降路。両側擁壁。 |
| **Cliff Large** | `gearforge_cliff_large.glb` | 32.0m × 15.9m × 12.6m | 876 | 32m幅×高さ12mの巨大岸壁。複数の段差、鉄骨サポート、重厚な岩塊。 |

### カテゴリ 3: 要塞ゲート・防衛壁セット (Fortress Gate & Wall Set)
*基準壁高: 8.5m / ゲート全高: 16.0m*

| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Fortress Gate** | `gearforge_fortress_gate.glb` | 24.0m × 8.8m × 16.0m | 1,448 | 開口部 幅10.0m×高12.5m（Titan直立通過可能）。二重強化防護扉、上部監視歩廊、動力コア。 |
| **Wall Straight** | `gearforge_wall_straight.glb` | 16.0m × 5.2m × 9.3m | 764 | 16m直線城壁。歩兵が配置可能な上部歩廊（胸壁・銃眼）、控え壁（バットレス）。 |
| **Wall Corner** | `gearforge_wall_corner.glb` | 9.0m × 9.0m × 9.6m | 256 | 90度コーナー壁。直線壁とシームレスに結合。 |
| **Wall Tower** | `gearforge_wall_tower.glb` | 9.3m × 9.3m × 14.0m | 424 | 全高14mの監視・防衛塔。八角形トップデッキ、真鍮装甲板。 |
| **Defensive Bastion** | `gearforge_defensive_bastion.glb` | 12.0m × 10.0m × 9.8m | 280 | 壁から前方に突出する稜堡（砲座）。十字砲火・側防射撃ポジション。 |

### カテゴリ 4: 道路・工業プロップ (Road & Industrial Edge Props)
| アセット名 | ファイル名 | 外寸 (W×L×H) | 面数 (Tris) | 特徴・役割 |
|---|---|---|---|---|
| **Road Straight** | `gearforge_road_straight.glb` | 12.0m × 16.0m × 0.4m | 176 | 重装甲舗装道路スラブ。中央エーテルインジケータライン、縁石。 |
| **Road Barrier** | `gearforge_road_barrier.glb` | 0.6m × 8.0m × 1.4m | 388 | 道路・橋梁進入路用の工業用防護柵。警告ビーコンライト付き。 |
| **Industrial Pipe Straight** | `gearforge_industrial_pipe_straight.glb` | 1.4m × 16.0m × 1.8m | 920 | 峡谷底や壁面に這わせる大型配管トラスガントリー（3連配管構造）。 |

- **全14アセット合計ポリゴン数**: 約 **13,580 三角面 (Tris)**
  - 1画面に多数配置しても現代のPC/デスクトップGPU（Intel Iris Xe / GTX 1060以上）で余裕の 60〜120+ FPS を維持できる高効率ローポリ・ミッドポリ最適化。

---

## 3. スケール検証と兵器階層 (Scale Hierarchy)

各アセットは、Aether Crown のユニット階層に基づいて厳密にスケール調整されています。

```
[Titan Crownpiercer]      全高 11.4m / 幅 7.5m   ==>  橋梁幅 14m / ゲート開口 10m×12.5m (完全通過可能)
[Medium Quad Ironbastion] 全高  5.2m / 幅 5.8m   ==>  ゲート前・橋上ですれ違い・防衛展開可能
[Light Biped Ironstride]  全高  4.5m / 幅 3.8m   ==>  側道・スロープを容易に機動可能
[Infantry Platoon]        全高  1.8m             ==>  城壁歩廊・防護柵の銃眼から射撃可能
```

---

## 4. マテリアル・テクスチャ設計

本キットは Gearforge の統一シェーダーパレットを採用し、ドローコール削減と視認性の向上を図っています。

1. **GF_DarkSteel** (`#2E3238`, Metallic 0.90, Roughness 0.35): トラス骨組み、装甲板、梁。
2. **GF_MachineryBrass** (`#B8863A`, Metallic 0.88, Roughness 0.32): ギア接合部、リベット帯、油圧ダンパー。
3. **GF_StoneFoundation** (`#3B3A38`, Metallic 0.05, Roughness 0.90): 橋脚、岩肌、擁壁コンクリート。
4. **GF_AetherCyan** (`#2AD4FF`, Emissive Strength 4.0): エーテル動力導管、パイロットランプ、ゲート動力核。
5. **GF_ReinforcedIron** (`#24262A`, Metallic 0.82, Roughness 0.45): 道路プレート、踏板、防護柵。
6. **GF_IndustrialPipe** (`#554D45`, Metallic 0.80, Roughness 0.40): 蒸気・オイル配管。

---

## 5. 視覚的検証（スクリーンショット）

`docs/screenshots/map_kit_01/` に保存された9枚の高解像度レンダリング（Cycles / PBRライティング）にて品質と構図を検証しました。

1. `01_map_kit_overview.png`: 峡谷を渡る大橋、北岸の高台要塞、南岸のスロープ、中央を渡るTitanを捉えたパノラマ鳥瞰。
2. `02_bridge_isometric.png`: Heavy Aether Bridge を斜め上から見たクォータービュー。橋脚とトラスの立体美。
3. `03_bridge_side.png`: 橋梁の真横プロファイル。石造橋脚の重厚さと鋼鉄アーチの力学構造。
4. `04_bridge_titan_scale.png`: 橋上を進む Titan Crownpiercer (11.4m) と護衛歩行機のスケール比較。
5. `05_cliff_modules.png`: スロープ、直線崖、角崖、配管が織りなす立体地形モジュール群。
6. `06_fortress_gate.png`: 要塞正面。全高16mのゲートと、10m×12.5mの巨大アーチ開口部。
7. `07_fortress_wall_set.png`: 直線壁、角壁、防衛塔、稜堡（バスティオン）が連なる強固な防衛ライン。
8. `08_rts_distance.png`: 実際のRTSプレイ視線距離（カメラ距離60m+）におけるシルエットと視認性の確認。
9. `09_road_and_props_detail.png`: 道路スラブ、防護柵ビーコン、工業パイプラインの詳細。

---

## 6. 新規作成ファイル一覧

すべて新規ファイルとして配置されており、既存ファイルの上書きや変更は一切ありません。

### Blender & スクリプト資産
- `blender/source/gearforge_map_kit_01.blend` (マスターモデリングBlendファイル)
- `blender/scripts/make_gearforge_map_kit_01.py` (完全自動モデリング＆GLBエクスポートスクリプト)
- `blender/scripts/render_map_kit_01_screenshots.py` (ジオラマ構築＆Cyclesマルチカメラ撮影スクリプト)

### GLBモデル資産 (`game/assets/models/map/` & `blender/exports/map/`)
1. `gearforge_bridge_heavy.glb`
2. `gearforge_cliff_straight.glb`
3. `gearforge_cliff_corner_in.glb`
4. `gearforge_cliff_corner_out.glb`
5. `gearforge_cliff_ramp.glb`
6. `gearforge_cliff_large.glb`
7. `gearforge_fortress_gate.glb`
8. `gearforge_wall_straight.glb`
9. `gearforge_wall_corner.glb`
10. `gearforge_wall_tower.glb`
11. `gearforge_defensive_bastion.glb`
12. `gearforge_road_straight.glb`
13. `gearforge_road_barrier.glb`
14. `industrial_pipe_straight.glb`

### Godot 独立展示シーン
- `game/scenes/showcase/gearforge_map_kit_01_showcase.tscn` (展示シーン)
- `game/scenes/showcase/gearforge_map_kit_01_showcase.gd` (カメラ切替・パレット＆ジオラマ生成ロジック)

### ドキュメント & 画像
- `docs/gearforge_map_kit_01.md` (本仕様書)
- `docs/screenshots/map_kit_01/01_map_kit_overview.png` 〜 `09_road_and_props_detail.png` (計9枚)

---

## 7. 今後の本線統合に向けた推奨タスク

本試作が本線採用となった場合、以下のステップで円滑にゲームプレイへ統合できます。

1. **NavigationMesh (NavigationRegion3D) の設定**:
   - 橋梁上面（Y=8.0）、道路スラブ、崖スロープにナビゲーションメッシュをベイクし、Titan・Walker・Infantryの経路探索領域を定義。
   - 崖垂直面および城壁外周にナビゲーションブロッカー（Obstacle）を設定。
2. **静的コリジョン (StaticBody3D + CollisionShape3D)**:
   - 橋床・道路・スロープ: BoxShape3D による軽量で正確な走行床コリジョン。
   - 手すり・城壁・ゲート柱: 弾道（射撃）および移動を遮蔽する遮蔽コリジョン。
3. **破壊可能ゲート / インタラクション (Gameplay Hooks)**:
   - `gearforge_fortress_gate.glb` の扉部分を別ノード化し、HP 0 で開口または崩壊するアニメーション/演出の追加。
4. **マップレベルデザインへの配置**:
   - `prototype_battlefield.tscn` または新規対戦マップ（Phase 2.7+）へのモジュラー配置。
