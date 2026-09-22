# Phase 2.5B — Titan Production Asset

最終更新: 2026-09-22
目的: Gearforge Titan 1体を Aether Crown の顔となる最初の Production Asset として完成させる。

## Titan 仕様

- 採用案: Variant B / Aether Siege Engine
- 固有名: **Crownpiercer**
- 役割: 前線破城用の重装二脚 Titan
- 主兵装: Crownspike Aether Siege Cannon
- 寸法: 7.761m W × 9.645m D × 11.390m H
- 識別形状: 長大な左砲、短い右 brace、幅広 torso、分離脚、双煙突
- 背面: twin boiler / exhaust、中央 Aether reactor、cyan chevron

## 制作方針

- Blender Python から完全再生成可能。`.blend` と生成 script の両方を正本とする。
- 大形状 -> 機能機構 -> 限定細部の順で配分し、遠景に残らない装飾を増やさない。
- bevel は silhouette と面分けに必要な装甲・砲身・軸に限定。
- 構成部品は modular に生成し、export 前に material 単位で8 meshへ結合。
- origin は接地中心、front は Blender `-Y` / Godot `+Z`。

## Material / texture

Phase 2.5A の `material_lib.py` から dark iron / steel / brass / bronze / copper /
rust / Aether glow / furnace glow の8種を使用。Principled BSDF のみ。

texture は0枚。Material Maker / Krita / GIMP は使用していない。現カメラ距離では
bevel、material contrast、emissive accent で十分読め、メモリと量産コストを増やさないため。

## Aether 設計

`rear reactor -> chest governor -> weapon feed -> muzzle lens` の意味がある流れに限定。
sensor visor と背面 chevron は制御/識別用。furnace orange は exhaust 口だけに使い、
Aether の cyan と燃焼熱を混同させない。

## Godot 統合

- `game/assets/models/gearforge_titan.glb` を Production GLB に差し替え。
- 現行 `VisualTitan` は同じ resource path と `muzzle` anchor を使うため、logic 無改変で反映。
- 安全な独立確認用 `phase25b_titan_showcase.tscn` を追加。ゲーム全体の main scene は変更しない。
- showcase は Titan、歩兵6体、建物2棟、圧力タンク/煙突を表示し、スケールを比較可能。
- `muzzle`, `reactor_anchor`, `exhaust_l`, `exhaust_r` を GLB に保持。

## Performance / LOD

- LOD0: 5,228 polygons / 10,392 triangles / 8 meshes / 8 materials / texture 0
- GLB: 719,656 bytes
- Iris Xe / 1920×1008 / Forward Plus benchmark: average 41 FPS / minimum 39 FPS
- sustained 30 FPS 未満なし。PNG 保存中の一時的停止は性能値から除外。
- LOD1/2 は未作成。命名は `_lod0`。将来は bevel / rivet / valve / vent slit / torus segment の順で削減する。

## Visual acceptance

- close: armor hierarchy、piston、core、barrel rail が読める。
- mid: 長砲身 / brace / twin stack / 二脚が一瞬で読める。
- strategic: 非対称と高さが残る。
- units: 歩兵1.8mとの明確なスケール差がある。
- back: twin stack / boiler / reactor で正面以外にも顔がある。
- silhouette: 発光と material を消しても主砲・肩・煙突・脚が残る。

## Screenshots

- `docs/screenshots/phase25b/titan_close.png`
- `docs/screenshots/phase25b/titan_mid.png`
- `docs/screenshots/phase25b/titan_zoomed_out.png`
- `docs/screenshots/phase25b/titan_with_units.png`
- `docs/screenshots/phase25b/titan_in_scene.png`
- `docs/screenshots/phase25b/titan_back_view.png`
- `docs/screenshots/phase25b/titan_silhouette_check.png`

## Phase boundary

今 Phase は Titan 1体で停止。Airship、Building Set、Titan 派生、gameplay / AI / balance は着手しない。

## Muse Spark Acceptance (2026-09-22)

Sol成果物を受け入れレビューし、生産コードの変更なしで受け入れ可能と判断。
詳細は `reports/phase25b_report.md` の `Muse Spark Acceptance` 節。
- 10観点 (close/mid/strategic/back/Gearforge性/建物一貫/スケール/gameplay視認/weapon/silhouette) すべてPASS。
- 微修正なし (emissive・collisionは次Phase送り、根拠をreportに記録)。
- bounds・anchor・再生成一致・benchmark両解像度・全回帰を検証済み。
