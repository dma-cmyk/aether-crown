# Phase 2.6A Report — Gearforge Building Set Foundation

最終更新: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe
branch: `main`

## 作成した5建物

| 建物 | generator | polys/tris/mesh/mat | GLB bytes |
|---|---|---|---|
| HQ Command Core | make_gearforge_hq.py | 924 / 1,908 / 6 / 6 | 133,132 |
| Barracks | make_gearforge_barracks.py | 440 / 848 / 6 / 6 | 67,248 |
| Factory | make_gearforge_factory.py | 794 / 1,672 / 6 / 6 | 121,332 |
| Boiler Works | make_gearforge_boilerworks.py | 794 / 1,792 / 6 / 6 | 125,284 |
| Aether Well | make_gearforge_aetherwell.py | 776 / 1,652 / 6 / 6 | 110,676 |

- 全棟 texture 0、接地中心原点、front -Y、scale 1.0。
- poly目安 (HQ 2,000–4,000 / 中型 1,000–2,500 / 小型 500–1,500) を下回る棟あり。
  理由: Iris Xeで都市全景 (10棟+units) を出す前提の軽量設計。
  目視で用途差・mechanical structure成立を確認 (specは絶対値ではないと明記)。
  Polish時に固有大形状の密度追加で対応可能 (kit部品は維持)。

## 既存Assetの再利用状況

- 再利用: `material_lib.py` 共有palette (全棟)、Titan helper
  (box/cylinder/between/torus/trapezoid/join/stats) をkit経由で再利用。
  新規material 0。既存textureなし方針を踏襲。
- 不変・維持: 2.5A showcase 5 GLB、visual_slice hall/boiler、
  district primitive visuals、hq_visual.gd、Titan/Airship資産。
- 新規名で衝突回避: `gearforge_boiler_works` (既存boiler_houseと別物)、
  `gearforge_aether_well` (既存aether_worksと別物)。安全置換はMap Production時。

## Modular parts一覧

`blender/scripts/building_kit/kit.py` (+`__init__.py`)、22関数:
base_pad / hall / upper_block / gable_roof / parapet / chimney /
boiler_horizontal / tank_vertical / pipe_run / pipe_elbow / door_large /
gate_arch / wall_segment / roof_machine / vent_stack / aether_node /
aether_conduit / furnace_mouth / support_frame / catwalk / crane_bridge /
join_by_material。
備蓄 (今Phase未使用): aether_node / support_frame / catwalk。

## Blender pipeline

- `blender --background --python blender/scripts/make_gearforge_<b>.py`
  → source/.blend → exports/.glb → `tools/export_blender_to_godot.sh`
  → game/assets/models/ + headless import (Titan pipelineと同一)。
- `.blend` 手修正禁止。各generatorが正本。
- 設計修正歴: crane向き誤り (南北に逸脱) → gate軸loading gantryに作り直し。
  pad広面stone白飛び → dark iron化。HQ別館/Factory側翼/Barracks倉庫で密度補強。

## poly / tris / mesh / material / texture

- 上表の通り。合計: 3,728 polys / 7,872 tris / 30 mesh / 6 mat種類
  (dark_iron/steel/brass/copper + stone/rust/aether/furnaceを棟別選択)。
- shared material状況: 全棟同一palette値。draw callは棟あたり6。
- texture使用: なし (0 memory)。Material Maker/Krita/GIMP未使用。

## Godot integration

- showcase scene新規 (既存map/logic不変)。set row + city block各5棟。
- 全棟 `RTSBuilding` wrap: setup(null, true) → alive/select/collision確認
  (phase26a_testでassert)。faction tintはgameplay側の責務のため neutral のまま。
- scale: door 2.2–3.2m / gate 4.5m / infantry 1.8m対比をscreenshot確認。
- collision: footprint実測に合わせたBoxShape (HQ 15×13 … Aether 9×9)。
- district / building slot compatibility (確認のみ):
  production footprint (例 HQ 15.2×13.2 / Factory 14×14.5) は現行def
  (gf_hq 7×6 / factory 4×4) やdistrict primitive slotより大きい。
  gameplay mapへの投入には大slot新設が必要 → Map Production phaseの作業。
  本Phaseではlogic・slot定義を変更しない。

## Performance (Iris Xe / Forward Plus / warmup 3s / 15s)

- set row 1080p: min 43 / avg 46
- city block 1080p (10棟+8 units): min 46 / avg 47
- set row 720p: min 45 / avg 46
- sustained 30 FPS未満なし。2.5A実績 (平均~43) と同等以上。

## tests

- phase26a_test: OK (set=5/block=5/meshes=6×5/footprint実測/yaw考慮/
  接地/select+collision/Titan同梱)。
- 全regression PASS: cli_smoke / skirmish / camera / phase1_5_test /
  phase1_5_playtest (OK) / visual_slice / phase2a / 2b / 2c / 2d /
  25a / 25b / 25b1 / 25c。
- ERROR 0 / SCRIPT ERROR 0 (全runs)。

## Screenshots (8枚、docs/screenshots/phase26a/)

- building_set_overview / hq_close / factory_close / aether_works_close /
  city_block_mid / city_block_strategic / building_scale_comparison /
  modular_parts_overview。

## Visual acceptance (自己評価)

- Close: mechanical structure成立 (gate/crane/pipes/rings/core判別可)。
- Mid: 5棟の用途差明確。
- Strategic: HQ spire / Factory gate mass / Aether core+rings が判別可。
  Boiler stacks / Barracks parapetはmidで判別、strategicではmassとして読める。
- City block: 同一文明の統一感 + 用途差あり。コピー建物には見えない。

## known issues

- 参考画像2枚は内容未確認 (タイトルのみ取得)。設計は言語化要件に基づく。
- production footprintが現行slotより大きい (大slotは後続作業)。
- Barracksは440 polysと軽い。用途差は成立しているがPolish候補になりうる。
- furnace/aether emissiveはcloseで白飛び気味 (Titanと同一の既知特性)。
- `game/tests/phase25c_test.gd.uid` のuntracked残存はAirship Phaseのもの。
  本Phaseでは触らない。

## Future Polish Candidates (最大3、Polish自体は開始しない)

1. HQ Command Core — faction landmarkで最も目立つ。spire周辺のlayeringと
   annex密度の追加が効果大。
2. Factory — gate/craneのhero化 (door開閉表現・crane可動は後続判断)。
3. Aether Well — 文明のenergy signature。core/ringsの発光階調が鍵。

## Git

- 新規: blender/scripts/building_kit/ (kit.py + __init__.py)、
  make_gearforge_{hq,barracks,factory,boilerworks,aetherwell}.py、
  source/.blend×5、game/assets/models/*.glb(+.import)×5、
  phase26a_building_showcase.gd/tscn(+.uid)、phase26a_test.gd(+.uid)、
  docs/phase26a.md、reports/phase26a_report.md、docs/art/building_kit.md、
  docs/screenshots/phase26a/ 8枚。
- 変更: なし (既存ファイル無改変)。
- 不変: 2.5A資産、visual_slice、district、Titan/Airship、balance数値。

## Commit / Push Status

- commit hash: (下記 `feat: establish gearforge production building set` を参照)
- commit message: feat: establish gearforge production building set
- branch: main
- origin/main push status: pushed (確認済み)
- working tree status: clean (確認済み)

## Phase 2.6A Completion Judgment

- 完成扱い可能。全完了条件を満たす (5棟/kit/統合/showcase/block/
  performance/regression/docs/report/screenshots/commit/push/clean)。
- 次候補 (Walker / Building Polish / Map Production) はChatGPT判断待ち。
  勝手に開始しない。
