# Phase 2.6A — Gearforge Building Set Foundation

最終更新: 2026-09-22
目的: 都市Production化の前段階として、主要5建物 + 量産用モジュール部品を成立させる。
最終Art Polishではない。Sol/Opus等による代表建築Polishの土台を作る。

## 参考画像について

指定の参考画像2枚 (imgur) は、テキストfetchではタイトル以外取得できず、
画像内容を確認できなかった。見たふりをせず、Titan/Building既存言語と
specの言語化要件 (density/用途差/pipes-tanks-chimneys/鉄鋼真鍮銅/Aether
infra/高低差/RTS readability/統一感) を設計根拠とした。

## 5建物

| 建物 | asset | footprint | 高さ | polys/tris | mesh/mat |
|---|---|---|---|---|---|
| HQ Command Core | gearforge_hq_command | 15.2×13.2m | 13.0m | 924 / 1,908 | 6 / 6 |
| Barracks | gearforge_barracks | 14.8×8.0m | 6.1m | 440 / 848 | 6 / 6 |
| Factory | gearforge_factory | 14.0×14.5m | 11.8m | 794 / 1,672 | 6 / 6 |
| Boiler Works | gearforge_boiler_works | 12.6×9.9m | 10.8m | 794 / 1,792 | 6 / 6 |
| Aether Well | gearforge_aether_well | 9.0×9.0m | 11.7m | 776 / 1,652 | 6 / 6 |

- poly数は目安 (HQ 2,000–4,000等) を下回るが、意図的な軽量設計。
  silhouette・用途差は目視確認済み。理由はreportに記録。
- texture 0。共有palette (Principled BSDF) + emissiveのみ。
- 全棟: 原点接地中心、front -Y、scale 1.0、Blender Python完全再生成。

## Silhouette差

- HQ: 中央Aether spire (3 rings) + twin tower + annex wings。最大・最高。
- Barracks: 低横長 + parapet + twin armory doors + yard walls + watch tower。
- Factory: 大gate + exit rails + loading gantry + tall chimney + wing + bunker。
- Boiler: 3-stack rhythm + twin boilers + twin tanks + pipe network + shed。
- Aether: vertical tower + tall core + 3 rings + 4 ground nodes + ground ring。最青。

## Modular kit

`blender/scripts/building_kit/kit.py` (22関数)。詳細は `docs/art/building_kit.md`。
未使用備蓄: aether_node / support_frame / catwalk (量産用)。

## 既存Assetの扱い

- 2.5A showcase資産 (civic_core/industry/aether_works/boiler_house/hall) は不変・維持。
- visual_sliceのhall/boiler dressingは不変。
- 新Boiler/Aetherは既存名衝突を避け `gearforge_boiler_works` /
  `gearforge_aether_well` とした。置き換えはMap Production時に判断。

## Godot統合

- `game/scenes/maps/phase26a_building_showcase.tscn`: set row 5棟 +
  city block 5棟 (street dressing付) + Titan + infantry 8体。
- 全棟RTSBuilding wrap (selection + footprint collision)。gameplay logic不変。
- district slot互換: 確認のみ。production footprintは現slotより大きく、
  大slot新設はMap Production phaseの作業 (report記録)。

## Screenshots (`docs/screenshots/phase26a/` 8枚)

overview / hq_close / factory_close / aether_works_close /
city_block_mid / city_block_strategic / building_scale_comparison /
modular_parts_overview。

## Performance (Iris Xe)

- set row 1080p: min 43 / avg 46
- city block 1080p: min 46 / avg 47
- set row 720p: min 45 / avg 46
- sustained 30 FPS未満なし

## Phase boundary

Building Set Foundationに集中。Map全面Production化・全City作り直し・
Walker・Infantry作り直し・Airship/Titan改造・HUD刷新・大規模VFX・
smoke大量配置・terrain改修はやらない。
