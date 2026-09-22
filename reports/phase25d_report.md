# Phase 2.5D Report — Gearforge Production Walker

最終更新: 2026-09-22
担当領域: Visual Design / Blender Modeling / silhouette / material language /
weapon identity / scale hierarchy / RTS readability
成果物: **Ironstride** (Gearforge Ironstride Line Walker)

## 1. Design concept

Walker は Gearforge 軍の「量産型中型戦闘 Walker」であり、
Crownpiercer Titan のような一点物の超兵器ではない。
そこで role を **Frontline Support Walker** に固定し、
歩兵支援・敵歩兵制圧・軽装甲攻撃・Titan 随伴を形で説明できるようにした。

命名も階層を示す道具として使った。Titan `Crownpiercer` と Airship `Crownhammer` は
`Crown*` の固有名だが、Walker は `Ironstride` という **class 名**にしてある。
名前の系統だけで「特別兵器」と「量産兵器」の区別がつく。

参考画像2枚 (`KLW3Yab` / `bPSGclL`) は Phase 2.5C で閲覧済みで、
industrial density / readable armor shapes / scale hierarchy の原理のみを流用した。
形状のコピーは行っていない。

## 2. Silhouette 方針

RTS distance で最も効く要素だけを Primary に置いた。

| 階層 | 要素 | 見える距離 |
|---|---|---|
| Primary | 外へ開く A フレーム脚 / 広い ram feet / 低く幅広の hull / 前方へ伸びる主砲 / 後方の双排気 | strategic |
| Secondary | digitigrade の Z 字側面 / brass knee・ankle・hip axle / copper hydraulic ram / recoil rail / boiler / ammo housing / 肩の faction plate | mid |
| Tertiary | 足の bolt 列と cleat / 肩の strake / turret hatch と trim / smoke launcher / rear rib | close |

4方向すべてで別の情報が出る。

- 正面: 横一文字 sensor slit と A フレーム脚、左右 shoulder の水平ライン
- 斜め前: 主砲 + mantlet + recoil rail + 膝の brass
- 側面: hip → 後方 knee → 前方 ankle の Z 字と、前へ突き出す砲身
- 斜め後ろ: boiler / ammunition housing / 双排気 / capacitor

## 3. Prototype からの変更

| 観点 | Prototype (822 polys / 1,548 tris) | Production Ironstride |
|---|---|---|
| 全体 proportion | 高さ 4.2m。幅狭で脚が垂直に近く、正面が縦長の箱 | 3.54m W × 4.20m D × 4.54m H。接地幅を最大にして「歩く砲台」へ再配分 |
| 脚 | 箱を縦に積んだだけ。膝がほぼ真っ直ぐ | hip/knee/ankle を3次元 station 化。膝を後方、足首を前方へ振り側面に Z 字を作った |
| 脚の開き | ほぼ平行 | 足を外へ、膝を内へ。正面が明確な A フレーム |
| 足 | 薄い板 | ram pad + deck + toe + claw + heel spur + cleat + bolt 列 |
| 主砲 | 箱から生えた細い筒 (右へオフセット) | 中央配置の recoil cannon。mantlet / trunnion / recoil rail ×2 / recoil cylinder ×2 / sleeve / muzzle brake / breech / counterweight |
| 胴 | 高さ優先の小さい箱 | 高さより奥行が勝る装甲 hull + 傾斜 glacis + shoulder block |
| 後部 | 煙突2本とタンクのみ | 横置き boiler + band + ammunition housing + hatch + 斜め双排気 + Aether capacitor + rear rib |
| Aether | sensor 1枚 | sensor slit / chest regulator / rear capacitor の3点に機能配置 |
| faction | シーン側で板を置くだけ | モデル側に専用の平面 plate を確保 (0.10 × 0.72 × 0.46m) |
| mesh 構造 | material ごとに全結合 (動かせない) | 4 機能グループ + pivot empty (walk / recoil / traverse の下地) |
| 数値 | 1,548 tris | 3,960 tris |

prototype の良い要素 (二脚 / wide feet / piston legs / shoulder deck /
top cannon / twin exhaust / industrial silhouette) は全て残し、
proportion を一度ゼロから引き直した上で再構成している。

## 4. Titan の縮小コピーになっていないこと

| 観点 | Titan Crownpiercer | Walker Ironstride |
|---|---|---|
| 頭部 | 低い sensor head を持つ | **頭部なし**。glacis の横一文字 slit のみ |
| 胴 | 高く厚い台形 torso | 高さより奥行・幅が勝る低い hull |
| 脚 | 幅広の分離二脚、ほぼ垂直 | 外開き A フレーム + 前傾 digitigrade |
| 主兵装 | 胴体奥行を超える非対称 Crownspike 巨砲 (前方 6.9m) | 対称の中型 recoil cannon (前方 2.68m) |
| 排気 | 背面の双大煙突 (11.4m) | 後方 18度の短い双排気 |
| Aether | 全身の reactor → governor → weapon 配線 | 3点のみ |

