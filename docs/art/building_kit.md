# Gearforge Building Kit

最終更新: 2026-09-22 (Phase 2.6A)
目的: 都市量産時に「建物ごとにゼロから作らない」ための共有部品・規則集。
実装: `blender/scripts/building_kit/kit.py` (Titan helper再利用)。

## Building visual rules

- 用途はsilhouetteで区別 (HQ=spire+twin tower / Barracks=parapet+横長 /
  Factory=gate+crane / Boiler=3 stacks / Aether=tower+rings)。
- 同じ箱に煙突だけ変える差別化は禁止。各建物に固有の大形状を1つ以上持たせる。
- Primary: 低く広い台形・分厚い直方体・大径円筒 (visual_language準拠)。
- bevelは大形状の面分けのみ。小部品はbevelなし。
- 原点は接地中心、front -Y、scale 1.0、texture 0。

## Module一覧 (kit.py)

| 部品 | 関数 | 用途 |
|---|---|---|
| base_pad | `base_pad` | 接地盤 (dark iron推奨) |
| hall | `hall` | 本体量塊 |
| upper_block | `upper_block` | 上部増築 (annex/monitor/shed) |
| gable_roof | `gable_roof` | 切妻屋根 |
| parapet | `parapet` | 城壁rim+隅柱 (military) |
| chimney | `chimney` | 煙突 (r/h可変、collar+lip+heat) |
| boiler_tank | `boiler_horizontal` | 横ボイラー+ bands |
| vertical_tank | `tank_vertical` | 立タンク + band + cap |
| straight_pipe | `pipe_run` | 2点間pipe |
| pipe_elbow | `pipe_elbow` | 90度継手+ joint |
| large_conduit | `aether_conduit` | 細径発光pipe |
| vent | `vent_stack` | 屋根vent (+glow可) |
| industrial_door | `door_large` | 扉+ frame + lintel |
| gate | `gate_arch` | 大門 (posts+lintel+dark開口) |
| reinforced_wall | `wall_segment` | 壁+ cap + buttress |
| roof_machine | `roof_machine` | 屋根機械+ vent |
| aether_node | `aether_node` | 小Aether core+ring (未使用・量産用) |
| support_frame | `support_frame` | 4柱frame+ rim (未使用・量産用) |
| catwalk | `catwalk` | 歩廊+ rail (未使用・量産用) |
| crane | `crane_bridge` | loading gantry (gate軸用) |
| furnace | `furnace_mouth` | 炉口 (frame+glow) |

## Material rules

- `material_lib.py` の共有paletteのみ。新規material追加禁止 (量産時も値追加のみ)。
- 建物あたり5–7 material → joinで同数mesh。透過なし。
- padはdark iron (stoneは小面積accentのみ。広面stoneは白飛びするため)。
- cyanはAether系 (core/conduit/slit) に限定。furnace orangeは炉口・stack熱のみ。

## Scale rules

- Infantry 1.8m基準。door高 2.2–3.2m、gate高 4.5m。
- HQ最大 (~15×13m, 高さ~13m)。他は用途別に 9–15m footprint。
- district slot (primitive級) とは直接互換なし。大slotはMap Production時に新設。

## Silhouette rules

- 遠景判別要素: HQ=中央spire / Barracks=横長parapet / Factory=gate+crane /
  Boiler=3 stacks / Aether=vertical core+rings。
- 双煙突・双タンクの反復で文明統一。主機能部のみ非対称可。

## Module reuse rules

- 新建物はkit部品の配置・寸法違いで作る。新規造形は固有大形状のみ。
- kit変更は全建物に波及するため、部品関数のsignature変更時は全generator再実行。
- 各generatorは独立再生成可能 (`blender --background --python`)。
  `.blend` 手修正禁止 (Titan pipelineと同一規則)。

## Future polish targets

- phase26a_report.md の Future Polish Candidates (最大3) を参照。
- Polish時はkit部品を維持し、固有大形状の密度・layeringを追加する (Titan polishと同一方針)。
