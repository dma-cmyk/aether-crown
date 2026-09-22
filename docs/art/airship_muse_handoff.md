# Gearforge Airship — Muse Spark Handoff

最終更新: 2026-09-22
対象: Phase 2.5C / `gearforge_airship` / **Crownhammer**
環境: EndeavourOS / Blender 5.2.2 LTS / Godot 4.7.2 / Intel Iris Xe

## Current completion state

**Checkpoint A–D 完了。Production LOD0 と Godot showcase が成立している。**

| CP | 内容 | 状態 |
|---|---|---|
| A | design 確定 / design docs + handoff | 完了 |
| B | 主要 silhouette (cell / keel / prow / tail) | 完了 |
| C | Production model / .blend / GLB / 数値 | 完了 |
| D | Godot import / showcase / 9構図撮影 / FPS 実測 | 完了 |

- 採用案: Variant C 「Twin-Cell Aether Dreadnought」
- 固有名: **Crownhammer**
- 完了: proportions, twin lift cell, keel hull, ram prow, keel girder, command gondola,
  belly siege mortar, broadside sponson ×4, machinery pod, ducted propeller ×2,
  tail Aether thruster ×2, H-tail, dorsal reactor, Aether 配線, material 割当,
  .blend 保存, GLB export, Godot import, showcase scene, `phase25c_test`
- 未確定: animation rig、LOD1/2、独自 texture / decal、gameplay 側の当たり判定更新

## 正本と再生成

- 生成 script: `blender/scripts/make_gearforge_airship.py`
- Blender 正本: `blender/source/gearforge_airship.blend`
- 中間 GLB: `blender/exports/gearforge_airship.glb` (`.gitignore` 対象)
- Godot GLB: `game/assets/models/gearforge_airship.glb`
- showcase: `game/scenes/maps/phase25c_airship_showcase.tscn` / `.gd`
- test: `game/tests/phase25c_test.gd`
- runtime 参照: `game/scripts/visual/visual_airship.gd`

```bash
# 再生成 + Godot 配置 + import
./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_airship.py
# 受け入れテスト
godot --headless --path game --script res://tests/phase25c_test.gd
# 9構図撮影 (docs/screenshots/phase25c/)
godot --path game res://scenes/maps/phase25c_airship_showcase.tscn -- --capture-phase25c
# Iris Xe ベンチマーク
godot --path game res://scenes/maps/phase25c_airship_showcase.tscn -- --benchmark-phase25c
```

## 数値仕様

| 項目 | 現在値 |
|---|---:|
| bounds | 14.206m W × 35.450m D × 11.379m H |
| Blender vertices | 7,702 |
| Blender polygons | 6,908 |
| export triangles | 14,500 |
| mesh | 8 |
| material | 8 |
| texture | 0 |
| GLB | 1,003,660 bytes |

polygons は Phase 2.5C の目安 3,500–7,000 内。triangles はリポジトリの巨大ユニット目安
8,000–25,000 tris 内 (Titan は 10,392 tris)。造形部品は material 単位に結合済み。

## Component 一覧

### Primary forms

1. 左右2本の Aether lift cell (半径2.55m / 直管19.6m + 前後コーン)
2. 中央の装甲 keel hull (幅4.4m / 上下3.4m)、cell より前後に長く両者を1体に繋ぐ
3. 装甲 ram prow (bronze ram + brass collar)
4. 下面の連続 keel girder と3つの塊 (gondola / mortar / machinery pod)
5. H-tail (垂直 fin ×2 + 上部 tailplane)

### Secondary forms

- cell: brass ring frame ×6/本、bow ring、tail ring、vent ring、steel stringer ×4/本、上面 deck panel
- keel: brass belt、steel shoulder、saddle ×3/側、brass brace、spine deck、spine rail、side rib ×4/側、copper boiler ×3/側
- underside: girder rail、girder rib ×6、truss ×4、command gondola + cyan bridge slit、
  belly siege mortar (breech / core / 3 bands / muzzle / lens / copper recoil)、
  sponson ×4 (装甲箱 + brass ring + 連装 bronze 砲身 + copper feed)、
  machinery pod (copper drum ×2 / brass band / furnace mouth / rust panel / steam pipe)