## 5. Dimensions / 数値

| 項目 | 値 |
|---|---:|
| bounds | 3.540m W × 4.200m D × 4.536m H |
| Blender vertices | 2,220 |
| Blender polygons | 1,866 |
| triangles | 3,960 |
| mesh object | 4 |
| GLB surface | 17 |
| material | 5 |
| texture | 0 |
| GLB | 284,044 bytes |

triangles は指定目安 3,000–7,000 の範囲内。Titan 10,392 tris /
Airship 14,500 tris より明確に軽く、量産ユニットとして妥当。

Scale hierarchy: Infantry 1.80m < **Walker 4.54m** < Titan 11.39m < Airship 35.45m (全長)。

## 6. Mesh 構造と将来の animation

LOD0 は4つの機能グループに結合し、それぞれ実際の回転軸に置いた pivot empty の子にした。
material は slot として残るので共有 palette は不変。

| pivot | Blender 位置 | 子 mesh | 将来の用途 |
|---|---|---|---|
| `leg_l_pivot` | (-0.70, 0.26, 2.42) | `gearforge_walker_leg_l_lod0` (4 surface) | walk |
| `leg_r_pivot` | (0.70, 0.26, 2.42) | `gearforge_walker_leg_r_lod0` (4 surface) | walk |
| `turret_pivot` | (0.0, -0.04, 3.56) | `gearforge_walker_turret_lod0` (4 surface) | traverse / recoil |
| `hull_pivot` | (0.0, 0.10, 2.82) | `gearforge_walker_hull_lod0` (5 surface) | idle machinery / 車体傾き |

skeleton を作らなくても pivot を回すだけで walk / recoil / traverse の下地になる。

## 7. Anchors

Godot 座標 (GLB root 相対、scale 1.0、front +Z)。

| anchor | Godot (x, y, z) | 用途 |
|---|---|---|
| `muzzle` | (0.00, 3.80, 2.68) | 主砲発射位置 / muzzle FX |
| `center_anchor` | (0.00, 3.02, -0.06) | 胴中心。被弾 / selection / UI 基準 |
| `reactor_anchor` | (0.00, 2.72, 1.10) | 胸部 regulator。damage / pulse FX |
| `exhaust_l` | (-0.66, 4.48, -1.46) | 左排気。steam / smoke |
| `exhaust_r` | (0.66, 4.48, -1.46) | 右排気。steam / smoke |
| `weapon_secondary` | (0.64, 3.48, 1.72) | coaxial support gun |
| `piston_l` | (-1.24, 0.60, 0.66) | 左脚接地 FX |
| `piston_r` | (1.24, 0.60, 0.66) | 右脚接地 FX |

`muzzle` / `center_anchor` / `reactor_anchor` / `exhaust_l` / `exhaust_r` は
Titan・Airship と同じ命名。`weapon_secondary` は Airship の `weapon_l`/`weapon_r` に、
`piston_l`/`piston_r` は Airship の `engine_l`/`engine_r` に相当する位置付け。

## 8. Blender / GLB paths

| 種別 | パス |
|---|---|
| 生成 script | `blender/scripts/make_gearforge_walker.py` |
| Blender 正本 | `blender/source/gearforge_walker.blend` |
| 中間 GLB | `blender/exports/gearforge_walker.glb` (`.gitignore` 対象) |
| Godot GLB | `game/assets/models/gearforge_walker.glb` |
| showcase | `game/scenes/maps/phase25d_walker_showcase.tscn` / `.gd` |
| test | `game/tests/phase25d_test.gd` |
| design doc | `docs/phase25d.md` |

## 9. Showcase / Screenshots

`game/scenes/maps/phase25d_walker_showcase.tscn` は art-only。
Walker 本体 + 3機の squad + prototype + Titan + Barracks + Factory + 歩兵6体を
scale reference として同居させる。gameplay・AI・HUD・balance には触れていない。

`docs/screenshots/phase25d/` に9枚 (1920×1080)。model 確認距離と RTS 距離を混在させた。

1. `walker_front.png` — 正面 (model 距離)
2. `walker_side.png` — 側面。digitigrade の Z 字 (model 距離)
3. `walker_rear.png` — 背面。boiler / ammo housing / 双排気 (model 距離)
4. `walker_weapon_close.png` — 主砲近景。mantlet / recoil rail / muzzle brake
5. `walker_prototype_compare.png` — prototype (左) と production (右) の同一カメラ比較
6. `walker_infantry_scale.png` — 歩兵6体との対比
7. `walker_titan_scale.png` — Titan Crownpiercer との対比
8. `walker_production_overview.png` — squad + 歩兵 + Titan + 建物
9. `walker_rts_distance.png` — RTS 距離。4機が「Walker」と一目で読めるか

