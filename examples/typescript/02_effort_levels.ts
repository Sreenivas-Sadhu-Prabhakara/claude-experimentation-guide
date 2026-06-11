// 02 · Effort is your main dial.
//
// `output_config.effort` replaces the old `budget_tokens` idea — it controls
// how much Fable thinks AND acts. Default to "high"; "xhigh" for the hardest
// work; "low"/"medium" for routine work. Counter-intuitively, "low" on Fable
// often beats "xhigh"/"max" on older models — always sweep it.
//
// Run:  npx tsx 02_effort_levels.ts
import { MODEL, client } from "./_shared.js";

const PROMPT =
  "A train leaves Bangalore at 60 km/h. Another leaves Chennai (350 km away) " +
  "toward it at 90 km/h, 30 minutes later. How far from Bangalore do they meet? " +
  "Show your reasoning briefly.";

for (const effort of ["low", "medium", "high"] as const) {
  const t0 = Date.now();
  const resp = await client.messages.create({
    model: MODEL,
    max_tokens: 2048,
    output_config: { effort },
    messages: [{ role: "user", content: PROMPT }],
  });
  const dt = ((Date.now() - t0) / 1000).toFixed(1);
  const answer = resp.content.find((b) => b.type === "text");
  console.log(`\n========== effort = ${effort} ==========`);
  console.log(`(took ${dt}s · ${resp.usage.output_tokens} output tokens)`);
  console.log(answer?.type === "text" ? answer.text.trim() : "");
}
