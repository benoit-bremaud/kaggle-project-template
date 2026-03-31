# Architecture

> **Status:** Scaffold — to be completed after reading the SAE specs.

## Overview

This project implements an AI agent that takes the Kaggle
[Standardized Agent Exam (SAE)](https://www.kaggle.com/competitions/sae).

<!-- TODO: describe the exam format here once you have read the specs -->

## Component Diagram

```
┌──────────────────────────────────────────────────────┐
│                      Agent Loop                      │
│                                                      │
│  question ──► Reason (LLM) ──► Act (Tool) ──► ...   │
│                    ▲                │                │
│                    └────── Observe ─┘                │
│                                                      │
│  Final answer ◄── LLM (stop_reason = end_turn)       │
└──────────────────────────────────────────────────────┘
         │                        │
         ▼                        ▼
   src/agent/loop.py       src/agent/tools.py
         │
         ▼
   src/llm/client.py  ──►  Anthropic API
         │
         ▼
   src/llm/cost_tracker.py  ──►  MAX_COST_USD guard
```

## Key Components

### `src/llm/client.py` — `LLMClient`

Thin wrapper around the Anthropic Messages API. Responsibilities:
- Load `ANTHROPIC_API_KEY` from environment
- Call `cost_tracker.check_limit()` before every request
- Record token usage and cost after every request
- Emit a structured JSON log entry for every call

### `src/llm/cost_tracker.py` — `CostTracker`

Tracks cumulative API spend across a session. Responsibilities:
- Compute USD cost per call from token counts and model pricing table
- Enforce `MAX_COST_USD` budget from environment
- Expose `summary()` for logging and monitoring

### `src/agent/loop.py` — `Agent`

Main agent orchestrator. Responsibilities:
- Receive a question
- Implement the Reason → Act → Observe loop
- Invoke tools as needed
- Return a final answer

> **TODO:** Implement once the SAE question format is understood.

### `src/agent/tools.py`

Tool definitions passed to the Anthropic function-calling API.

> **TODO:** Define tools once the SAE specs are read.

### `src/agent/prompts/`

Versioned system prompts as plain Markdown files. See `CHANGELOG.md` for the
history of changes and the reasoning behind each iteration.

## Data Flow

```
SAE question
    │
    ▼
Agent.run(question)
    │
    ├── LLMClient.complete(messages=[...], system=system_prompt)
    │       │
    │       ├── CostTracker.check_limit()
    │       ├── anthropic.messages.create(...)
    │       └── CostTracker.record(...)
    │
    ├── [Tool call if needed]
    │       └── tools.py function → observation
    │
    └── Final answer (string)
```

## Environment Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ANTHROPIC_API_KEY` | Yes | — | Anthropic API key |
| `MAX_COST_USD` | No | `1.00` | Maximum API spend per session |
| `LOG_LEVEL` | No | `INFO` | Python logging level |
| `LOG_FILE` | No | `` | Log file path (empty = stdout) |

## Decisions

See [DECISIONS.md](DECISIONS.md) for architectural decision records.
