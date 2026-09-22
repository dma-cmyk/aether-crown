# Airship Art Direction and Production Design

最終更新: 2026-09-22
対象: Phase 2.5C Gearforge Production Airship
基準: `docs/art/gearforge_visual_language.md` / `docs/art/titan_design.md`

## 参考画像の閲覧結果

指定された2枚 (`KLW3Yab` / `bPSGclL`) を実際にダウンロードして閲覧した。
デザインはコピーせず、以下の「密度の作り方」だけを構造原理として抽出した。

| 抽出した原理 | Aether Crown への翻訳 |
|---|---|
| 船体の外側に露出した金属フレーム (環状リング + 縦通材) が密度を作る | 外付け brass ring frame + dark iron stringer で hull を分節する |
| リングが船体を等間隔に分節し、遠景でもリズムが残る | Primary 形状ではなくリズムで巨大さを読ませる |
| 下面に長い understructure とトラスで吊られた機械デッキがある | 下面を空白にせず keel hull + gondola + 兵装で埋める |
| 尾部に大型 fin と発光する推進ノズル | H-tail + Aether thruster + 炉口 orange で前後を判別させる |
| 大量塊 → 中量塊 → 小金具 の3階層が同居している | Primary / Secondary / Tertiary を明示的に分ける |
| 機首が尖った装甲プロウで進行方向が読める | armored ram prow で -Y front を確定させる |

コピーしない: 具体的機体形状、紋章、色配置、構図、UI。

## Task 1: Phase 1.75 Airship の Visual Review

対象: `blender/scripts/make_gearforge_airship.py` (旧版) と
`docs/screenshots/phase1_75/titan_airship.png`。

| 観点 | 現状 | prototype 感の原因 |
|---|---|---|
| silhouette | UV sphere を Y方向に2.25倍した単一楕円体 | 分節がなく、輪郭が1本の滑らかな卵。距離に関係なく情報量が一定で、シルエットに「読む場所」がない |
| scale | envelope 全長約9m、全高約6m | Titan 11.4m より小さい。空の主役ではなく「浮いている小物」になっている |
| proportions | 船体が太く短い (長さ/直径 ≈ 2.25) | 飛行船の長大さが出ず、風船に見える |
| hull | 単一の球体スケール変形 | hull section (bow / mid / stern) の区別がなく、機体の「向き」が形から読めない |
| propulsion | 半径0.12mのハブ + 板1枚のプロペラ2基 | 全長9mの船体に対して推進器が小さすぎ、何で飛ぶのか説明できていない |
| underside | 木製 gondola 1個 (1.6×3.6×1.2m) のみ | RTSカメラで最もよく見える下面がほぼ空白。旧版は gondola が envelope の影に隠れる |
| weapon identity | 長さ1.4m / 半径0.12m の砲身1本 | mid zoom で消える。戦闘ユニットとして何もしていないように見える |
| material | `canvas` / `wood` / 独自 `iron` `brass` を local 定義 | **`material_lib.py` を使っていない**。木と帆布は Gearforge の重工業語彙に存在しない。Titan・都市と「同じ文明」に見えない最大の原因 |
| Aether identity | 発光 torus 3本が envelope を巻く + 窓3枚 | cyan が装飾帯として最大面積の発光になっている。reactor も conduit もなく、機能の説明がない |
| Gearforge identity | pipe / boiler / containment ring / twin motif が皆無 | 都市と Titan が共有する語彙をひとつも持っていない |
| RTS readability | 遠景では白い卵 + cyan の輪 | 「大型飛行船」ではなく「発光する楕円」と読める |

### なぜ完成目標画像ほどワクワクしないのか

polygon 数ではない。旧 Airship は約1,100 polygon だが、同程度の polygon でも
下記4点を満たせば印象は大きく変わる。

1. **分節がない。** 参考画像の船体は外付けフレームで8〜10個のセクションに割れており、
   輪郭線に凹凸のリズムがある。旧版は滑らかな一続きの曲面で、視線が止まる場所がない。
2. **階層がない。** 大量塊 → 中量塊 → 小金具の3階層が無く、envelope (巨大) と
   gondola (小) の2段しかない。中間サイズの機械部品が存在しないため、
   スケールを比較する手掛かりがなく「大きく」見えない。
