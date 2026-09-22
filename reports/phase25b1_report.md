# Phase 2.5B.1 Report — Titan Productionization

最終更新: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe
branch: `main`

## 目的

Crownpiercer (Phase 2.5B確定) を実ゲーム投入可能な状態へ仕上げる。
再デザインなし。collision / selection / footprint + LOD1 のみ。

## Task 1: Collision / Selection / Footprint

### 調査結果 (旧仕様)

- `VisualTitan._build_markers`: cylinder radius 2.2 / height 9.0 @y4.5、
  layer 2 / mask 3。units (layer 2 / mask 3) と物理衝突する。
- visual実寸: sole外端 ±2.39m、半幅 3.88m、高さ 11.39m。
  → infantry (r0.35) は中心2.2mまで侵入 = 脚の間に立つ。既知問題の通り。
- selection ring 3.4 (solid disc) / HP bar 11.0 @y11.0。
- click-select: `_pick_target` のwalk-upが RTSUnit/RTSBuildingのみ →
  Titanはclick不可 (deselect扱い)。box-selectも rts_units のみで対象外。
- targeting: `unit.gd _nearest_enemy` は rts_units + rts_buildings を
  duck-type走査。Titanは `rts_buildings` group所属 + is_alive/take_damage/
  is_playerを持つため、敵は既に自動でTitanを狙う (中心距離ベース)。
- movement: unitsは NavigationAgent3D + move_and_slide。Titanはnavmesh
  obstacle未登録。chaseは attack_range (infantry 13) で停止するため
  接触しない。attack-move通過時は物理bodyに滑る + `_order_arrived`
  stuck fallback (2s) で有界。
- separationは rts_units間のみ。Titanは対象外で問題なし。

### 新collision仕様

- cylinder radius 3.0 / height 9.0 @y4.5 (layer/mask不変)。
- 3.0の根拠: 2.39 (sole外端) + 0.35 (infantry) = 2.74 < 3.0、
  heavy (0.5) でも 2.89 < 3.0。脚内部侵入を防ぐ最小値。
- visual半幅3.88に対し3.0 = 「見た目より少し簡略化」準拠。
  通路塞ぎすぎ防止のため全体包囲 (r3.88+) は採用しない。
- height 9.0維持の理由: hull + sensor head (~9m) をカバー。
  双煙突 (~11.4m) はthinのため除外。click raycastにも十分。
- navmeshは登録しない (Titanはpatrol移動する。静的obstacleは誤り)。
- selection ring 3.4 / HP bar 11.0 は変更なし。
  ring 3.4は新footprintを0.4 marginで囲み、視覚的に適合。

### visual / collision / navigation / selection boundsの関係

| 用途 | 値 | 差の理由 |
|---|---|---|
| visual bounds | W7.76 / H11.39 | 実形状 |
| collision (gameplay) | r3.0 / h9.0 | sole外端+ infantry半径。簡略化で通路確保 |
| navigation footprint | なし (navmesh非登録) | 移動体のため。chase停止13m + 物理slideで代替 |
| selection bounds | ring r3.4 / clickはbody形状 | collisionを囲み選択しやすく。HP bar 11.0 |

### selection変更 (最小)

- `selection_manager.gd` の `_pick_target` walk-upと
  `_is_owned_selectable` に `VisualTitan` を追加。
- player Titan: click-select可。enemy Titan: 選択不可・force-attack可
  (`_is_foe_damageable` はduck-typeのため既存logicで成立)。
- box-selectは変更なし。Titanの存在するmapはvisual_slice系のみのため
  Phase 1系の挙動不変。balance変更なし (auto-acquireは従来通り)。

### 設計判断まとめ

- gameplay balanceを変える数値 (HP/damage/range/speed/AI) は一切触らない。
- 変更は collision半径 2.2→3.0 と selection受付の2点のみ。
- muzzle / 発射経路 / patrol / HP bar位置は不変。

## Task 2: LOD1 Production

### 成果物

- generator: `blender/scripts/make_gearforge_titan_lod1.py`
  (LOD0のhelperをimport再利用。重複なし)
- source: `blender/source/gearforge_titan_lod1.blend`
- Godot: `game/assets/models/gearforge_titan_lod1.glb` (281,780 bytes)
- LOD0 (`gearforge_titan.glb`) はbyte同一のまま (再export差分を破棄)。

### 数値

- meshes 5 / materials 5 / triangles 4,500 / verts 2,420 / polygons 1,652
- texture 0。目標 4–6 mesh / 4,500–6,000 tris の範囲内。
- anchors 4 (muzzle / reactor_anchor / exhaust_l / exhaust_r) は
  LOD0と位置一致 (≤0.05、testでassert)。

### 何を削減したか

- 削除: shin rivets全8、chest vent slits全6、deck valves/wheels全4、
  cannon bore inset、cooling fins 3→1、boiler bands 3→2/side、
  knee_cap (kneeへ統合)。
- 縮小: cylinder segments 16→14等、torus major 16–18→12–14、
  pipes/pistons 10→8seg。
- bevel: LOD0のほぼ全部品 → sole/heel/hip_beam/torso/front_plate/
  cannon_shoulder/cannon_breech/brace_shoulder の9大形状のみ。
- material merge: steel/rust → hull (dark_iron)、bronze → trim (brass)。
  copper / Aether glow / furnace glow は維持。

### 何を残したか (silhouette)

