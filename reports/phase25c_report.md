# Phase 2.5C Report — Gearforge Airship Production Asset

最終更新: 2026-09-22
担当領域: Art Direction / Airship Visual Design / Blender Production Modeling
成果物: **Crownhammer** (Twin-Cell Aether Dreadnought)

## 1. Reference 画像の確認

指定された2枚を実際にダウンロードして閲覧した。

- `https://i.imgur.com/KLW3Yab.png` — 閲覧できた
- `https://i.imgur.com/bPSGclL.png` — 閲覧できた

デザインはコピーせず、密度の作り方だけを構造原理として抽出した。抽出した6原理は
`docs/art/airship_design.md` に表で残している。最も効いたのは
「船体の外側に露出したフレーム (環状リング + 縦通材) が密度を作る」「下面に長い
understructure がある」「大量塊 → 中量塊 → 小金具の3階層が同居している」の3点。

## 2. Task 1 — Phase 1.75 Airship のレビュー

旧 `make_gearforge_airship.py` と `docs/screenshots/phase1_75/titan_airship.png` を確認した。
prototype 感の主因は polygon 数 (約1,100) ではなく、次の4点だった。

1. **分節がない。** UV sphere を Y方向に2.25倍しただけの単一楕円体で、輪郭に視線が止まる場所がない。
2. **階層がない。** envelope (巨大) と gondola (小) の2段しかなく、スケールを比較する中間部品が存在しない。
3. **因果関係がない。** 発光リングは何も駆動せず、プロペラはボイラーに繋がっていない。
   「浮く理由」「飛ぶ理由」「撃つ理由」が形の中で接続されていない。
4. **文明が違う。** `canvas` / `wood` の local material を使っており、
   `material_lib.py` を一度も参照していなかった。鋳鉄・真鍮・銅で出来た都市と Titan とは
   別世界の物体に見える。これが統一感を壊す最大の原因だった。

観点別の詳細表は `docs/art/airship_design.md` にある。

## 3. Task 2 — Design Variants と採用

| 案 | 内容 | 判定 |
|---|---|---|
| A. Bulwark | 単一大型装甲 envelope の正統派飛行船 | 安全だが固有性が弱く、俯瞰で1本の筒にしかならない |
| B. Skyforge | 空飛ぶ工廠。炉・クレーン・投下ベイ | 「空飛ぶ建物」に見え、Airship の読みと主役性を失う |
| **C. Crownhammer** | **2本の Aether lift cell が中央装甲 keel hull を抱える3胴構造** | **採用** |

採用理由: C は A の「飛行船である」読みやすさを保ったまま、Gearforge の
paired pressure vessel motif (双煙突 / 双タンク) を船体そのものに昇格させられる。
さらに `reactor → lift cell / mortar / thruster` という1本の Aether 系統で
浮力・火力・推進を同時に説明でき、texture を増やさずに完成感を上げられる。
俯瞰で「2本の筒 + 中央の船」という形になり、Titan の非対称単腕砲とも読みが衝突しない。

## 4. Task 3 / 4 — Production Design と Visual Hierarchy

3層構造 (上: lift cell ×2、中: 装甲 keel hull、下: gondola / mortar / sponson / pod)。
weapon identity は Titan の巨大単腕砲を避け、「下と横に撃つ」に統一した。
Primary / Secondary / Tertiary の割り当ては `docs/phase25c.md` の表のとおり。

制作中に実際のレンダーを見て以下を修正している (これが完成度を最も上げた)。

- lift cell を半径2.95m → 2.55m に絞り、bow cone を 3.3m → 4.7m に伸ばした。
  初回版は「2つのボイラー」に見えていた。
- ram prow を細い spike から装甲の量塊に作り替え、断面を上げて艦首を主役にした。
- 下面に連続する keel girder を追加した。初回版は gondola / mortar / pod が
  ばらばらの3塊で、参考画像のような「長い understructure」になっていなかった。
- H-tail を大型化し、tailplane を fin の頂部へ移して背面を1つの H として読ませた。
- cell 間の谷が狭すぎて dorsal reactor が見えなかったため、cell を細くして谷を2.9mに広げた。

