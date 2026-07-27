# Kriya model routing — recommendation

**Version 2026-07-27** · derived from measured runs, not vibes.
Source labs: [`sonnet5-vs-opus48-default`](../sonnet5-vs-opus48-default/) · [`sonnet5-vs-opus48-ultrathink`](../sonnet5-vs-opus48-ultrathink/) · [`fable5-vs-opus48-burnzone`](../fable5-vs-opus48-burnzone/) · [`opus5-vs-opus48-burnzone`](../opus5-vs-opus48-burnzone/).
Machine-readable: [`routing.json`](routing.json).

This is the actionable output of the model labs: **which model + effort tier each Kriya agent role should use**, with the evidence behind it. Wire it into Kriya's per-agent front-matter / tech-radar.

## Headline

**Opus 5 takes the gate; Opus 4.8 keeps the build.** Run on the *same* suite and keys as the Fable lab, Opus 5 and Opus 4.8 **both hit the objective ceiling on all four tasks** — 2/2 seeded criticals, correct minimal fix, 16/16 rubric, correct VETO. The answer key cannot separate them. Two things can:

- **Depth past the key.** 15 valid defects vs 6 on the security capture; 6 vs 3 on the gate; and Opus 5 is the **first arm in any lab** to pin the no-500 invariant explicitly.
- **Availability.** Opus 5 served **both** security prompts that Fable 5 declined — the first clean **4/4** head-to-head in this repo.

Because Opus 5 bills at Opus 4.8's **identical $5/$25 tier**, its **1.94×** cost is *pure token volume* (adaptive thinking on by default), not a price premium. That changes the question from *"is it worth the premium"* to *"is the extra enumeration worth it"* — **yes** where the deliverable *is* enumeration, **no** where it's one correct minimal fix.

## The table

| Kriya role | Stage | Model | Effort | Why (evidence) |
|---|---|---|---|---|
| **Gate verifier** ⬆ | verify · independent gate | `claude-opus-5` | `high` | **Changed from 4.8.** Both VETO correctly and both catch the planted fail-open — the verdict is model-robust. But a gate's value is the enumeration behind it: **6 findings vs 3** at only **1.32× tokens**, the cheapest place to buy the upgrade. Opus 5 ranked *above* the planted bug the deeper cause 4.8 left secondary — the deny-list keys off the attacker-supplied request string, not the resolved role row. |
| **Security critic** ⬆ | security capture · threat model · auth audit | `claude-opus-5` | `high` | **Changed from 4.8.** Widest quality gap in the lab: **15 valid defects vs 6**, 0 false positives on both. Opus 5's extras were each verified against the source — `oauth_accounts` missing `tenant_id`, `/idtoken` with no `try/catch`, unguarded `rows[0]`, type-confusable password check, role changes not invalidating live JWTs. It also ships per-finding confidence and flags what it *couldn't* verify. And it doesn't decline — Fable refused this exact prompt. |
| **Producer — code** = | build · brownfield | `claude-opus-4-8` | `high` | **Unchanged.** Both produced the same correct minimal LEFT JOIN, 4/4 invariants — when the deliverable is *one correct fix*, 4.8 already reaches the ceiling. Opus 5's extra 1.5× bought real but marginal depth (the ON-vs-WHERE trap; a `b.id DESC` pagination tiebreaker; it *ran a SQL parser* on its own output). Escalate to Opus 5 for pagination/ordering/concurrency-sensitive or hard-to-reverse changes. |
| **Producer — design** ⬆ | design · LLD · shift-left · strangler plan | `claude-opus-5` | `high` | **Changed, conditionally.** Both scored **16/16** — the rubric is saturated. Opus 5 earns it off-rubric: first arm anywhere to pin **no-500 explicitly** (invariant I6), plus `INTENDED`/`OBSERVED`/`SUSPECT` goldens with companion red tests so the net can't canonize the frozen bug, a **mutation-score** merge gate on auth middleware (assertion *count* is gameable, mutation score isn't), a 90-day window for billing/cron routes, and hard caps on `UNDECIDED`/`FINISH` as forcing functions. Widest token gap (**2.95×**) — worth it for write-once architecture, not for routine design (use 4.8 at 16/16). |
| **High-volume worker** = | drafts · triage · breadth | `claude-sonnet-5` | `default` | **Unchanged.** Cost-efficient, adequate recall for non-gate work. Opus 5 is the wrong tier — its value is enumeration depth, exactly what low-stakes breadth doesn't pay for. |
| **Critical audit** ⬆ | highest-stakes review | **ensemble** `opus-5` **+** `sonnet-5` | `max` | **Opus member upgraded.** Blind spots stay complementary and effort doesn't close them, so keep unioning two models. Sonnet 5 stays — its unique catches aren't a subset of Opus's. Fable remains disqualified (classifiers decline). |
| **Frontier build** *(conditional)* ⬇ | novel · long-horizon · above-**Opus-5**-ceiling only | `claude-fable-5` | `high` | **Narrowed.** Opus 5 absorbs most of what this role existed for — deeper than 4.8 at the same price, and it never declines. The Fable premium ($10/$50) is now justified only where **Opus 5's** ceiling is the demonstrated bottleneck. No lab has produced such a task. Try Opus 5 first, always. |

## Principles

1. **When the successor is the same price tier, the question changes.** Not *"is it worth the premium"* but *"is the extra token volume worth it"*. Opus 5 costs 1.94× at an identical rate — that's adaptive thinking running by default. Worth it where the deliverable **is** enumeration; not where it's a single correct fix.
2. **A saturated answer key can't rank two strong models.** All four tasks were ceiling-tied; every real difference lived past the key. When both arms max the rubric, grade the unkeyed depth explicitly or raise the difficulty — don't report a tie as "no difference."
3. **Availability is a routing property, not a footnote.** Fable declines security content and silently yields Opus 4.8. Opus 5 served every prompt. Route to what actually answers.
4. **The most capable model still isn't the default-right model.** Opus 4.8 keeps producer-code.
5. **Verify the *served* model, not the requested one.** 2 of 4 Fable requests in lab #3 were served by Opus; all 8 here verified clean.
6. **Pay for max effort on *enumeration*, not on *PASS/VETO*.** The gate verdict is robust to both effort *and* model.
7. **Cap Sonnet 5's output** (1.5–1.9× verbosity).
8. **Front-load Sonnet-heavy work before 2026-08-31**, while intro pricing ($2/$10) makes it ~37–40% cheaper.

## Caveats

Single run per task (signal, not a benchmark — the 15-vs-6 and 6-vs-3 margins are one sample each) · all four tasks were **ceiling-tied on the keys**, so the Opus 5 call rests on grader-assessed depth *beyond* the key · extra findings were individually checked against the source for false positives (zero found), but the source is an excerpt — Opus 5 self-flagged two of its own as unverifiable · Opus 5 **diverged from the key's severity calibration in both directions** on Task A, so severity ranking is not a strength this lab can claim for it · effort held **equal** (Claude Code default on both) but **not thinking-matched** — Opus 5 runs adaptive thinking by default and 4.8 does not, which is most of the 1.97× token gap · costs at official published rates · graded vs real-commit keys by the author, not a blind panel.

---
*Regenerate after any new lab: `python3 harness/grade.py …` → update `routing.json`. See [`../harness/README.md`](../harness/README.md).*
