# AGENTS.md - Aether Crown (OpenCode作業ルール)

## プロジェクト概要
- 目的: 3Dクォータービュー RTS「Aether Crown」のAI主体開発
- プロジェクトルート: `/home/dma/プロジェクト/aether-crown/`
- Godotプロジェクト: `game/` (プロジェクト名 Aether Crown)
- Blender制作: `blender/source/`, 自動化: `blender/scripts/`, 出力: `blender/exports/`
- 共有アセット: `assets/`, 自動化ツール: `tools/`, ドキュメント: `docs/`

## 技術スタック
- Godot 4 を使用 (確認済み 4.7.2)。バージョン決め打ち禁止。`godot --version` で確認する
- Blenderで3Dアセット制作 (確認済み 5.2.2 LTS)。`blender --background --python` が正規経路
- 標準交換形式は GLB / glTF 2.0 のみ。FBX/OBJは持ち込まない
- 基本言語は GDScript。C#/GDExtensionは合意なく導入しない
- レンダラーは Forward Plus (デスクトップ品質優先)。Web対応は将来課題のため、ゲームロジックへレンダラー依存機能を強く結合しない

## アーキテクチャ
- 大量ユニット表示を想定。巨大な単一スクリプト禁止。小さなスクリプトに分割する
- データ駆動設計を優先: `core/*_definition.gd` + `resources/*/*.tres` に数値を持たせる。スクリプト直書きのバランス値を増やさない
- squad単位AIを将来的に採用する。単体AIに最適化しすぎない
- Autoloadは `GameManager` のみ。新しいSingletonは必要性を説明してから追加する
- 責務分離: Godot本体 (`game/`) / Blender制作 (`blender/`) / 共有 (`assets/`) / 自動化 (`tools/`) を混ぜない

## Blenderルール (docs/model_rules.md 準拠)
- Metric, 1 Unit = 1m。Forward -Z / Up +Y。原点は接地中心
- 命名は英数字+snake_case (例 `gearforge_infantry`)
- PBRは Principled BSDF のみ。BaseColor/Normal/Roughness/Metallic を基本にする
- ポリゴン予算: 兵士 Low-Mid / ヒーロー Mid / 巨大 Mid-High / 建物 Mid / 小物 Low。遠景で見えない細部を作り込まない。LOD追加可能な命名 (`_lod0/1/2`) を守る

## 作業フロー
- 既存機能を壊さない。変更後は必ず `godot --headless --path game --import` と該当シーンの `--quit-after` 実行で確認する
- エラーを残したまま次へ進まない。`ERROR` / `SCRIPT ERROR` をゼロにしてから完了報告する
- 不要な大規模リファクタリングを避ける。不足分だけ足す
- 既存ゲームの固有アセットや名称をコピーしない。オリジナル名 (`gearforge_*` 等) を使う
- `/home/dma/プロジェクト/aether-crown/` の外部を勝手に変更しない。他プロジェクト・親ディレクトリ・ユーザー設定・システム設定に触れない
- 重要な設定ファイルを変更する前は現状確認とバックアップを行う
- MCP (Godot/Blender) を勝手にインストールしない。CLI + Godot + Blender Python が正規経路

## よく使うコマンド
```bash
godot --headless --path game --import
godot --headless --path game --script res://tests/cli_smoke.gd
timeout 25 godot --headless --path game --quit-after 60
./tools/export_blender_to_godot.sh --script blender/scripts/make_test_turret.py
blender --background --python blender/scripts/export_glb.py -- --out blender/exports/foo.glb
```
