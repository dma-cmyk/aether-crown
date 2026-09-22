# Phase 2.5A 設計 (Art Production Foundation + Representative Asset)

目的: Phase 2Dのゲームループを壊さず、Production Artの基準を作る。
代表建築1 + District 2種 + 共有PBR基盤 + GLB pipeline確認 + 性能確認。
量産は次Phase以降。

作らないもの (今回):
Titan・Airship本格制作、全都市・全District量産、Infantry作り直し、
本格Minimap、HUD刷新、大規模VFX、Audio、Trailer。

## asset方針

- 代表先行・少量検証: 3アセットのみ (civic core / industry / aether works)。
- RTS距離の読みやすさ優先: シルエット・大形状・色・発光で区別。
  close-up qualityは追わない。
- modular・共有material・低poly。Blender Python再生成可能を維持。

## art direction

- industrial steampunk: iron / steel / brass / bronze / copper /
  stone / rust + pipes / tanks / chimneys + warm furnace glow +
  blue Aether glow。
- 用途の silhouette 差: civic (時計塔+煙突+ボイラー)、
  industry (大煙突+横ボイラー+双炉口)、aether (塔+コア+コイル+リング)。
- 独自世界として制作 (目標画像の構図・デザインはコピーしない)。

## representative building仕様

- gearforge_civic_core: 12.5x10.5m、高さ~11m、23 mesh / 202 poly。
  stone hall + iron roof + brass trim + clock tower (Aether dial) +
  chimney (furnace lip) + copper boiler + annex + Aether windows +
  furnace mouth + pipes。

## district仕様

- gearforge_industry_works: 10.5x8.5m、煙突頂 ~10.5m、23 mesh / 234 poly。
  factory hall + 大煙突 + 横ボイラー (brass caps) + 立タンク×2 +
  双炉口 + rust vents + pipes。
- gearforge_aether_works: 8.5x8.5m、コア頂 ~9m、22 mesh / 766 poly。
  stone base + iron tower + brass cup + Aether core (icosphere) +
  coil rings×3 + copper conduits (aether strips) + ground ring + shed。
  torus由来でやや重いが総量は軽微 (Titan 58KB級と同等以下)。

## material方針

- `blender/scripts/material_lib.py` に9種集約 (Principled BSDFのみ):
  dark_iron / steel / brass / bronze / copper / stone / rust /
  aether_glow (2.5) / furnace_glow (2.2)。全アセット共通値。
- textureなし (0 texture memory)。理由: Iris Xe fill/bandwidth、
  RTS距離では無地Principledで十分、既存資産との一貫性、
  model_rules準拠。汚し・decal・atlasは量産Phaseで検討。

## texture方針

- Phase 2.5Aではtextureを導入しない (上記理由)。
- Material Makerは評価の結果、今回は未使用:
  standalone版の導入は別途完了済み。tileable noise等の用途は
  量産時 (dirt/decals/atlas) に回す。
- Krita/GIMP/Inkscape/ImageMagickも今回は未使用 (用途なし)。
  ImageMagickは必要時のresize/batch用に待機。

## camera修正

- 問題: zoom-out時に南bound不足でマップ下側が見切れる
  (画面中心 ≈ rig.z - distance のため)。
- 修正: 南clampのみzoom連動
  `max = map_limit + max(0, distance-28) * 0.75`。
  北・東西・速度・edge・zoom操作は不変。drift影響なし。
- 検証: dist60→76.0 / dist28→52.0 / 北-52.0 をprobeで確認。
  camera_test PASS。1280・1920で目視確認。

## Godot integration

- `game/scenes/maps/phase25a_showcase.tscn` (+.gd): 新規独立シーン。
  既存マップ・logic無改変。civic + 2 district + 固定2領土
  (hard frontline) + 5v5 skirmish + 最小HUD (FPS)。
- GLB pipeline維持: scripts→source/.blend→exports/.glb→
  game/assets/models/*.glb (+.import追跡) → headless import。
- `game/tests/phase25a_test.gd`: city・district・領土・前線・10体をassert。

## performance方針

- 静的primitive + 共有material。Sun影ON維持、小物・FX影OFFの方針は踏襲。
  毎フレーム生成なし。
- 実測 (showcase+戦闘): 1080pで38〜59 (平均~43)、1280で46〜58。
  Phase 2D実績 (平均41〜44) と同等。継続30割れなし。

## 今後の量産方針

- material_lib拡張 (色バリエーションは値追加のみ)。
- 都市・Districtは代表3種の部品語彙 (chimney/tank/pipe/trim/glow) で展開。
- Titan → Airship → Building Setの順を推奨 (report詳述)。
- texture導入時はatlas + 共有UV + 解像度上限 (256/512) を先に決める。
