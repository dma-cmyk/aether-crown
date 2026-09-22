# Phase 2.5B.2 Report — Crownpiercer Polish Productionization

最終更新: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe
branch: `main`
前提: Sol polish commit `a8f7768` (受け入れ対象)

## Sol Polishの受け入れ判断: ACCEPT

- 全面再設計ではなく、荷重・反動・圧力経路を説明するgeometry追加に限定。
  Identity (非対称主砲/双煙突/幅広torso/二脚/chest core/reactor) 維持。
- generator再実行で一致確認: TITAN_STATS 7820/7670/14964/8/8 がhandoffと一致、
  GLB accessor bounds/count 全32一致、node集合12一致。
  `.blend` 手修正なし。検証後にcommit済み `.blend` を復元しtreeをclean化。
- GLB meshes 8 / materials 8 / anchors 4 (muzzle/exhaust_l/exhaust_r/reactor_anchor)。
- bounds 7.772 × 9.645 × 11.390 (幅+0.011mのみ)。原点・scale・facing・接地不変。
- Sol 8 screenshots (titan_polish/) で side / rear の密度向上と
  silhouette維持を目視確認。
- LOD0 GLB (`gearforge_titan.glb` 1,047,796 bytes) は本Phaseで不変。

## LOD0最新数値

- verts 7,820 / polygons 7,670 / triangles 14,964 / meshes 8 / materials 8
- texture 0 / 1,047,796 bytes
- Phase 2.5B比: polygons +2,442 / triangles +4,572 (巨大ユニット目安8,000–25,000内)。

## LOD1最新数値 (再生成あり)

- 再生成した: YES。`make_gearforge_titan_lod1.py` をpolish後LOD0へ追従更新。
- 5 meshes / 5 materials / 4,804 triangles / 2,652 verts / 2,046 polygons
- texture 0 / 307,144 bytes。
- 追加の簡略再現: foot deck / ankle fork+ram / knee guard / thigh crown /
  front leg ram / glacis / torso side rib / governor keel+lock /
  cannon counterweight / trunnion / recoil cradle+ram / crossbar×1 /
  mount struts / brace crown+shock+rear block / stack stay /
  reactor cage+cross×1 / pressure pipe / rear manifold。
- 省略維持: rivets / vent slits / deck valves / bore / fins 2/3 /
  boiler bands 1/3 / knee cap / press plate / side rail / manifold valve。
- 寸法追従: sole 1.74 / shin 1.10 / thigh 1.26 / plate 1.40。
- material merge方針は2.5B.1のまま (steel/rust→hull、bronze→trim)。
- 過剰segの適正化: brace piston / reactor pipe 14→8、
  lens 14→8、feed維持8 (いずれもLOD0以下)。
- anchors 4はLOD0と位置一致 (phase25b1_testで≤0.05をassert)。

## LOD切替

- 変更なし: 32m以下LOD0 / 34m以上LOD1、hysteresis 2m、0.25s判定。
- forced + auto をtestでassert。close/mid/strategicでpopなし
  (同構図lod0/lod1比較 + strategic autoログ lod=1)。

## collision / selection / footprint (変更なし)

- collision cylinder r3.0 / h9.0 @y4.5、layer/mask不変。
- sole外端 約2.45m + infantry 0.35 = 2.80 < 3.0 (heavy 2.95 < 3.0)。
  巨大collision化は不要と判断。
- selection ring 3.4 / HP bar 11.0 / click-select (playerのみ) 維持。
- navmesh非登録・中心距離targetingの方針維持。
- visual差: cyan r3.0 / orange r3.88 rings + infantry隣接で可視確認。
  stress shotではdebug wireframe (r3.0) 可視。

## anchor変更有無

- なし。Solが4 anchorの名前・座標・意味を不変と記録し、GLB node名 +
  Godot実測 (phase25b1_test parity + visual_slice発射) で確認。
- weapon FX / TitanShell spawnは新主砲先端と一致 (muzzle不変のため)。

## FPS (Iris Xe / Forward Plus / warmup 3s / 15s)

| 条件 | min | avg | lod |
|---|---|---:|---|
| LOD0強制 1080p | 48 | 50 | 0 |
| LOD1強制 1080p | 48 | 50 | 1 |
| auto strategic 1080p | 47 | 49 | 1 |
| auto strategic 720p | 47 | 49 | 1 |
| stress Titan×3 1080p | 46 | 48 | 1 |

- sustained 30 FPS未満なし。
- LOD0 +44% trisでも2.5B.1比で実用上の悪化なし (誤差範囲内)。
- LOD1はLOD0比68%削減 (14,964→4,804 tris)。

## tests

- phase25b1_test: OK (collision_r=3.0 / lod0=8 / lod1=5 / anchors=4 /
  select=player-only / forced+auto swap)。
- phase25b_test: OK (8 meshes / 4 anchors)。LOD0維持の証拠。
- visual_slice_test: OK (muzzle発射経路)。
- cli_smoke / skirmish / camera / phase1_5_test / phase2a / 2b / 2c / 2d /
  25a / 25c: すべて OK。
- phase1_5_playtest: OK (3:01 win)。非決定性は既知 (2.5B記録)。
- ERROR 0 / SCRIPT ERROR 0 (全runs)。

## Screenshots

- Sol: `docs/screenshots/titan_polish/` 8枚 (close/mid/side/zoomed_out/
  with_units/in_scene/back_view/silhouette_check)。
- 追加: `docs/screenshots/phase25b2/` 5枚 (titan_lod0 / titan_lod1 /
  titan_lod_strategic / titan_collision_check / titan_multi_stress)。
- `docs/screenshots/phase25b1/` 5枚は復元・不変 (2.5B.1記録保護)。

## known issues

- phase1_5_playtestの非決定性 (既知・対象外。今回はOK)。
- selection ringはsolid discのまま (対象外)。
- rig / walk-recoil animation / LOD2 / decalは未着手 (計画通り後続)。
- `game/tests/phase25c_test.gd.uid` のuntracked残存はAirship Phaseの成果物。
  本Phaseでは触らない。

## Titan最終判断: 閉じてよい

- Polish受け入れ・LOD1最新化・切替・collision・selection・footprint・
  anchor・performance・regressionの全完了条件を満たす。
- Airship (Opus製) 統合の前提としてTitan側の残件なし。

## Git

- 変更: `blender/scripts/make_gearforge_titan_lod1.py` (polish追従)、
  `blender/source/gearforge_titan_lod1.blend`、
  `game/assets/models/gearforge_titan_lod1.glb`、
  `game/scenes/maps/phase25b1_titan_production.gd` (撮影先phase25b2分離 +
  capture時stress spawn分離)。
- 新規: `docs/phase25b2.md`、`reports/phase25b2_report.md`、
  `docs/screenshots/phase25b2/` 5枚、handoff追記。
- 不変: LOD0 GLB/blend/generator、visual_titan.gd、selection_manager.gd、
  phase25b showcase/test、phase25b1 screenshots、balance数値。

## Commit / Push Status

- commit hash: (下記 `feat: finalize polished crownpiercer production asset` を参照)
- commit message: feat: finalize polished crownpiercer production asset
- branch: main
- origin/main push status: pushed (確認済み)
- working tree status: clean (確認済み)

## Phase 2.5B.2 Completion Judgment

- 完成扱い可能。上記すべての完了条件を満たす。残件は後続計画内のみ。
- 次はOpus製AirshipのMuse Spark統合予定。本PhaseでAirshipには着手していない。
