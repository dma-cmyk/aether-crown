# Titan Art Direction and Production Design

最終更新: 2026-09-22
対象: Phase 2.5B Gearforge Production Titan

## 現状 Visual Review

Phase 1.75 / 1.9 の Titan、Phase 2.5A screenshot、civic / industry / Aether Works GLB を比較した。

| 観点 | 成立していた点 | prototype 感の原因 / Titan での対応 |
|---|---|---|
| silhouette | 建物は煙突・タワー・リングで用途が分かる | 旧 Titan は箱と円筒が均等。非対称主砲と双煙突を第一形状にする |
| proportions | 歩兵 / 建物 / 飛行船のスケール差はある | 旧 Titan は胴体と脚のメリハリが弱い。長い主砲、小さい頭、幅広 torso、分離脚に再配分 |
| scale feeling | 建物高10m、歩兵1.8mの基準は明確 | Titan の機構単位が大きすぎた。piston / rivet / bands で比較寸法を入れる |
| material | iron / brass / copper / stone の分類は読める | 無地プリミティブの平坦さ。細い bevel と大面の金属明暗差で改善 |
| steampunk | chimney / tank / pipe / warm furnace は明確 | 部品が付属物に見える。圧力容器・収束環・配管に因果関係を与える |
| Aether identity | cyan は暖色金属と強い色差 | 発光が窓や先端に分散。reactor -> chest -> cannon の energy flow に統合 |
| faction identity | 各建物に共通 palette / chimney / band あり | Titan は旧独自色。Phase 2.5A `material_lib.py` をそのまま使う |
| RTS readability | cyan 点と大形状は遠景でも残る | 旧 Titan の武器が正面で胴体と融合。砲を肩外に移し、本体奥行を超える長さにする |
| production | GLB pipeline、共有 PBR、再生成 script が成立 | 鋭い直方体、低 polygon、部品あたり1 mesh。bevel と material 結合で更新 |

prototype 感の主因は polygon 数の少なさではなく、形の優先順位、面の切り替え、
部品間の機能的関係が弱いこと。Production 化では tertiary detail よりこの3点を優先する。

## Design variants

### A. Forge Bastion / Industrial Fortress

- silhouette: 横長 fortress torso、双肩 turret、四角い装甲脚、中央煙突。
- personality: 戦場を押し上げる移動要塞。
- strong: 重装甲と防御拠点の役割が即座に読める。
- weak: 建物とシルエットが近く、「動かしたい」感より環境 asset に寄る。
- RTS readability: 高さは残るが、正面と背面の変化が少ない。
- implementation: 低。直方体中心で最も安価。
- Gearforge 適性: 高。ただし建築語彙へ寄りすぎる。

### B. Crownpiercer / Aether Siege Engine — 採用

- silhouette: 胴体から外した長大な左 Crownspike cannon、短い右 brace、低い sensor、双煙突。
- personality: 圧力と Aether を一発に集約する、不屈の前線破城機。
- strong: weapon identity、非対称、正面/背面の異なる見せ場、energy flow が同時に成立。
- weak: cannon が camera と同軸だと短く見える。quarter-view で本体を18–24度振る。
- RTS readability: 高。遠景でも主砲、双煙突、二脚が残る。
- implementation: 中。砲身・feed・back reactor の接続が必要。
- Gearforge 適性: 最高。Phase 2.5A の都市インフラを兵器機構に変換できる。

### C. Marching Crucible / Mobile Foundry

- silhouette: 垂直巨大炉、ハンマーアーム、クレーン状背骨、多数タンク。
- personality: 戦場で修理と製造を続ける歩く製造所。
- strong: 独自性、steampunk 密度、背面 silhouette。
- weak: 兵装より生産施設に見える。部品が多く戦場の主役性が散る。
- RTS readability: 中。垂直炉は強いが、砲撃ユニットとは読みにくい。
- implementation: 高。crane / foundry 可動部と多数 pipe が必要。
- Gearforge 適性: 高。派生 Titan や support super-unit に向く。

## 採用理由

Variant B は A の工業的重量と C の機構密度を持ちつつ、主砲と非対称で
「この Titan を動かしたい」という兵器の顔を最も強く作れる。また、reactor -> cannon の
Aether 経路が役割とビジュアルを直結し、texture を増やさず完成感を上げられる。

## Final Titan design

### Overall silhouette / primary forms

1. 左右に分かれた幅広の装甲脚
2. 低く広い台形 torso
3. 本体より長い左 Crownspike cannon
4. 短く重い右 siege brace arm
5. 背面から伸びる twin boiler stacks

### Proportions

- 全高11.39m、幅7.76m、奥行9.65m。原点は接地中心。
- head/sensor: 肩幅の約30%。高くしすぎず、砲と煙突に優先順位を譲る。
- torso/shoulders: hip 上に大きな一体ブロック。左右肩は水平だが arm の長さで非対称。
- hips/legs/feet: 回転盤 -> thigh -> 大径 knee -> shin -> 前後に長い foot。重心は低い。

### Secondary forms / locomotion

boiler、pressure bands、external piston、knee axle、shin armor、vent slit、cooling rail、
copper pipe、deck valve を配置。脚は人間の筋肉ではなく、圧力シリンダーと
大径軸が重量を受ける機械構造にする。アニメーション未実装でも、接地面と
piston の向きから遅い歩行を想起できることを優先。

### Weapon identity

`Crownspike Aether Siege Cannon`。左肩外側の breech から shroud / bands / rails / barrel /
muzzle lens へ段階的に細くなる。全長が torso 奥行を超え、発射方向と役割が遠目で読める。
右 arm は短い brace とし、左砲と競合しない。

### Aether system

- rear reactor: 背面中央の cyan core + brass ring
- chest governor: 正面中央で出力を調停
- weapon feed: chest から breech への2本の cyan conduit
- muzzle lens: 射出終端
- sensor visor / back chevron: 制御と識別

orange 発光は twin exhaust 口の熱に限定。cyan と orange を機能で分ける。

### Back silhouette

高さが異なる twin stack、copper boiler、中央 reactor ring、下部の cyan chevron が
正面に依存しない識別点。主砲は肩から後方に breech の量塊が見え、背面でも左右非対称が残る。

## Production result

- Reference-Informed Visual Polish後: Blender polygons 7,670 / triangles 14,964 /
  mesh 8 / material 8 / texture 0
- Principled BSDF 共有 palette のみ。補助ツール未使用。
- close / mid / side / strategic / units / scene / back / silhouette の8構図をGodot Forward Plusで確認。
- mid と strategic で主砲、twin stack、脚が残り、歩兵との scale 差が成立。

## Reference-Informed Visual Polish

2026-09-22に指定の2参考画像を実見し、形状はコピーせず、重量を支える関節、装甲の段差、
武器mount、前後左右の機能密度というproduction principleだけを抽出した。

- legs / feet: raised deck、toe ram、heel cap、ankle fork、front ram、knee guard、thigh crownを追加。
- torso: side rib、glacis、governor keel、top-deck lipで大平面を分節。
- Crownspike: counterweight、outer trunnion、lower recoil cradle / ram、crossbar、mount strutを追加。
- right brace: shoulder crown、shock、side rail、press plate、rear support blockで支持機構を明示。
- back: boiler cap / stack stay、reactor cage、pressure manifold、lower pressure pipeを追加。

identity、front方向、origin、scale、4 runtime anchorは不変。boundsは幅のみ
7.761m→7.772m（+0.011m）、depth 9.645m / height 11.390mは不変。
