#!/usr/bin/env bash
# Blender headless -> GLB -> Godot assets/models -> godot --import を1コマンド化
# Usage:
#   ./tools/export_blender_to_godot.sh --script blender/scripts/make_test_turret.py
#   ./tools/export_blender_to_godot.sh --blend blender/source/foo.blend --out foo.glb
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLENDER_SCRIPT=""
BLEND_FILE=""
OUT_NAME=""

usage() {
  echo "Usage: $0 [--script <blender_python>] [--blend <file.blend> --out <name.glb>]"
  echo "  --script : Blender Pythonを実行して blender/exports/*.glb を生成"
  echo "  --blend  : 指定blendを blender/scripts/export_glb.py でGLB化"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --script) BLENDER_SCRIPT="$2"; shift 2 ;;
    --blend) BLEND_FILE="$2"; shift 2 ;;
    --out) OUT_NAME="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1"; usage ;;
  esac
done

if [[ -n "$BLENDER_SCRIPT" ]]; then
  echo "[1/3] blender --background --python $BLENDER_SCRIPT"
  blender --background --python "$ROOT/$BLENDER_SCRIPT"
elif [[ -n "$BLEND_FILE" ]]; then
  [[ -z "$OUT_NAME" ]] && { echo "--out required with --blend"; usage; }
  echo "[1/3] blender --background $BLEND_FILE --python export_glb.py"
  blender --background "$ROOT/$BLEND_FILE" --python "$ROOT/blender/scripts/export_glb.py" -- --out "$ROOT/blender/exports/$OUT_NAME"
else
  echo "either --script or --blend required"
  usage
fi

echo "[2/3] copy blender/exports/*.glb -> game/assets/models/"
mkdir -p "$ROOT/game/assets/models"
shopt -s nullglob
copied=0
for f in "$ROOT"/blender/exports/*.glb; do
  cp -v "$f" "$ROOT/game/assets/models/"
  copied=$((copied+1))
done
if [[ $copied -eq 0 ]]; then
  echo "ERROR: no .glb in blender/exports/"
  exit 1
fi

echo "[3/3] godot --headless --import"
godot --headless --path "$ROOT/game" --import
echo "PIPELINE_OK copied=$copied"