## 5. Production model

| 項目 | 値 |
|---|---:|
| bounds | 14.206m W × 35.450m D × 11.379m H |
| Blender vertices | 7,702 |
| Blender polygons | 6,908 |
| export triangles | 14,500 |
| mesh | 8 |
| material | 8 |
| texture | 0 |
| GLB | 1,003,660 bytes |

polygons は Phase 2.5C の目安 3,500–7,000 内。triangles は `docs/model_rules.md` の
巨大ユニット目安 8,000–25,000 内 (Titan は 5,228 polygons / 10,392 tris)。
material は Titan と完全に同一の共有 palette。texture は 0 のまま成立させた。

runtime anchor は12個 (`muzzle` / `weapon_l` / `weapon_r` / `reactor_anchor` /
`engine_l` / `engine_r` / `exhaust_l` / `exhaust_r` / `thruster_l` / `thruster_r` /
`bow_lens` / `bridge_anchor`)。Godot 座標は `docs/art/airship_muse_handoff.md` に実測値で記載。

## 6. Godot integration

- `game/scenes/maps/phase25c_airship_showcase.tscn` を新設。Titan / 歩兵6体 /
  civic core / industry works / 係留マストを scale reference として同居させた。
- 9構図を 1920×1080 / Forward Plus で撮影 (`docs/screenshots/phase25c/`):
  close / mid / strategic / front / back / underside / with_titan / in_scene / silhouette_check。
- `VisualAirship.CRUISE_HEIGHT` を 19.0 → 26.0 に変更した。船体が 35.45m になり
  旧高度では街並みへ食い込むため。`_nearest_foe` は水平距離のみを見ているので
  bombardment の到達範囲・damage・interval は変わらない。gameplay balance は未変更。

## 7. 検証結果

| 項目 | 結果 |
|---|---|
| `phase25c_test` | OK (meshes=8 anchors=12 length=35.45 width=14.21 height=11.38) |
| `phase25a_test` | OK |
| `phase25b_test` | OK |
| `phase25b1_test` | OK |
| `visual_slice_test` | OK (titan hp + airship altitude OK) |
| `phase2d_test` | OK |
| `cli_smoke` | OK |
| ERROR / SCRIPT ERROR | 0 |

performance (Intel Iris Xe / Forward Plus):

- showcase benchmark: min 47 FPS / avg 50 FPS / 603 samples
- 1920×1080 capture 中: min 38 FPS / avg 38 FPS

sustained 30 FPS 未満は発生しなかった。

## 8. Visual acceptance

- close: ring frame、stringer、boiler、conduit、mortar、sponson の機構と material 階層が読める。
- mid: 2本の cell / keel hull / ducted engine / belly mortar / gondola が読める。
- strategic: 横長 + 中央切り欠き + H-tail で「大型 Gearforge Airship」と一目で分かる。
- front / back: 前は ram prow + 2つの bow cone、後は H-tail + duct + thruster で即断できる。
- relation: `airship_with_titan.png` で、同じ material 語彙でありながら
  横長3胴 vs 縦長非対称二脚とシルエットが混同しないことを確認した。

## 9. 未完了 / 既知の課題

1. 背面が正面ほど強くない。duct と thruster が cell 尾部の陰に入りやすい。
2. 真正面から見ると2本の bow cone が大きな暗い円として読める。
3. cell 下腹の cyan injector slit は真下からしか見えない (意図通りだが強調の余地あり)。
4. animation rig 未作成。プロペラは静止している。
5. LOD1 / LOD2 未作成。
6. Airship を gameplay unit に昇格させる場合の当たり判定は未更新。
7. `VisualAirship` の bombardment は `TitanShell` 流用のまま。

すべて `docs/art/airship_muse_handoff.md` に対処方針込みで記載し、Muse Spark へ引き継ぐ。

## 10. 本 Phase で触れていないもの

Titan Crownpiercer、Building Set、Airship 派生機、gameplay balance、AI、HUD、
次 Phase の作業。参考画像のデザインコピーおよび高解像度 texture の追加も行っていない。
