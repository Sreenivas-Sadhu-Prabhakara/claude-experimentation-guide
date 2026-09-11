#!/usr/bin/env bash
# run-build-lab.sh — drive a repo-building lab (as opposed to run-lab.sh, which is
# single-shot Q&A). Two arms, each a headless coding agent working inside its own
# git repo, across three rounds:
#
#   round-1  build   — arm reads BRIEF.md, builds autonomously, harness tags round-1
#   judge            — fmt / init / validate / tflint / checkov, raw output saved
#   round-2  repair  — arm gets ITS OWN raw judge output verbatim, one pass, tag round-2
#   round-3  review  — arm reviews the OTHER arm's round-2 repo, read-only, findings saved
#
# Usage:
#   ./run-build-lab.sh init                 # create both arm repos: git init + BRIEF.md only
#   ./run-build-lab.sh build                # round 1, both arms in parallel
#   ./run-build-lab.sh judge round-1        # judge both repos at that tag
#   ./run-build-lab.sh repair               # round 2 (needs judge round-1 output)
#   ./run-build-lab.sh judge round-2
#   ./run-build-lab.sh review               # round 3
#   ./run-build-lab.sh telemetry            # -> $OUT/telemetry.json from raw run files
#   ./run-build-lab.sh publish              # LICENSE + PROVENANCE.md, gh repo create --public, push
#
# Environment (all optional):
#   LAB_DIR    lab folder holding BRIEF.md, prompts/, judge/   (default: the tf lab)
#   ARMS_BASE  where arm repos live                            (default: ~/Code/Code)
#   OUT        raw run output                                  (default: harness/out/<lab-id>)
#   ARMS       space-separated arm labels to run               (default: both)
#   GH_OWNER   GitHub owner for publish                        (default: gh's active account)
#
# Fairness controls implemented here (see the lab's design spec):
#   - BRIEF.md is copied byte-for-byte and shasum-verified in every arm repo.
#   - RUBRIC.md is never copied anywhere. judge/ and prompts/ stay in the lab folder.
#   - Both arms read the same prompt file from stdin. Round-2 prompts embed each
#     arm's own judge output; nothing is summarised or edited.
#   - Neither arm is OS-sandboxed (Claude Code has no sandbox; codex's is bypassed
#     for parity). Instead GCP credentials are stripped from BOTH arms' environment.
#   - The harness, not the arm, commits and tags each round, so tags are comparable.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB="$(dirname "$HERE")"
LAB_DIR="${LAB_DIR:-$HUB/opus5-1m-vs-astra6-gcp-multitenant-tf}"
LAB_ID="$(basename "$LAB_DIR")"
ARMS_BASE="${ARMS_BASE:-$HOME/Code/Code}"
OUT="${OUT:-$HERE/out/$LAB_ID}"
ARMS="${ARMS:-opus5-1m astra6}"
mkdir -p "$OUT/judge" "$OUT/review" "$OUT/.tf-plugin-cache" "$OUT/.no-gcloud"

# ---- arm table (bash 3.2: no associative arrays) ---------------------------
model_of  () { case "$1" in opus5-1m) echo 'claude-opus-5[1m]';; astra6) echo 'gpt-6-astra';; *) die "unknown arm $1";; esac; }
runner_of () { case "$1" in opus5-1m) echo claude;; astra6) echo codex;; *) die "unknown arm $1";; esac; }
repo_of   () { case "$1" in opus5-1m) echo tf-multitenant-gcp-opus5;; astra6) echo tf-multitenant-gcp-astra6;; *) die "unknown arm $1";; esac; }
other_of  () { case "$1" in opus5-1m) echo astra6;; astra6) echo opus5-1m;; *) die "unknown arm $1";; esac; }
repo_dir  () { echo "$ARMS_BASE/$(repo_of "$1")"; }