- 長大左Crownspike (shroud/bands/barrel/muzzle/lens/rails/feed)
- 短右brace (teeth 3維持)
- 幅広torso + chest core/ring/vents
- 分離脚 (sole/toe/heel/shin/thigh + piston pairs)
- 双煙突 + boiler/collar/lip/heat
- rear reactor (housing/core/ring/pipes/chevron)
- sensor head (neck/head/brow/visor/rangefinder)
- 非対称 silhouette

### LOD切替方式

- `VisualTitan` 内完結のcamera距離切替。framework新設なし。
- threshold: 32m以下LOD0 / 34m以上LOD1、hysteresis 2m、判定0.25s間隔。
- camera取得は `rts_camera` group (Camera3D子) をcache。
- 切替時はvisible swap + muzzle再解決 (発射経路不変)。
- `set_lod()` / `lod_locked` / `unlock_lod()` はtest/showcase/benchmark用。
  gameplay defaultはauto (unlocked)。

## Visual確認

- Close (LOD0強制): Production Titan維持。砲・core・visor・piston・煙突判別可。
- Mid (LOD1強制・同構図): 不自然なpopなし。主要節が残る。
- Strategic (43m・auto): lod=1をログ確認。主砲・双煙突・二脚・非対称が読める。
- Collision: footprint rings (cyan r3.0 / orange r3.88) + 隣接infantry 4体が
  hullにめり込まず立つ。stress shotではdebug wireframe (r3.0 cylinder) 可視。
- LOD0維持: phase25b_test PASS (8 meshes / 4 anchors)、SS 7枚の資産不変。

## Performance (Iris Xe / Forward Plus)

| 条件 | min | avg | lod |
|---|---|---:|---|
| LOD0強制 1080p | 47 | 48 | 0 |
| LOD1強制 1080p | 48 | 49 | 1 |
| auto strategic 1080p | 49 | 50 | 1 |
| auto strategic 720p | 48 | 50 | 1 |
| stress Titan×3 1080p | 42 | 44 | 1 |

- warmup 3s / 15s計測。sustained 30 FPS未満なし。
- LOD1はLOD0比57%削減 (10,392→4,500 tris) だが単体FPS差は小さい
  (Iris XeではTitan1体がbottleneckではない)。stress時の余裕として効く。

## Regression

- cli_smoke / skirmish / camera / phase1_5_test / phase1_5_playtest /
  visual_slice / phase2a / 2b / 2c / 2d / 25a / 25b / 25b1: すべて OK
- phase1_5_playtest: 今回 OK (2:49 win)。非決定性は既知 (2.5B report記録)。
- ERROR 0 / SCRIPT ERROR 0 (全runs)。

## Screenshots

- `docs/screenshots/phase25b1/titan_lod0.png`
- `docs/screenshots/phase25b1/titan_lod1.png`
- `docs/screenshots/phase25b1/titan_lod_strategic.png`
- `docs/screenshots/phase25b1/titan_collision_check.png`
- `docs/screenshots/phase25b1/titan_multi_stress.png`

## known issues

- phase1_5_playtestの非決定性 (既知・対象外。今回はOK)。
- selection ringはsolid disc (r3.4) のまま。視覚設計の変更は本Phase対象外。
- LOD1の一部小径cylinderはLOD0同等seg (全体は57%削減のため無害)。
- Titan animation / rig / LOD2 / emissive tuningは未着手 (計画通り後続)。

## Git

- 新規: `blender/scripts/make_gearforge_titan_lod1.py`、
  `blender/source/gearforge_titan_lod1.blend`、
  `game/assets/models/gearforge_titan_lod1.glb(+.import)`、
  `game/scenes/maps/phase25b1_titan_production.gd/tscn(+.uid)`、
  `game/tests/phase25b1_test.gd(+.uid)`、
  `docs/phase25b1.md`、`reports/phase25b1_report.md`、
  `docs/screenshots/phase25b1/` 5枚。
- 変更: `game/scripts/visual/visual_titan.gd` (collision r3.0 + LOD)、
  `game/scripts/units/selection_manager.gd` (Titan受付)。
- 不変: LOD0 GLB、phase25b showcase/test、他map、balance数値。

## Commit / Push Status

- commit hash: (下記 `feat: productionize crownpiercer collision and lod` を参照)
- commit message: feat: productionize crownpiercer collision and lod
- branch: main
- origin/main push status: pushed (確認済み)
- working tree status: clean (確認済み)

## Phase 2.5B.1 Completion Judgment

- 完成扱い可能。collision確認・修正済み、selection確認済み、footprint確認済み、
  LOD1完成 (5mesh/4500tris/anchor parity)、LOD0維持、LOD切替確認 (forced+auto)、
  strategic readability確認、Iris Xe performance確認 (5条件・30割れなし)、
  regression PASS (13 suite)、ERROR 0 / SCRIPT ERROR 0、docs/report完成、
  screenshots 5枚、commit/push済み、working tree clean。
- 残件: known issues 4件はいずれも本Phase対象外として記録。Titan rig/animation/
  LOD2は後続Phaseの判断に委ねる。

## Airship Readiness

- Titanを閉じてAirshipへ進める状態。Titan production pipeline
  (generator + LOD分離 + showcase/test + benchmark)はAirshipに流用可能。
- Airshipは別AIのArt Direction予定のため、本Phaseではデザイン案を作っていない。
