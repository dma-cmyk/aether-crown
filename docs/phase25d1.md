# Phase 2.5D.1 — Ironstride Production Integration

最終更新: 2026-09-22
目的: Ironstride (Phase 2.5D Production Modeling済み) を正式に扱える
Production Walker Assetへ移行する。再デザインなし。RTSUnit化・combat・
animation は対象外 (Phase 2.5D仕様の「Muse Spark工程」が本Phase)。

## Production scene構造

- `VisualWalker` (CharacterBody3D) がwrapper: `_visual_lod0` /
  `_visual_lod1` / CollisionShape3D ×2 / faction plates / code anchors /
  markersを分離所有。VisualTitan / VisualAirshipと同一API
  (setup / set_lod / lod_locked / unlock_lod / find_anchor)。
- 見た目meshとgameplay collisionは密結合しない (別node)。
- `is_player` でfaction判定。GLBとpaletteはGearforge neutralのまま。

## Collision構成

- Mesh collision不使用。BoxShape ×2 (layer 2 / mask 3):
  torso (2.2×1.2×2.0 @y3.0) + legs (3.5×2.4×2.3 @y1.2)。
- 砲身先端・足先は意図的に除外 (hitboxが視覚を超えないように)。
- 建物/Titanと違い脚部hitboxが接地側に来る2段構成。

## Selection方式

- click-select対応 (`SelectionManager` にVisualWalker受審、playerのみ)。
  box-select対象外 (rts_units維持)。
- 表示: HP bar (billboard、選択時のみ、y5.2) + 地面ring (TorusMesh r2.2、
  faction色)。3.54m footprintに対するring径は歩兵ringとTitan ringの中間。
- faction plate overlay: 両肩外面 (±1.34, 3.18, 0.1) に青/赤の板。
  共有GLB・paletteは不変 (showcase方針をruntime化)。
- take_damageは実装しない (combat scope外)。敵walkerは攻撃不可、
  通常orderは地面扱いにfallthrough。

## LOD

- LOD0: 4 mesh / 17 surface / 5 mat / 3,960 tris (不変)。
- LOD1: 4 mesh / 5 mat / **1,784 tris (LOD0比45%)**。
  GLB 130,328 bytes (LOD0 284,044の46%)。
- LOD1は4 group / 4 pivot / 8 anchor構造を完全維持:
  - 削減: foot claw/spur/cleat/bolt、shin rib、副ram、hull strake、
    hatch/step、smoke半減、segments 14/12/10/8→10/8/6。
  - 維持: A-frame digitigrade脚、低広hull、recoil cannon、双排気、
    faction plate、sensor slit、regulator、capacitor core。
  - LOD0/LOD1でanchor・pivot座標は同一 (test assert、許容0.05m)。
- 切替: 22m以下LOD0 / 26m以上LOD1、hysteresis 4m、判定0.25s。
  4.5m級は近接で読ませるためTitan (40/45m) より近いband。
- generator: `blender/scripts/make_gearforge_walker_lod1.py`
  (make_gearforge_walker.pyのstation/helperを再利用、複製なし)。

## Anchors

- GLB 8 (LOD0/LOD1同座標): muzzle / center_anchor / reactor_anchor /
  exhaust_l / exhaust_r / weapon_secondary / piston_l / piston_r。
  座標はPhase 2.5Dのruntime anchors表と同一。
- code追加1: healthbar_anchor (0, 5.2, 0)。
- pivot 4: leg_l / leg_r / turret / hull (将来のwalk・traverse用)。

## Prototype再統合

- `prototype_battlefield.gd` の5体 (青3+赤2) を仮置きNode3D+prototype GLB
  からVisualWalker本番wrapperに置換。位置・yaw・選択状態は維持。
- 旧 `_place_walker` (手製ring・faction plate・collision) は削除し、
  wrapper側の本番実装に一本化。`gearforge_walker_prototype.glb` は
  phase25d showcase (比較用) のみで使用継続。
- prototype test (walkers=5 / grounded) は無改修でPASS。

## Performance (Iris Xe)

- 25d1 showcase LOD0強制 1080p: min 39 / avg 40
- 25d1 showcase LOD1強制 1080p: min 36 / avg 40
- 25d1 showcase LOD0強制 720p: min 40 / avg 43
- 25d1 showcase LOD1強制 720p: min 43 / avg 45
- 25d1 auto 720p: min 45 / avg 46 (視点26mでLOD1安定)
- prototype 1080p (本番walker 5体): min 35 / avg 35
  (25c1時と同一値。walker差し替えによる低下なし)
- sustained 30 FPS未満なし (1080p showcase除く)。LOD1でtris 55%減が
  軽量シーンではboundされない (draw call主体の既知傾向)。

## Tests

- phase25d1_test (新規): load / LOD0=4 / LOD1=4 / collision=2 /
  anchors 8+pivots 4 (LOD間座標一致) / bounds 4.54m (4.0–5.2) /
  footprint (3.0–4.8) / 接地 / faction / scale 1.0 /
  select=player-only / take_damageなし / forced+auto切替。PASS
- prototype_battlefield_test (既存無改修): PASS。
- 回帰: phase25d / phase25c1 / phase25b1 / phase26a /
  visual_slice / skirmish / cli_smoke。全PASS。
- ERROR 0 / SCRIPT ERROR 0 (`--quit-after`起動確認済み)。

## Screenshots

- `docs/screenshots/phase25d1/` 6枚: production_overview / selection /
  lod0 / lod1 / titan_scale / frontline_integration。
- prototype (8枚) / prototype_polish (6枚): 本番walker差し替え後に
  再撮影 (構図・枚数は不変)。

## Known issues

- 敵walkerは攻撃不可 (combat scope外。weapon system時に再設計)。
- walk / traverse / recoil animation未実装 (pivot構造のみ準備)。
- LOD1 benchmark差が小さい (シーンがcollision/markers主体のため。
  量産時のdraw call削減効果は今後の大量配置検証で確認)。

## 次候補 (最大3)

1. Walker weapon system (recoil cannon gameplay化、muzzle接続)。
2. Walker walk animation (pivot駆動、歩行FX)。
3. Map Production Foundation (大slot・terrain・正式投入)。
