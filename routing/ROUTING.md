# Kriya model routing — recommendation

**Version 2026-07-01** · derived from measured runs, not vibes.
Source labs: [`sonnet5-vs-opus48-default`](../sonnet5-vs-opus48-default/) · [`sonnet5-vs-opus48-ultrathink`](../sonnet5-vs-opus48-ultrathink/).
Machine-readable: [`routing.json`](routing.json).

This is the actionable output of the model labs: **which model + effort tier each Kriya agent role should use**, with the evidence behind it. Wire it into Kriya's per-agent front-matter / tech-radar.

## The table

| Kriya role | Stage | Model | Effort | Why (evidence) |
|---|---|---|---|---|
| **Gate verifier** | verify · independent gate | `claude-opus-4-8` | `high` | Most exhaustive enumeration, fewest misses. Gate verdict was identical at default & max effort → don't pay for max on the decision. (Task C: 11→14 findings, correct VETO both.) |
| **Producer — design** | design · LLD · shift-left | `claude-sonnet-5` | `high` *(+ cap output)* | Matched Opus on rubric coverage with richer domain modeling, at lower cost. Verbosity (1.5–1.9×) is the thing to cap. (Task B: 14/14 both; Sonnet added PH-specific edges.) |
| **Producer — code** | build · brownfield | `claude-opus-4-8` | `high` | Tighter, more minimal output; data-minimization instinct; caught more brownfield gotchas in fewer tokens. (Task A: most valid defects, least verbose.) |
| **High-volume worker** | drafts · triage · breadth | `claude-sonnet-5` | `default` | Cost-efficient, adequate recall for non-gate work; escalate to Opus for the gate. (~5% std / 37% intro cheaper.) |
| **Critical audit** | highest-stakes review | **ensemble** `opus-4-8` **+** `sonnet-5` | `max` | Blind spots are complementary and effort doesn't close them — at max, Opus *still* missed the stateful-regex bug Sonnet caught. Union both. |

## Principles

1. **Pay for max effort on *enumeration*, not on *PASS/VETO*.** The binary gate decision was robust to effort; max only lengthened the finding list (~1.7× cost).
2. **Cap Sonnet 5's output.** Its cheaper tokens only pay off once its 1.5–1.9× verbosity is controlled.
3. **Ensemble for the highest stakes.** Blind spots are model-characteristic, not effort-limited — two models' union > either alone.
4. **Front-load Sonnet-heavy work before 2026-08-31**, while intro pricing ($2/$10) makes it ~37–40% cheaper.

## Caveats

Single run per task (signal, not a benchmark) · graded vs published keys by the author, not a blind panel · effort held **equal** across arms, not pinned to a literal max knob · Sonnet 5 was < 2 days old · costs at official published rates.

---
*Regenerate after any new lab: `python3 harness/grade.py …` → update `routing.json`. See [`../harness/README.md`](../harness/README.md).*