## 10. 検証結果

| 項目 | 結果 |
|---|---|
| `phase25d_test` (新規) | OK (meshes=4 surfaces=17 materials=5 textures=0 anchors=8 pivots=4 size=3.54x4.20x4.54) |
| 既存 regression 16 suite | 全 OK (phase1_5 / 25a / 25b / 25b1 / 25c / 25c1 / 26a / 2a / 2b / 2c / 2d / prototype_battlefield / skirmish / visual_slice / playtest / cli_smoke) |
| `camera_probe` | NG (bounds)。**本 Phase 以前からの既存事象** — 追跡ファイル無変更の状態 (HEAD 相当) で再現し、camera_controller / test_world は一切触れていない |
| ERROR / SCRIPT ERROR | 0 |

performance (Intel Iris Xe / Forward+ / 1920×1080):

- showcase capture (walker 4機 + Titan + 建物2 + 歩兵6): min 40 / avg 40
- showcase benchmark 15秒: min 35 / avg 38

sustained 30 FPS 未満なし。本格的な performance tuning は次工程。

### 作業中に見つけて直した既存の落とし穴

`tools/export_blender_to_godot.sh` は `blender/exports/*.glb` を**全部**
`game/assets/models/` へコピーする。ローカルの `blender/exports/` に古い
Titan export が残っていたため、commit 済みの polished Titan GLB が一度上書きされた。
`git checkout` で復元し、現行 generator から再生成して mesh/node JSON が
完全一致することを確認済み (差分は bevel 評価順による float ノイズのみ)。
最終 commit に Titan の変更は含まれていない。

## 11. Acceptance

- [x] Production Walker silhouette 成立
- [x] Prototype より明確に高品質 (`walker_prototype_compare.png`)
- [x] Infantry より圧倒的に大きい (4.54m vs 1.80m)
- [x] Titan より明確に小さい (4.54m vs 11.39m)
- [x] Titan の縮小コピーではない (頭部なし / A フレーム脚 / 対称中型砲)
- [x] main cannon identity 成立 (recoil rail / mantlet / muzzle brake)
- [x] Gearforge 文明として統一 (共有 palette のみ)
- [x] Aether cyan 控えめ (3点のみ)
- [x] shared material palette (新規 material 0)
- [x] polygon budget 現実的 (3,960 tris)
- [x] texture 0
- [x] ground center origin (実測 base y = 0.000)
- [x] scale 正常 (1 unit = 1m)
- [x] front 方向正常 (Blender -Y → Godot +Z、muzzle z=+2.68)
- [x] future animation 可能な構造 (4 group + pivot)
- [x] anchors 準備 (8個)
- [x] Blender source 保存
- [x] generator 保存
- [x] GLB export 成功
- [x] showcase 作成
- [x] screenshots 作成 (9枚)

## 12. Known issues

1. **正面真っ向からは主砲が foreshorten して消える。** 砲身が視線と同軸になるため、
   正面カットだけだと「脚の上の箱」に見える。斜め前・側面では問題ない。
   気になる場合は mantlet の左右幅をあと 0.1m 広げるのが最小の対処。
2. **RTS 距離で hull roof の steel が明るく飛びやすい。** 太陽角によっては
   上面が白く見え、dark iron 主体の Gearforge らしさが弱まる。
   roof を dark_iron へ寄せるか、roughness を上げる調整余地がある。
3. **mesh object 4 に対し GLB surface は 17。** draw call は surface 数に比例するため、
   量産ユニットとしては将来的に static LOD1 を material 単位の5 mesh へ畳む価値がある。
   本 Phase では animation 可能性を優先した。
4. **animation / rig 未実装。** pivot は用意したが static。
5. **collision / selection / RTSUnit 統合なし。** 次工程。
   showcase の faction plate はシーン側で重ねた板で、モデルには含まれない。
6. `game/tests/phase25c_test.gd.uid` は Phase 2.5C から untracked のままだったため、
   本 commit で追加した。

## 13. 次候補 (最大3)

1. **Walker Production Integration** — RTSUnit 化、collision / selection、
   LOD1、walk / recoil animation、faction marking のモデル側取り込み。
2. **Map Production Foundation** — terrain paint、高低差、正式 cover / navigation。
3. **赤軍 visual identity** — 現状は同一モデルの塗り分けのみ。固有 silhouette の検討。
