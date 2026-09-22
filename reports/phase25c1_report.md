# Phase 2.5C.1 Report — Crownhammer Production Integration

最終更新: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe
branch: `main`
前提: Opus 5 Production Modeling (2.5C) + Sol readability pass (bdeb47f)

## 変更内容

- `game/scripts/visual/visual_airship.gd` 拡張 (+213行):
  LOD0/LOD1二重所有 + 距離切替、3-box collision、selection markers、
  code anchors 3、is_alive/set_selected、Titan同一LOD API。
  cruise/bombard/faction logicは不変。
- `game/scripts/units/selection_manager.gd`: VisualAirship受付
  (walk-up + _is_owned_selectable)。box-select・他map不変。
- 新規: `blender/scripts/make_gearforge_airship_lod1.py`、
  `blender/source/gearforge_airship_lod1.blend`、
  `game/assets/models/gearforge_airship_lod1.glb(+.import)`、
  `game/scenes/maps/phase25c1_airship_production.gd/tscn(+.uid)`、
  `game/tests/phase25c1_test.gd(+.uid)`、
  `docs/phase25c1.md`、本report、
  `docs/screenshots/phase25c1/` 6枚。
- 不変: LOD0 GLB/blend/generator、prototype_battlefield.gd、
  gameplay scenes、balance数値。

## Production scene構造

`VisualAirship`
├─ `_visual_lod0` (GLB, 8 mesh)
├─ `_visual_lod1` (GLB, 6 mesh)
├─ `CollisionBody` (StaticBody3D, layer 2/mask 0)
│  ├─ hull / cells / gondola (BoxShape×3)
├─ center_anchor / selection_anchor / healthbar_anchor
├─ _proj_ring (TorusMesh outline, 地面追従)
└─ _hp_bg / _hp_fg (billboard)

## Collision構成

- hull (4.8, 25.0, 4.6) @ (0,-0.5,0.2): keel + girder + gondola上部
- cells (13.4, 28.5, 5.6) @ (0,-0.15,3.3): twin lift cells (先端除く)
- gondola (4.2, 7.0, 3.6) @ (0,-7.3,-2.6): bridge/command域 (下方click用)
- nose/tail tips・砲身は除外。根拠はdocs/phase25c1.md。

## Selection方式

- click-select (playerのみ)、box-select対象外。
- 本体HP bar + 地面投射ring outline (r11、faction色)。
- solid disc案は撮影で却下→outline化。UI刷新なし。
- take_damageなし → foe airshipはforce-attack不可 (仕様)。

## Anchors一覧

- GLB 12: muzzle (0,-3.46,-4.66) / weapon_l/r (±4.5,-6.8,-0.48) /
  reactor_anchor (0,4.2,KEEL_TOP+2.6) / engine_l/r (±5.2,8.95,-0.62) /
  exhaust_l/r (±5.2,4.45,-0.62) / thruster_l/r (±1.2,TAIL_TIP-0.45,0.2) /
  bow_lens (0,PROW_TIP+0.8,0.85) / bridge_anchor (0,-10.55,-2.3)。
  LOD0/LOD1同座標 (testで≤0.05 assert)。
- code 3: center (0,0,0) / selection (0,7.5,0) / healthbar (0,8.6,0)。

## LOD0 / LOD1 stats

- LOD0: 6,908 polys / 14,500 tris / 8 mesh / 8 mat / 0 texture。
  14.21 × 35.45 × 11.38m。
- LOD1: 1,992 polys / 4,736 tris / 6 mesh / 6 mat / 0 texture (315,784 bytes)。
  LOD0比33%。bronze→brass、rust→hull merge。
- 削減: rings 6→3、injectors 6→3/side、stringers 4→2、ribs/saddles減、
  sponson複装→単装、seg 20/18/16/14→12/10、中小bevel削除。
- 維持: twin cells / prow / keel / girder / gondola / mortar /
  sponsons / nacelle+prop / H-tail / thrusters / reactor / 12 anchors。

## Bounds

- 上記の通り35m級実寸維持。prototype scale (0.46/0.44) と分離。
  testでproduction scale 1.0 + length≥30/width≥12をassert。

## Performance

- 25c1 LOD0 1080p: min 40 / avg 41。LOD1 1080p: min 41 / avg 41。
  LOD0 720p: min 40 / avg 44。auto: min 38–43 / avg 42–43 (軌道依存)。
- prototype 1080p: min 35 / avg 36。新旧code同一値 (35/35) のため
  本Phaseのregressionなし。既知値からの低下はSol pass内容量増による。
- sustained 30未満なし。LOD有効 (forced比較で同等以上)。

## Tests

- phase25c1_test: PASS (上記全項目 + forced/auto切替)。
- 既存phase25c_test: PASS。
- 全17 suite: cli_smoke / skirmish / camera / phase1_5_test /
  phase1_5_playtest (OK) / visual_slice / phase2a / 2b / 2c / 2d /
  25a / 25b / 25b1 / 25c / 25c1 / 26a / prototype。ALL PASS。
- ERROR 0 / SCRIPT ERROR 0。

## Screenshots

`docs/screenshots/phase25c1/`: overview / titan_scale / base_scale /
selection / lod0 / lod1 (6枚)。

## Known issues

- auto benchmarkのlod表示は軌道位相依存 (評価はforced値で)。
- 敵airship攻撃不可・高度/半径のgameplay未検討 (継承)。
- LOD1 finは近似 (LOD0不変)。
- phase25c_test.gd.uidはuntrackedのまま (test自体PASS)。

## Commit / Push Status

- commit hash: (下記 `feat: productionize crownhammer airship integration` を参照)
- commit message: feat: productionize crownhammer airship integration
- branch: main
- origin/main push status: pushed (確認済み)
- working tree status: clean (確認済み。phase25c_test.gd.uidのuntrackedは除く)

## Phase 2.5C.1 Completion Judgment

- 完成扱い可能。全完了条件を満たす (integration/collision/selection/
  anchors/LOD0確認/LOD1作成切替/prototype再統合/scale非波及/headless test/
  ERROR 0/benchmark/screenshots/report/commit/push)。
- 残件はknown issues + 次候補3件のみ。Airship gameplay systemは別scope。
