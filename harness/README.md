# harness — run and grade a model lab

The engine behind this repo. It runs a head-to-head between models on a suite of
tasks, using your logged-in **Claude Code** (a Max plan works — **no API key
needed**), and turns the raw runs into a durable, auditable `results.json`.

It exists so that **adding lab #4, #5, … is mechanical**, not hand-crafted.

## Why it's trustworthy

- The **served** model, tokens, cost and duration come from Claude Code's
  `modelUsage` billing telemetry — *not* the model's self-report (models lie
  about their own identity: a `claude-sonnet-5` run once insisted it was 4.6).
- Only **distilled metrics** land in the repo. The models' generated
  answers/code are never committed.

## Run a lab

```bash
# 1. Put one prompt file per task in a suite dir:  A.txt  B.txt  C.txt ...
# 2. Run every task through every model arm (raw JSON -> out/):
./run-lab.sh suites/my-lab out/my-lab \
    "claude-sonnet-5=sonnet5" "claude-opus-4-8=opus48"

# For a max-effort variant, hold effort equal across arms with the built-in
# ultrathink directive:
LAB_ULTRATHINK=1 ./run-lab.sh suites/my-lab out/my-lab-max \
    "claude-sonnet-5=sonnet5" "claude-opus-4-8=opus48"
```

## Grade it

```bash
python3 grade.py \
  --raw   out/my-lab \
  --meta  ../my-lab/meta.json \
  --scores ../my-lab/scores.json \
  --out   ../my-lab/results.json
```

- `meta.json` — lab id/title/date/effort and the `arms` map (`{arm: model-id}`).
- `scores.json` — the per-task, per-arm grades (defect counts, verdict, unique
  findings). Kept separate and in-repo so the grading is transparent and
  reviewable, and objective tasks can be re-scored independently.
- `results.json` — generated. Telemetry + normalized cost (official published
  rates) + scores. This is what the gallery and routing read.

## Then

1. Add the lab to [`../manifest.json`](../manifest.json) (`items[]`).
2. Re-derive the recommendation in [`../routing/`](../routing/) and bump its version.
3. Drop an `index.html` deck in the lab folder (reuse [`../shared/keynote.css`](../shared/keynote.css)).

Grading has a human-in-the-loop step by design (objective answer keys applied by
a reviewer). The **measurement** is automated and reproducible; the **judgement**
is explicit and in-repo. That's the honesty boundary.

## Repo-building labs: `run-build-lab.sh`

`run-lab.sh` is single-shot Q&A and cannot drive a repo build. For labs where each
arm builds a whole repository (first used by `opus5-1m-vs-astra6-gcp-multitenant-tf`),
use `run-build-lab.sh`. It runs two headless coding agents — Claude Code and Codex
CLI — each inside its own git repo, across three rounds, and it (not the arm) makes
the `round-N` tags so the repos stay comparable.

```bash
./run-build-lab.sh init            # both arm repos: git init + BRIEF.md only (shasum-verified)
./run-build-lab.sh build           # round 1, both arms in parallel
./run-build-lab.sh judge round-1   # fmt / init / validate / tflint(google) / checkov, in a clean checkout
./run-build-lab.sh repair          # round 2: each arm gets its OWN judge output verbatim, one pass
./run-build-lab.sh judge round-2
./run-build-lab.sh review          # round 3: each arm reviews the OTHER arm's round-2 repo, read-only
./run-build-lab.sh telemetry       # out/<lab>/telemetry.json — Claude modelUsage + Codex turn.completed
./run-build-lab.sh publish         # LICENSE + PROVENANCE.md, gh repo create --public, push with tags
```

The lab folder supplies `BRIEF.md`, `prompts/round-{1,2,3}-*.txt` and `judge/tflint.hcl`.
`RUBRIC.md` never leaves the lab folder. Both arms run with GCP credentials stripped
from the environment; neither is OS-sandboxed, so the posture is identical.
Raw run output goes to `out/` (gitignored). The build round can take a long time —
run it under `nohup` or in a terminal you can leave alone.
