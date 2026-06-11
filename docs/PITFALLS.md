# Pitfalls & Gotchas — the long version

Every trap below comes from a real behavioral difference between Fable 5 and the Opus/Sonnet models. They're ordered roughly by how often they bite. Each has the symptom, the cause, and the fix.

---

## 1. Sending a `thinking` parameter (or `budget_tokens`)

**Symptom:** `400 invalid_request_error` on a request that worked on Opus.

**Cause:** On Fable, thinking is *always on*. There is no off switch and no token budget.
- `thinking={"type":"enabled","budget_tokens":N}` → 400
- `thinking={"type":"disabled"}` → 400 (this one is accepted on Opus 4.7/4.8, which is why it's easy to miss)
- `temperature`, `top_p`, `top_k` → also removed, also 400

**Fix:** Omit `thinking` entirely. Control depth with `output_config.effort`:

```python
client.messages.create(
    model="claude-fable-5",
    max_tokens=16000,
    output_config={"effort": "high"},   # low | medium | high | xhigh | max
    messages=msgs,
)
```

If you specifically want a readable reasoning summary, the *only* allowed thinking config is `thinking={"type":"adaptive","display":"summarized"}`.

---

## 2. Crashing on an empty `content` because of a refusal

**Symptom:** Intermittent `IndexError` / `undefined` from `response.content[0]`, on a successful `200`.

**Cause:** Fable runs safety classifiers (mainly bio + most cyber; benign adjacent work like security tooling or life‑sciences can occasionally false‑positive). When one declines, you get `HTTP 200` with `stop_reason == "refusal"`:
- **pre‑output** — `content` is an empty array, and you were **not billed** (no input or output tokens)
- **mid‑stream** — partial output was streamed and **was billed**; discard it, don't treat it as complete

**Fix:** Branch on `stop_reason` before reading `content`. Branch on `stop_reason`, **never** on `stop_details` — that object can be `null` even on a refusal.

```python
resp = client.messages.create(model="claude-fable-5", max_tokens=1024, messages=msgs)
if resp.stop_reason == "refusal":
    category = getattr(resp.stop_details, "category", None)  # "cyber"|"bio"|"reasoning_extraction"|None
    handle_refusal(category)
else:
    print(resp.content[0].text)
```

**Recovery:** to auto‑retry a refusal on another model in one round trip, use the server‑side `fallbacks` parameter (beta header `server-side-fallback-2026-06-01`):

```python
resp = client.beta.messages.create(
    model="claude-fable-5",
    max_tokens=1024,
    betas=["server-side-fallback-2026-06-01"],
    fallbacks=[{"model": "claude-opus-4-8"}],
    messages=msgs,
)
```

A `fallback` content block in the response marks where one model handed off to the next. There are also SDK client‑side middleware and a "fallback credit" path for raw HTTP — see Anthropic's migration docs.

---

## 3. Reusing Opus token budgets and cost math

**Symptom:** Output truncates mid‑thought; costs are higher than expected; compaction triggers fire at the wrong time.

**Cause:** Fable uses a **new tokenizer**. The same content tokenizes to **~30% more tokens** than on Opus‑tier models (varies by content — code and non‑English shift more). Billing is per token.

**Fix:** Re‑baseline with `count_tokens`. Passing `model="claude-fable-5"` returns counts under both tokenizers so you can measure the delta on your actual prompts. Never apply a blanket multiplier.

```python
r = client.messages.count_tokens(model="claude-fable-5", messages=msgs)
r.input_tokens                  # new tokenizer — billed
r.input_tokens_prior_tokenizer  # same request, old tokenizer
```

Give `max_tokens` and any compaction triggers extra headroom.

---

## 4. Non‑streaming requests at large `max_tokens`

**Symptom:** Requests hang and then drop; the SDK refuses the call up front with a `ValueError` about timeouts.

**Cause:** Fable can run for **minutes** on a hard task and emit up to **128K** output tokens. Idle connections drop long before that on a blocking request.

**Fix:** Stream anything large or long. Use the SDK's final‑message helper if you don't need per‑token handling.

```python
with client.messages.stream(model="claude-fable-5", max_tokens=64000,
                            output_config={"effort": "high"}, messages=msgs) as stream:
    for text in stream.text_stream:
        ...
    final = stream.get_final_message()
```

Beyond streaming, **design for long turns**: generous timeouts, a progress indicator, and (for agentic work) async check‑ins rather than one blocking synchronous request.

---

## 5. Editing or stripping thinking blocks in multi‑turn / tool loops

**Symptom:** `400` when continuing a conversation, especially in an agentic loop.

**Cause:** "Protected thinking." When you continue **on Fable**, the API rejects *modified* thinking blocks. A common mistake is trimming the assistant turn down to just its text before appending it back.

**Fix:** Append the full `response.content` back, **unchanged** — including empty‑text thinking blocks.

```python
messages.append({"role": "assistant", "content": resp.content})   # verbatim
messages.append({"role": "user", "content": tool_results})
```

Note the asymmetry: continuing on a **different** model is fine — it silently *drops* Fable's protected blocks from the prompt (and doesn't bill for them). No stripping needed on your side either way.

