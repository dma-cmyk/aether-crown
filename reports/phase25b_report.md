# Phase 2.5B 完了報告 (Titan Art Direction + Production Asset)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe / RAM 約7.4GB
開始基準: `main` / `origin/main` 71cd142

## 実施内容

- Phase 1.75 / 1.9 Titan と Phase 2.5A の asset / screenshots を visual review
- Gearforge visual language を shape / material / color / motif / scale で定義
- Titan 3案を比較し、Variant B `Crownpiercer / Aether Siege Engine` を採用
- Production LOD0 を Blender Python で制作し、`.blend` 保存と GLB export
- Production GLB を Godot の旧 Titan resource path に安全に置き換え
- 独立 Titan showcase、asset test、自動撮影7構図、Iris Xe benchmark を追加
- 全主要回帰テストを実行

## 使用ツール

- Blender 5.2.2 LTS: modeling、bevel、material assignment、`.blend`、GLB export
- Godot 4.7.2 Forward Plus: import、showcase、screen capture、benchmark、tests
- Material Maker / Krita / GIMP: 未使用
- texture 生成 / bake: 未使用

## Titan 仕様

| 項目 | 結果 |
|---|---|
| 名称 | Gearforge Crownpiercer |
| design | Aether Siege Engine |
| dimensions | 7.761m W × 9.645m D × 11.390m H |
| vertices | 5,408 |
| Blender polygons | 5,228 |
| triangles | 10,392 |
| mesh | 8 |
| material | 8 |
| texture | 0 |
| GLB size | 719,656 bytes |

Blender polygon 数は依頼目安 2,500–6,000 内。triangle 数は `model_rules.md` の巨大ユニット
8,000–25,000 tris 内。生成時は多数の modular part に分け、export 前に共有 material 単位で8 meshへ結合した。

## Visual 結果

- 主要 silhouette: 非対称長砲身、幅広 torso、分離脚、twin stack
- main weapon: shoulder-mounted Crownspike。breech / shroud / cooling rail / barrel / muzzle lens を大形状で分離
- Aether: reactor -> chest governor -> weapon feed -> muzzle の意味ある配線
- back: copper boiler、twin exhaust、reactor ring、cyan chevron
- 歩兵との高さ比約6.3:1。建物と同程度の高さでも移動兵器と読める。
- close / mid / strategic / scale / scene / back / silhouette の7構図で受け入れ基準を満たす。

## Material / texture

- Phase 2.5A 共有 palette の dark iron / steel / brass / bronze / copper / rust /
  Aether glow / furnace glow の8種。
- Principled BSDF のみ。transparent material なし。
- texture 0枚、texture memory 0。「無地だから単純」に見えないよう、bevel highlight、
  metal value contrast、material boundary、限定 emissive で密度を作った。

## Blender / GLB pipeline

```text
blender/scripts/make_gearforge_titan.py
  -> blender/source/gearforge_titan.blend
  -> blender/exports/gearforge_titan.glb
  -> game/assets/models/gearforge_titan.glb
  -> Godot import
```

- metric 1 unit = 1m
- Blender front `-Y`, Godot front `+Z`, origin ground center
- runtime anchors: `muzzle`, `reactor_anchor`, `exhaust_l`, `exhaust_r`
- regeneration/import command: `./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_titan.py`

Blender export は成功。`MeshOptimizer is not available` は Blender の optional export library 通知で、
GLB 生成・Godot import・mesh/anchor 検証に影響なし。

## Godot 統合

- `VisualTitan` が既存 path を preload しているため、GLB 差し替えだけで gameplay 側へ反映。
- `muzzle` 名を維持し、TitanShell / muzzle FX を互換。
- `phase25b_titan_showcase.tscn/.gd`: 独立アートシーン。main scene ・ gameplay logic ・ balance は無改変。
- `phase25b_test.gd`: 8 mesh、4 anchor、6 infantry、2 scale-reference buildings を検証。

## Performance

| 条件 | 結果 |
|---|---:|
| renderer | Forward Plus / Vulkan / Intel Iris Xe |
| viewport | 1920×1008（window decoration 除外） |
| warm-up | 3 sec |
| duration | 15 sec |
| average FPS | 41 |
| minimum FPS | 39 |
| sustained <30 FPS | なし |

別プロセスの benchmark で計測。screen capture の PNG encode / disk write は値から除外。

## Tests

| テスト | 結果 |
|---|---|
| `godot --headless --path game --import` | PASS |
| `tests/phase25b_test.gd` | PASS |
| `tests/visual_slice_test.gd` | PASS（新 Titan + muzzle 互換） |
| `tests/cli_smoke.gd` | PASS |
| `tests/skirmish_test.gd` | PASS |
| `tests/camera_test.gd` | PASS |
| `tests/phase1_5_test.gd` | PASS |
| `tests/phase1_5_playtest.gd` | PASS |
| `tests/phase2a_test.gd` | PASS |
| `tests/phase2b_test.gd` | PASS |
| `tests/phase2c_test.gd` | PASS |
| `tests/phase2d_test.gd` | PASS |
| `tests/phase25a_test.gd` | PASS |

ERROR: 0 / SCRIPT ERROR: 0。

## Screenshots

`docs/screenshots/phase25b/` に 1920×1008 PNG を7枚保存。

- `titan_close.png`
- `titan_mid.png`
- `titan_zoomed_out.png`
- `titan_with_units.png`
- `titan_in_scene.png`
- `titan_back_view.png`
- `titan_silhouette_check.png`

## Known issues

- LOD1/2、rig、walk / recoil animation は未実装。Phase 2.5B の static Production Asset 範囲外。
- 現行 `VisualTitan` collision（radius 2.2m / height 9m）は旧 model 寸法。幅の広い新 LOD0 と完全一致しない。
  gameplay / balance を改変しないため今回は保持。
- Aether emissive は Phase 2.5A 共有値を使うため close で白飛び気味。mid / strategic の識別は良好。
- アニメーション化時は material 結合前の modular part を生成 script から再構築する。

## Muse Spark への引き継ぎ

詳細は `docs/art/titan_muse_handoff.md`。次に Titan を調整する場合は、細部追加ではなく
animation / collision acceptance -> LOD1/2 -> emissive tuning の順。Airship / Building Set / Titan 派生の量産は開始しない。

## Git

- commit message: `feat: implement production titan art foundation`
- branch: `main`
- push / synchronization / clean-tree は完了手順の最後に確認する。
