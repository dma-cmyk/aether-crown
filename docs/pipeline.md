# Blender → Godot パイプライン

標準形式: **GLB / glTF 2.0**

## ディレクトリ責務

- `blender/source/` : 手作業・生成共通の .blend 正本
- `blender/scripts/` : Blender Python (headless実行前提)
- `blender/exports/` : GLB中間出力 (Godotへコピーする前段)
- `game/assets/models/` : Godotが読む最終配置 (GLB + .godot importファイルは自動生成)
- `assets/` (ルート): 生テクスチャ・共有素材の退避 (Godot外管理)

## 標準フロー

```text
blender/source/*.blend
  ↓ blender --background --python blender/scripts/<task>.py
blender/exports/*.glb
  ↓ tools/export_blender_to_godot.sh (コピー + godot --import)
game/assets/models/*.glb
  ↓ Godot import (自動)
res://assets/models/*.glb として利用
```

## コマンド

```bash
# 1. テスト砲塔を生成→GLB→Godot配置→importまで一括
./tools/export_blender_to_godot.sh --script blender/scripts/make_test_turret.py

# 2. 既存blendからGLB化したい場合 (例)
blender --background blender/source/my_unit.blend --python blender/scripts/export_glb.py -- --out blender/exports/my_unit.glb

# 3. Godot側import確認
godot --headless --path game --import

# 4. GDScript検証
godot --headless --path game --script res://tests/cli_smoke.gd
```

## export_glb.py の規約

- `--out` で出力GLBパスを受ける
- エクスポート設定: `export_format='GLB', use_selection=False, export_apply=True, export_yup=True`
- マテリアルは Principled BSDF 前提。対応外ノードは事前にBake
- 実行後に `bpy.ops.wm.quit_blender()` 不要 (CLIが終了させる)

## Godot側の受け入れ条件

- `game/assets/models/*.glb` に置くだけで import される
- シーンからは `Instance` として配置。GLB自体を直接編集しない
- コリジョン・LOD・リグ設定は `.tscn` ラッパー側で持つ
