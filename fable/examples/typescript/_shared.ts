// Shared bootstrap. Every example imports `client` + the model constants
// from here so the Fable-specific code stays front-and-centre.
import "dotenv/config";
import Anthropic from "@anthropic-ai/sdk";

// Use the exact model string — no date suffix.
export const MODEL = "claude-fable-5";

// Where to send work if Fable's safety classifiers decline a request.
export const FALLBACK_MODEL = "claude-opus-4-8";

if (!process.env.ANTHROPIC_API_KEY) {
  console.error(
    "ANTHROPIC_API_KEY is not set.\n" +
      "  export ANTHROPIC_API_KEY='sk-ant-...'   (or put it in a .env file)\n" +
      "Note: your org must have 30-day data retention enabled — Fable 5 is\n" +
      "not available under zero-data-retention and will 400 on every request.",
  );
  process.exit(1);
}

// Reads ANTHROPIC_API_KEY from the environment automatically.
export const client = new Anthropic();
