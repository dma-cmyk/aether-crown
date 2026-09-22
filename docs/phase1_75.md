# Phase 1.75 記録 (Visual Vertical Slice)

目的: 最終的な Aether Crown のビジュアル方向性が Godot + Intel Iris Xe で
現実的に成立するかを確認する。ゲームシステムの追加はしない。
Phase 1.5 (`phase1_5_match`) は gameplay 安定基準として無改変で残す。

## 実装内容

- 新規独立シーン `res://scenes/maps/visual_slice.tscn` (+ `scripts/visual/visual_slice.gd`)
  - Phase 1 の Camera / Selection / Order / MapNav / Unit 戦闘をそのまま再利用
  - Visual 固有処理は `scripts/visual/` + `scripts/fx/visual_fx.gd` に分離
- Gearforge 蒸気都市 1区画 (青系 faction color)
  - Blender GLB: `gearforge_civic_hall` (中央議事堂 12x10m, 時計塔〜11m, 発光ダイヤル/旗)
  - Blender GLB: `gearforge_boiler_house` x2 (工業棟 + 9m煙突, 炉口発光, 配管, ランプ)
  - Godot primitive: 舗装, 道路 (都市→敵陣), 木箱/樽/機械, 街灯 (暖色発光), 敵陣 (赤旗/バリケード/篝火)
- 歩兵 15体 (8青 vs 7赤): 既存 Infantry / Marksman / Heavy Guard を活用
  - 内訳 P: inf x4, mar x2, hev x2 / E: inf x4, mar x2, hev x1
  - faction color / 選択リング / HPバー / 移動 / 戦闘は既存 rereadable のまま
- 巨大兵器 1体 (`scripts/visual/visual_titan.gd`, HP 1500, 高さ〜10m)
  - Blender GLB `gearforge_titan`: 機械脚 / 船体 / ボイラー / 煙突 / -Z 主砲 / 側面副砲 / 青発光装甲
  - 軽量実装のみ: 2点低速パトロール, 3.2秒毎の主砲撃 (射程30m, AoE r=4m, 90dmg)
  - muzzle FX + TitanShell (tracer弾) + 着弾爆発。複雑AIなし。選択/被弾/HP表示あり
- 飛行船 1体 (`scripts/visual/visual_airship.gd`, 高度19m)
  - Blender GLB `gearforge_airship`: 気嚢9m / 発光帯 / 尾翼 / ゴンドラ / プロペラ / 竜骨砲
  - 円軌道低速巡航 + 上下動 + 6秒毎の軽爆撃 (35dmg)。航空AIなし。影OFF
- VFX (`scripts/fx/visual_fx.gd`, class VisualFX)
  - muzzle flash / tracer (infantry) / projectile (TitanShell) / hit / explosion (大小) /
    steam vent / smoke vent (煙突ループ) / death
  - 上限制御: one-shot同時80, ループvent同時12, 短lifetime, 自動解放, 全FX影OFF
- World/Lighting (Visual Slice専用)
  - ProceduralSky + Environment (ACES, 露光1.05, 密度0.008のfog)
  - DirectionalLight 1.2 + 影ON (shadow距離80m)。glow/SSAO等の重いPPなし
  - 影を落とすのは hall/boiler/titan のみ。小物・FX・飛行船は影OFF
- HUD (`scenes/ui/visual_slice_hud.tscn` + `scripts/ui/visual_slice_hud.gd`)
  - Material (デモ加算+2/s) / Pop (青生存数/40) / 選択情報 (titan対応) /
    コマンドボタン (中央へattack-move / ホールド) / GEARFORGE帯 /
    FPS + Units + live FX/vent数
- 自動テスト `tests/visual_slice_test.gd` (headless): 都市/15体/titan/飛行船/
  配線/戦闘FX発生を確認。終了前にFxRoot解放でRIDリーク回避

## 作ったアセット (Blender 5.2.2 LTS, CLI再生成可能)

| GLB (game/assets/models/) | 生成スクリプト | .blend | 規格 |
|---|---|---|---|
| gearforge_civic_hall.glb (45KB) | blender/scripts/make_gearforge_hall.py | blender/source/gearforge_civic_hall.blend | Metric, -Z/+Y, 原点接地中心, snake_case, Principled BSDFのみ |
| gearforge_boiler_house.glb (42KB) | blender/scripts/make_gearforge_boiler.py | blender/source/gearforge_boiler_house.blend | 同上 |
| gearforge_titan.glb (58KB) | blender/scripts/make_gearforge_titan.py | blender/source/gearforge_titan.blend | 同上 + `muzzle` 空オブジェクト (砲口FX基点) |
| gearforge_airship.glb (130KB) | blender/scripts/make_gearforge_airship.py | blender/source/gearforge_airship.blend | 同上。原点のみゴンドラ中心 (飛行物の例外、スクリプト内注記) |

全て `blender --background --python` で再生成→ `blender/exports/` (gitignore中間物)
→ `game/assets/models/` に配置 → `godot --headless --path game --import`。
`blender/exports/*.glb` は追跡しない。巨大生成物なし (合計260KB)。

## Visual Slice 構成

