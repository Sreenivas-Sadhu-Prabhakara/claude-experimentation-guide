# Fable 5 Cheat Sheet

One page. Print it. `claude-fable-5`.

## At a glance
| | |
|---|---|
| Model ID | `claude-fable-5` (no date suffix) |
| Context window | 1M tokens (max **and** default) |
| Max output | 128K tokens |
| Pricing | $10 / $50 per 1M input / output |
| Min cacheable prefix | 2048 tokens |
| Requires | 30‑day data retention (ZDR → 400 on everything) |

## The call
```python
client.messages.create(
    model="claude-fable-5",
    max_tokens=16000,
    output_config={"effort": "high"},   # low|medium|high|xhigh|max
    messages=[...],
)
# NO thinking param. NO temperature/top_p/top_k. NO assistant prefill.
```

## Removed → returns 400
- `thinking={"type":"enabled","budget_tokens":N}`
- `thinking={"type":"disabled"}`  ← accepted on Opus 4.7/4.8, **not** Fable
- `temperature`, `top_p`, `top_k`
- assistant‑turn prefill (last message is `assistant`)

## Do this instead
| You want… | Do |
|---|---|
| Control thinking depth | `output_config={"effort": "..."}` |
| See the reasoning | `thinking={"type":"adaptive","display":"summarized"}` (summary only — raw CoT never returned) |
| Strict JSON output | `output_config={"format":{"type":"json_schema","schema":{...}}}` or `messages.parse()` |
| Big / long output | **Stream** (`messages.stream()`), up to 128K |
| Accurate token counts | `count_tokens(model="claude-fable-5", ...)` → `.input_tokens` + `.input_tokens_prior_tokenizer` |

## Must‑handle in code
```python
# 1. Refusal arrives as HTTP 200 — check BEFORE reading content
if resp.stop_reason == "refusal":
    cat = getattr(resp.stop_details, "category", None)  # branch on stop_reason, not stop_details
    ...

# 2. Multi-turn: append response.content VERBATIM (thinking blocks intact)
messages.append({"role": "assistant", "content": resp.content})
```

## Auto‑retry a refusal
```python
client.beta.messages.create(
    model="claude-fable-5",
    betas=["server-side-fallback-2026-06-01"],
    fallbacks=[{"model": "claude-opus-4-8"}],
    max_tokens=1024, messages=[...],
)
```

## Numbers that changed vs Opus
- Tokens: **~30% more** for the same text (new tokenizer) → re‑baseline budgets & cost.
- Latency: single turns can run **minutes** at higher effort → stream + async UX.

## Effort guide
`low` routine · `medium` everyday · **`high` default** · `xhigh` hardest/agentic · `max` extreme only.
`low` on Fable often beats `xhigh`/`max` of older models — sweep it.

## Prompting
- Goal + constraints, **not** step‑by‑step. Over‑prescription lowers quality.
- Full task spec up front in one turn for long‑horizon work.
- Give the *why*, not just the *what*.
- Add a communication‑style section (it over‑elaborates un‑steered).
- Snippets to paste: see [`PROMPTING.md`](PROMPTING.md).

## When to use Fable
✅ Hard, long‑horizon, quality‑first, agentic.
❌ High‑volume / latency‑ / cost‑sensitive / simple → use Opus, Sonnet, or Haiku.
❌ ZDR org → can't, until retention is fixed.
"Just the latest model" with no specific need → default is `claude-opus-4-8`, not Fable.
