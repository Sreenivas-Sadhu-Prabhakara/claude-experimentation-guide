#!/usr/bin/env bash
# run-lab.sh — run one head-to-head lab: every task prompt through every model
# arm, capturing Claude Code's authoritative JSON telemetry (served model,
# tokens, cost, duration). Uses your logged-in Claude Code auth (e.g. a Max
# plan) — no API key required.
#
# Usage:
#   ./run-lab.sh <suite-dir> <out-dir> "<model-id-1>=<arm-1>" "<model-id-2>=<arm-2>" ...
#
#   <suite-dir>  holds task prompt files named  A.txt  B.txt  C.txt ...
#   <out-dir>    receives  <TASK>_<arm>.json  (raw) + <TASK>_<arm>.walltime
#
# Example (the Sonnet 5 vs Opus 4.8 labs):
#   ./run-lab.sh suites/sonnet5-vs-opus48 out/default \
#       "claude-sonnet-5=sonnet" "claude-opus-4-8=opus"
#
# For a max-effort ("ultrathink") variant, prepend an identical max-rigor
# directive to each task file first (see MAXDIRECTIVE below) so effort is held
# equal across arms. Grade with grade.py; that reads modelUsage as ground truth.
set -euo pipefail

SUITE="${1:?suite dir}"; OUT="${2:?out dir}"; shift 2
mkdir -p "$OUT"
command -v claude >/dev/null || { echo "claude CLI not found on PATH"; exit 1; }

# optional: export LAB_ULTRATHINK=1 to prepend the max-effort directive
MAXDIRECTIVE=$'ultrathink\n\nOperate at your maximum reasoning effort. Enumerate every defect, edge case, threat and failure mode; challenge your own first conclusions; do not stop early. Then produce your full answer.\n\n---\n\n'

run () { # $1 = prompt file  $2 = model-id  $3 = arm-label
  local prompt; prompt="$(cat "$1")"
  [ "${LAB_ULTRATHINK:-0}" = "1" ] && prompt="${MAXDIRECTIVE}${prompt}"
  local s; s=$(date +%s)
  claude --model "$2" -p "$prompt" --output-format json </dev/null \
      > "$OUT/$3.json" 2> "$OUT/$3.err" || echo "  ! $3 exited non-zero (see $OUT/$3.err)"
  echo $(( $(date +%s) - s )) > "$OUT/$3.walltime"
  echo "  done $3"
}

for task in "$SUITE"/*.txt; do
  t="$(basename "$task" .txt)"
  echo "task $t:"
  for pair in "$@"; do
    model="${pair%%=*}"; arm="${pair##*=}"
    run "$task" "$model" "${t}_${arm}" &
  done
  wait
done
echo "raw telemetry in $OUT/ — now grade with: python3 grade.py --raw $OUT ..."