- propulsion: nacelle ×2 (dark iron 本体 / copper drum / brass band / furnace mouth / steel pylon)、
  duct ring + duct lip + hub + bronze blade ×4、tail Aether thruster ×2
- tail: fin ×2 + bronze 前縁 + brass spar + cyan fin mark、tailplane + brass spar + bronze edge、stay ×4
- Aether: dorsal reactor (steel housing / cyan core / brass ring ×2 / bronze cap / copper twin stack)、
  injector trunk ×2、keel conduit 前後 ×4、cell 下腹 injector slit ×6/本 + brass shroud、
  bow lens、cyan flank chevron ×2

### Tertiary

rivet 相当の突起は設けず、ring / band / valve / rail の反復で近景の情報量を作っている。

## Proportions

- 全長 35.45m。Titan Crownpiercer (11.39m 高) の約3.1倍の長さ。
- 全高 11.38m。Titan とほぼ同じ「高さクラス」で、長さで巨大さを出す。
- lift cell 中心は keel 中心から左右 ±4.00m、上 +3.30m。cell 間の空隙は幅2.9m。
- keel hull 上端 +1.70m、下端 -1.70m。girder は -1.98m。mortar 砲口は -4.66m。
- reactor 上端 +6.00m、cell 上端 +5.85m、tailplane 上端 +6.05m。
- 頭でっかちを避けるため、ram prow の断面は keel 断面の約40%まで絞っている。

## 向き・原点

- front は Blender `-Y`。GLB import 後 Godot **`+Z`**。現行 `VisualAirship` の
  `atan2(dir.x, dir.z)` と一致する。
- up は Blender `+Z` → Godot `+Y`。
- 原点は **飛行原点 = keel hull 中心線** (`docs/model_rules.md` の接地中心ルールの
  飛行体例外)。原点から下端まで 5.13m、上端まで 6.25m。
  地上高 H に置くと、船体下端は `H - 5.13` m になる。

## Propulsion system

2系統で役割が分かれている。

| 系統 | 位置 | 駆動 | 用途 |
|---|---|---|---|
| steam ducted propeller ×2 | 後部外側 (X ±5.20, Z -0.62) | keel boiler bank → copper drum → brass gearbox | 巡航 |
| Aether thruster ×2 | 尾端 (X ±1.20, Z +0.20) | reactor → keel 後方 conduit | 加速・機動 |

将来の回転 animation は `engine_l` / `engine_r` を基準にブレードを再分離する
(現在は material 結合済みなので、`make_gearforge_airship.py` の `build_engines` から
`prop_blade_*` を除外して別 object のまま残すのが最短)。

## Aether energy flow

```
dorsal reactor (0, +4.20B, +4.30B)
  ├─ injector trunk L/R → lift cell 下腹 cyan slit ×6/本  (浮力)
  ├─ keel conduit 前方 → belly mortar breech → muzzle lens (火力)
  └─ keel conduit 後方 → tail Aether thruster ×2          (推進)
```

cyan はこの経路と bridge slit / bow lens / fin mark に限定。
orange (`furnace_glow`) は machinery pod 炉口、nacelle 炉口、cell 尾部 vent のみ。
装甲面には発光を置いていない。

## Weapon system

| 兵装 | 位置 | 役割 |
|---|---|---|
| belly siege mortar | 下面中央、下前方へ約28度 | 主兵装。`muzzle` anchor。mid zoom で読める |
| broadside sponson ×4 | keel 側面、左右2基ずつ | 副兵装。連装 bronze 砲身。`weapon_l` / `weapon_r` |
| bow ram + lens | 艦首 | 兵装ではないが進行方向と攻撃性を示す |

Titan の「長大な単腕砲を横へ突き出す」に対し、Airship は「下と横へ撃つ」。
遠景でもシルエットの論理が異なるので混同しない。

## Runtime anchors

