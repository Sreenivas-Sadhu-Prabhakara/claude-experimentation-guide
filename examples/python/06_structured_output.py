"""06 · Structured output — the replacement for assistant prefill.

The classic trick to force JSON was to prefill the assistant turn with an
opening brace. That returns a 400 on Fable (no assistant prefill).

Use structured outputs instead — the response is guaranteed to match your
schema. The cleanest path is `client.messages.parse()` with a Pydantic model,
which validates and returns a typed object.

Run:  python 06_structured_output.py
"""

from typing import List

from pydantic import BaseModel

from _shared import MODEL, client


class Character(BaseModel):
    name: str
    species: str
    trait: str


class FableBreakdown(BaseModel):
    title: str
    moral: str
    characters: List[Character]


resp = client.messages.parse(
    model=MODEL,
    max_tokens=2048,
    output_format=FableBreakdown,
    messages=[
        {
            "role": "user",
            "content": "Break down Aesop's 'The Tortoise and the Hare' into a "
            "structured summary.",
        }
    ],
)

# Refusals still apply — parsed_output may be None if the model declined.
if resp.stop_reason == "refusal":
    print("Declined:", resp.stop_details)
else:
    data = resp.parsed_output  # a validated FableBreakdown instance
    print("Title: ", data.title)
    print("Moral: ", data.moral)
    print("Characters:")
    for c in data.characters:
        print(f"  - {c.name} ({c.species}): {c.trait}")


# ── Raw-schema alternative (no Pydantic) ────────────────────────────────────
# resp = client.messages.create(
#     model=MODEL,
#     max_tokens=2048,
#     output_config={"format": {"type": "json_schema", "schema": {
#         "type": "object",
#         "properties": {"title": {"type": "string"}, "moral": {"type": "string"}},
#         "required": ["title", "moral"],
#         "additionalProperties": False,
#     }}},
#     messages=[{"role": "user", "content": "..."}],
# )
# import json; data = json.loads(next(b.text for b in resp.content if b.type == "text"))
