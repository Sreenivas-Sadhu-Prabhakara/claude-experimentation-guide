"""03 · Refusals come back as a SUCCESS — handle them.

Fable runs safety classifiers (mainly bio + most cyber). When one declines a
request you still get HTTP 200, but with `stop_reason == "refusal"`:
  • pre-output  → `content` is empty, and you were NOT billed
  • mid-stream  → partial output was billed — discard it

Code that does `response.content[0].text` will crash on the empty array. The
fix is to branch on `stop_reason` first.

This example also shows the cleanest recovery path: the server-side
`fallbacks` parameter, which retries on another model in a single round trip.

Run:  python 03_handle_refusal.py
"""

from _shared import FALLBACK_MODEL, MODEL, client


def ask_safely(prompt: str) -> str:
    """A request that won't explode on a refusal."""
    resp = client.messages.create(
        model=MODEL,
        max_tokens=1024,
        output_config={"effort": "low"},
        messages=[{"role": "user", "content": prompt}],
    )

    # ── the load-bearing line ───────────────────────────────────────────
    if resp.stop_reason == "refusal":
        # Branch on stop_reason, NEVER on stop_details — it can be None even
        # on a refusal. .category is "cyber" | "bio" | "reasoning_extraction" | None
        cat = getattr(resp.stop_details, "category", None)
        return f"[declined by classifiers · category={cat}]"

    return next((b.text for b in resp.content if b.type == "text"), "")


def ask_with_fallback(prompt: str) -> str:
    """Auto-retry a refusal on Opus, server-side, in one round trip."""
    resp = client.beta.messages.create(
        model=MODEL,
        max_tokens=1024,
        betas=["server-side-fallback-2026-06-01"],
        fallbacks=[{"model": FALLBACK_MODEL}],
        messages=[{"role": "user", "content": prompt}],
    )

    # A `fallback` content block marks each point where one model handed off
    # to the next. Its presence tells you a switch happened.
    for block in resp.content:
        if block.type == "fallback":
            print(f"   ↳ {block.from_.model} declined; {block.to.model} continued")

    if resp.stop_reason == "refusal":
        return "[every model in the chain declined]"
    return next((b.text for b in resp.content if b.type == "text"), "")


if __name__ == "__main__":
    print("Plain (refusal-safe) call:")
    print("  ", ask_safely("Summarise the plot of Aesop's 'The Tortoise and the Hare'."))

    print("\nWith server-side fallback:")
    print("  ", ask_with_fallback("Summarise the plot of Aesop's 'The Tortoise and the Hare'."))
