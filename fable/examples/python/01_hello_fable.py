"""01 · Hello, Fable — the smallest correct call.

What to notice:
  • NO `thinking` parameter. Thinking is always on; sending `budget_tokens`
    or `type:"disabled"` returns a 400.
  • `output_config.effort` is how you control how hard it thinks.
  • We check `stop_reason` BEFORE reading `content` (see example 03 for why
    that matters even on a perfectly innocent request).

Run:  python 01_hello_fable.py
"""

from _shared import MODEL, client

resp = client.messages.create(
    model=MODEL,
    max_tokens=1024,
    output_config={"effort": "low"},  # low | medium | high | xhigh | max
    messages=[
        {"role": "user", "content": "In two sentences, what is a fable?"}
    ],
)

# Always branch on stop_reason first — `content` can be empty on a refusal.
if resp.stop_reason == "refusal":
    print("Request was declined by safety classifiers:", resp.stop_details)
else:
    text = next((b.text for b in resp.content if b.type == "text"), "")
    print(text)

# Token usage is worth glancing at on Fable — the tokenizer counts higher
# than Opus-tier (see example 05).
print("\n---")
print("model:       ", resp.model)
print("stop_reason: ", resp.stop_reason)
print("usage:       ", resp.usage.input_tokens, "in /", resp.usage.output_tokens, "out")
