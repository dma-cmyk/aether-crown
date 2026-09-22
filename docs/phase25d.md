# Phase 2.5D — Gearforge Production Walker

最終更新: 2026-09-22
目的: prototype battlefield の仮メカ `gearforge_walker_prototype` を、
Gearforge 軍が量産運用する正式な Production Walker Asset に作り直す。
対象は Visual Design と Blender Modeling。RTSUnit 統合・collision・selection・
LOD・animation・performance tuning は次の Muse Spark 工程。

## Walker 仕様

- 固有名: **Ironstride** (Gearforge Ironstride Line Walker)
- class: Frontline Support Walker (歩兵支援 / 敵歩兵制圧 / 軽装甲攻撃 / Titan 随伴)
- 寸法: 3.540m W × 4.200m D × 4.536m H
- 識別形状: 外へ開いた A フレーム脚、広い ram feet、digitigrade の Z 字側面、
  低く幅広の装甲 hull、上面の recoil cannon、後方の boiler / ammo housing / 双排気
- 原点: ground centre / front: Blender -Y → Godot +Z

### 命名の意味

Crownpiercer (Titan) と Crownhammer (Airship) は `Crown*` の固有名を持つ
一点物の超兵器。Walker は量産される line unit なので、あえて `Crown*` を使わず
`Ironstride` という **class 名**にした。名前の系統そのもので
「特別兵器」と「量産兵器」の階層を示す。

## Scale hierarchy

| 対象 | 高さ | 位置付け |
|---|---:|---|
| Infantry | 1.80m | 人間主体 |
| **Walker Ironstride** | **4.54m** | **量産型歩行砲台** |
| Titan Crownpiercer | 11.39m | 文明を象徴する巨大 Siege Engine |
| Airship Crownhammer | 11.38m H / 35.45m L | 空を支配する巨大戦略兵器 |

Walker は歩兵の約2.5倍、Titan の約0.40倍。Titan との差は高さだけでなく
「何で読ませるか」も分けている (下表)。

## Titan の縮小版にしないための設計差

| 観点 | Titan Crownpiercer | Walker Ironstride |
|---|---|---|
| 頭部 | 低い sensor head を持つ | **頭部を持たない。** glacis の横一文字 sensor slit のみ |
| 胴 | 高く厚い台形 torso | 高さより奥行・幅が勝る低い装甲 hull |
| 脚 | 幅広の分離二脚、ほぼ垂直 | 外へ開く A フレーム + 前傾 digitigrade の Z 字 |
| 主兵装 | 胴体奥行を超える非対称 Crownspike 巨砲 | 対称の中型 recoil cannon。砲は hull 上面の浅い mount |
| 排気 | 背面の双大煙突 (11.4m まで伸びる) | 後方へ 18度寝かせた短い双排気 |
| Aether | reactor → governor → weapon の全身配線 | sensor slit / chest regulator / rear capacitor の3点のみ |
| 印象 | 立ち止まって撃つ攻城兵器 | 歩きながら支援する砲台 |

## Locomotion language

人型ではなく industrial walking gun platform。
脚は hip → knee → ankle を3次元の station として定義し、
**膝を後方へ、足首を前方へ**振ることで側面に明確な Z 字を作っている。

- hip (±0.70, +0.26, 2.42)
- knee (±0.90, +0.72, 1.48) ← 後方へ
- ankle (±1.24, -0.22, 0.60) ← 前方へ
- foot pad 中心 (±1.24, -0.26, 0.11)

各節に copper の hydraulic ram を前後に配し、brass の knee axle / ankle axle /
hip axle を露出させる。足は ram pad + toe + claw + heel spur + cleat で
「歩く戦車」の接地面にする。

## Primary weapon

`Ironstride Recoil Cannon`。hull roof の brass traverse ring に載る浅い mount。

- armored mantlet + steel mantlet face + 左右 trunnion
- 砲身上を走る copper recoil rail ×2 と rail cross
- 砲身下の copper recoil cylinder ×2
- steel barrel sleeve → dark iron barrel → brass muzzle brake (brake slot 付き)
- 後方に breech + brass breech ring + steel counterweight

砲口は原点から 2.68m 前方、砲軸高 3.80m。Titan の Crownspike (前方 6.9m) と
違い、本体から大きくはみ出さない量産可能な中型砲として読ませる。

## Secondary

- 右肩の coaxial support gun 1門のみ
- 肩上の smoke launcher クラスタ (左右2本ずつ)
- 肩下の pressure tank、後部 ammunition housing

武装を盛らず、主役は silhouette + main cannon + walking machinery に置く。

## Aether

Titan より明確に控えめ。cyan は3か所だけ。

1. glacis の横一文字 sensor slit
2. 胸部 regulator (brass ring 内の小円)
3. 後部 Aether capacitor core

