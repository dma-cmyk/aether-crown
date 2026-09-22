# Phase 2.5B 完了報告 (Titan Art Direction + Production Asset)

日付: 2026-09-22
環境: EndeavourOS / Godot 4.7.2 / Blender 5.2.2 LTS / Intel Iris Xe / RAM 約7.4GB
開始基準: `main` / `origin/main` 71cd142

## 実施内容

- Phase 1.75 / 1.9 Titan と Phase 2.5A の asset / screenshots を visual review
- Gearforge visual language を shape / material / color / motif / scale で定義
- Titan 3案を比較し、Variant B `Crownpiercer / Aether Siege Engine` を採用
- Production LOD0 を Blender Python で制作し、`.blend` 保存と GLB export
- Production GLB を Godot の旧 Titan resource path に安全に置き換え
- 独立 Titan showcase、asset test、自動撮影7構図、Iris Xe benchmark を追加
- 全主要回帰テストを実行

## 使用ツール

- Blender 5.2.2 LTS: modeling、bevel、material assignment、`.blend`、GLB export
- Godot 4.7.2 Forward Plus: import、showcase、screen capture、benchmark、tests
- Material Maker / Krita / GIMP: 未使用
- texture 生成 / bake: 未使用

## Titan 仕様

| 項目 | 結果 |
|---|---|
| 名称 | Gearforge Crownpiercer |
| design | Aether Siege Engine |
| dimensions | 7.761m W × 9.645m D × 11.390m H |
| vertices | 5,408 |
| Blender polygons | 5,228 |
| triangles | 10,392 |
| mesh | 8 |
| material | 8 |
| texture | 0 |
| GLB size | 719,656 bytes |

Blender polygon 数は依頼目安 2,500–6,000 内。triangle 数は `model_rules.md` の巨大ユニット
8,000–25,000 tris 内。生成時は多数の modular part に分け、export 前に共有 material 単位で8 meshへ結合した。

## Visual 結果

- 主要 silhouette: 非対称長砲身、幅広 torso、分離脚、twin stack
- main weapon: shoulder-mounted Crownspike。breech / shroud / cooling rail / barrel / muzzle lens を大形状で分離
- Aether: reactor -> chest governor -> weapon feed -> muzzle の意味ある配線
- back: copper boiler、twin exhaust、reactor ring、cyan chevron
- 歩兵との高さ比約6.3:1。建物と同程度の高さでも移動兵器と読める。
- close / mid / strategic / scale / scene / back / silhouette の7構図で受け入れ基準を満たす。

## Material / texture

- Phase 2.5A 共有 palette の dark iron / steel / brass / bronze / copper / rust /
  Aether glow / furnace glow の8種。
- Principled BSDF のみ。transparent material なし。
- texture 0枚、texture memory 0。「無地だから単純」に見えないよう、bevel highlight、
  metal value contrast、material boundary、限定 emissive で密度を作った。

## Blender / GLB pipeline

```text
blender/scripts/make_gearforge_titan.py
  -> blender/source/gearforge_titan.blend
  -> blender/exports/gearforge_titan.glb
  -> game/assets/models/gearforge_titan.glb
  -> Godot import
```

- metric 1 unit = 1m
- Blender front `-Y`, Godot front `+Z`, origin ground center
- runtime anchors: `muzzle`, `reactor_anchor`, `exhaust_l`, `exhaust_r`
- regeneration/import command: `./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_titan.py`

Blender export は成功。`MeshOptimizer is not available` は Blender の optional export library 通知で、
GLB 生成・Godot import・mesh/anchor 検証に影響なし。

## Godot 統合

- `VisualTitan` が既存 path を preload しているため、GLB 差し替えだけで gameplay 側へ反映。
- `muzzle` 名を維持し、TitanShell / muzzle FX を互換。
- `phase25b_titan_showcase.tscn/.gd`: 独立アートシーン。main scene ・ gameplay logic ・ balance は無改変。
- `phase25b_test.gd`: 8 mesh、4 anchor、6 infantry、2 scale-reference buildings を検証。

## Performance

| 条件 | 結果 |
|---|---:|
| renderer | Forward Plus / Vulkan / Intel Iris Xe |
| viewport | 1920×1008（window decoration 除外） |
| warm-up | 3 sec |
| duration | 15 sec |
| average FPS | 41 |
| minimum FPS | 39 |
| sustained <30 FPS | なし |

