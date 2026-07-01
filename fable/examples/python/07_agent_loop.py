"""07 · A minimal agentic loop — and the multi-turn gotcha.

Fable is built for tool-using, multi-step work. The loop itself is standard,
but there's one Fable-specific rule that bites people:

  ► Append the FULL `response.content` back to the conversation, UNCHANGED —
    including the (possibly empty-text) thinking blocks. On Fable, replaying
    *modified* thinking blocks is rejected. Don't trim the assistant turn down
    to just text.

What to notice:
  • We append `resp.content` verbatim, then add tool_result blocks.
  • Each tool_result carries the matching `tool_use_id`.
  • We loop until `stop_reason == "end_turn"`, and still guard for "refusal".

Run:  python 07_agent_loop.py
"""

from _shared import MODEL, client

TOOLS = [
    {
        "name": "get_word_count",
        "description": "Count the words in a piece of text.",
        "input_schema": {
            "type": "object",
            "properties": {"text": {"type": "string"}},
            "required": ["text"],
        },
    }
]


def run_tool(name: str, args: dict) -> str:
    if name == "get_word_count":
        return str(len(args["text"].split()))
    return f"Unknown tool: {name}"


messages = [
    {
        "role": "user",
        "content": "Write a one-sentence fable, then tell me exactly how many "
        "words it has using the tool.",
    }
]

while True:
    resp = client.messages.create(
        model=MODEL,
        max_tokens=2048,
        output_config={"effort": "medium"},
        tools=TOOLS,
        messages=messages,
    )

    if resp.stop_reason == "refusal":
        print("Declined:", resp.stop_details)
        break

    # Show any text the model produced this turn.
    for block in resp.content:
        if block.type == "text":
            print(block.text)

    if resp.stop_reason == "end_turn":
        break

    # ► Append the assistant turn VERBATIM (thinking + tool_use blocks intact).
    messages.append({"role": "assistant", "content": resp.content})

    # Execute every tool the model asked for, collect results.
    tool_results = []
    for block in resp.content:
        if block.type == "tool_use":
            print(f"   [tool] {block.name}({block.input}) ", end="")
            result = run_tool(block.name, block.input)
            print(f"-> {result}")
            tool_results.append(
                {
                    "type": "tool_result",
                    "tool_use_id": block.id,  # must match the tool_use block
                    "content": result,
                }
            )

    messages.append({"role": "user", "content": tool_results})
