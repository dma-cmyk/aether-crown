# Gearforge Visual Language

最終更新: 2026-09-22
適用基準: Phase 2.5B Titan Production Asset

## Core statement

Gearforge は「都市と兵器が同じ重工業インフラから作られた文明」。
厚い鋳鉄の量塊を真鍮・銅の機構で締結し、蒸気と Aether の流れをパイプと
局所発光で見せる。装飾性ではなく「修理可能で圧力に耐える」ことを形にする。

## Shape language

- Primary: 低く広い台形、分厚い直方体、大径円筒。弱い細身シルエットは避ける。
- Secondary: 回転軸、バンド付きタンク、斜め装甲、段付き砲身、外付け piston。
- Rhythm: 「量塊 -> 細い接続機構 -> 量塊」を繰り返す。煙突やタンクは双数を基本とし、
  主兵装や機能部で意図的に非対称を作る。
- Edge: 完全な角ではなく、RTS 光源で面が分かる程度の細い bevel を入れる。

## Material language

| 階層 | material | 用途 |
|---|---|---|
| 構造 | dark iron / steel | 骨格、装甲、接地部、砲身 |
| 機構 | brass / bronze | バンド、軸、開口部、収束環 |
| 流体 | copper | boiler、pipe、piston、熱交換部 |
| 使用痕 | rust | vent や熱源周辺の限定アクセント |
| エネルギー | Aether cyan / furnace orange | 機能を説明できる箇所のみ |

金属は明暗差を取り、dark iron の大面積の中に steel で面を分け、brass / copper で
機能境界を示す。材質は Principled BSDF のみとし、不要な透過は使わない。

## Color hierarchy

1. 65–75%: charcoal / dark iron — 重量と派閥の土台
2. 15–25%: steel / bronze / copper — 部品階層と工業感
3. 3–7%: cyan Aether — sensor、core、conduit、weapon endpoint
4. 1–3%: furnace orange — 燃焼と exhaust の熱

cyan は faction 塗装ではなく、「制御された Aether が通る系」に限定する。

## Repeated motifs

- brass containment ring: core、reactor、barrel、tank を収束する
- paired stack / paired tank: civilization-wide の圧力機関語彙
- exposed copper conduit: エネルギーと熱の経路を見せる
- furnace mouth: orange の深い開口部。cyan との機能差を作る
- cyan lens / slit: 窓、sensor、dial、weapon lens を共通化
- armor-over-machine: 外装プレートの間から piston / pipe / axle が見える

## Scale language

- Infantry: 頭・胴・装備の色分けで読む。小さい発光は用いない。
- Building: footprint、roof、tower/chimney の3階層。同じユニットの繰り返しで規模を見せる。
- Titan: 8–12m。歩兵の約6倍の高さと大きな二脚、建物にはない主兵装の方向性で区別する。
- RTS 遠景では細部ではなく、幅・高さ・非対称・発光点の数でクラスを判別する。

## Titan へ引き継ぐ要素

- Phase 2.5A の chimney / tank / pipe / brass band / cyan core を、都市より高密度に統合する。
- 建物と同じ material で faction を繋ぎ、シルエットと主砲で兵器に分ける。
- Aether は reactor -> governor -> weapon と機能的に配線する。
- 正面だけでなく、背面にも twin stack / boiler / reactor の独立 silhouette を持たせる。