die () { echo "!! $*" >&2; exit 1; }
log () { echo "[$(date +%H:%M:%S)] $*"; }
need () { command -v "$1" >/dev/null || die "$1 not found on PATH"; }

# ---- credential-free environment for BOTH arms ------------------------------
# No arm may reach GCP. Both get the same environment, so this is not a handicap.
arm_env () {
  env -u GOOGLE_APPLICATION_CREDENTIALS -u GOOGLE_CLOUD_PROJECT -u CLOUDSDK_CORE_PROJECT \
      -u GOOGLE_CLOUD_QUOTA_PROJECT -u GOOGLE_OAUTH_ACCESS_TOKEN \
      CLOUDSDK_CONFIG="$OUT/.no-gcloud" \
      GOOGLE_APPLICATION_CREDENTIALS=/nonexistent \
      TF_PLUGIN_CACHE_DIR="$OUT/.tf-plugin-cache" \
      "$@"
}

# ---- run one arm: run_arm <arm> <workdir> <prompt-file> <out-prefix> <mode> -----
# mode = write | readonly.  Prompt is fed on stdin to both runners.
run_arm () {
  local arm="$1" dir="$2" prompt="$3" prefix="$4" mode="$5"
  local model; model="$(model_of "$arm")"
  local s; s=$(date +%s)
  log "start $arm ($model) mode=$mode in $dir"
  case "$(runner_of "$arm")" in
    claude)
      local perm
      if [ "$mode" = write ]; then
        perm="--dangerously-skip-permissions"
      else
        perm="--allowedTools Read,Glob,Grep --disallowedTools Write,Edit,MultiEdit,NotebookEdit,Bash"
      fi
      # shellcheck disable=SC2086
      ( cd "$dir" && arm_env claude --model "$model" -p --output-format json $perm \
          < "$prompt" > "$OUT/$prefix.json" 2> "$OUT/$prefix.err" ) \
        || log "  ! $arm exited non-zero (see $OUT/$prefix.err)"
      ;;
    codex)
      local sb
      if [ "$mode" = write ]; then
        sb="--dangerously-bypass-approvals-and-sandbox"
      else
        sb="-s read-only"
      fi
      # shellcheck disable=SC2086
      ( arm_env codex exec --json -m "$model" -C "$dir" $sb -o "$OUT/$prefix.last.md" - \
          < "$prompt" > "$OUT/$prefix.jsonl" 2> "$OUT/$prefix.err" ) \
        || log "  ! $arm exited non-zero (see $OUT/$prefix.err)"
      ;;
  esac
  echo $(( $(date +%s) - s )) > "$OUT/$prefix.walltime"
  log "done  $arm in $(cat "$OUT/$prefix.walltime")s"
}

# ---- harness commit + tag (never commits .terraform/ or state) --------------
tag_round () {
  local dir="$1" tag="$2" msg="$3"
  git -C "$dir" add -A -- . ':(exclude,glob)**/.terraform/**' ':(exclude,glob)**/*.tfstate' ':(exclude,glob)**/*.tfstate.*' >/dev/null
  if ! git -C "$dir" diff --cached --quiet; then
    git -C "$dir" -c user.name=lab-harness -c user.email=lab-harness@localhost commit -q -m "$msg"
  fi
  git -C "$dir" tag -f "$tag" >/dev/null
  log "tagged $tag in $dir at $(git -C "$dir" rev-parse --short HEAD)"
}