別プロセスの benchmark で計測。screen capture の PNG encode / disk write は値から除外。

## Tests

| テスト | 結果 |
|---|---|
| `godot --headless --path game --import` | PASS |
| `tests/phase25b_test.gd` | PASS |
| `tests/visual_slice_test.gd` | PASS（新 Titan + muzzle 互換） |
| `tests/cli_smoke.gd` | PASS |
| `tests/skirmish_test.gd` | PASS |
| `tests/camera_test.gd` | PASS |
| `tests/phase1_5_test.gd` | PASS |
| `tests/phase1_5_playtest.gd` | PASS |
| `tests/phase2a_test.gd` | PASS |
| `tests/phase2b_test.gd` | PASS |
| `tests/phase2c_test.gd` | PASS |
| `tests/phase2d_test.gd` | PASS |
| `tests/phase25a_test.gd` | PASS |

ERROR: 0 / SCRIPT ERROR: 0。

## Screenshots

`docs/screenshots/phase25b/` に 1920×1008 PNG を7枚保存。

- `titan_close.png`
- `titan_mid.png`
- `titan_zoomed_out.png`
- `titan_with_units.png`
- `titan_in_scene.png`
- `titan_back_view.png`
- `titan_silhouette_check.png`

## Known issues

- LOD1/2、rig、walk / recoil animation は未実装。Phase 2.5B の static Production Asset 範囲外。
- 現行 `VisualTitan` collision（radius 2.2m / height 9m）は旧 model 寸法。幅の広い新 LOD0 と完全一致しない。
  gameplay / balance を改変しないため今回は保持。
- Aether emissive は Phase 2.5A 共有値を使うため close で白飛び気味。mid / strategic の識別は良好。
- アニメーション化時は material 結合前の modular part を生成 script から再構築する。

## Muse Spark への引き継ぎ

詳細は `docs/art/titan_muse_handoff.md`。次に Titan を調整する場合は、細部追加ではなく
animation / collision acceptance -> LOD1/2 -> emissive tuning の順。Airship / Building Set / Titan 派生の量産は開始しない。

## Git

- commit message: `feat: implement production titan art foundation`
- branch: `main`
- push / synchronization / clean-tree は完了手順の最後に確認する。

---

# Muse Spark Acceptance (2026-09-22, Moses Spark 引き継ぎ分)

## 受け入れ判断: ACCEPT (生産コード変更なし)

10観点を Sol の7 screenshots + 実測で評価し、すべてPASS:

| # | 観点 | 結果 |
|---|---|---|
| 1 | quarter-view close readability | PASS: 砲前後・sensor・chest core・piston・煙突が判別可 |
| 2 | mid zoom readability | PASS: 長左砲・短右brace・双煙突・二脚が一瞬で読める |
| 3 | strategic zoom readability | PASS: 非対称と高さが残る |
| 4 | back silhouette readability | PASS: stack・boiler・reactor ring・chevronで特定可 |
| 5 | Gearforgeらしさ | PASS: 共有palette・chimney・band言語 |
| 6 | 建物との文明的一貫性 | PASS: titan_in_scene で同一言語 |
| 7 | 歩兵とのスケール差 | PASS: 約6倍、明確 |
| 8 | gameplay画面での視認性 | PASS: visual_slice_test muzzle互換 + 発射経路不変 |
| 9 | weapon identity | PASS: Crownspike が全距離で読める |
| 10 | silhouette clarity | PASS: silhouette_check で主砲・肩・煙突・脚が残る |

## 行った微修正: なし (意図的)

- emissive close白飛び (Sol known issue): mid/strategic (実gameplay視点) は良好。
  下げると遠景識別を損なうため変更せず。
- collision radius 2.2 (旧寸法): 脚端 (±3.88) より小さく、近接時に足へ
  めり込む場合がある。visual_titan.gd 共有のため visual_slice に波及する
  変更は避け、次Phaseの collision acceptance へ送り (handoffの順序通り)。
- facing (+Z) / scale 1.0 / 接地 (min Z 0.03) / 原点接地中心: すべて確認済み。

## 検証数値

- bounds (Blender world): 7.761 W × 9.645 D × 11.390 H、handoff一致。
- anchor (Godot): muzzle (-2.72, 7.26, 6.92)、reactor (0, 7.12, -2.52)、
  exhaust ±(1.18, 11.45, -1.4)。handoffの Blender→Godot 変換と完全一致。
