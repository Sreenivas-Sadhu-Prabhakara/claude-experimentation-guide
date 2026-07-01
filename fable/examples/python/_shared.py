"""Shared bootstrap for the Fable examples.

Every example imports `client` and the model constants from here so the
interesting, Fable-specific code stays front-and-centre in each file.
"""

import os

from anthropic import Anthropic

# Optional: load a local .env so you don't have to export the key each time.
try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

# The model this whole repo is about. Use the exact string — no date suffix.
MODEL = "claude-fable-5"

# Where to send work if Fable's safety classifiers decline a request.
FALLBACK_MODEL = "claude-opus-4-8"

if not os.getenv("ANTHROPIC_API_KEY"):
    raise SystemExit(
        "ANTHROPIC_API_KEY is not set.\n"
        "  export ANTHROPIC_API_KEY='sk-ant-...'   (or put it in a .env file)\n"
        "Note: your org must have 30-day data retention enabled — Fable 5 is\n"
        "not available under zero-data-retention and will 400 on every request."
    )

# Reads ANTHROPIC_API_KEY from the environment automatically.
client = Anthropic()
