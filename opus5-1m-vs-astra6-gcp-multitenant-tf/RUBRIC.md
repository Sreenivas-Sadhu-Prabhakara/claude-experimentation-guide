# Grading rubric — 100 points

> **Withheld from both arms.** This file lives only in the lab folder and is never
> copied into an arm repository. It is committed **before** the run so that no
> criterion can be adjusted after seeing output.

> Sections 1–4 and 6 are objective: a passing command, a countable finding, a
> greppable resource attribute. Section 5 (architecture) is the single human-judged
> section and is scored against the written criteria below, fixed in advance.
> Section 7 scores round 3 (cross-review). A criterion scores full marks only with
> concrete evidence, cited by file and line in `scores.json`.

**How the rubric is applied**

| Column | Scope | Scored on |
|---|---|---|
| `round1` | Sections 1–6 (out of 90) | The `round-1` tag: first draft |
| `round2` | Sections 1–6 (out of 90) | The `round-2` tag: after one self-repair pass |
| `review` | Section 7 (out of 10) | The arm's findings against the other arm's `round-2` repo |
| **`total`** | **round2 + review** | **Headline score, out of 100** |

`round2 − round1` is the repair delta and is reported alongside the total.

## 1 · Judge gate — 20 pts
| Check | Pts | How it's verified |
|---|---|---|
| `terraform fmt -check -recursive` exits 0 | 4 | run the command |
| `terraform init -backend=false` exits 0 in every root | 4 | run the command |
| `terraform validate` exits 0 in every root | 6 | run the command |
| `tflint --recursive` with the `google` ruleset: 0 errors, 0 warnings | 4 | 0 issues = 4 · ≤3 warnings, 0 errors = 2 · otherwise 0 |
| `checkov -d . --framework terraform` | 2 | 0 failed checks = 2 · ≤5 failed = 1 · otherwise 0 |

## 2 · Requirements coverage — 25 pts
| Required outcome actually implemented (not stubbed) | Pts | Evidence |
|---|---|---|
| Tenant onboarding is a data change; ≥2 example tenants present | 4 | a `for_each` over tenant data; adding a tenant touches no `.tf` file |
| Data-isolation model is stated in the README | 2 | the statement exists (its quality is scored in §5) |
| Consumer API and provider API are separate Cloud Run services | 3 | two `google_cloud_run_v2_service` (or equivalent) resources |
| Per-tenant service accounts exist and are used by tenant workloads | 3 | `google_service_account` per tenant, referenced by the services |
| Cloud SQL instance has no public IP | 3 | `ipv4_enabled = false`, `private_network` set |
| Secret Manager secrets scoped per tenant, IAM limits access to that tenant's SA | 3 | per-tenant `google_secret_manager_secret` + member-level IAM |
| GCS backend declared with bucket as an input | 2 | `backend "gcs"` block; no hard-coded bucket name |
| `dev` / `staging` / `prod` differ by configuration only | 3 | shared modules; env difference is tfvars or a single map |
| Per-tenant log sink routing + billing budget alerts | 2 | `google_logging_project_sink` with tenant filter; `google_billing_budget` |

## 3 · Security posture — 15 pts
| Check | Pts | How it's verified |
|---|---|---|
| No primitive roles anywhere | 4 | `grep -rE 'roles/(owner\|editor\|viewer)"'` returns nothing |
| Public invokers (`allUsers`, `allAuthenticatedUsers`) appear only where the README declares the service public | 3 | grep, then cross-check the README |
| No secret values in code or examples | 3 | grep for `secret_data`, `password`, `key` literals; none carry a real or placeholder value inline |
| No `google_service_account_key` resources | 2 | grep |
| Cloud SQL `deletion_protection` not disabled in `prod`; SSL required or private-only documented | 3 | resource attributes per environment |

## 4 · Code structure — 10 pts
| Check | Pts |
|---|---|
| Modules with typed variables, descriptions, and sensible defaults | 3 |
| Zero duplicated resource blocks across environments | 3 |
| `validation` blocks or preconditions on tenant input (id format, uniqueness, allowed regions) | 2 |
| Outputs expose what an operator needs (service URLs, SA emails, SQL connection name) | 2 |

## 5 · Architecture judgement — 15 pts (human-scored against these fixed criteria)

> This is the residual subjectivity in the lab. The grader knows which arm is
> which. Each criterion below is therefore phrased as a **question with a yes/no
> or count answer**, so that two graders working independently would land within a
> point of each other.

| Criterion (answerable yes/no or by count) | Pts | How it's scored |
|---|---|---|
| Tenant boundary: does the README name the chosen boundary (project-per-tenant / shared / hybrid), at least one rejected alternative, and at least one accepted trade-off? | 3 | all three present = 3 · choice + one of the other two = 2 · choice only = 1 · absent = 0 |
| Data isolation: does the README name the chosen model, at least one rejected alternative, and at least one accepted trade-off, **and** does the code match the stated model? | 4 | README complete = 2 · code matches the stated model = 2 (a stated model the code does not implement scores 0 for the whole row) |
| Blast radius: if one tenant's service account is compromised, how many other tenants' data or secrets does it reach, per the IAM bindings as written? | 4 | zero = 4 · read-only reach into ≥1 other tenant = 2 · write reach into ≥1 other tenant = 0 |
| Service boundary: do the consumer and provider services run under **different** service accounts, and does the README state why the two sides are separate services rather than one? | 2 | both = 2 · one = 1 · neither = 0 |
| Consistency: count the "left open" decisions in the brief whose README rationale contradicts what the code does (e.g. README says schema-per-tenant, code creates one database per tenant) | 2 | 0 contradictions = 2 · 1 = 1 · ≥2 = 0 |

## 6 · Documentation — 5 pts
| Check | Pts |
|---|---|
| README architecture rationale covers every "left open" decision in the brief | 2 |
| Tenant-onboarding runbook is complete: a new operator could follow it without reading the code | 2 |
| `required_version` and provider versions pinned to explicit values | 1 |

## 7 · Cross-review (round 3) — 10 pts
| Check | Pts | How it's verified |
|---|---|---|
| Verified-real findings, severity-weighted: critical 3 · high 2 · medium 1 · low 0.5, capped at 6 | 6 | each finding is reproduced by the grader against the other arm's `round-2` repo |
| Precision: verified ÷ raised ≥ 0.8 = 4 · ≥ 0.6 = 2 · otherwise 0 | 4 | count |

Raw finding count is never a metric. A finding that cannot be reproduced scores
nothing and counts against precision.

---
**Scoring notes.**

- **Cap rule (run-and-failed only).** An arm that **was run** but whose repo fails
  `terraform validate` caps at the points it can evidence in sections 2–6. An arm
  that was **not run** has *no* score at all, not a zero. "Not run" and "run and
  scored low" must never be conflated.
- **Checkov is not pre-announced.** The brief names four gate commands; `checkov`
  is a judge-only tool. Its round-1 findings are handed to each arm verbatim in
  round 2, so it measures repair from unfamiliar tool output rather than
  instruction-following. Both arms face the identical bar.
- **Correlated checks.** Sections 2 and 3 both touch Cloud SQL and IAM from
  different angles (presence vs. absence of smells). The overlap is deliberate:
  a missing resource loses in §2, a present-but-dangerous one loses in §3.
- **`terraform plan` is not run.** It needs live credentials and would make the
  score depend on project state, not code. Anything only a plan would catch is
  outside this lab's measurement.
- **Token and cost figures** are reported from telemetry but no efficiency winner
  is claimed unless the gap exceeds an order of magnitude (two different
  harnesses).