- 再生成一致: script再実行で accessor bounds/count 全32一致、mesh 8 /
  material 8 / texture 0。`.blend` 手修正なし (source of truth 維持)。
  検証後に commit 済み `.blend` を復元し、working tree を clean に戻した。
- benchmark (showcase 組み込み `--benchmark-phase25b`, warmup 3s / 15s):
  1280x720 min 39 / avg 40、1920x1080 min 40 / avg 43。
  sustained 30 FPS未満なし (Sol実測 41/39 と整合)。

## Godot統合状態

- VisualTitan は既存 path preload のため GLB差し替えのみで反映。
  muzzle 解決・TitanShell発射経路は不変 (visual_slice_test PASS)。
- selection ring 3.4 / HP bar 11.0 は新寸法 (幅7.76/高11.39) に適合。
- showcase・test・全回帰で ERROR 0 / SCRIPT ERROR 0。

## collision / footprint 所見 (次Phase送り)

- CollisionShape (r2.2/h9.0) に対し visual は W7.76/H11.39。
  近接歩兵が脚端にめり込む場合あり。gameplay balanceへの影響は
  確認されず (units は ranged 中心、targeting は距離計算)。
- 対応は handoff 順序通り次Phase: collision acceptance → LOD1/2 →
  emissive tuning。今Phaseでは balance 改修禁止のため対応しない。

## tests (Muse 実施分)

- phase25b_test: OK (meshes=8 anchors=4 units=6 buildings=2)
- cli_smoke / skirmish / camera / phase1_5_test / visual_slice_test /
  phase2a / 2b / 2c / 2d / 25a: すべて OK
- phase1_5_playtest: 非決定的 (下記)。それ以外は決定的に PASS。

## phase1_5_playtest 非決定性について (既知・スコープ外)

- 同一 main コードで6 runs: NG, NG, OK, NG, OK, NG (2/6 pass)。
  71cd142 対照 (worktree) でも OK を確認。
- 原因: `game/scripts/units/unit.gd:126-127` の unseeded `randf()`
  (scan offset) + `time_scale=8` による非決定的戦闘展開。
  Sol成果物 (Titan GLB・showcase・docs) は phase1_5_match を参照せず、
  gameplay logic差分もないため無関係。
- 対応: 今Phaseでは対象外 (test安定化はAI/driver/timing設計に踏み込むため)。
  決定的suite 11/12 + flake証拠を残し、test seeding・安定化を後続へ推奨。
- ERROR / SCRIPT ERROR は全runs 0 (NGは quit(1) のみ)。

## FPS

- 1280x720: min 39 / avg 40。1920x1080: min 40 / avg 43。
- sustained <30 なし。Phase 2.5A実績・2D実績と同等。

## known issues (Muse 追記)

- 上記 playtest flake (推奨: test seeding)。
- collision 旧寸法 (次Phase)。
- 撮影時 phantom input 1件観測歴あり (本件撮影では再発なし)。

## 次にやるべきPhase (判断のみ、未着手)

1. Titan collision acceptance + LOD1 (+emissive微調整) — handoff順序通り、
   小規模・完結。rig/animationはその後。
2. Airship Production Asset — Titan pipelineを流用。
3. Building Set量産 / Military District — 最後に (語彙は確立済み)。
   Titan派生・gameplay/AI/balance改修は開始しない。

## Commit / Push Status

- commit hash: (下記 `feat: finalize phase 2.5b titan integration` を参照)
- commit message: feat: finalize phase 2.5b titan integration
- branch: main
- origin/main push status: pushed (確認済み)
- working tree status: clean (確認済み)

## Phase 2.5B Completion Judgment

- 完成扱い可能。受け入れレビュー (10観点PASS)・検証数値・benchmark両解像度・
  決定的回帰11/12・ERROR 0・screenshots 7枚維持・docs/report更新・push済み。
- 留保: phase1_5_playtest の非決定性 (証拠・原因・推奨を本節に記録)。
  Sol成果物・本Phase変更との因果関係なし。

## Questions for ChatGPT

- 受け入れ (変更なし) の判断に同意か。特に emissive据え置き・collision送り。
- playtest flake の扱い (記録のみで完了扱い) に同意か。test seeding の優先度は。
- 次Phaseは Titan collision+LOD1 の認識でよいか (Airship先行の選択肢もある)。
- GLB 719KB (10,392 tris) のサイズ感は量産基準として許容か。
