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
elif [[ -n "$BLEND_FILE" ]]; then
  [[ -z "$OUT_NAME" ]] && { echo "--out required with --blend"; usage; }
  echo "[1/3] blender --background $BLEND_FILE --python export_glb.py"
else
  echo "either --script or --blend required"
  usage
fi

# マーカー以降に書き出された GLB のみコピー対象にする (過去実行の無関係 GLB 再コピー防止)
RUN_MARKER="$(mktemp)"
trap 'rm -f "$RUN_MARKER"' EXIT

if [[ -n "$BLENDER_SCRIPT" ]]; then
  blender --background --python "$ROOT/$BLENDER_SCRIPT"
else
  blender --background "$ROOT/$BLEND_FILE" --python "$ROOT/blender/scripts/export_glb.py" -- --out "$ROOT/blender/exports/$OUT_NAME"
fi

echo "[2/3] copy blender/exports/*.glb -> game/assets/models/ (this run only)"
mkdir -p "$ROOT/game/assets/models"
shopt -s nullglob
copied=0
for f in "$ROOT"/blender/exports/*.glb; do
  if [[ "$f" -nt "$RUN_MARKER" ]]; then
    cp -v "$f" "$ROOT/game/assets/models/"
    copied=$((copied+1))
  fi
done
if [[ $copied -eq 0 ]]; then
  echo "ERROR: no new .glb generated in blender/exports/ by this run"
  exit 1
fi

echo "[3/3] godot --headless --import"
godot --headless --path "$ROOT/game" --import
echo "PIPELINE_OK copied=$copied"