# ---- subcommands -------------------------------------------------------------
cmd_init () {
  need git; need shasum
  [ -f "$LAB_DIR/BRIEF.md" ] || die "no BRIEF.md in $LAB_DIR"
  local want; want="$(shasum "$LAB_DIR/BRIEF.md" | cut -d' ' -f1)"
  for arm in $ARMS; do
    local dir; dir="$(repo_dir "$arm")"
    [ -e "$dir" ] && die "$dir already exists — refusing to overwrite an arm repo"
    mkdir -p "$dir"
    git -C "$dir" init -q -b main
    cp "$LAB_DIR/BRIEF.md" "$dir/BRIEF.md"
    local got; got="$(shasum "$dir/BRIEF.md" | cut -d' ' -f1)"
    [ "$got" = "$want" ] || die "BRIEF.md sha mismatch in $dir"
    git -C "$dir" add BRIEF.md
    git -C "$dir" -c user.name=lab-harness -c user.email=lab-harness@localhost commit -q -m "Add BRIEF.md (lab $LAB_ID)"
    git -C "$dir" tag round-0 >/dev/null
    log "init $arm -> $dir  (BRIEF.md $want, tag round-0, $(git -C "$dir" ls-files | wc -l | tr -d ' ') file)"
  done
}

cmd_build () {
  need claude; need codex
  for arm in $ARMS; do
    local dir; dir="$(repo_dir "$arm")"
    [ -d "$dir/.git" ] || die "$dir missing — run init first"
    [ "$(git -C "$dir" ls-files | tr -d ' ')" = "BRIEF.md" ] || die "$dir is not a clean BRIEF.md-only repo"
  done
  for arm in $ARMS; do
    run_arm "$arm" "$(repo_dir "$arm")" "$LAB_DIR/prompts/round-1-build.txt" "${arm}_round-1" write &
  done
  wait
  for arm in $ARMS; do tag_round "$(repo_dir "$arm")" round-1 "round-1: $arm build (harness commit)"; done
  log "round-1 complete. next: ./run-build-lab.sh judge round-1"
}

# roots = every dir with a .tf file, excluding .terraform/ and anything under a
# modules/ path. Over-inclusion is harmless (validate does not need var values).
tf_roots () {
  ( cd "$1" && find . -name '*.tf' -not -path '*/.terraform/*' -not -path '*/modules/*' -not -path '*/module/*' \
      | xargs -n1 dirname | sort -u )
}

judge_repo () { # judge_repo <arm> <tag>  — runs in a CLEAN checkout of the tag, never the working tree
  local arm="$1" tag="$2" src; src="$(repo_dir "$arm")"
  git -C "$src" rev-parse -q --verify "$tag^{commit}" >/dev/null || die "$src has no tag $tag"
  local dir="$OUT/judge/wt-${arm}-${tag}"
  rm -rf "$dir"; git -C "$src" worktree prune; git -C "$src" worktree add -q --detach "$dir" "$tag"
  local f="$OUT/judge/${arm}_${tag}.txt"
  {
    echo "# judge: $arm @ $tag ($(git -C "$src" rev-parse --short "$tag")) $(date -u +%FT%TZ)  [clean checkout]"
    echo "# terraform $(terraform version -json | python3 -c 'import sys,json;print(json.load(sys.stdin)["terraform_version"])')  tflint $(tflint --version | head -1 | awk '{print $3}')  checkov $(checkov --version)"
    echo
    echo '$ terraform fmt -check -recursive'
    ( cd "$dir" && terraform fmt -check -recursive -no-color 2>&1 ); echo "[exit $?]"; echo
    for r in $(tf_roots "$dir"); do
      echo "$ terraform -chdir=$r init -backend=false"
      ( cd "$dir" && arm_env terraform -chdir="$r" init -backend=false -input=false -no-color 2>&1 ); echo "[exit $?]"; echo
      echo "$ terraform -chdir=$r validate"
      ( cd "$dir" && terraform -chdir="$r" validate -no-color 2>&1 ); echo "[exit $?]"; echo
    done
    echo '$ tflint --recursive   (with the terraform + google rulesets)'
    ( cd "$dir" && tflint --init --config "$LAB_DIR/judge/tflint.hcl" >/dev/null 2>&1; tflint --recursive --config "$LAB_DIR/judge/tflint.hcl" --no-color 2>&1 ); echo "[exit $?]"; echo
    echo '$ checkov -d . --framework terraform --quiet --compact --skip-download'
    ( cd "$dir" && checkov -d . --framework terraform --quiet --compact --skip-download 2>&1 ); echo "[exit $?]"; echo
  } > "$f" 2>&1 || true
  git -C "$src" worktree remove --force "$dir" >/dev/null 2>&1 || rm -rf "$dir"
  log "judge $arm@$tag -> $f ($(wc -l < "$f" | tr -d ' ') lines)"
}

