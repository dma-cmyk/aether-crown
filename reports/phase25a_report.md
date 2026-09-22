# Phase 2.5A 完了報告 (Art Production Foundation + Representative Asset)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe
基準: Phase 2D feat 36b6a39、作業開始時 main 36b6a39

目的: ゲームループを壊さずProduction Art基準を作る。
代表建築1 + District 2種 + PBR基盤 + camera修正 + 実機・性能確認。

## 実施内容

- Camera南boundのzoom連動化 + probe検証 + camera_test PASS
- 共有PBR material library (9種、Principledのみ、textureなし)
- 代表建築 gearforge_civic_core + industry + aether_works (Blender再生成可能)
- Godot統合: 新規showcaseシーン (既存map・logic無改変)
- 自動テスト + 全回帰 + 実機撮影5枚 (1080p) + 720p確認

## 作成asset一覧

| asset | meshes | polys | GLB | 用途 |
|---|---|---|---|---|
| gearforge_civic_core | 23 | 202 | 49KB | 代表都市建築 |
| gearforge_industry_works | 23 | 234 | 55KB | Industry District |
| gearforge_aether_works | 22 | 766 | 124KB | Aether Works District |

- .blendは blender/source/ に追跡、exports/ はgitignore中間物。
- game/assets/models/*.glb (+.glb.import) を追跡。
- 向き・接地はGodot dumpで検証 (pad水平・chimney垂直・pipe正立)。

## 使用した制作ツール

- Blender 5.2.2 LTS: modeling全般 + GLB export (正規経路)。
- Material Maker: 未使用 (評価済み、理由はmaterial方針に記録)。
- Krita / GIMP / Inkscape / ImageMagick: 未使用 (今回用途なし)。
- Audacity / Kdenlive: 未使用 (仕様通り)。

## Blender側の制作方法

- blender/scripts/material_lib.py: palette() が9種を生成 (全asset共通値)。
- make_gearforge_{civic_core,industry,aetherworks}.py:
  clear→units設定→palette→box/cylinder/torus/sphere配置
  (Blender Z-up: footprint X/Y・高さZ)→save .blend→export GLB (Y-up)。
- civicのdial・aetherworksのring/torusは回転適用済み (dumpで正立確認)。

## Material Maker使用内容

- 未使用。standalone版 (1.7) の導入は別途完了。
- tileable noise・dirt・decal用途は量産Phaseへ送り (方針記録あり)。

## Krita/GIMPを使った場合は用途

- 未使用。hand-painted・mask・cleanup需要は今回なし。

## poly / geometry方針

- box/cylinder/torus/sphereのlow-poly primitiveのみ。
  bevel・subdiv・sculptなし。cylinder 8〜16seg、torus 16/8以下。
- aether_worksはtorus×4で766 poly (最多) も総量は軽微。

## material数 / texture resolution / shared material状況

- material 9種 (全asset共有、GLB内は使用分のみ)。
- texture 0枚、resolution該当なし。
- 共有状況: 全3 assetが同一パラメータ (material_lib保証)。

## Godotへの統合内容

- phase25a_showcase.tscn/.gd (新規): civic + 2 district + 固定2領土
  (hard frontline) + 5v5 skirmish + 最小HUD。既存scene・logic無改変。
- TerritoryController.refresh() を追加 (cityなし構成用、旧挙動不変)。
- phase25a_test.gd: 構成物・前線・10体をassert、400f完走。

## camera修正内容

- camera_controller.gd: 南clampのみ `map_limit + max(0, distance-28)*0.75`。
- 検証: dist60→76.0 / dist28→52.0 / 北-52.0 (probe一致)。
- camera_test PASS。1080p・720pで下側表示を目視確認。
- edge/pan/zoom・drift挙動は不変 (速度系未接触)。

## 1280x720確認結果 / 1920x1080確認結果

- 1080p: 5枚採用 (close/mid/variants/zoomout/gameplay)。
- 720p: zoomout + UI相当を確認、clip・崩れなし。
- 撮影中に無入力zoom変動 (21→17) を1回観測: 環境phantom input。
  staging側で再assert対処。本番camera無改変 (既知issueとして記録)。

## average FPS / minimum FPS / sustained <30 FPS

- showcase + 戦闘同時表示: 1080p 38〜59 (平均~43)、720p 46〜58。
- minimum 38 (単発)。sustained <30 なし。
- Phase 2D実績 (平均41〜44) と同等。悪化なし。

## automated tests / regression tests

- phase25a_test OK (新規)。
- cli_smoke / skirmish / camera / phase1_5_test / phase1_5_playtest /
  visual_slice_test / phase2a / 2b / 2c / 2d: すべて OK。

## ERROR数 / SCRIPT ERROR数

- 全テスト・実機撮影: 0 / 0。
- 開発中2件 ( territory_controller の編集ミス1行、testのget_tree、
  いずれも即修正・本番影響なし)。

## known issues

- レンダリング実行時のphantom input (zoomが無入力で1段変化、
  従来のdriftと同根の環境現象)。本番操作に影響なし (実入力優先)。
  stagingは再assertで対処。
- zoomout最大時は地面外の黒背景が見える (showcase地面120mのため、
  実mapではMapNav地面サイズに依存)。
- close-upはdist 16では屋根しか見えない (11m建築のため21を使用)。
  RTS距離の見せ方の知見として記録。

## visual上の問題

- なし (採用5枚で確認)。coils・dial・ringの発光はRTS距離で判読可。
- chimney lip・furnace mouthの暖色とAether cyanの対比が成立。

## 次Phaseへの推奨事項

- 次に進めるべき順: Titan → Airship → Building Set量産。
  理由: Titanは既存visual_sliceにGLB差し替え検証路あり (muzzle基点等の
  接続確認が明確)、Airshipは飛行物例外ルールあり、Building Setは
  material_lib語彙の横展開で最も予測可能。Titanでpipeline・性能の
  再確認後に量産が安全。
- texture導入時はatlas + 共有UV + 256/512上限を先決すること。
- Military Districtは未制作 (2種要件のため)。量産時に industry語彙で対応可。

## Commit / Push Status

- commit hash: (下記 `feat: establish phase 2.5a art production foundation` を参照)
- commit message: feat: establish phase 2.5a art production foundation
- branch: main
- origin/main push status: pushed (確認済み)
- working tree status: clean (確認済み)

## Phase 2.5A Completion Judgment

- 完成扱い可能。代表建築・District×2・PBR基盤・camera修正・統合・
  性能・回帰・撮影・文書・pushがすべて成立。ERROR 0。
- 「prototypeから一段上がった」状態をshowcase + 5枚で確認可能。

## Questions for ChatGPT

- Art Direction: 現3 assetの iron/brass/copper + cyan 方向で量産へ進めてよいか。
  特にrhythm (chimney/tank/pipeの繰り返し) の濃淡について判断を求む。
- Performance: aether_works 766 poly / 124KB は許容か (Titan 58KB比)。
  量産時の1 asset上限目安 (poly・KB) の提案を求む。
- 次候補: Titan → Airship → Building Set の順序案に同意か。
- texture導入時期: 現状0 textureで十分か、次Phaseでdirt/decalを入れるべきか。
- Military District未制作の影響 (2種で要件満足) について。