全身を青く光らせない。「工業兵器に Aether 技術が組み込まれている」程度に留める。

## Faction color

Production model は Gearforge neutral のまま。
両肩外側に **faction plate** 用の平らな steel パネル (0.10 × 0.72 × 0.46m,
Blender (±1.28, -0.24, 3.18)) を確保してある。showcase は
ここにだけ塗装色 (Blue / Red) の板を重ねて陣営差を出しており、
共有 material も GLB も1つのまま両陣営に使える。

## Material

`blender/scripts/material_lib.py` の共有 palette から5色のみ。新規 material なし。

- `gearforge_dark_iron`: hull body / glacis / shoulder / 脚の主装甲 / 砲身 / mantlet / turret body
- `gearforge_steel`: foot deck / toe / 脚の装甲板 / hip yoke / roof / 反射面 / counterweight / faction plate
- `gearforge_brass`: knee / ankle / hip axle / belt / brow / cleat / strake / muzzle brake / boiler band
- `gearforge_copper`: hydraulic ram / recoil rail / recoil cylinder / boiler / tank / feed pipe
- `gearforge_aether_glow`: sensor slit / chest regulator / rear capacitor core

texture / alpha / normal map は未使用 (texture 0)。

## Mesh 構造と将来の animation

LOD0 は **4つの機能グループ**に結合し、それぞれを実際の回転軸に置いた
pivot empty の子にしている。material は slot として残すので共有 palette は不変。

| pivot | 位置 (Blender) | 子 mesh | 将来の用途 |
|---|---|---|---|
| `leg_l_pivot` | (-0.70, 0.26, 2.42) | `gearforge_walker_leg_l_lod0` | walk |
| `leg_r_pivot` | (0.70, 0.26, 2.42) | `gearforge_walker_leg_r_lod0` | walk |
| `turret_pivot` | (0.0, -0.04, 3.56) | `gearforge_walker_turret_lod0` | traverse / recoil |
| `hull_pivot` | (0.0, 0.10, 2.82) | `gearforge_walker_hull_lod0` | idle machinery / 車体傾き |

脚・砲・torso が一体化していないので、skeleton を作らなくても
pivot を回すだけで walk / recoil / traverse の下地になる。

## Runtime anchors

Godot 座標 (GLB root 相対、scale 1.0)。front は +Z。

| anchor | Godot (x, y, z) | 用途 |
|---|---|---|
| `muzzle` | (0.00, 3.80, 2.68) | 主砲発射位置 / muzzle FX |
| `center_anchor` | (0.00, 3.02, -0.06) | 胴中心。被弾 / selection / UI 基準 |
| `reactor_anchor` | (0.00, 2.72, 1.10) | 胸部 regulator。damage / pulse FX |
| `exhaust_l` | (-0.66, 4.48, -1.46) | 左排気。steam / smoke |
| `exhaust_r` | (0.66, 4.48, -1.46) | 右排気。steam / smoke |
| `weapon_secondary` | (0.64, 3.48, 1.72) | coaxial support gun |
| `piston_l` | (-1.24, 0.60, 0.66) | 左脚接地 FX (歩行時の蒸気 / 土煙) |
| `piston_r` | (1.24, 0.60, 0.66) | 右脚接地 FX |

## 成果物

| 種別 | パス |
|---|---|
| 生成 script | `blender/scripts/make_gearforge_walker.py` |
| Blender 正本 | `blender/source/gearforge_walker.blend` |
| 中間 GLB | `blender/exports/gearforge_walker.glb` (`.gitignore` 対象) |
| Godot GLB | `game/assets/models/gearforge_walker.glb` |
| showcase | `game/scenes/maps/phase25d_walker_showcase.tscn` / `.gd` |
| test | `game/tests/phase25d_test.gd` |
| screenshots | `docs/screenshots/phase25d/` (9枚) |

```bash
# 再生成 + Godot 配置 + import
./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_walker.py
# 受け入れテスト
godot --headless --path game --script res://tests/phase25d_test.gd
# 9構図撮影
godot --path game res://scenes/maps/phase25d_walker_showcase.tscn -- --capture-25d
# ベンチマーク
godot --path game res://scenes/maps/phase25d_walker_showcase.tscn -- --benchmark-25d
```

## 数値

Blender vertices 2,220 / polygons 1,866 / triangles 3,960。
mesh object 4 / GLB surface 17 / material 5 / texture 0。GLB 284,044 bytes。
triangles は目安 3,000–7,000 の範囲内で、Titan 10,392 tris・
Airship 14,500 tris より明確に軽い。

## 本 Phase でやらないこと

RTSUnit 正式統合 / gameplay balance / combat AI / pathfinding /
LOD production / collision production / selection production / HP UI /
full animation set / VFX 本実装 / Walker 派生機 / Red 専用 Walker /
Titan・Airship・Building Set の再制作 / Map Production Foundation。
