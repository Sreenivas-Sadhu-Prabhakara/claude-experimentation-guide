// 04 · Stream, because turns can take minutes.
//
// Fable can run for many minutes and emit up to 128K output tokens. A blocking
// request at a large max_tokens will hit HTTP timeouts. Stream instead.
//   • client.messages.stream(...) → for-await over events
//   • stream.finalMessage() → the assembled Message (usage, stop_reason)
//   • display:"summarized" surfaces a reasoning summary (default is empty
//     thinking blocks, which look like a long frozen pause).
//
// Run:  npx tsx 04_streaming.ts
import { MODEL, client } from "./_shared.js";

const stream = client.messages.stream({
  model: MODEL,
  max_tokens: 8000,
  output_config: { effort: "medium" },
  thinking: { type: "adaptive", display: "summarized" },
  messages: [
    {
      role: "user",
      content:
        "Write a short modern fable (~200 words) about an AI that learns " +
        "patience. Give it a clear moral at the end.",
    },
  ],
});

for await (const event of stream) {
  if (event.type === "content_block_start" && event.content_block.type === "thinking") {
    process.stdout.write("\n[thinking…]\n");
  } else if (event.type === "content_block_delta") {
    if (event.delta.type === "thinking_delta") process.stdout.write(event.delta.thinking);
    else if (event.delta.type === "text_delta") process.stdout.write(event.delta.text);
  }
}

const final = await stream.finalMessage();
console.log("\n\n---");
console.log("stop_reason:", final.stop_reason);
console.log("output tokens:", final.usage.output_tokens);
