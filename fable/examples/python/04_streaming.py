"""04 · Stream, because turns can take minutes.

Fable can run for many minutes on a hard task and emit up to 128K output
tokens. A blocking, non-streaming request at a large `max_tokens` will hit
HTTP timeouts and drop — the SDK will even refuse it up front.

What to notice:
  • `client.messages.stream(...)` as a context manager.
  • `stream.text_stream` yields text as it arrives (good UX during long runs).
  • `stream.get_final_message()` gives you the assembled Message afterwards,
    so you can still read `usage` and `stop_reason`.
  • `display:"summarized"` surfaces a readable reasoning summary instead of
    the default empty thinking blocks (which look like a long frozen pause).

Run:  python 04_streaming.py
"""

from _shared import MODEL, client

with client.messages.stream(
    model=MODEL,
    max_tokens=8000,
    output_config={"effort": "medium"},
    # Optional: show a reasoning summary while it works. You never get the
    # raw chain of thought — only this summary.
    thinking={"type": "adaptive", "display": "summarized"},
    messages=[
        {
            "role": "user",
            "content": "Write a short modern fable (~200 words) about an AI that "
            "learns patience. Give it a clear moral at the end.",
        }
    ],
) as stream:
    for event in stream:
        if event.type == "content_block_start" and event.content_block.type == "thinking":
            print("\n[thinking…]\n")
        elif event.type == "content_block_delta":
            if event.delta.type == "thinking_delta":
                print(event.delta.thinking, end="", flush=True)
            elif event.delta.type == "text_delta":
                print(event.delta.text, end="", flush=True)

    final = stream.get_final_message()

print("\n\n---")
print("stop_reason:", final.stop_reason)
print("output tokens:", final.usage.output_tokens)
