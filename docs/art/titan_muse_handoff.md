# Gearforge Titan — Muse Spark Handoff

最終更新: 2026-09-22
対象: Phase 2.5B / `gearforge_titan` / **Crownpiercer**
環境: EndeavourOS / Blender 5.2.2 LTS / Godot 4.7.2 / Intel Iris Xe

## 現在の到達点

Production LOD0 の主要デザインと生成パイプラインは完了。

- 採用案: Variant B 「Aether Siege Engine」
- 固有名: Crownpiercer
- 主要 silhouette: 非対称 Crownspike 主砲 / 低い sensor head / 幅広 torso / 双煙突 / 分離脚
- 完了: proportions, main weapon, chest governor, rear reactor, boiler, pipes, exhaust, armor, material 割当
- 完了: Blender source 保存、GLB export、Godot asset 配置・import
- 完了: Godot showcase、7構図撮影、Iris Xe benchmark、全主要 regression
- 未確定: アニメーション用 rig、LOD1/2、独自 texture / decal

## 正本と再生成

- 生成 script: `blender/scripts/make_gearforge_titan.py`
- Blender 正本: `blender/source/gearforge_titan.blend`
- 中間 GLB: `blender/exports/gearforge_titan.glb` (`.gitignore` 対象)
- Godot GLB: `game/assets/models/gearforge_titan.glb`
- runtime 参照: `game/scripts/visual/visual_titan.gd`

再生成と import:

```bash
./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_titan.py
```

## 数値仕様

| 項目 | 現在値 |
|---|---:|
| bounds | 7.761m W × 9.645m D × 11.390m H |
| Blender vertices | 5,408 |
| Blender polygons | 5,228 |
| export triangles | 10,392 |
| mesh | 8 |
| material | 8 |
| texture | 0 |
| GLB | 719,656 bytes |

`polygons` は指定目安 2,500–6,000 内。triangles はリポジトリの巨大ユニット目安
8,000–25,000 tris 内。造形部品は material 単位に結合済みで、GLB の mesh 数は8。

## Component 一覧

### Primary forms

1. 左右の大型接地脚: wide sole / toe armor / heel / ankle axle
2. 回転盤を含む hip deck
3. 台形の幅広 armored torso
4. 左肩の長大な Crownspike siege cannon
5. 右肩から垂れる siege brace arm

### Secondary forms

- shin / thigh armor, knee axle, external copper/brass pistons
- compact sensor head, cyan visor, rangefinder
- chest Aether governor, brass containment ring, front vents
- cannon breech / shroud / barrel / cooling rails / muzzle lens
- rear twin copper boilers, pressure bands, twin exhaust stacks
- rear Aether reactor, copper feed pipes, cyan back chevrons
- deck valves, stack collars, furnace-lit exhaust mouths

## Proportions

- 全高: 11.39m。脚元から hip まで約4.9m、torso 上端約7.7m。
- sensor head 上端: 約9.0m。煙突が11.4mまで伸び、背面の crown silhouette を作る。
- 肩幅: 約7.7m。建物と同程度の高さでも、脚の分離と肩の非対称で移動兵器と読ませる。
- 主砲先端: front に約6.9m。本体奥行を超える長さを weapon identity に使う。
- 頭部は torso 幅の約30%に抑え、ヒーロー人型ではなく重工業機械として読ませる。

## Material

`blender/scripts/material_lib.py` の共有 palette のみ使用。

- `gearforge_dark_iron`: 骨格・主装甲・砲身
- `gearforge_steel`: 前装甲・shin plate・肩・砲 shroud
- `gearforge_brass`: 輪縁・軸・バンド・収束機構
- `gearforge_bronze`: 砲口・brace teeth・上面装甲
- `gearforge_copper`: piston・pipe・boiler・weapon rail
- `gearforge_rust`: front vent のみ
- `gearforge_aether_glow`: visor / chest / weapon feed / muzzle lens / rear reactor / back chevron
- `gearforge_furnace_glow`: exhaust mouth のみ

texture / alpha / normal map / Material Maker / Krita / GIMP は未使用。

## Aether の意味配置

energy flow は `rear reactor -> chest governor -> weapon feed -> muzzle lens`。cyan はこの経路と
sensor visor / 背面 faction chevron に限定し、面積の大きな armor には使わない。
orange 発光は exhaust 口だけで、Aether と燃焼熱を色で分離している。

## Runtime anchor

| node | Blender 位置 | 用途 |
|---|---|---|
| `muzzle` | (-2.72, -6.92, 7.26) | 現行 TitanShell / muzzle FX |
| `reactor_anchor` | (0, 2.52, 7.12) | 将来の reactor pulse / damage FX |
| `exhaust_l` | (-1.18, 1.40, 11.45) | 将来の steam/smoke |
| `exhaust_r` | (1.18, 1.40, 11.45) | 将来の steam/smoke |

front は Blender `-Y`。Godot では GLB import 後 `+Z` を向き、現行 `VisualTitan`
の `atan2(face.x, face.z)` と一致する。原点は接地中心。

## Optimization / LOD notes

- LOD0 は material ごとに8 mesh。透過なし、texture memory 0。
- シルエットと material boundary を変えない篤囲で、内部の隠れ面は将来削除可。
- LOD1 目標: 4–6 mesh / 4,500–6,000 tris。bevel、rivet、deck valve、vent slit、torus minor segment を削減。
- LOD2 目標: 3–4 mesh / 1,800–2,500 tris。主砲・脚・torso・双煙突・reactor glow だけ残す。
- LOD でも muzzle / exhaust / reactor anchor 名と位置は不変とする。
- rig 化する場合は material 結合前の生成部品単位を script から再構築し、
  hip / thigh / shin / foot / shoulder / brace / cannon に割り当てる。

## Visual acceptance criteria

- quarter-view close: 砲身の前後、sensor、chest core、piston、煙突が判別できる。
- mid zoom: 「長い左砲 / 短い右 brace / 双煙突 / 二脚」が一瞬で読める。
- strategic zoom: 左右非対称と歩兵の約6倍の高さが残る。
- back view: 双煙突、copper boilers、reactor ring、cyan chevron で Titan を特定できる。
- cyan が金属面積より支配的にならず、発光部の機能が説明可能。
- 接地、scale 1.0、正面、`muzzle` が Godot 内で保持される。
- Iris Xe の Titan showcase で sustained 30 FPS 未満にならない。

実測は 1920×1008 / Forward Plus で average 41 FPS / minimum 39 FPS。sustained 30 FPS 未満なし。
撮影結果は `docs/screenshots/phase25b/` の7枚。`phase25b_test` と既存の全主要回帰は PASS、
ERROR 0 / SCRIPT ERROR 0。

## 次に行う場合の順序

1. Godot quarter-view の close / mid / strategic / back を見て silhouette のみ判定。
2. 読みに問題がある場合は `make_gearforge_titan.py` の主要寸法だけ修正。
3. `.blend` を直接手修正したら、同じ変更を生成 script にも戻す。
4. LOD1/2 は本 asset 受け入れ後。Airship / Building Set の量産は開始しない。

## Known risks

- LOD0 は範囲内だが、bevel と ring のため triangles は10,392。単体性能確認が必要。
- モデルは現在 static。歩行の重量感は proportions / piston で示し、animation は後続。
- `VisualTitan` の collision は旧寸法（radius 2.2m / height 9m）。showcase には影響しないが、
  gameplay では新幅約7.7mに合わせた別途判定が必要。今 Phase では gameplay balance を変えない。
