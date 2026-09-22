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
| Walker prototype | 今回新規 (`gearforge_walker_prototype`, 332 polys) | 青3 (前進楔形) + 赤2 (防御) |
| Infantry | 既存 gf_infantry | 青8 + 赤8 (静止) |
| Banners/fieldworks/roads/zones | シーン内生成 | 青旗・赤旗・赤barricade・道路・zone tint |

全棟RTSBuilding wrap (selection + collision)。gameplay logic・既存map無改変。

## 2. 修正した点

- Walker試作の新規作成 (前提に反してWalker資産は存在しなかった)。
  332 polys / 656 tris / 5 mesh、接地中心・front -Y。
- Zone tint減衰 (初期は飽和しすぎ → 青0.08/0.16/0.32・赤0.30/0.09/0.07)。
- Airship撮影はoverview方式に統一 (50° pitch rigではh26の船体追従は不可。
  上1/3配置の計算式も残したが最終的にwide framingを採用)。
- 赤基地はplaceholder (生産建物の色違い + 赤旗 + barricade)。

## 3. スケールや見た目でまだ気になる点

- Airship (35m) がRTS画面に対して巨大。高度26m・運用半径の gameplay
  影響は未検討 (今回は雰囲気のみ)。
- Zone tintは平面slabのため遠景で人工的。正式mapではterrain paintに置換要。
- Walker 4.2m vs infantry 1.8mは良好。Titan 11.4mとの階層も成立。
- 赤が生産建物の色違いのため、赤固有silhouetteは将来課題。
- Selection disc (建物) が大きい。選択UI刷新時に見直し。

## 4. 次にやるべき優先順位トップ5

1. Walker Production Asset (prototype→本制作。RTSUnit化・ faction差・LOD)。
2. Map Production Foundation (terrain paint・大slot・正式mapへの建物投入)。
3. 赤軍 visual identity (赤固有のtrim/silhouette言語)。
4. Airship運用設計 (高度・半径・爆撃のgameplay化。現状は周回のみ)。
5. Selection/UI刷新 (disc・HP bar・box選択のTitan/Walker対応)。

## 5. スクリーンショット一覧 (docs/screenshots/phase26a… ではなく prototype/)

- proto_overview.png — 全景 (青/中央/赤 + 両airship + titan + walkers)
- proto_blue_base.png — 青軍拠点 (5棟+旗+mooring mast)
- proto_walker_close.png — Walker近景 (選択ring付、前進3体)
- proto_airship.png — 青airship + 基地の対比
- proto_factory_close.png — Factory寄り (gate/crane)
- proto_aether_close.png — Aether Well寄り
- proto_red_base.png — 赤エリア (赤airship・walkers・barricade)
- proto_selection.png — 選択表示 (walker ring + infantry選択)

## Performance

- overview 1080p: min 39 / avg 39。sustained 30割れなし。
