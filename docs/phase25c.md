# Phase 2.5C — Gearforge Airship Production Asset

最終更新: 2026-09-22
目的: Gearforge Airship 1機を、Titan Crownpiercer と並ぶ Aether Crown の
もう1つの「顔」として Production Asset 化する。

## Airship 仕様

- 採用案: Variant C / Twin-Cell Aether Dreadnought
- 固有名: **Crownhammer**
- 役割: 制空しながら地上を叩く空中砲台。Titan が押し込む正面を上から割る。
- 主兵装: Belly Aether Siege Mortar
- 副兵装: Broadside Sponson Turret ×4
- 寸法: 14.206m W × 35.450m D × 11.379m H
- 識別形状: 2本の Aether lift cell、中央装甲 keel hull、装甲 ram prow、
  連続する下面 girder、H-tail、後部 ducted propeller ×2
- 背面: H-tail、duct ring、cyan thruster ×2、orange 炉口

## 制作方針

- Blender Python から完全再生成可能。`.blend` と生成 script の両方を正本とする。
- Phase 1.75 版の local material (canvas / wood) を廃止し、Titan と同じ
  `blender/scripts/material_lib.py` の共有 palette に統一する。
- 分節 → 階層 → 因果の順で作る。tertiary detail より
  「何で浮き、何で飛び、何で撃つか」が形から読めることを優先する。
- texture 0 で成立させる。geometry + shared PBR + emissive のみ。
- bevel は silhouette と面分けに必要な装甲・砲身・フレームに限定する。

## Scale

| 対象 | 寸法 |
|---|---|
| Infantry | 1.8m |
| Building | 4m グリッド / 高さ 約10m |
| Titan Crownpiercer | 11.39m H |
| Airship Crownhammer | 35.45m L × 14.21m W × 11.38m H |

Titan と同じ「高さクラス」を保ち、長さで約3.1倍の体積感を出す。
画面を覆わないよう全高は Titan +0.01m に抑えた。

## Visual hierarchy

| 階層 | 要素 | 見える距離 |
|---|---|---|
| Primary | 2本の lift cell / keel hull / ram prow / H-tail / 下面の塊 | strategic |
| Secondary | ring frame / stringer / ducted engine / belly mortar / sponson / gondola / reactor / cyan slit | mid |
| Tertiary | valve / 手すり / 細い pipe / vent / muzzle lens | close |

## Aether energy flow

`dorsal reactor` → `injector trunk → lift cell` (浮力) /
`keel conduit 前方 → belly mortar` (火力) / `keel conduit 後方 → tail thruster` (推進)。

cyan はこの経路と bridge slit / bow lens / fin mark / flank chevron に限定。
orange は炉口のみ。装甲面には発光を置かない。

## 成果物

| 種別 | パス |
|---|---|
| 生成 script | `blender/scripts/make_gearforge_airship.py` |
| Blender 正本 | `blender/source/gearforge_airship.blend` |
| Godot GLB | `game/assets/models/gearforge_airship.glb` |
| showcase | `game/scenes/maps/phase25c_airship_showcase.tscn` / `.gd` |
| test | `game/tests/phase25c_test.gd` |
| design | `docs/art/airship_design.md` |
| handoff | `docs/art/airship_muse_handoff.md` |
| screenshots | `docs/screenshots/phase25c/` (9枚) |

## 数値

Blender vertices 7,702 / polygons 6,908 / triangles 14,500 / mesh 8 / material 8 / texture 0。
GLB 1,003,660 bytes。

## 受け入れ条件

- `phase25c_test` が mesh 8 / anchor 12 / bounds を検証して OK。
- 既存の `phase25a` / `phase25b` / `phase25b1` / `visual_slice` / `phase2d` が PASS。
- ERROR 0 / SCRIPT ERROR 0。
- Intel Iris Xe で sustained 30 FPS 未満なし。

## 本 Phase でやらないこと

- Titan Crownpiercer の変更
- Building Set 量産 / Airship 派生機量産
- gameplay balance / AI / HUD の変更
- LOD1 / LOD2、animation rig、独自 texture
