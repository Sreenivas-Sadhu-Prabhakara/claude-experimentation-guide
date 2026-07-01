// 01 · Hello, Fable — the smallest correct call.
//
// What to notice:
//   • NO `thinking` parameter. Thinking is always on; `budget_tokens` or
//     type:"disabled" return a 400.
//   • `output_config.effort` controls how hard it thinks.
//   • Check `stop_reason` BEFORE reading `content` (see 03 for why).
//
// Run:  npx tsx 01_hello_fable.ts
import { MODEL, client } from "./_shared.js";

const resp = await client.messages.create({
  model: MODEL,
  max_tokens: 1024,
  output_config: { effort: "low" }, // low | medium | high | xhigh | max
  messages: [{ role: "user", content: "In two sentences, what is a fable?" }],
});

if (resp.stop_reason === "refusal") {
  console.log("Request was declined by safety classifiers:", resp.stop_details);
} else {
  const text = resp.content.find((b) => b.type === "text");
  console.log(text?.type === "text" ? text.text : "");
}

console.log("\n---");
console.log("model:      ", resp.model);
console.log("stop_reason:", resp.stop_reason);
console.log("usage:      ", resp.usage.input_tokens, "in /", resp.usage.output_tokens, "out");