cmd_judge () {
  local tag="${1:?tag: round-1 | round-2}"
  need terraform; need tflint; need checkov
  for arm in $ARMS; do judge_repo "$arm" "$tag"; done
}

cmd_repair () {
  need claude; need codex
  for arm in $ARMS; do
    local dir; dir="$(repo_dir "$arm")"
    local j="$OUT/judge/${arm}_round-1.txt"
    [ -f "$j" ] || die "missing $j — run: judge round-1"
    [ "$(git -C "$dir" rev-parse round-1)" = "$(git -C "$dir" rev-parse HEAD)" ] || die "$dir not at round-1"
    local p="$OUT/${arm}_round-2.prompt.txt"
    { cat "$LAB_DIR/prompts/round-2-repair.txt"; echo; echo "===== JUDGE OUTPUT ====="; echo; cat "$j"; } > "$p"
  done
  for arm in $ARMS; do
    run_arm "$arm" "$(repo_dir "$arm")" "$OUT/${arm}_round-2.prompt.txt" "${arm}_round-2" write &
  done
  wait
  for arm in $ARMS; do tag_round "$(repo_dir "$arm")" round-2 "round-2: $arm repair (harness commit)"; done
  log "round-2 complete. next: ./run-build-lab.sh judge round-2"
}

cmd_review () {
  need claude; need codex
  for arm in $ARMS; do
    local other; other="$(other_of "$arm")"
    local src; src="$(repo_dir "$other")"
    local wt="$OUT/review/${arm}-reviews-${other}"
    git -C "$src" rev-parse -q --verify round-2 >/dev/null || die "$src has no round-2 tag"
    rm -rf "$wt"; git -C "$src" worktree prune
    git -C "$src" worktree add -q --detach "$wt" round-2
    run_arm "$arm" "$wt" "$LAB_DIR/prompts/round-3-review.txt" "${arm}_round-3" readonly &
  done
  wait
  for arm in $ARMS; do
    local other; other="$(other_of "$arm")"
    local wt="$OUT/review/${arm}-reviews-${other}"
    if [ -n "$(git -C "$wt" status --porcelain)" ]; then
      log "  ! $arm modified the read-only worktree — recorded in $OUT/review/${arm}_violation.txt"
      git -C "$wt" status --porcelain > "$OUT/review/${arm}_violation.txt"
      git -C "$wt" checkout -q -- . && git -C "$wt" clean -qfd
    fi
    case "$(runner_of "$arm")" in
      claude) python3 -c 'import sys,json;print(json.load(open(sys.argv[1])).get("result",""))' "$OUT/${arm}_round-3.json" > "$OUT/review/${arm}_findings.md" ;;
      codex)  cp "$OUT/${arm}_round-3.last.md" "$OUT/review/${arm}_findings.md" ;;
    esac
    log "findings $arm -> $OUT/review/${arm}_findings.md ($(grep -c '^\s*[-*]' "$OUT/review/${arm}_findings.md" || true) bullets)"
  done
  log "round-3 complete. grade the findings (verified / not) into scores.json"
}

