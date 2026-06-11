// 03 · Refusals come back as a SUCCESS — handle them.
//
// Fable runs safety classifiers (mainly bio + most cyber). A decline is still
// HTTP 200, but with stop_reason === "refusal":
//   • pre-output → content is empty, NOT billed
//   • mid-stream → partial output WAS billed, discard it
//
// Code that does resp.content[0] will crash on the empty array. Branch on
// stop_reason first. This also shows the server-side `fallbacks` recovery.
//
// Run:  npx tsx 03_handle_refusal.ts
import { FALLBACK_MODEL, MODEL, client } from "./_shared.js";

async function askSafely(prompt: string): Promise<string> {
  const resp = await client.messages.create({
    model: MODEL,
    max_tokens: 1024,
    output_config: { effort: "low" },
    messages: [{ role: "user", content: prompt }],
  });

  // ── the load-bearing line ───────────────────────────────────────────────
  if (resp.stop_reason === "refusal") {
    // Branch on stop_reason, NEVER on stop_details (can be null on a refusal).
    return `[declined · category=${resp.stop_details?.category ?? "n/a"}]`;
  }
  const text = resp.content.find((b) => b.type === "text");
  return text?.type === "text" ? text.text : "";
}

async function askWithFallback(prompt: string): Promise<string> {
  const resp = await client.beta.messages.create({
    model: MODEL,
    max_tokens: 1024,
    betas: ["server-side-fallback-2026-06-01"],
    fallbacks: [{ model: FALLBACK_MODEL }],
    messages: [{ role: "user", content: prompt }],
  });

  // A `fallback` content block marks each hand-off between models.
  for (const block of resp.content) {
    if (block.type === "fallback") {
      console.log(`   ↳ ${block.from.model} declined; ${block.to.model} continued`);
    }
  }

  if (resp.stop_reason === "refusal") return "[every model in the chain declined]";
  const text = resp.content.find((b) => b.type === "text");
  return text?.type === "text" ? text.text : "";
}

const q = "Summarise the plot of Aesop's 'The Tortoise and the Hare'.";
console.log("Plain (refusal-safe) call:\n  ", await askSafely(q));
console.log("\nWith server-side fallback:\n  ", await askWithFallback(q));