Godot 座標 (GLB root からの相対、scale 1.0)。

| node | Godot 位置 (x, y, z) | Blender 位置 | 用途 |
|---|---|---|---|
| `muzzle` | (0.00, -4.66, 3.46) | (0.00, -3.46, -4.66) | belly mortar 砲口。`VisualAirship._try_bombard` の発射原点 |
| `weapon_l` | (-4.50, -0.48, 6.80) | (-4.50, -6.80, -0.48) | 左舷前部 sponson |
| `weapon_r` | (4.50, -0.48, 6.80) | (4.50, -6.80, -0.48) | 右舷前部 sponson |
| `reactor_anchor` | (0.00, 4.30, -4.20) | (0.00, 4.20, 4.30) | dorsal reactor。damage / pulse FX |
| `engine_l` | (-5.20, -0.62, -8.95) | (-5.20, 8.95, -0.62) | 左 ducted propeller hub |
| `engine_r` | (5.20, -0.62, -8.95) | (5.20, 8.95, -0.62) | 右 ducted propeller hub |
| `exhaust_l` | (-5.20, -0.62, -4.45) | (-5.20, 4.45, -0.62) | 左 nacelle 炉口。steam / smoke |
| `exhaust_r` | (5.20, -0.62, -4.45) | (5.20, 4.45, -0.62) | 右 nacelle 炉口。steam / smoke |
| `thruster_l` | (-1.20, 0.20, -15.75) | (-1.20, 15.75, 0.20) | 左 Aether thruster。加速 FX |
| `thruster_r` | (1.20, 0.20, -15.75) | (1.20, 15.75, 0.20) | 右 Aether thruster。加速 FX |
| `bow_lens` | (0.00, 0.85, 16.20) | (0.00, -16.20, 0.85) | 艦首 cyan lens。索敵 / 被弾 FX |
| `bridge_anchor` | (0.00, -2.30, 10.55) | (0.00, -10.55, -2.30) | command gondola。乗員 / 被弾 FX |

`phase25c_test` がこの12個の存在を検証する。LOD を作る場合も名前と位置を変えないこと。

## Future animation parts

| 部位 | 分離方法 |
|---|---|
| propeller blade | `build_engines` の `prop_blade_*` を `join_by_material` 対象から外す |
| sponson turret | `sponson_ring` / `sponson_barrel_*` を turret 単位で別 object 化 |
| mortar barrel | `mortar_barrel` / `mortar_band_*` / `mortar_muzzle` / `mortar_lens` を1群にする |
| fin / tailplane | 舵として動かす場合は `fin_*` を左右別に残す |

`join_by_material` は material 単位で全結合するため、可動部を残す場合は
除外リストを引数で受け取る形に拡張するのが最小変更。

## Material

`blender/scripts/material_lib.py` の共有 palette のみ使用 (Titan と完全に同一)。
Phase 1.75 版の `canvas` / `wood` local material は廃止した。

- `gearforge_dark_iron`: lift cell 本体、keel hull、prow、girder、nacelle、tailplane
- `gearforge_steel`: cell stringer / deck、keel shoulder、saddle、gondola、sponson plate、fin、reactor housing
- `gearforge_brass`: **ring frame (Airship の主役)**、keel belt、containment、nozzle、spar、duct
- `gearforge_bronze`: ram、砲身、spine deck、prop blade、cell cap、tailplane edge
- `gearforge_copper`: boiler drum、conduit、injector trunk、recoil、steam pipe、reactor stack
- `gearforge_rust`: machinery pod 周辺のみ
- `gearforge_aether_glow`: injector slit / reactor core / mortar core+lens / thruster / bridge / bow lens / fin mark / flank chevron
- `gearforge_furnace_glow`: machinery pod 炉口、nacelle 炉口、cell 尾部 vent のみ

texture / alpha / normal map / Material Maker / Krita / GIMP は未使用 (texture 0)。

## Godot integration notes

- `game/scenes/maps/phase25c_airship_showcase.tscn` が art-only showcase。
  Titan / 歩兵6体 / civic / industry / 係留マストを scale reference として同居させている。
  gameplay、AI、HUD、balance には触れていない。