---

## 6. Expecting to read the model's reasoning

**Symptom:** Streaming UI shows a long frozen pause, then output appears all at once. Or: thinking blocks arrive with empty text.

**Cause:** The raw chain of thought is **never** returned on Fable ("protected thinking"). The default `display` is `"omitted"`, which streams thinking blocks with empty text.

**Fix:** Ask for the summary explicitly:

```python
thinking={"type": "adaptive", "display": "summarized"}
```

Do **not** try to *prompt* the model to reveal its reasoning — that can be refused with `stop_details.category == "reasoning_extraction"`. If you need reasoning visibility, read the summarized `thinking` blocks.

---

## 7. Forcing output shape with an assistant prefill

**Symptom:** `400` when the last message in `messages` is an `assistant` turn.

**Cause:** Assistant prefill (seeding the start of the answer) is not supported on Fable.

**Fix:** Use structured outputs (`output_config.format` with a JSON schema), or a system‑prompt instruction. The SDK's `messages.parse()` with a Pydantic/Zod model is the cleanest path. (The one exception: redeeming a fallback credit, where the server accepts the echoed assistant message — niche, see Anthropic's refusal docs.)

---

## 8. Leaving over‑prescriptive prompts in place

**Symptom:** Lower‑quality output than you got on Opus; over‑planning; unrequested refactors; verbose narration; heavy PR descriptions.

**Cause:** Fable follows instructions **literally** and is tuned to need *less* scaffolding. Prompts written to push older models ("CRITICAL: YOU MUST…", numbered step lists, "double‑check X before returning") now over‑trigger and reduce quality.

**Fix:** State the goal and constraints up front; remove the step‑by‑step scaffolding. A/B your workload with the old instructions deleted. See [`PROMPTING.md`](PROMPTING.md) for drop‑in system‑prompt snippets (anti‑overplanning, no‑tidying, grounded progress, boundaries, etc.).

---

## 9. Every request 400s and the payload looks correct

**Symptom:** A clean, valid request body still returns `400 invalid_request_error` — on everything.

**Cause:** Two org/account‑level conditions, not payload problems:
1. **Data retention.** Fable requires **30‑day** retention. Under zero‑data‑retention (or anything shorter), every request 400s.
2. **Leftover removed params.** A stray `temperature` / `top_p` / `top_k` / `budget_tokens` anywhere in the request.

**Fix:** Check the org's data‑retention setting first, then scrub the removed parameters.

---

## 10. (Migrating) Forgetting Fable isn't the default "latest model"

**Symptom:** Surprise cost increase after a blanket "upgrade to the newest model."

**Cause:** Fable is the *most capable* widely released model, but it costs more than Opus‑tier and re‑baselines your token math. For a generic "use the latest," the intended upgrade target is `claude-opus-4-8`.

**Fix:** Choose Fable deliberately — for genuinely hard, long‑horizon, quality‑first work. Use the [decision helper](../index.html#decide) in the guide if you're unsure.
