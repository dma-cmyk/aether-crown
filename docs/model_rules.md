# Blender / Godot モデルルール (Aether Crown)

## 単位・スケール
- Units: Metric, 1 Blender Unit = 1 meter
- Unit Scale: 1.0
- RTS基準: 歩兵 高さ約1.8m / 建物 4mグリッド / タイタン 8-12m

## 軸・Transform
- Forward: -Z, Up: +Y (glTF / Godot 標準)
- エクスポート設定: Forward `-Z`, Up `+Y`, Apply Transform ON
- オブジェクト原点: 接地中心 (足元 / 建物は敷地中心の地面)
- エクスポート前に `Scale/Rotation` は Apply、Location は原点整理後に Apply 判断

## 命名 (snake_case, 英数字)
- 例: `gearforge_infantry`, `gearforge_factory`, `gearforge_titan`
- メッシュ: `<asset>_mesh`, アーマチュア: `<asset>_rig`, アクション: `<asset>_idle` 等
- マテリアル: `<asset>_mat`, テクスチャ: `<asset>_basecolor.png` 等

## マテリアル / テクスチャ (PBR, Godot移行優先)
- Principled BSDF のみ使用。カスタムノード群は Bake してから出す
- セット: Base Color / Normal(OpenGL) / Roughness / Metallic (+必要なら AO, Emissive)
- 解像度目安: 歩兵 512, 建物 1024, ヒーロー 1024, タイタン 2048 (上限)
- アルファは必要な場合のみ。透過多用禁止

## ポリゴン予算 (遠距離カメラ前提)
- 兵士 Low-Mid: 800-2500 tris
- ヒーロー Mid: 3000-8000 tris
- 巨大ユニット Mid-High: 8000-25000 tris
- 建物 Mid: 2000-10000 tris
- 背景小物 Low: <800 tris
- 遠距離で見えない細部 (ボルト、内部機構) にポリゴンを割かない
- N-gon禁止、原則 Quad/Tris。Subdiv は適用してから出す

## LOD方針
- 現段階でLOD実装不要。ただし将来追加できるよう命名と分離を守る
- 推奨: `_lod0` (フル), `_lod1` (50%), `_lod2` (25%) を同一blend内で別オブジェクト化
- Godot側は `LOD` / `VisibilityRange` / HLOD で切り替え予定

## リグ・アニメーション
- 単位: `+Y Up`, ボーン名 snake_case, ルートボーンを原点に置く
- アクション名: `idle`, `walk`, `attack`, `die` を基本に
- NLAにpushしてから glTF エクスポート (NLA + Actions 両対応予定のGodotに合わせる)
