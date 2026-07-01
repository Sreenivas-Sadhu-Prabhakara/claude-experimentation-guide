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
