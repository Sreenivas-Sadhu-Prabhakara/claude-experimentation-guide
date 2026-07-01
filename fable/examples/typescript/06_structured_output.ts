// 06 · Structured output — the replacement for assistant prefill.
//
// Assistant prefill (seeding the answer with a leading assistant turn) returns
// a 400 on Fable. Use structured outputs instead — guaranteed schema-valid.
// `client.messages.parse()` with a Zod schema validates and returns typed data.
//
// Run:  npx tsx 06_structured_output.ts
import { z } from "zod";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { MODEL, client } from "./_shared.js";

const FableBreakdown = z.object({
  title: z.string(),
  moral: z.string(),
  characters: z.array(
    z.object({
      name: z.string(),
      species: z.string(),
      trait: z.string(),
    }),
  ),
});

const resp = await client.messages.parse({
  model: MODEL,
  max_tokens: 2048,
  output_config: { format: zodOutputFormat(FableBreakdown) },
  messages: [
    {
      role: "user",
      content:
        "Break down Aesop's 'The Tortoise and the Hare' into a structured summary.",
    },
  ],
});

if (resp.stop_reason === "refusal") {
  console.log("Declined:", resp.stop_details);
} else {
  const data = resp.parsed_output; // typed + validated, or null
  if (data) {
    console.log("Title: ", data.title);
    console.log("Moral: ", data.moral);
    console.log("Characters:");
    for (const c of data.characters) console.log(`  - ${c.name} (${c.species}): ${c.trait}`);
  }
}