3. **因果関係がない。** 発光リングは envelope を巻いているだけで、何も駆動していない。
   プロペラはボイラーに繋がっていない。「浮く理由」「飛ぶ理由」「撃つ理由」が
   形の中で接続されていないので、機械ではなくオブジェに見える。
4. **文明が違う。** 木と帆布の materials は、鋳鉄・真鍮・銅で出来た Gearforge の
   都市・Titan と別の世界の物体に見える。並べた瞬間に統一感が壊れる。

Production 版ではこの4点 (分節 / 階層 / 因果 / 共有 material) を最優先で解決し、
tertiary detail の追加は最後に回す。

## Task 2: Design Variants

### A. Bulwark — Armored Crown Zeppelin

- silhouette: 単一の巨大装甲 envelope、外付け ring frame、装甲プロウ、十字尾翼、
  全長 underslung gondola、舷側 sponson turret、左右の engine pod。
- role: 制空と絨毯砲撃を担う正統派の装甲飛行船。
- hull proportions: 全長 32m / 直径 8m (長さ比 4.0)。
- machinery: hull 側面に boiler bank、後部に engine pod。
- propulsion: 大型 ducted propeller 2基 + 舵。
- weapon: 舷側 sponson turret 4基 + 前方砲。
- Aether: 下面 conduit と砲の endpoint。
- underside: 全長 gondola とトラス。密度は出しやすい。
- rear: 十字尾翼と2基のプロペラ。
- strengths: どのズームでも100%「飛行船」と読める。実装が最も安い。
- weaknesses: 参考画像のジャンル形状に最も近く、Aether Crown 固有性が弱い。
  上から見ると単なる1本の筒で、RTS の俯瞰で他勢力の飛行船と差が出にくい。
- RTS readability: 高。
- implementation: 低。
- Gearforge 適性: 中。重工業感は出るが、都市・Titan の twin motif を活かせない。

### B. Skyforge — Flying Foundry

- silhouette: 垂直の大型炉を抱えた箱型 hull、上面に多数の煙突、クレーン腕、下面に投下ベイ。
- role: 前線で修理・生産・投下を行う移動工廠。
- hull proportions: 全長 24m / 幅 14m の平たい塊。
- machinery: 炉・タンク・クレーンが主形状そのもの。
- propulsion: 四隅の articulated engine pod。
- weapon: 投下爆弾と炉の火。直接兵装は弱い。
- Aether: 炉と生産ラインに分散。
- underside: 投下ベイとクレーンで密度は最高。
- rear: 煙突群。
- strengths: 工業密度と独自性が最も高い。Gearforge 語彙をそのまま拡大できる。
- weaknesses: 「空飛ぶ建物」に見え、Airship の読みを失う。Titan C 案と役割が被る。
  戦闘ユニットとしての主役性が弱く、「使いたい」より「置きたい」になる。
- RTS readability: 中。strategic zoom で建物と混同する危険がある。
- implementation: 高。可動クレーン・多数の pipe が必要。
- Gearforge 適性: 高 (ただし Airship ではなく support 施設として)。

### C. Crownhammer — Twin-Cell Aether Dreadnought — 採用

- silhouette: **2本の長大な Aether lift cell が中央の装甲 keel hull を左右から抱える**
  3胴構造。前方に装甲 ram prow、上面に露出した reactor spine、
  下面に command gondola と belly siege mortar、後部に H-tail と ducted engine。
- role: 制空しながら地上を叩く空中砲台。Titan が押し込む正面を上から割る。
- hull proportions: 全長 34m / 全幅 13.8m / 全高 11.2m。cell 直径 6m。
- machinery: keel hull 側面に boiler bank と sponson、cell 下腹に injector 列、
  後部に engine nacelle。機械が装甲の隙間から見える armor-over-machine。
- propulsion: 巡航は steam ducted propeller 2基 (boiler 駆動)、
  加速は tail の Aether thruster 2基 (reactor 駆動)。2系統の役割が形で分かれる。
- weapon: 下面 belly siege mortar (主)、舷側 sponson turret 4基 (副)、bow ram lens。
- Aether: reactor → 2本の injector trunk で両 lift cell へ (浮力)、
  reactor → keel conduit で mortar breech と tail thruster へ (火力・推進)。
