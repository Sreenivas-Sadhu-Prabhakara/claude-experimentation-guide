// 05 · Re-baseline your token math.
//
// Fable's new tokenizer counts ~30% more tokens than Opus-tier for the same
// text. Old budgets and cost estimates are now wrong. Passing
// model="claude-fable-5" to countTokens returns counts under BOTH tokenizers.
//
// Run:  npx tsx 05_token_counting.ts
import { MODEL, client } from "./_shared.js";

const SAMPLE =
  "The quick brown fox jumps over the lazy dog. ".repeat(40) +
  "\n\nfunction add(a, b) {\n  return a + b;\n}\n";

const r = await client.messages.countTokens({
  model: MODEL,
  messages: [{ role: "user", content: SAMPLE }],
});

const fresh = r.input_tokens;
// Newer SDK field; cast through unknown in case your version predates it.
const prior = (r as unknown as { input_tokens_prior_tokenizer?: number })
  .input_tokens_prior_tokenizer;

console.log(`Fable tokenizer (what you're billed):   ${fresh}`);
if (prior) {
  console.log(`Prior-generation tokenizer (Opus-tier): ${prior}`);
  console.log(`Delta:                                  ${(((fresh / prior) - 1) * 100).toFixed(1)}%`);
} else {
  console.log("(Upgrade @anthropic-ai/sdk to see input_tokens_prior_tokenizer.)");
}

console.log(`\nEstimated input cost at $10/1M: $${((fresh / 1_000_000) * 10).toFixed(6)}`);
