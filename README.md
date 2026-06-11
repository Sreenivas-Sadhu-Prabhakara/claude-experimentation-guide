# 📖 The Fable Field Guide

A hands-on, interactive guide to using **Claude Fable 5** (`claude-fable-5`) well — the model, its quirks, the pitfalls people miss, and copy‑paste patterns you can drop into real work.

Built for someone who wants to *actually use* Fable, not just read marketing about it.

> **What is Fable?** Anthropic's most capable widely‑released model — built for the hardest reasoning and long‑horizon, multi‑step agentic work. 1M‑token context window, up to 128K output tokens, `$10` / `$50` per million input/output tokens. It behaves differently from the Opus family in a handful of important ways, and this guide is about exactly those differences.

---

## What's inside

| Path | What it is |
|------|------------|
| **`index.html`** | The interactive guide. Open it in a browser — no build step, no API key. Has an **ELI5 ↔ technical** toggle, pitfall accordions, a "should I use Fable?" helper, copy‑paste prompt snippets, and a short quiz. |
| **`examples/python/`** | Seven small, runnable Python scripts. Each one demonstrates **one** Fable‑specific behavior correctly (and shows the wrong way next to it). |
| **`examples/typescript/`** | The same lessons in TypeScript. |
| **`docs/PITFALLS.md`** | Every gotcha, written out long‑form with the fix. |
| **`docs/PROMPTING.md`** | Prompting Fable — the behavioral shifts, plus ready‑to‑use system‑prompt snippets. |
| **`docs/CHEATSHEET.md`** | One‑page quick reference. Print it. |

---

## Quick start

### 1. Read the interactive guide (zero setup)

```bash
open index.html        # macOS
# or just double-click index.html
```

Everything in `index.html` works offline. Start with the **ELI5** tab if you want the gentle version, flip to **Technical** when you're ready.

### 2. Run the code (needs an API key)

```bash
# Python
cd examples/python
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # then paste your key into .env
export ANTHROPIC_API_KEY="sk-ant-..."
python 01_hello_fable.py
```

```bash
# TypeScript
cd examples/typescript
npm install
cp .env.example .env          # then paste your key into .env
export ANTHROPIC_API_KEY="sk-ant-..."
npx tsx 01_hello_fable.ts
```

> Get a key at <https://console.anthropic.com>. **Heads up:** your organization must have **30‑day data retention** enabled — Fable 5 is *not* available under zero‑data‑retention and will return a `400` on every request otherwise. (That one trips people up; see the pitfalls.)

---

## The 60‑second version

If you read nothing else, these are the things that bite people moving to Fable from Opus/Sonnet:

1. **Thinking is always on.** Don't send a `thinking` parameter. `thinking:{type:"disabled"}` → `400`. `budget_tokens` → `400`. Control how hard it thinks with `output_config.effort` (`low` → `max`), not a token budget.
2. **You never get the raw chain of thought.** Set `display:"summarized"` for a readable summary; the default returns empty thinking blocks. When you continue a conversation **on Fable**, pass thinking blocks back *unchanged*.
3. **Tokens count ~30% higher** than on Opus‑tier models, with a new tokenizer. Re‑measure with `count_tokens` — don't reuse old `max_tokens` budgets.
4. **Requests can run for minutes.** Stream, set generous timeouts, and design for async check‑ins.
5. **`stop_reason` can be `"refusal"`** on a successful `200`. Check it *before* reading `response.content`, or you'll crash on an empty array.
6. **No assistant prefill.** Use `output_config.format` (structured outputs) or system‑prompt instructions instead.
7. **Prompt it less.** Fable follows instructions literally and over‑prescriptive prompts *hurt* quality. State the goal and constraints; drop the step‑by‑step scaffolding.

Full detail (and the *why*) lives in [`docs/PITFALLS.md`](docs/PITFALLS.md) and the interactive guide.

---

## Deploying the guide (optional)

The guide is a static site — same as a GitHub Pages demo. Push this repo and turn on Pages (serve from the repo root), and `index.html` is your live, shareable Fable explainer.

```bash
# after creating an empty GitHub repo:
git remote add origin git@github.com:<you>/fable-field-guide.git
git push -u origin main
# then: Settings → Pages → Deploy from branch → main / root
```

---

*Built as a learning resource. All model facts reflect Fable 5 as documented by Anthropic; when in doubt, the live source of truth is the [Anthropic docs](https://platform.claude.com/docs).*