cmd_telemetry () {
  python3 - "$OUT" $ARMS <<'PY'
import glob, json, os, sys
out, arms = sys.argv[1], sys.argv[2:]
tel = {}
for arm in arms:
    tel[arm] = {}
    for rnd in ("round-1", "round-2", "round-3"):
        rec = {}
        wt = f"{out}/{arm}_{rnd}.walltime"
        if os.path.exists(wt):
            rec["wall_s"] = int(open(wt).read().strip() or 0)
        cj = f"{out}/{arm}_{rnd}.json"
        if os.path.exists(cj):                      # Claude Code: modelUsage is ground truth
            d = json.load(open(cj))
            mu = d.get("modelUsage", {})
            main = [k for k in mu if "haiku" not in k]
            rec.update({"harness": "claude-code", "served_model": main[0] if main else None,
                        "usage": mu.get(main[0], {}) if main else {},
                        "cost_usd_reported": d.get("total_cost_usd"), "duration_ms": d.get("duration_ms"),
                        "num_turns": d.get("num_turns"), "session_id": d.get("session_id")})
        cx = f"{out}/{arm}_{rnd}.jsonl"
        if os.path.exists(cx):                      # Codex: sum turn.completed usage events
            tot, thread = {}, None
            for line in open(cx):
                try: e = json.loads(line)
                except Exception: continue
                if e.get("type") == "thread.started": thread = e.get("thread_id")
                if e.get("type") == "turn.completed":
                    for k, v in e.get("usage", {}).items(): tot[k] = tot.get(k, 0) + v
            tot["new_tokens"] = tot.get("input_tokens", 0) - tot.get("cached_input_tokens", 0) + tot.get("output_tokens", 0)
            rec.update({"harness": "codex-cli", "requested_model": "gpt-6-astra", "usage": tot, "thread_id": thread,
                        "source": "codex exec --json turn.completed events (sum)"})
        if rec: tel[arm][rnd] = rec
json.dump(tel, open(f"{out}/telemetry.json", "w"), indent=2)
print(json.dumps(tel, indent=2))
PY
}

cmd_publish () {
  need gh; need curl
  local owner="${GH_OWNER:-$(gh api user -q .login)}"
  for arm in $ARMS; do
    local dir name; dir="$(repo_dir "$arm")"; name="$(repo_of "$arm")"
    [ -f "$dir/LICENSE" ] || curl -fsSL https://www.apache.org/licenses/LICENSE-2.0.txt -o "$dir/LICENSE"
    cat > "$dir/PROVENANCE.md" <<EOF
# Provenance

This repository is **unreviewed machine output** from an AI-model comparison lab.

| | |
|---|---|
| Lab | \`$LAB_ID\` in https://github.com/$owner/claude-experimentation-guide |
| Arm | \`$arm\` |
| Model (from telemetry, not self-report) | \`$(model_of "$arm")\` |
| Harness | $(runner_of "$arm") CLI, headless, non-interactive |
| Brief | \`BRIEF.md\` (byte-identical across arms) |
| Tags | \`round-0\` brief only · \`round-1\` first build · \`round-2\` after one self-repair pass |

Nothing here was applied to GCP. The commits tagged \`round-1\` and \`round-2\` were made by the
lab harness, not by the model. \`LICENSE\` and this file were added by the harness after the runs.
EOF
    git -C "$dir" add LICENSE PROVENANCE.md
    git -C "$dir" -c user.name=lab-harness -c user.email=lab-harness@localhost commit -q -m "Add LICENSE (Apache-2.0) and PROVENANCE.md (harness)" || true
    if gh repo view "$owner/$name" >/dev/null 2>&1; then
      git -C "$dir" push -q -u origin main --tags
    else
      gh repo create "$owner/$name" --public --source "$dir" --remote origin --push \
        --description "Lab $LAB_ID — arm $arm ($(model_of "$arm")), unreviewed machine output"
      git -C "$dir" push -q --tags
    fi
    log "published https://github.com/$owner/$name"
  done
}

case "${1:-}" in
  init)      cmd_init ;;
  build)     cmd_build ;;
  judge)     cmd_judge "${2:-}" ;;
  repair)    cmd_repair ;;
  review)    cmd_review ;;
  telemetry) cmd_telemetry ;;
  publish)   cmd_publish ;;
  *) sed -n '2,32p' "$0"; exit 1 ;;
esac