- `VisualAirship.CRUISE_HEIGHT` を 19.0 → 26.0 に変更した。船体が 35.45m になり
  旧高度では街並みへ食い込むため。`_nearest_foe` は水平距離のみを見ているので
  bombardment の到達範囲・damage・interval は変わらない。
- `VisualAirship` は GLB の影を切っている (`SHADOW_CASTING_SETTING_OFF`)。showcase 側では ON。
- 実測 FPS: 1920×1080 / Forward Plus / Intel Iris Xe で capture 中 min 38 / avg 38。
  sustained 30 FPS 未満なし。

## Optimization / LOD notes

- LOD0 は material ごとに8 mesh。透過なし、texture memory 0。
- LOD1 目標: 5–6 mesh / 6,000–8,000 tris。削減候補は
  ring frame を6→4本、stringer を4→2本、girder rib を6→3、
  sponson を装甲箱+砲身のみ、prop blade を4→2、torus の minor segment 削減。
- LOD2 目標: 3–4 mesh / 2,500–3,500 tris。
  2本の cell、keel hull、prow、H-tail、mortar、duct ring、cyan 発光のみ残す。
- シルエットを決めているのは cell / keel / prow / H-tail / 下面の塊なので、
  この5つを削らなければ遠景の読みは落ちない。

## Visual acceptance criteria

- close: ring frame、stringer、boiler、conduit、mortar、sponson の機構と material 階層が読める。
- mid: 2本の cell / keel hull / ducted engine / belly mortar / gondola が読める。
- strategic: 横長 + 中央切り欠き + H-tail で「大型 Gearforge Airship」と一目で分かる。
- front / back: 前は ram prow + 2つの bow cone、後は H-tail + duct + thruster で即断できる。
- relation: Titan と同じ material 語彙だが、横長3胴 vs 縦長非対称二脚でシルエットは混同しない。
- 撮影結果は `docs/screenshots/phase25c/` の9枚。

## Unfinished items / known visual issues

1. **背面が正面ほど強くない。** H-tail は読めるが、duct と thruster が cell 尾部の陰に入りやすい。
   nacelle をあと 0.3–0.5m 後方か外側へ出すと改善する見込み。
2. **艦首を真正面から見ると、2本の bow cone が大きな暗い円として読める。** 角度が付けば問題ないが、
   正面固定カット用に cone 表面へ brass の縦リブを1本足す余地がある。
3. **cell 下腹の cyan injector slit は真下からしか見えない。** RTS の quarter view では
   flank chevron と bridge slit が cyan の主役になっている。意図通りだが、
   浮力の説明を強めたい場合は slit を cell 側面寄り (角度 20–25度) に回すとよい。
4. **animation rig 未作成。** 現在 static。プロペラは回っていない。
5. **LOD1 / LOD2 未作成。**
6. **gameplay 側の当たり判定は未更新。** `VisualAirship` は当たり判定を持たないが、
   Airship を gameplay unit に昇格させる場合は 35.45m × 14.21m に合わせた判定が別途必要。
   今 Phase では gameplay balance を変えていない。
7. **`VisualAirship` の bombardment は `TitanShell` を流用したまま。** 本来は mortar らしい
   弧を描く弾道が似合うが、これは Phase 2.5C の範囲外。

## Muse Spark next actions

1. `phase25c_airship_showcase` を quarter / mid / strategic / front / back で見て silhouette のみ判定する。
2. 読みに問題があれば `make_gearforge_airship.py` の主要寸法だけ修正する。
   `.blend` を直接手修正した場合は、同じ変更を生成 script へ必ず戻す。
3. 上記 known issue の 1 と 2 は寸法の微調整で閉じられる。優先度はこの順。
4. LOD1/2 は本 asset 受け入れ後。`make_gearforge_titan_lod1.py` と同じ作り方で足せる。
5. Titan Crownpiercer は変更しない。Airship 派生機・Building Set の量産は開始しない。
