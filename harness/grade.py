#!/usr/bin/env python3
"""
grade.py — turn a lab's raw Claude Code telemetry into a durable, auditable
results.json (metrics + scores only; never the models' generated answers).

Usage:
  python3 grade.py --raw <dir-of-{TASK}_{arm}.json> \
                   --meta meta.json --scores scores.json --out results.json

- <raw dir> holds one `<TASK>_<arm>.json` per run, produced by run-lab.sh
  (i.e. `claude --model <id> -p ... --output-format json`).
- The *served* model, token counts, cost and duration are read from the
  `modelUsage` block in that JSON — ground truth, not the model's self-report.
- meta.json  = { id, title, date, effort, arms:{<arm>:<model-id>}, ... }
- scores.json = per-task, per-arm human/objective grades (defect counts,
  verdict, unique findings). Kept separate so grading is transparent.

Only distilled metrics are written out. The raw JSON (which contains the
models' generated code/answers) is never copied into the repo.
"""
import argparse, glob, json, os

# official published $/1M-token rates (input, output, cache-read, cache-write)
RATES = {
    "claude-opus-4-8":       {"in": 5.0, "out": 25.0, "cr": 0.5,  "cw": 6.25},
    "claude-sonnet-5":       {"in": 3.0, "out": 15.0, "cr": 0.3,  "cw": 3.75},
    "claude-sonnet-5-intro": {"in": 2.0, "out": 10.0, "cr": 0.2,  "cw": 2.5},
    "claude-fable-5":        {"in": 10.0,"out": 50.0, "cr": 1.0,  "cw": 12.5},
}

def norm_cost(u, rate):
    return round((u.get("inputTokens", 0)*rate["in"]
                  + u.get("outputTokens", 0)*rate["out"]
                  + u.get("cacheReadInputTokens", 0)*rate["cr"]
                  + u.get("cacheCreationInputTokens", 0)*rate["cw"]) / 1e6, 4)

def served_usage(raw):
    """Return (served_model_id, usage_dict) for the main (non-haiku) model."""
    mu = raw.get("modelUsage", {})
    main = [k for k in mu if "haiku" not in k]
    if not main:
        return None, {}
    return main[0], mu[main[0]]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", required=True)
    ap.add_argument("--meta", required=True)
    ap.add_argument("--scores", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    meta = json.load(open(a.meta))
    scores = json.load(open(a.scores))
    arms = meta["arms"]                       # {arm_label: model_id}
    intro = {m: m + "-intro" for m in RATES if m == "claude-sonnet-5"}

    tasks_out = []
    totals = {arm: {"out": 0, "dur_s": 0.0, "cost_std": 0.0, "cost_intro": 0.0}
              for arm in arms}

    for task in scores["tasks"]:
        tid = task["id"]
        entry = {"id": tid, "name": task["name"], "type": task.get("type", "graded")}
        for arm, model in arms.items():
            f = os.path.join(a.raw, f"{tid}_{arm}.json")
            if not os.path.exists(f):
                entry[arm] = {"error": "missing raw file"}
                continue
            raw = json.load(open(f))
            served, u = served_usage(raw)
            rate = RATES.get(served)
            cost_std = norm_cost(u, rate) if rate else None
            cost_intro = norm_cost(u, RATES[served + "-intro"]) if (served + "-intro") in RATES else None
            dur = round((raw.get("duration_ms") or 0) / 1000, 1)
            rec = {
                "requested_model": model,
                "served_model": served,            # verification: should equal requested
                "verified": served == model,
                "input_tokens": u.get("inputTokens"),
                "output_tokens": u.get("outputTokens"),
                "cache_read_tokens": u.get("cacheReadInputTokens"),
                "cache_create_tokens": u.get("cacheCreationInputTokens"),
                "duration_s": dur,
                "cost_usd_std": cost_std,
                "cost_usd_intro": cost_intro,
                "score": task.get("score", {}).get(arm, {}),
            }
            entry[arm] = rec
            totals[arm]["out"] += u.get("outputTokens", 0) or 0
            totals[arm]["dur_s"] += dur
            totals[arm]["cost_std"] += cost_std or 0
            totals[arm]["cost_intro"] += cost_intro or 0
        tasks_out.append(entry)

    for arm in totals:
        totals[arm] = {k: round(v, 4) if isinstance(v, float) else v
                       for k, v in totals[arm].items()}

    out = {
        "id": meta["id"], "title": meta["title"], "date": meta["date"],
        "effort": meta["effort"], "arms": arms,
        "verified_via": "claude-code modelUsage billing telemetry",
        "pricing_note": meta.get("pricing_note", ""),
        "headline": meta.get("headline", ""),
        "tasks": tasks_out, "totals": totals,
        "all_models_verified": all(
            t[arm].get("verified") for t in tasks_out for arm in arms
            if isinstance(t.get(arm), dict) and "verified" in t[arm]),
    }
    json.dump(out, open(a.out, "w"), indent=2)
    print(f"wrote {a.out} · all_models_verified={out['all_models_verified']}")

if __name__ == "__main__":
    main()
