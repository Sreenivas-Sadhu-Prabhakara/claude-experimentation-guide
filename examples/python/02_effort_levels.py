"""02 · Effort is your main dial.

`output_config.effort` replaces the old `budget_tokens` idea. It controls how
much Fable thinks AND acts.

What to notice:
  • The same prompt at different effort levels — watch output tokens (and
    wall-clock) climb as effort rises.
  • Counter-intuitive but true: `low` on Fable often beats `xhigh`/`max` on
    older models. Always sweep effort on your own task before assuming you
    need the ceiling.
  • Default to `high`. Use `xhigh` for the hardest work, `low`/`medium` for
    routine or latency-sensitive work.

Run:  python 02_effort_levels.py
"""

import time

from _shared import MODEL, client

PROMPT = (
    "A train leaves Bangalore at 60 km/h. Another leaves Chennai (350 km away) "
    "toward it at 90 km/h, 30 minutes later. How far from Bangalore do they meet? "
    "Show your reasoning briefly."
)

for effort in ("low", "medium", "high"):
    t0 = time.time()
    resp = client.messages.create(
        model=MODEL,
        max_tokens=2048,
        output_config={"effort": effort},
        messages=[{"role": "user", "content": PROMPT}],
    )
    dt = time.time() - t0
    answer = next((b.text for b in resp.content if b.type == "text"), "")
    print(f"\n========== effort = {effort} ==========")
    print(f"(took {dt:.1f}s · {resp.usage.output_tokens} output tokens)")
    print(answer.strip())
