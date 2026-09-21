# 環境セットアップ記録 (2026-09-22)

- OS: Linux (EndeavourOS)
- Godot: 4.7.2.stable.arch_linux (`/usr/bin/godot`)
- Blender: 5.2.2 LTS (`/usr/bin/blender`)
- GPU: Intel Iris Xe Graphics (TGL GT2), Mesa 26.2.3
- Vulkan: 1.4.x, Forward+ 動作確認済み
- OpenGL: 4.6 Core / ES 3.2
- メモリ: 7.4GiB / ディスク空き: 179G (/home)

## 確認済みコマンド
- `godot --headless --path game --import`
- `godot --headless --path game --script res://tests/cli_smoke.gd`
- `timeout 25 godot --headless --path game --quit-after 60`
- `timeout 25 godot --path game --quit-after 60` (Vulkan Forward+)
- `blender --background --python blender/scripts/make_test_turret.py`
- `./tools/export_blender_to_godot.sh --script blender/scripts/make_test_turret.py`

## 既存設定の扱い
- 既存のGodot/Blenderユーザー設定は変更していない (初期化なし)
- 作業範囲は `/home/dma/プロジェクト/aether-crown/` 内部のみ
