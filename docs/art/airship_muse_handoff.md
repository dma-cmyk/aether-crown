# Gearforge Airship — Muse Spark Handoff

最終更新: 2026-09-22
対象: Phase 2.5C / `gearforge_airship` / **Crownhammer**
環境: EndeavourOS / Blender 5.2.2 LTS / Godot 4.7.2 / Intel Iris Xe

## Current completion state

**Checkpoint A 完了 (design 確定)。Blender production model は未着手。**

- 採用案: Variant C 「Twin-Cell Aether Dreadnought」
- 固有名: Crownhammer
- 完了: 参考画像レビュー、旧 Airship 分析、variant 比較、Production design、scale、material 方針
- 進行中: Blender production model
- 未着手: GLB export、Godot integration、showcase、performance、tests

Checkpoint は以下の順で更新する。

| CP | 内容 | 状態 |
|---|---|---|
| A | design 確定 / design docs + handoff 保存 | 完了 |
| B | 主要 silhouette (cell / keel / prow / tail) 完成 / .blend 保存 | 未 |
| C | Production model 成立 / .blend + GLB + 数値 | 未 |
| D | Godot integration / showcase | 未 |

## 正本と再生成

- 生成 script: `blender/scripts/make_gearforge_airship.py`
- Blender 正本: `blender/source/gearforge_airship.blend`
- 中間 GLB: `blender/exports/gearforge_airship.glb`
- Godot GLB: `game/assets/models/gearforge_airship.glb`
- runtime 参照: `game/scripts/visual/visual_airship.gd`

```bash
./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_airship.py
```

## 数値仕様

Checkpoint C で確定させる。設計目標値:

| 項目 | 目標 |
|---|---|
| bounds | 13.8m W × 34.0m D × 11.2m H |
| Blender polygons | 3,500–7,000 |
| export triangles | 8,000–16,000 |
| mesh | 8 (material 単位に結合) |
| material | 8 |
| texture | 0 |

## Design 要点 (詳細は `docs/art/airship_design.md`)

3層構造: 上に2本の Aether lift cell、中央に装甲 keel hull、下面に gondola / mortar / sponson。
Aether flow は `dorsal reactor → lift cell injector (浮力) / keel conduit → belly mortar (火力) / tail thruster (推進)`。
主兵装は下面 belly siege mortar、副兵装は舷側 sponson turret ×4。

## Runtime anchors (設計値 / Checkpoint C で実測に更新)

| node | 用途 |
|---|---|
| `muzzle` | belly siege mortar 砲口。既存 `VisualAirship._try_bombard` の発射原点 |
| `weapon_l` / `weapon_r` | 舷側 sponson turret |
| `reactor_anchor` | dorsal reactor。damage / pulse FX |
| `engine_l` / `engine_r` | ducted propeller hub。将来の回転 animation |
| `exhaust_l` / `exhaust_r` | engine nacelle の炉口。steam / smoke |
| `thruster_l` / `thruster_r` | tail Aether thruster。加速 FX |

front は Blender `-Y`。GLB import 後 Godot `+Z`。
origin は飛行体のため接地中心ではなく **keel hull 中心線** (飛行原点)。

## Muse Spark next actions

1. `make_gearforge_airship.py` を実行して `.blend` / GLB を再生成できることを確認する。
2. Godot showcase で close / mid / strategic / front / back / Titan との scale 比較を撮る。
3. 読みに問題があれば script の主要寸法のみ修正し、`.blend` 直接編集はしない。
4. Titan Crownpiercer は変更しない。Airship 派生機・Building Set 量産は開始しない。
