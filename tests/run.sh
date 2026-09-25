#!/usr/bin/env bash
# Runs a headless simulation against a temporary copy of the project, with the chosen
# test script added as an autoload (so the real project.godot is never touched).
#
#   tests/run.sh voyage [runs]     # BOTS=2 by default; PIECES=4 for the pirate battle
#   tests/run.sh islands           # VOYAGE=1 Blossom Isle (default), VOYAGE=2 Wind Isle
#   tests/run.sh smoke             # load every scene and fail on script errors
#
# Set GODOT to the Godot 4.7 executable if it is not on PATH as "godot".
set -euo pipefail

GODOT="${GODOT:-godot}"
MODE="${1:-smoke}"
RUNS="${2:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp -r "$ROOT/project.godot" "$ROOT/icon.svg" "$ROOT/assets" "$ROOT/scenes" "$ROOT/scripts" "$ROOT/tests" "$TMP/"

if [ "$MODE" = "smoke" ]; then
  "$GODOT" --headless --path "$TMP" --import >/dev/null 2>&1 || true
  status=0
  for scene in menu story voyage island; do
    if "$GODOT" --headless --path "$TMP" "res://scenes/$scene.tscn" --quit-after 300 2>&1 | grep -E "SCRIPT ERROR|Parse Error"; then
      echo "FAIL $scene"; status=1
    else
      echo "OK   $scene"
    fi
  done
  exit $status
fi

case "$MODE" in
  voyage) SCRIPT="sim_voyage.gd" ;;
  islands) SCRIPT="sim_islands.gd" ;;
  *) echo "unknown mode: $MODE"; exit 2 ;;
esac

# Register the simulation as an autoload right after the Sound autoload.
sed -i.bak "s|^Sound=\"\*res://scripts/core/sound.gd\"|&\nSim=\"*res://tests/$SCRIPT\"|" "$TMP/project.godot"
"$GODOT" --headless --path "$TMP" --import >/dev/null 2>&1 || true

for i in $(seq 1 "$RUNS"); do
  "$GODOT" --headless --fixed-fps 60 --path "$TMP" 2>&1 | grep -E "^t=|PASS|FAIL|RESULT|SCRIPT ERROR"
done
