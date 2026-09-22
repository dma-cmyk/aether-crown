# Phase 2.5C.1 — Crownhammer Production Integration

最終更新: 2026-09-22
目的: Crownhammer (Opus 5 Production Modeling済み) を正式に扱える
Production Airship Assetへ移行する。再デザインなし。gameplay system完成は対象外。

## Production scene構造

- `VisualAirship` (Node3D) がwrapper: `_visual_lod0` / `_visual_lod1` /
  `CollisionBody` (StaticBody3D) / code anchors / markersを分離所有。
- 見た目meshとgameplay collisionは密結合しない (別node)。
- per-instance設定 (cruise_height/radius/speed, bombard_enabled, scale,
  is_player, center) はSol passのまま維持。gameplay default不変。

## Collision構成

- Mesh collision不使用。`CollisionBody` (layer 2 / mask 0) + 3 BoxShape:
  hull (4.8×25.0×4.6 @y-0.5)、cells (13.4×28.5×5.6 @y-0.15)、
  gondola (4.2×7.0×3.6 @y-7.3)。
- nose/tail先端・砲身は意図的に除外 (巨大hitbox化防止)。
- 高度変更に強い (bodyがshipと一体移動)。ground unit設計は流用しない。

## Selection方式

- click-select対応 (`SelectionManager` にVisualAirship受付、playerのみ)。
  box-select対象外。UI刷新なし。
- 表示: 本体HP bar (billboard、選択時のみ) + 地面投射ring outline
  (TorusMesh r11、faction色、高度・bob・scaleに追従)。
- 巨大地面discは使わない (一度solid discで撮影しoutlineに修正)。
- take_damageは実装しない (combat scope外)。敵airshipはforce-attack不可、
  通常orderは地面扱いにfallthrough。

## Anchors一覧

- GLB 12 (LOD0/LOD1同座標): muzzle / weapon_l / weapon_r /
  reactor_anchor / engine_l / engine_r / exhaust_l / exhaust_r /
  thruster_l / thruster_r / bow_lens / bridge_anchor。
- code追加3: center_anchor (0,0,0) / selection_anchor (0,7.5,0) /
  healthbar_anchor (0,8.6,0)。将来のVFX/weapon/UI接続用。
- bombardは従来通りglobal_position発射 (muzzle移行はweapon実装時)。

## LOD

- LOD0: 8 mesh / 8 mat / 14,500 tris (不変)。
- LOD1: 6 mesh / 6 mat / 4,736 tris (LOD0比33%)。bronze→brass /
  rust→hull merge。rings/injectors/stringers/ribs削減、sponson単装化、
  segments縮小。silhouette維持項目は全保持。
- 切替: 40m以下LOD0 / 45m以上LOD1、hysteresis 5m、判定0.25s。
  Titanと同一API (set_lod/lod_locked/unlock_lod)。
- 周回shipは軌道によりbandを横切る (正常動作。hysteresisでflickerなし)。

## Bounds

- 14.21m W × 35.45m L × 11.38m H (LOD0実測、phase25c_testと一致)。
  原点はkeel中心 (飛行体のため接地例外)。35m級実寸を維持。

## Prototype再統合

- prototype_battlefield.gd無改変。scale 0.46/0.44、cruise個別設定、
  bombard disabled、2機構成を維持確認。
- VisualAirship拡張は後方互換 (defaults不変)。gameplay sceneへの
  scale波及なし (testでscale 1.0 assert)。

## Performance (Iris Xe)

- 25c1 showcase LOD0強制 1080p: min 40 / avg 41
- 25c1 showcase LOD1強制 1080p: min 41 / avg 41
- 25c1 showcase LOD0強制 720p: min 40 / avg 44
- 25c1 auto: 軌道依存でlod往復 (正常)。min 38–43 / avg 42–43
- prototype 1080p: min 35 / avg 36 (旧codeでも35/35で同一。新旧差なし。
  既知値41/42からの低下はSol readability passの内容量増による)
- sustained 30 FPS未満なし。texture追加なし。material増加なし (6 merge)。

## Tests

- phase25c1_test (新規): load / LOD0=8 / LOD1=6 / collision=3 /
  anchors 15 / bounds / 地面非接触 / faction / scale 1.0 /
  select=player-only / take_damageなし / forced+auto切替。PASS
- phase25c_test (既存): PASS (8 mesh / 12 anchors / 35.45m)。
- 全regression 17 suite PASS。ERROR 0 / SCRIPT ERROR 0。

## Screenshots (`docs/screenshots/phase25c1/` 6枚)

overview / titan_scale / base_scale / selection / lod0 / lod1。

## Known issues

- auto LODのbenchmark値は軌道位相依存 (forced値で評価すること)。
- 敵airshipは攻撃不可 (combat scope外。将来のweapon system時に再設計)。
- Airship高度26m・運用半径のgameplay影響は未検討 (prototype notes継承)。
- LOD1のfin/tailplaneは近似再現 (遠景用。LOD0不変)。
- `game/tests/phase25c_test.gd.uid` は引き続きuntracked (本Phaseでも不問。
  25c test自体はPASS)。

## 次候補 (最大3)

1. Airship weapon system (mortar/sponson gameplay化、muzzle接続)。
2. Walker Production Asset (RTSUnit化・LOD。prototype notes継承)。
3. Map Production Foundation (大slot・terrain・正式投入)。
