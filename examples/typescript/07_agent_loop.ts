// 07 · A minimal agentic loop — and the multi-turn gotcha.
//
// The loop is standard, but one Fable-specific rule bites people:
//   ► Append the FULL response.content back, UNCHANGED — including the
//     (possibly empty-text) thinking blocks. Replaying *modified* thinking
//     blocks is rejected on Fable. Don't trim the assistant turn to text only.
//
// Run:  npx tsx 07_agent_loop.ts
import Anthropic from "@anthropic-ai/sdk";
import { MODEL, client } from "./_shared.js";

const TOOLS: Anthropic.Tool[] = [
  {
    name: "get_word_count",
    description: "Count the words in a piece of text.",
    input_schema: {
      type: "object",
      properties: { text: { type: "string" } },
      required: ["text"],
    },
  },
];

function runTool(name: string, args: any): string {
  if (name === "get_word_count") return String(String(args.text).trim().split(/\s+/).length);
  return `Unknown tool: ${name}`;
}

const messages: Anthropic.MessageParam[] = [
  {
    role: "user",
    content:
      "Write a one-sentence fable, then tell me exactly how many words it has " +
      "using the tool.",
  },
];

while (true) {
  const resp = await client.messages.create({
    model: MODEL,
    max_tokens: 2048,
    output_config: { effort: "medium" },
    tools: TOOLS,
    messages,
  });

  if (resp.stop_reason === "refusal") {
    console.log("Declined:", resp.stop_details);
    break;
  }

  for (const block of resp.content) {
    if (block.type === "text") console.log(block.text);
  }

  if (resp.stop_reason === "end_turn") break;

  // ► Append the assistant turn VERBATIM (thinking + tool_use blocks intact).
  messages.push({ role: "assistant", content: resp.content });

  const toolResults: Anthropic.ToolResultBlockParam[] = [];
  for (const block of resp.content) {
    if (block.type === "tool_use") {
      console.log(`   [tool] ${block.name}(${JSON.stringify(block.input)}) `);
      toolResults.push({
        type: "tool_result",
        tool_use_id: block.id, // must match the tool_use block
        content: runTool(block.name, block.input),
      });
    }
  }

  messages.push({ role: "user", content: toolResults });
}
