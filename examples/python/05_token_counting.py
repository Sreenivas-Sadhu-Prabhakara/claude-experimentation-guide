"""05 · Re-baseline your token math.

Fable uses a new tokenizer: the same text counts ~30% more tokens than on
Opus-tier models. Budgets, cost estimates, and compaction triggers calibrated
on Opus are now wrong — and you can silently truncate output.

The fix is one call. When you pass `model="claude-fable-5"`, count_tokens
returns counts under BOTH tokenizers so you can see the delta on your own
prompts. Never apply a blanket multiplier.

Run:  python 05_token_counting.py
"""

from _shared import MODEL, client

SAMPLE = (
    "The quick brown fox jumps over the lazy dog. " * 40
    + "\n\ndef add(a, b):\n    return a + b\n"  # code tokenizes differently
)

r = client.messages.count_tokens(
    model=MODEL,
    messages=[{"role": "user", "content": SAMPLE}],
)

new = r.input_tokens
old = getattr(r, "input_tokens_prior_tokenizer", None)

print(f"Fable tokenizer (what you're billed):   {new}")
if old:
    print(f"Prior-generation tokenizer (Opus-tier): {old}")
    print(f"Delta:                                  {(new / old - 1) * 100:+.1f}%")
else:
    print("(Your SDK didn't return input_tokens_prior_tokenizer — upgrade the")
    print(" `anthropic` package to see the side-by-side comparison.)")

# Rough cost preview at Fable's input price ($10 / 1M tokens):
print(f"\nEstimated input cost at $10/1M: ${new / 1_000_000 * 10:.6f}")