- underside: keel hull / gondola / mortar / sponson 下縁 / conduit で全長が埋まる。
- rear: 2本の cell 尾部 + H-tail + ducted prop 2基 + cyan thruster 環 + orange 炉口。
- strengths: **twin tank / twin stack という Gearforge の中核 motif を船体スケールで実装できる。**
  俯瞰で「2本の筒 + 中央の船」という他に無いシルエットになり、
  Titan の非対称単腕砲とも読みが衝突しない。浮力・推進・火力の因果が全部見える。
- weaknesses: cell 2本が strategic zoom で「2隻」に割れて見える危険。
  → nose ram・keel hull・H-tail・dorsal spine を全長で連結し、必ず1体に見せる。
- RTS readability: 高。横長 + 中央の切り欠きで固有。
- implementation: 中。cell・keel・engine の接続部に手数が要る。
- Gearforge 適性: 最高。

### 採用理由

A は安全だが Aether Crown 固有性が生まれず、B は Airship の役割を失う。
C は A の「飛行船である」読みやすさを保ったまま、Gearforge の paired pressure vessel
motif を船体そのものに昇格させられる。さらに `reactor → lift cell / mortar / thruster`
という1本の Aether 系統で浮力・火力・推進を同時に説明でき、
texture を増やさずに完成感を上げるという Titan と同じ戦略が使える。

## Task 3: 採用案の Production Design

固有名: **Crownhammer** (Titan `Crownpiercer` と同じ命名族。上から叩く役割)
Variant: C / Twin-Cell Aether Dreadnought

### Overall silhouette

上から下へ3層:

1. 2本の Aether lift cell (直径6m / 長さ27m) — 左右に分離し、間に空隙を作る
2. 中央の装甲 keel hull — cell より前後に長く、両端で cell を連結する
3. 下面の command gondola / belly siege mortar / sponson

strategic zoom では「横長の塊の中央に縦の切り欠きがある」という形が残り、
Titan (縦長・非対称) や Building (正方形 footprint) と混同しない。

### Main hull

普通の zeppelin にしないための固有構造:

- 気嚢ではなく **Aether lift cell**: 鋳鉄のスラット装甲に包まれた与圧シリンダーで、
  下腹にだけ cyan の injector slit が並ぶ。浮力源が見える。
- **keel hull** が cell より長い。前は ram prow、後ろは H-tail まで伸び、
  2本の cell を骨格として繋ぐ。これが「2隻に見える」問題の解決部。
- hull 断面は円ではなく、上面平坦・下面台形の **装甲 keel** 形状。

### Structural frame

- brass ring frame: 各 cell に等間隔6本。外周に 0.12m 突出させ、遠景で分節を作る。
- dark iron stringer: 各 cell の上面・外側面に縦通材。ring と交差してケージを作る。
- cross brace: cell と keel hull を繋ぐ斜めトラス (前・中・後の3組)。
- dorsal spine deck: keel 上面の露出したキャットウォークと手すり。
- armor-over-machine: keel 側面の装甲板の間から boiler と copper pipe が覗く。

### Gondola / underside

下面を4ブロックで埋める。

1. 前部 **command gondola**: cyan の横長ブリッジスリット。2段の装甲。
2. 中央 **belly siege mortar**: 短く太い砲身を下前方へ約25度。brass containment ring 3本、
   breech に cyan。主兵装。
3. 中後部 **machinery pod**: boiler drum と copper pipe が露出。orange の炉口。
4. 左右 **sponson 下縁**: 舷側 turret の下半分が keel から張り出す。

### Propulsion

2系統。機構的理由を分ける。

- **steam ducted propeller ×2**: 後部外側、cell の下に吊られた nacelle。
  copper boiler drum → brass gearbox → duct ring 内の4枚ブレード。
  keel の boiler bank から蒸気配管が繋がる。巡航用。
- **Aether thruster ×2**: 尾端 keel の brass ring nozzle。cyan 発光。
  reactor から直結の conduit が見える。加速・機動用。

### Aether system

energy flow を1本の系統にする。

```
dorsal reactor (keel 上面 中後部, cyan core + brass containment ring)
  ├─ injector trunk L/R  → lift cell 下腹の cyan slit 列   (浮力)
  ├─ keel conduit 前方   → belly mortar breech → muzzle lens (火力)
  └─ keel conduit 後方   → tail Aether thruster ×2          (推進)
```

