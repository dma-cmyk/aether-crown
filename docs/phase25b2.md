# Phase 2.5B.2 — Crownpiercer Polish Productionization

最終更新: 2026-09-22
目的: Sol / Codex の Reference-Informed Visual Polish を受け入れ、
LOD1再同期・collision再確認・runtime検証を行い Titan を最終的に閉じる。
再デザインなし。Airshipには着手しない。

## 受け入れ (Task 1)

- Sol成果物 commit `a8f7768` を受け入れ。全面再設計ではなくPolish。
- generator再実行で accessor bounds/count 全32一致、mesh 8 / material 8 /
  node 12一致。`.blend` 手修正なし (source of truth維持)。
- LOD0最新数値: 7,820 verts / 7,670 polygons / 14,964 triangles /
  8 meshes / 8 materials / texture 0 (1,047,796 bytes)。
- bounds 7.772 W × 9.645 D × 11.390 H (幅のみ+0.011m、depth/height不変)。
  原点接地中心、scale 1.0、front -Y 不変。
- Identity維持: 非対称主砲 / 双煙突 / 幅広torso / 二脚 /
  chest Aether core / rear reactor。

## LOD1再同期 (Task 2)

- `blender/scripts/make_gearforge_titan_lod1.py` をpolish後LOD0へ追従。
- 追加の簡略再現: foot deck / ankle fork / ankle ram / knee guard /
  thigh crown / front leg ram / glacis / side rib / governor keel /
  governor lock / counterweight / trunnion / recoil cradle+ram /
  crossbar 1 / mount struts / brace crown / brace shock / rear block /
  stack stay / reactor cage / pressure pipe / manifold。
- 寸法追従: sole 1.74 / shin 1.10 / thigh 1.26 / plate 1.40。
- LOD1最新数値: 5 meshes / 5 materials / 4,804 triangles /
  2,652 verts / texture 0 (307,144 bytes)。
- anchors 4はLOD0と位置一致 (testでassert)。
- LOD0 GLBはbyte同一のまま。

## LOD切替 (Task 3)

- 変更なし: 32m以下LOD0 / 34m以上LOD1、hysteresis 2m、判定0.25s。
- forced + auto切替をtestでassert。close/mid/strategicで不自然なpopなし。

## Collision / Selection / Footprint (Task 4)

- 変更なし: collision r3.0 / h9.0、selection ring 3.4、click-select維持。
- sole外端 2.39→約2.45mでも 2.45 + 0.35 = 2.80 < 3.0 (heavy 2.95 < 3.0)。
- navmesh非登録・targeting中心距離の方針維持。

## Runtime Anchors (Task 5)

- 変更なし: muzzle (-2.72, -6.92, 7.26) 等4 anchorの名前・座標・意味不変。
- LOD0/LOD1 parity + visual_slice発射経路で確認。

## Godot実機確認 (Task 6)

- Sol 8構図 (`docs/screenshots/titan_polish/`) でidentity確認。
- 追加5構図 (`docs/screenshots/phase25b2/`): lod0 / lod1 /
  lod_strategic (auto LOD1) / collision_check / multi_stress。

## Performance (Task 7, Iris Xe)

- LOD0強制 1080p: min 48 / avg 50
- LOD1強制 1080p: min 48 / avg 50
- auto strategic 1080p: min 47 / avg 49 (LOD1)
- auto strategic 720p: min 47 / avg 49
- stress Titan×3 1080p: min 46 / avg 48
- sustained 30 FPS未満なし。Polish (+44% tris) による実用上の悪化なし。

## Phase boundary

Titanは本Phaseで最終的に閉じる。Airship (Opus製・別途統合予定) には着手しない。
残件は rig/animation/LOD2/decal のみ (計画通り後続判断)。
