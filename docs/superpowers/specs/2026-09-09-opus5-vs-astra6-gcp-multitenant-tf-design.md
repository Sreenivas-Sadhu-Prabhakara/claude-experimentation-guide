# Lab design — Opus 5 (1M) vs GPT-6 Astra: GCP multi-tenant Terraform

**Lab id:** `opus5-1m-vs-astra6-gcp-multitenant-tf`
**Date:** 2026-09-09
**Status:** design approved, not yet run

---

## The question

Given an identical infrastructure brief that states *requirements* but deliberately
does not dictate *topology*, which model produces the better Terraform
configuration for a multi-tenant, two-sided GCP platform — and does the gap show
up in first-draft quality, in self-repair from real tool output, or in review?

## Why this task

Terraform is unusually well suited to a model bake-off because a large share of
quality is machine-checkable rather than taste-based:

- `terraform fmt -check`, `init -backend=false`, `validate` are pass/fail.
- `tflint` and `checkov` produce countable findings.
- IAM smells (`roles/editor`, `roles/owner`, `allUsers`) are greppable.
- A public Cloud SQL IP or a plaintext secret is a fact, not an opinion.

This keeps the human-in-the-loop judgement confined to one rubric section
(architecture) instead of spread across the whole score.

## Arms

| Arm | Model id (from telemetry) | Runner |
|---|---|---|
| `opus5-1m` | `claude-opus-5[1m]` (canonical `claude-opus-5`, 1M ctx) | `claude -p` headless, tools enabled, inside the arm repo |
| `astra6` | `gpt-6-astra` | `codex exec -m gpt-6-astra` inside the arm repo |

**Model labels come from telemetry, never self-report.** The requester referred to
this session as "Opus 5.1"; `modelUsage` returns `claude-opus-5[1m]`, so the lab
records `claude-opus-5[1m]`. Codex CLI 0.153.4 is required — 0.145.0 rejects
`gpt-6-astra` with *"requires a newer version of Codex"*.

Both arms run **headless and non-interactive**, in a fresh isolated context, with
write access confined to their own repo. Neither arm is run via an in-process
subagent: an in-process agent shares the grader's context and returns no
independent billing telemetry, which would break both fairness and measurement.

## Deviation from the hub's standing trust model

The repo README states: *"Only distilled metrics are committed. The models'
generated answers/code are discarded."*

**This lab deliberately deviates.** Both arms' full output is preserved in public
GitHub repositories so the comparison is independently reviewable and the
Terraform is reusable:

- `tf-multitenant-gcp-opus5` — Apache-2.0, public
- `tf-multitenant-gcp-astra6` — Apache-2.0, public

Each repo's README declares its provenance (which model, which lab, unreviewed
machine output). The deviation is documented here and on the lab deck rather than
applied silently.

## Fairness controls

1. **Byte-identical brief.** `BRIEF.md` is written once and copied unmodified into
   both repos. Verified by `shasum` before the run.
2. **Identical starting state.** Each repo begins as a fresh `git init` containing
   `BRIEF.md` and nothing else — no scaffolding, no `.tf` stub, no license yet.
3. **Rubric withheld.** `RUBRIC.md` is written *before* the run, committed to the
   lab folder, and never placed in either arm repo. An arm that can see the rubric
   optimises to the scorecard, which measures instruction-following rather than
   engineering judgement.
4. **No differential hinting.** Any clarification given to one arm invalidates the
   round. If an arm asks a question, the run is non-interactive, so it must decide
   — and its choice is data.
5. **Same tool posture.** Both arms get file-write access to their own repo plus
   network access for provider downloads. Neither gets `terraform apply`; no GCP
   credentials are exposed to either arm.
6. **Grading order.** Repos are graded in a fixed order with the arm identity
   visible (blinding is impractical: Terraform style is identifiable). The
   objective sections neutralise most of this; the architecture section is the
   residual risk and is scored against written criteria fixed in advance.

## The brief

Requirements are stated; topology is left open. Full text lives in `BRIEF.md`.

**Required:**

1. Declarative tenant onboarding — adding a tenant is a data change, not a code
   change.
2. A stated *and justified* data-isolation model.
3. Consumer-side and provider-side APIs as separate Cloud Run services.
4. Per-tenant service accounts, least-privilege IAM, no primitive roles.
5. Private-IP Cloud SQL; no public database endpoint.
6. Secret Manager with per-tenant secret scoping; no plaintext secrets.
7. Remote GCS state backend with locking.
8. `dev` / `staging` / `prod` separable without copy-paste.
9. Log sinks with per-tenant routing, plus budget alerts.
10. Passes `fmt -check`, `init -backend=false`, `validate`; clean `tflint`.
11. README with architecture rationale and a tenant-onboarding runbook.

**Deliberately left open — these are the discriminators:**

- Project-per-tenant vs. shared-project-with-labels vs. hybrid.
- Database-per-tenant vs. schema-per-tenant vs. row-level security.
- Module decomposition and repository layout.

## Rounds

### Round 1 — Build
Each arm receives `BRIEF.md` and builds autonomously. No interaction, no
follow-ups. Output committed to the arm repo, tagged `round-1`.

Measures: first-draft engineering judgement.

### Round 2 — Repair
The judge command set is run against each repo. Each arm is handed **its own** raw
tool output, verbatim and unsummarised, and gets exactly one repair pass. Tagged
`round-2`.

Measures: self-correction from real error text — the everyday loop, and the thing
a single-shot benchmark cannot see.

### Round 3 — Cross-review
Each arm reviews the *other* arm's `round-2` repo and produces findings. Findings
are then verified by the grader as real / not-real, and **the verified findings**
are what score — raw finding count is not a metric, because inflating it is free.

Measures: review quality, independent of authoring ability.

## Judge

Run identically against both repos at the end of each round:

```
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
tflint --recursive
checkov -d . --framework terraform
```

`terraform plan` is **not** run: it requires live GCP credentials and would make
the score depend on project state rather than on the code. This is a stated limit
of the lab, not an oversight.

## Grading

`RUBRIC.md`, 100 points, weighted toward objective checks. Sections and their
point allocation are fixed **before** the run. Per-section scores land in
`scores.json`; `results.json` is generated from telemetry plus scores.

## Telemetry and the cost caveat

- Opus arm: Claude Code `modelUsage` — served model, tokens, cost, duration.
- Astra arm: Codex CLI's own reported token count.

These are **two different harnesses** with different system prompts and different
tool-call overheads. Following the precedent set by
`opus48-vs-gpt56sol-mobile-aab`, token and cost figures are reported but **no
token-efficiency winner is claimed** unless the gap exceeds an order of magnitude.

## Deliverables

| Artifact | Location |
|---|---|
| `BRIEF.md`, `RUBRIC.md`, `meta.json`, `scores.json`, `results.json`, `index.html` | `opus5-1m-vs-astra6-gcp-multitenant-tf/` in this repo |
| Build runner | `harness/run-build-lab.sh` (new — the existing `run-lab.sh` is single-shot Q&A and cannot drive a repo build) |
| Opus arm output | `github.com/Sreenivas-Sadhu-Prabhakara/tf-multitenant-gcp-opus5` (public) |
| Astra arm output | `github.com/Sreenivas-Sadhu-Prabhakara/tf-multitenant-gcp-astra6` (public) |
| Hub entry | `manifest.json` `items[]` |
| Routing update | `routing/` — re-derived, version bumped |

## Out of scope

- No `terraform apply`; nothing is deployed to GCP.
- No cost-optimisation review of the generated infrastructure.
- No third arm. Two-way comparison only.
