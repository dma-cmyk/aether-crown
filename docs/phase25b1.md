# Phase 2.5B.1 — Titan Productionization

最終更新: 2026-09-22
目的: Crownpiercer (LOD0確定済み) を実ゲームへ安全に投入できる状態へ仕上げる。
再デザインなし。対象は collision / selection / footprint と LOD1 のみ。

## 前提 (Phase 2.5B 確定事項、変更なし)

- Variant B / Aether Siege Engine / Crownpiercer
- LOD0: 5,228 polygons / 10,392 triangles / 8 meshes / 8 materials / texture 0
- Bounds: 7.761m W × 9.645m D × 11.390m H、接地中心原点、scale 1.0
- Anchors: muzzle / reactor_anchor / exhaust_l / exhaust_r
- `game/assets/models/gearforge_titan.glb` (719,656 bytes) は byte同一のまま

## Collision / footprint (Task 1)

旧仕様: cylinder radius 2.2 / height 9.0 @y4.5 (旧Titan寸法)。
新仕様: cylinder radius 3.0 / height 9.0 @y4.5。

- 3.0 の根拠: sole外端 ±2.39m + infantry半径 0.35m = 2.74 < 3.0
  (heavy 0.5m → 2.89 < 3.0)。脚内部への立ち入りを防ぐ最小値。
- visual半幅 3.88 に対し 3.0 = 「見た目より少し簡略化」。
  主砲オーバーハングは高所 (y7.26) のため歩兵が下を通れるのは自然。
- height 9.0 維持: hull + sensor head をカバー。薄い双煙突 (〜11.4) は意図的に除外。
- navmeshは未登録のまま (Titanはpatrol移動するため静的obstacle化は誤り)。
  chaseは attack_range 13 で停止 (3.0より十分外側)。
  attack-move通過時は move_and_slide で滑り + stuck fallbackで有界。
- targetingは中心距離ベースで変更なし。muzzle位置・発射経路不変。
- selection ring 3.4 / HP bar 11.0 は変更なし (3.0を0.4 marginで囲む)。

## Selection (Task 1)

- `SelectionManager` が VisualTitan を click-select / force-attack可能に
  (player Titanのみ選択可、enemy Titanは選択不可・攻撃対象可)。
- box-select (drag) は rts_units のまま。Titanは対象外。
- 他mapにTitanは存在しないため、Phase 1系の挙動は不変。

## LOD1 (Task 2)

- `blender/scripts/make_gearforge_titan_lod1.py` (LOD0 helper再利用、別asset)
- `blender/source/gearforge_titan_lod1.blend` / `game/assets/models/gearforge_titan_lod1.glb`
- 5 meshes / 5 materials / 4,500 triangles / 2,420 verts / texture 0 (281,780 bytes)
- material merge: steel/rust → hull (dark_iron)、bronze → trim (brass)。
  copper / Aether glow / furnace glow は維持 (color story保持)。
- 削減: rivets全8、vent slits全6、deck valves/wheels全4、cannon bore、
  cooling fins 3→1、boiler bands 3→2/side、torus major縮小、
  bevelは9大形状のみ残し他削除。
- 維持: 長左Crownspike、短右brace (+teeth 3)、幅広torso、分離脚 (+pistons)、
  双煙突、chest core、非対称、anchors 4 (LOD0と位置一致 ≤0.05)。

## LOD切替

- `VisualTitan` 内完結の距離切替。framework新設なし、Titan以外LOD化なし。
- LOD0: camera距離 32m以下。LOD1: 34m以上。hysteresis 2m、判定0.25s間隔。
- cameraは `rts_camera` group経由。`set_lod` / `lod_locked` は test/showcase用。

## Performance (Iris Xe)

- LOD0強制 1080p: min 47 / avg 48
- LOD1強制 1080p: min 48 / avg 49
- auto (strategic 43m, LOD1): min 49 / avg 50
- auto 720p: min 48 / avg 50
- stress (Titan×3, 1080p): min 42 / avg 44
- sustained 30 FPS未満なし

## Screenshots

- `docs/screenshots/phase25b1/titan_lod0.png`
- `docs/screenshots/phase25b1/titan_lod1.png`
- `docs/screenshots/phase25b1/titan_lod_strategic.png` (auto切替LOD1確認)
- `docs/screenshots/phase25b1/titan_collision_check.png` (footprint rings + infantry)
- `docs/screenshots/phase25b1/titan_multi_stress.png` (Titan×3 + collision wireframe)

## Phase boundary

Collision / selection / footprint / LOD1 / LOD切替で停止。
Airship制作・Building Set量産・Titan派生・gameplay/AI/balance改修は着手しない。