cyan はこの経路と bridge slit・bow lens のみ。装甲面には使わない。
orange は machinery pod と engine nacelle の炉口だけに限定し、燃焼と Aether を色で分ける。

### Weapon identity

Titan の巨大単腕砲を避け、Airship 固有の戦闘方法にする。

- **主**: belly siege mortar。下面中央、下前方へ向く短砲身。mid zoom で必ず読める。
  `muzzle` anchor。
- **副**: 舷側 sponson turret ×4 (左右2基ずつ)。連装短砲身。`weapon_l` / `weapon_r`。
- **識別**: bow ram prow の cyan lens。撃たないが進行方向と攻撃性を示す。

Titan は「1本の長大な砲を横に突き出す」、Airship は「下と横に撃つ」。
シルエットの論理が異なるので遠景でも混同しない。

### Rear silhouette

H-tail (2枚の垂直 fin + 間を渡す水平 tailplane) + ducted propeller 2基 +
cyan thruster 環2個 + orange 炉口。上から見ても後ろから見ても前後が即断できる。

## Task 4: Visual Hierarchy

| 階層 | 要素 | 見える距離 |
|---|---|---|
| Primary | 2本の lift cell / 中央 keel hull / ram prow / H-tail / 下面の塊 | strategic |
| Secondary | ring frame / stringer / ducted engine / belly mortar / sponson / gondola / dorsal reactor / cyan injector slit | mid |
| Tertiary | rivet / valve / 手すり / 細い pipe / vent slit / muzzle lens | close |

Tertiary は Primary の輪郭を侵食しない位置にのみ置く。
ring frame は Secondary だが、突出量を確保することで strategic でも「分節のリズム」として残す。

## Scale

| 対象 | 寸法 |
|---|---|
| Infantry | 高さ 1.8m |
| Building | 4m グリッド / 高さ 約10m |
| Titan Crownpiercer | 11.39m H × 7.76m W × 9.65m D |
| **Airship Crownhammer** | **34.0m L × 13.8m W × 11.2m H** |

Airship は Titan と同程度の「高さ」を持ちながら、全長で約3倍の体積感を持つ。
1920×1080 の mid zoom で画面幅の約40%、strategic zoom で約15%に収まり、
画面を覆わない。cruise 高度は既存 `VisualAirship.CRUISE_HEIGHT` 相当を維持する。

## Material Language

`blender/scripts/material_lib.py` の共有 palette のみを使う (旧版の canvas / wood は廃止)。
Titan と同一 vocabulary だが、面積比を変えて Airship 固有の印象を作る。

| material | Titan での役割 | Airship での役割 | 面積比 |
|---|---|---|---:|
| dark_iron | 骨格・主装甲・砲身 | lift cell のスラット装甲、keel 装甲 | 約 45% |
| steel | 前装甲・肩・shroud | cell 上面パネル、gondola、fin | 約 22% |
| brass | 輪縁・軸・バンド | **ring frame** (Airship の主役)、nozzle、containment | 約 14% |
| bronze | 砲口・上面装甲 | 砲身・spine deck | 約 6% |
| copper | piston・pipe・boiler | boiler drum、conduit、injector trunk | 約 9% |
| rust | vent 周辺 | machinery pod 周辺のみ | 約 1% |
| aether_glow | reactor → 砲 | injector slit / reactor / mortar breech / thruster / bridge / bow lens | 約 2% |
| furnace_glow | exhaust 口 | machinery pod と engine 炉口のみ | 約 1% |

Titan は dark_iron の量塊が支配的だが、Airship は **brass ring frame の反復**が
最大の識別要素になる。同じ絵の具で違う絵を描く。

## Texture

Titan と同じく texture 0 で Production 形状を成立させる方針。
geometry + shared PBR + emissive のみ。Material Maker / Krita / GIMP は使用しない。

## RTS Camera 受け入れ条件

- close: ring frame / stringer / boiler / conduit / mortar の機構と material 階層が読める。
- mid: 2本の cell / keel hull / ducted engine / belly mortar / gondola が読める。
- strategic: 横長 + 中央切り欠き + H-tail で「大型 Gearforge Airship」と一目で分かる。
- relation: Titan と並べて同じ material 語彙 (dark iron / brass / copper / cyan) だが、
  シルエット (横長3胴 vs 縦長非対称二脚) は決して混同しない。
