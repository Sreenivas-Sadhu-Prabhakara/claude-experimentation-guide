# Prompting Fable

Fable is highly steerable — but *under*‑prompted usually beats *over*‑prompted. The single biggest mistake when moving from older models is leaving aggressive, step‑by‑step prompts in place. Fable follows them literally and the scaffolding actively lowers quality.

This doc has two parts: the **mindset shifts**, then **ready‑to‑paste system‑prompt snippets**.

---

## Mindset shifts

### 1. `output_config.effort` is your primary control
Not the prompt. Effort governs how much Fable thinks *and* acts.

| Effort | Use for |
|--------|---------|
| `low` | Routine, latency‑sensitive work. (Often beats `xhigh`/`max` of older models — really.) |
| `medium` | Everyday tasks. |
| `high` | **Default.** Most work. |
| `xhigh` | The most capability‑sensitive / agentic work. |
| `max` | Extremely hard, latency‑insensitive cases only. |

Sweep it on *your* task. Higher effort on agentic work often *reduces* total turns and cost because the planning is better up front.

### 2. Give the full task spec in one well‑specified turn
For long‑horizon work, front‑load the goal, constraints, and context. Ambiguous, progressively‑revealed prompts (drip‑feeding requirements over many turns) reduce both efficiency and quality.

### 3. Give the *why*, not just the *what*
Fable connects a task to the right context when it understands intent. A template that works well:

> I'm working on **[the larger task]** for **[who it's for]**. They need **[what the output enables]**. With that in mind: **[the specific request]**.

### 4. Invest in a communication‑style section
Un‑steered, Fable can over‑elaborate: heavy PR descriptions, sections on alternatives it didn't pick, comments narrating what the next line does, dense arrow‑chain shorthand in long sessions. A short style instruction fixes all of it — and Fable responds to it strongly.

### 5. Drop the scaffolding
Delete "CRITICAL: YOU MUST…", numbered step lists, and "double‑check X before returning." State the goal and the constraints. A/B with the old scaffolding removed before assuming you need it.

---

## Ready‑to‑paste snippets

Drop these into your **system prompt** (combine the ones you need). They're written for Fable's literal instruction‑following.

### Don't over‑plan (for ambiguous tasks)
```
When you have enough information to act, act. Do not re-derive facts already
established, re-litigate a decision the user has made, or narrate options you
won't pursue. If you're weighing a choice, give a recommendation, not an
exhaustive survey. (This does not apply to thinking blocks.)
```

### Don't tidy / over‑engineer (at higher effort)
```
Don't add features, refactor, or introduce abstractions beyond what the task
requires. A bug fix doesn't need surrounding cleanup. Don't design for
hypothetical future requirements — do the simplest thing that works. Don't add
error handling or validation for scenarios that cannot happen; only validate at
system boundaries (user input, external APIs).
```

### Ground progress claims (long agentic runs)
```
Before reporting progress, audit each claim against a tool result from this
session. Only report work you can point to evidence for; if something isn't
verified, say so. Report outcomes faithfully: if tests fail, say so with the
output; if a step was skipped, say that; when something is done and verified,
state it plainly without hedging.
```

### Respect boundaries (avoid unrequested actions)
```
When the user is describing a problem, asking a question, or thinking out loud
rather than requesting a change, the deliverable is your assessment. Report your
findings and stop. Don't apply a fix until they ask. Before running a
state-changing command (restarts, deletes, config edits), check the evidence
actually supports that specific action.
```

### Delegate to sub‑agents (parallelizable work)
```
Delegate independent subtasks to sub-agents and keep working while they run.
Prefer sub-agents that communicate asynchronously over spawn-and-block.
Intervene if a sub-agent goes off track or is missing relevant context.
```

### Use a memory file (recurring work)
```
Store one lesson per file with a one-line summary at the top. Record corrections
and confirmed approaches alike, including why they mattered. Don't save what the
repo or chat history already records; update an existing note rather than
duplicating; delete notes that turn out to be wrong.
```

### Stay autonomous (unattended / async pipelines)
```
You are operating autonomously. The user is not watching and cannot answer
mid-task, so asking "Want me to…?" will block the work. For reversible actions
that follow from the request, proceed without asking. Before ending your turn,
check your last paragraph: if it's a plan, a question, or a promise about work
you haven't done, do that work now with tool calls. End your turn only when the
task is complete or you're blocked on input only the user can provide.
```

### Write readable summaries (long sessions)
```
When you write the final summary, drop the working shorthand. Open with the
outcome: one sentence on what happened or what you found. Then the supporting
detail. Use complete sentences; spell terms out; no arrow chains or made-up
labels the reader hasn't seen. If you must choose between short and clear,
choose clear.
```

### Lead with the outcome (knowledge work / reports)
```
Lead with the outcome. Your first sentence should answer "what happened" or
"what did you find" — the TLDR. Supporting detail and reasoning come after.
Keep it short by being selective about what you include, not by compressing into
fragments, abbreviations, or jargon.
```

---

## A note on `send_to_user`

For async agents that must deliver something the user sees **exactly as written** mid‑run (a number, a deliverable, a direct answer), give the agent a client‑side `send_to_user` tool whose input you render directly — tool inputs are never summarized, so the content arrives intact.

```json
{
  "name": "send_to_user",
  "description": "Display a message directly to the user. Use for progress updates, partial results, or content the user must see exactly as written before the task finishes.",
  "input_schema": {
    "type": "object",
    "properties": { "message": { "type": "string" } },
    "required": ["message"]
  }
}
```

Return a simple acknowledgement as the tool result. For agents that only narrate routine progress, the default summaries are usually fine without this tool.