```
VisualSlice (visual_slice.gd)
├ WorldEnvironment (Sky/ACES/fog)
├ Sun (影ON, 距離80m)
├ CameraRig (Phase 1 camera再利用)
├ MapNav (Phase 1 地面/nav再利用) + GroundRoot
├ CityRoot (GLB x3 + 舗装/道路/小物/街灯/敵陣)
├ UnitsRoot (歩兵15 + VisualTitan + VisualAirship)
├ FxRoot ("visual_fx_root" group, steam/smoke x4 vents)
├ SelectionManager / OrderManager (Phase 1再利用)
└ HUD (visual_slice_hud)
```

起動直後に両軍へ中央へのattack-moveを発行し、操作なしでも交戦・Titan砲撃・
爆撃が読める。Titanは `rts_buildings` groupにも属し歩兵の索敵対象になる。

## FPS結果 (Intel Iris Xe, TigerLake-LP GT2, Forward+, 1280x720, 描画あり)

1500フレーム実走 (`--quit-after 1500`):

| 時刻 | FPS | 状態 |
|---|---|---|
| t=5s | 32〜45 | 開戦・Titan砲撃開始 (fx 27〜31) |
| t=10s | 29〜34 | 激戦 (爆発多発。最低29を1回記録) |
| t=15s | 33 | 敵掃討完了 |
| t=20s | 55 | 戦闘終了直後 (ばらつき大) |
| t=25〜40s | 31〜35 | 都市+Titan+飛行船+vent待機 (fx 0) |

- 通常FPS: 32〜45 (都市待機時 31〜35)
- 戦闘時最低FPS: 29 (一瞬。概ね30以上を維持)
- 目標 (通常40前後 / 戦闘時30継続割らない) に対し概ね達成だが余裕なし
- 参考: 同条件の phase1_5_match は 36/28 (Phase 1記録の傾向と一致)

## 使用した主要描画機能

- Forward Plus, MSAA 3D 2x (project.godot既定)
- ProceduralSkyMaterial Sky + Environment ambient (sky source)
- ACES tonemap, exponential fog (sky affect 0.4)
- DirectionalLight shadow (max distance 80m)
- GLB PBR (Principled BSDF → BaseColor/Metallic/Roughness/Emissive)
- GPUParticles3D (burst: 6〜26個/回、vent: 10〜14個ループ)
- Unshaded emissive tracer/flash (遠距離の戦闘可読性用)
- Billboard HPバー/選択リング (既存流用)

## パフォーマンス上の問題

1. 待機都市だけでも31〜35 FPS (fx=0時)。base scene costが支配的で、
   particleは主因ではない (激戦時も29〜34で大差なし)
2. 候補: 影 (全域80m + hall/boiler/titan caster) / MSAA 2x / sky+fog /
   draw call数 (CityRoot 48子 + GLB内30超メッシュ + マテリアル切替) /
   街灯・小物の非影メッシュも頂点処理は残る
3. t=20s の55 FPSは外れ値気味で、ウィンドウフォーカス・シェーダ温まり・
   vsync絡みのばらつきとみられる。固定条件の計測ハーネスがない
4. Titan GLBは60KB未満だがメッシュ分割が細かく、マテリアル数が多い
   (真鍮/鉄/銅/発光x2)。RTS距離では過剰な分割

## Phase 2で注意すべき点

- 影: casterを重要物のみに限定済だが、distance 80mは広い。40〜60mへ短縮検討
- MSAA 2x の実コストをValidate (project既定。Iris Xeでは要測定)
- 都市GLBはマテリアル統合・メッシュ結合でdraw call削減 (現状は部品ばら)
- Titanは遠景LOD (`_lod1`) を命名規則どおり追加する (model_rules準拠)
- Ventは12上限だが常時4本稼働。都市拡大時は本数×amount予算を先に決める
- 透明・billboard多用は避け済。爆発の重ね回数に上限があることを維持する
- FPS計測はHUD+VISUAL_PERFログのみ。専用profilingは作らない方針を維持し、
  必要なら `--quit-after` 実走ログで比較する

## テスト結果

| テスト | 結果 |
|---|---|
| godot --headless --path game --import | PASS (ERROR 0) |
| tests/cli_smoke.gd | PASS |
| tests/skirmish_test.gd (Phase 1) | PASS |
| tests/camera_test.gd (Phase 1) | PASS |
| tests/phase1_5_test.gd (Phase 1.5) | PASS (全16項目 OK) |
| tests/phase1_5_playtest.gd player-win | PASS (4:58 sim, won=true) |
| phase1_5_match 起動 (headless 120f) | PASS, ERROR 0 |
| tests/visual_slice_test.gd (新規) | PASS (15体/titan/飛行船/都市/FX) |
| visual_slice 起動 (headless 150f) | PASS, ERROR 0 / SCRIPT ERROR 0 |
| visual_slice 描画あり実走 (400f + 1500f) | PASS, クラッシュなし, ERROR 0 |
| phase1_5_match 描画あり実走 (400f) | PASS (36/28 FPS, 回帰なし) |

合格条件: ERROR=0 / SCRIPT ERROR=0 / Phase1回帰PASS / Phase1.5回帰PASS /
Visual Sliceクラッシュなし / 既存Match遊戯可 / FPS測定可 — すべて満たす。

## commit hash

COMMIT: 5aecdd0
