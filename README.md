# Kriya Model Lab

**A re-runnable evaluation harness that decides which Claude model + effort tier
[Kriya](https://github.com/Sreenivas-Sadhu-Prabhakara) should use for each agent
role — with the real runs to prove it.**

This is an **engineering artifact, not a research write-up**. It answers one
operational question, repeatedly and with evidence: *for a given agent role in an
adversarial, spec-driven build pipeline, which model and effort earn their cost?*
The hosted decks are the evidence; the machine-readable **routing recommendation**
is the point.

🔗 **Live:** <https://sreenivas-sadhu-prabhakara.github.io/claude-experimentation-guide/>

---

## What's here

| Path | What it is |
|------|------------|
| **`index.html`** | The hub — leads with the current [routing recommendation](routing/), then the labs. Reads `manifest.json` + `routing/routing.json`, so new labs appear automatically. |
| **`routing/`** | **The output.** [`ROUTING.md`](routing/ROUTING.md) + [`routing.json`](routing/routing.json): role → model → effort, evidence-backed, ready to wire into Kriya's per-agent config. |
| **`harness/`** | The engine — [`run-lab.sh`](harness/run-lab.sh) + [`grade.py`](harness/grade.py) + [README](harness/README.md). Runs a head-to-head via Claude Code (Max plan, no API key) and turns raw runs into an auditable `results.json`. Adding lab #4, #5, … is mechanical. |
| **`shared/`** | One keynote design system (`keynote.css`) so every deck is one visual family. |
| **`sonnet5-vs-opus48-default/`** | Lab — Sonnet 5 vs Opus 4.8 at **default** effort. `index.html` deck + `meta.json` + `scores.json` + generated `results.json`. |
| **`sonnet5-vs-opus48-ultrathink/`** | Lab — the same, re-run at **max** effort (ultrathink). |
| **`fable/`** | The original **Fable Field Guide** (Claude Fable 5 explainer). |
| **`manifest.json`** | Generic index of every item; the hub renders from it. |

## The trust model

- The **served** model, tokens, cost and duration come from Claude Code's
  `modelUsage` billing telemetry — **not** the model's self-report (models are
  unreliable narrators about their own identity).
- Only **distilled metrics** are committed. The models' generated answers/code
  are discarded.
- **Costs** are normalized to official published per-token rates.
- Grading has an explicit human-in-the-loop step against published answer keys —
  the *measurement* is automated and reproducible; the *judgement* is in-repo and
  reviewable (`scores.json` per lab).

## Add a lab

```bash
# 1. Run every task through every model (raw telemetry -> out/)
harness/run-lab.sh suites/<name> out/<name> "claude-sonnet-5=sonnet5" "claude-opus-4-8=opus48"
# 2. Grade -> results.json
python3 harness/grade.py --raw out/<name> --meta <name>/meta.json --scores <name>/scores.json --out <name>/results.json
# 3. Add it to manifest.json, refresh routing/, drop an index.html deck (reuse shared/keynote.css)
```

## Hosting

Static site on GitHub Pages via [`.github/workflows/deploy.yml`](.github/workflows)
— every push to `main` uploads the repo root, so each sibling folder is served at
its own path. No build step.

---

*Built with Kriya's methodology on the Apolaki build. All model facts reflect the
official Anthropic docs as of the run date; generated code discarded.*
