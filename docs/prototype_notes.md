# Prototype Battlefield Notes

最終更新: 2026-09-22
Scene: `game/scenes/maps/prototype_battlefield.tscn`
目的: 統合確認用 vertical slice (プレイアブル・balance対象外)。

## 実行/確認手順

```bash
# 対話確認 (Iris Xe推奨)
godot --path game res://scenes/maps/prototype_battlefield.tscn
# 撮影 (8枚、docs/screenshots/prototype/)
godot --path game res://scenes/maps/prototype_battlefield.tscn -- --capture-proto
# 集中修正パス撮影 (6枚、docs/screenshots/prototype_polish/)
godot --path game res://scenes/maps/prototype_battlefield.tscn -- --capture-proto-polish
# benchmark (warmup 3s / 15s)
godot --path game res://scenes/maps/prototype_battlefield.tscn -- --benchmark-proto [--res-720p]
# test
godot --headless --path game --script res://tests/prototype_battlefield_test.gd
```

## 1. 統合できたアセット一覧

| アセット | 出典 | 配置 |
|---|---|---|
| HQ Command Core | 2.6A新規 | 青基地 |
| Barracks | 2.6A新規 | 青基地 + 赤基地(placeholder) |
| Factory | 2.6A新規 | 青基地 + 赤基地(placeholder) |
| Boiler Works | 2.6A新規 | 青基地 + 赤基地(placeholder) |
| Aether Well | 2.6A新規 | 青基地 |
| Crownpiercer Titan | 2.5B.2確定 | 中盤 (青) |
| Crownhammer Airship | 2.5C確定 | 青・赤 各1 (周回中) |
| Walker prototype | 集中修正 (`gearforge_walker_prototype`, 822 polys / 1,548 tris) | 青3 (前進楔形) + 赤2 (防御) |
| Infantry | 既存 gf_infantry | 青9 + 赤9 (静止) |
| Banners/fieldworks/roads/zones | シーン内生成 | 青旗・赤旗・前線cover・道路・抑えたzone tint |

全棟RTSBuilding wrap (selection + collision)。gameplay logic・既存map無改変。

## 2. 集中修正パス (2026-09-22)

- 飛行船: 共有アセット/通常シーンの既定値は維持し、このシーンだけ青46%、赤44%へ縮小。
  高度23–25m・後方9–10m半径の低速待機軌道へ移し、HQと前線を隠さない支援兵器にした。
  雰囲気確認シーンなので爆撃は停止。
- 建物: HQにcommand ringとbeacon、Factoryに出撃apron/cargo、Aether Wellに
  containment ring/pylon、Barracks周辺に低い通信mastを追加。建物本体の再制作なしで
  中枢・生産・発電・支援の役割差を補強した。
- Walker: Blender generatorから再制作し、広い足、toe/heel、shin/thigh装甲、knee、
  piston、肩deck、砲盾、recoil rail、counterweight、双排気を追加。5 shared materials、
  texture 0枚、822 polys / 1,548 tris / 117,580 bytes。選択表示は円盤から細いringへ変更。
- 構図: 全面を横切っていた黄色帯を中立色の争奪地帯と点線へ整理。Walkerを楔形と
  防御線に分け、歩兵を随伴配置し、低いcover・scorch・控えめなtracerで前線を明示。
- 照明: 青fillを少し抑え、前線東側へ弱い暖色fillを追加。陣営差を読みやすくした。

## 3. スケールや見た目でまだ気になる点

- Airship本体は35m級のまま。今回はscene-local scaleで構図を調整したため、正式な
  gameplay寸法・飛行高度・selection/collisionは別途設計が必要。
- Zone tintは平面slabのため遠景で人工的。正式mapではterrain paintに置換要。
- Walker 4.2m vs infantry 1.8mは良好。Titan 11.4mとの階層も成立。
- 赤が生産建物の色違いのため、赤固有silhouetteは将来課題。
- Selection disc (建物) が大きい。選択UI刷新時に見直し。

## 4. 次にやるべき候補 (優先順3つ)

1. Walker Production Asset化: rig/歩行・反動、正式RTSUnit統合、LOD、faction marking。
2. Map Production Foundation: terrain paint、高低差、正式cover/navigationへ置換。
3. 赤軍visual identity + 最小combat VFX: 固有silhouetteと着弾/射線の情報設計。

## 5. 集中修正パスのスクリーンショット

`docs/screenshots/prototype_polish/`

- `rts_overview.png` — 全景。拠点・争奪帯・両軍の三層構図。
- `blue_base_roles.png` — HQ / Factory / Power / Supportの配置とサイズ差。
- `frontline_clash.png` — 楔形Walker、随伴歩兵、防御線。
- `walker_scale.png` — Walkerの強化silhouetteと歩兵との比較。
- `building_role_angle.png` — 建物役割差を別距離から確認。
- `airship_support.png` — 縮小・後方配置した支援飛行船と拠点の関係。

## 6. 以前のスクリーンショット (`docs/screenshots/prototype/`)

- proto_overview.png — 全景 (青/中央/赤 + 両airship + titan + walkers)
- proto_blue_base.png — 青軍拠点 (5棟+旗+mooring mast)
- proto_walker_close.png — Walker近景 (選択ring付、前進3体)
- proto_airship.png — 青airship + 基地の対比
- proto_factory_close.png — Factory寄り (gate/crane)
- proto_aether_close.png — Aether Well寄り
- proto_red_base.png — 赤エリア (赤airship・walkers・barricade)
- proto_selection.png — 選択表示 (walker ring + infantry選択)

## Performance

- Intel Iris Xe / Forward+ / 1280×720 / 15秒: min 40 / avg 42 FPS。
- Intel Iris Xe / Forward+ / 1920×1080 / 15秒: min 41 / avg 42 FPS。
- `prototype_battlefield_test.gd`: 拠点・役割prop・5 Walker・2 Airship・20 unitを検証。
