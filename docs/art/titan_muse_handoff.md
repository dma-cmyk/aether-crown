# Gearforge Titan — Muse Spark Handoff

最終更新: 2026-09-22
対象: Phase 2.5B / 2.5B.1 / Reference-Informed Visual Polish / `gearforge_titan` / **Crownpiercer**
環境: EndeavourOS / Blender 5.2.2 LTS / Godot 4.7.2 / Intel Iris Xe

## 現在の到達点

Production LOD0 の Reference-Informed Visual Polish と生成パイプライン更新は完了。

- 採用案: Variant B 「Aether Siege Engine」
- 固有名: Crownpiercer
- 主要 silhouette: 非対称 Crownspike 主砲 / 低い sensor head / 幅広 torso / 双煙突 / 分離脚
- 完了: proportions, main weapon, chest governor, rear reactor, boiler, pipes, exhaust, armor, material 割当
- 完了: foot / ankle / knee / thigh の荷重経路、torso armor layering、Crownspike recoil mount、
  right brace support、rear reactor cage の polish
- 完了: Blender source 保存、GLB export、Godot asset 配置・import
- 完了: Godot showcase、polish後8構図撮影、Phase 2.5B / 2.5B.1 relevant regression
- 未確定: アニメーション用 rig、LOD2、独自 texture / decal
- 完了 (Phase 2.5B.2): LOD1をpolish後LOD0へ再生成 (5 mesh / 4,804 tris、anchor parity維持)

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
| bounds | 7.772m W × 9.645m D × 11.390m H |
| Blender vertices | 7,820 |
| Blender polygons | 7,670 |
| export triangles | 14,964 |
| mesh | 8 |
| material | 8 |
| texture | 0 |
| GLB | 1,047,796 bytes |

Phase 2.5B比で polygonsは+2,442、trianglesは+4,572。追加は荷重・反動・圧力経路を
説明するgeometryに限定した。trianglesはリポジトリの巨大ユニット目安8,000–25,000内。
造形部品はmaterial単位に結合済みで、GLBのmesh数は8のまま。

旧bounds 7.761 × 9.645 × 11.390mに対し、幅のみ+0.011m（+0.14%）。depth / height、
原点、scale 1.0、front -Yは不変で、runtime上の寸法変更として扱う必要はない。

## Component 一覧

### Primary forms

1. 左右の大型接地脚: wide sole / toe armor / heel / ankle axle
2. 回転盤を含む hip deck
3. 台形の幅広 armored torso
4. 左肩の長大な Crownspike siege cannon
5. 右肩から垂れる siege brace arm

### Secondary forms

- raised foot deck / toe ram / heel cap / ankle fork、layered shin / thigh armor、
  knee guard / axle / external copper/brass pistons
- compact sensor head, cyan visor, rangefinder
- chest Aether governor, brass containment ring, front vents
- cannon breech / counterweight / trunnion / recoil cradle / recoil rams / mount struts /
  shroud / barrel / cooling rails / muzzle lens
- right brace shoulder crown / shock / side rail / press plate / rear support block
- rear twin copper boilers, pressure bands, twin exhaust stacks
- rear Aether reactor, protective cage, pressure manifold, copper feed pipes, cyan back chevrons
- deck valves, stack collars, furnace-lit exhaust mouths

## Proportions

- 全高: 11.39m。脚元から hip まで約4.9m、torso 上端約7.7m。
- sensor head 上端: 約9.0m。煙突が11.4mまで伸び、背面の crown silhouette を作る。
- 最大幅: 7.772m。建物と同程度の高さでも、脚の分離と肩の非対称で移動兵器と読ませる。
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

Polish passで4 anchorの名前・座標・意味はすべて変更なし。

| node | Blender 位置 | 用途 |
|---|---|---|
| `muzzle` | (-2.72, -6.92, 7.26) | 現行 TitanShell / muzzle FX |
| `reactor_anchor` | (0, 2.52, 7.12) | 将来の reactor pulse / damage FX |
| `exhaust_l` | (-1.18, 1.40, 11.45) | 将来の steam/smoke |
| `exhaust_r` | (1.18, 1.40, 11.45) | 将来の steam/smoke |

front は Blender `-Y`。Godot では GLB import 後 `+Z` を向き、現行 `VisualTitan`
の `atan2(face.x, face.z)` と一致する。原点は接地中心。

## Optimization / LOD notes

- LOD0 は material ごとに8 mesh / 14,964 tris。透過なし、texture memory 0。
- シルエットと material boundary を変えない篤囲で、内部の隠れ面は将来削除可。
- 現行LOD1は5 mesh / 4,804 tris (Phase 2.5B.2でpolish後LOD0へ再同期済み)。
  foot deck / knee guard / torso layering / recoil cradle / brace crown /
  reactor cageを簡略再現し、anchor parity (≤0.05) を維持。
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

Polish撮影結果は `docs/screenshots/titan_polish/` の8枚。close / mid / side / strategic /
units / scene / back / silhouetteをGodot Forward Plus / Intel Iris Xeで確認する。
15秒benchmark（warmup 3秒）は minimum 39 / average 43 FPS。sustained 30 FPS未満なし。
`cli_smoke` / `phase25b_test` / `phase25b1_test` / `visual_slice_test`とshowcase起動はPASS、
Godot ERROR 0 / SCRIPT ERROR 0。

## 次に行う場合の順序

1. (Phase 2.5B.2で完了) LOD1再同期・32m/34m切替確認・4 anchor維持。
2. rig化時はankle fork / knee axle / thigh piston / cannon cradleを可動階層へ分ける。
3. LOD2、歩行・反動animation、decalはTitan最終判断後に着手する。

## Known risks

- LOD0は14,964 tris。複数体benchmarkはPhase 2.5B.2で再確認済み
  (Titan×3でmin 46 / avg 48、sustained 30未満なし)。
- モデルは現在 static。歩行の重量感は proportions / piston で示し、animation は後続。
- `VisualTitan` collisionはPhase 2.5B.1のradius 3.0m / height 9mを維持。sole外端約2.45mに
  infantry半径0.35mを加えても2.80mで収まり、数値上の変更は不要。relevant testで再確認する。
- Blender exportは任意MeshOptimizer library不在のメッセージを出すが、Draco検出、GLB生成、
  Godot importと全validatorは成功している。今回のasset固有障害ではない。

## Phase 2.5B.2 productionization (Muse Spark実施)

- Sol polish受け入れ: generator再実行でaccessor全32一致、mesh 8 / node 12一致。
- LOD1再同期: 5 mesh / 4,804 tris / 307,144 bytes、anchor parity維持。
- collision r3.0 / selection / footprint / threshold 32m/34mは変更なし。
- benchmark (Iris Xe): LOD0 min48/avg50、LOD1 min48/avg50、
  strategic min47/avg49、Titan×3 min46/avg48。sustained 30未満なし。
- regression 14 suite PASS、ERROR 0 / SCRIPT ERROR 0。
- 詳細は `docs/phase25b2.md` / `reports/phase25b2_report.md`。
  Titanは本Phaseで最終的に閉じる。
