"""API cost tracker with configurable spending guard.

Tracks cumulative token usage and USD cost across all LLM calls in a session.
Raises CostLimitExceededError if the configured MAX_COST_USD threshold is hit.
"""

from __future__ import annotations

import os


class CostLimitExceededError(RuntimeError):
    """Raised when cumulative API cost exceeds MAX_COST_USD."""


# Anthropic pricing per million tokens (update as pricing changes)
# Source: https://www.anthropic.com/pricing
COST_PER_MILLION_TOKENS: dict[str, dict[str, float]] = {
    "claude-opus-4-6": {"input": 15.00, "output": 75.00},
    "claude-sonnet-4-6": {"input": 3.00, "output": 15.00},
    "claude-haiku-4-5-20251001": {"input": 0.80, "output": 4.00},
}
DEFAULT_COST = {"input": 3.00, "output": 15.00}  # fallback


class CostTracker:
    """Tracks cumulative LLM API cost and enforces a spending limit.

    Usage:
        tracker = CostTracker()
        tracker.check_limit()  # call before each API request
        tracker.record(model="claude-sonnet-4-6", input_tokens=100, output_tokens=50)
    """

    def __init__(self, max_cost_usd: float | None = None) -> None:
        limit = max_cost_usd or float(os.getenv("MAX_COST_USD", "1.00"))
        self.max_cost_usd: float = limit
        self.total_cost_usd: float = 0.0
        self.total_input_tokens: int = 0
        self.total_output_tokens: int = 0
        self.call_count: int = 0

    def check_limit(self) -> None:
        """Raise CostLimitExceededError if the spending limit has been reached."""
        if self.total_cost_usd >= self.max_cost_usd:
            raise CostLimitExceededError(
                f"API cost limit reached: ${self.total_cost_usd:.4f} >= "
                f"${self.max_cost_usd:.2f} (MAX_COST_USD). "
                "Increase MAX_COST_USD in .env to continue."
            )

    def record(self, model: str, input_tokens: int, output_tokens: int) -> float:
        """Record token usage for one API call and return its cost in USD."""
        pricing = COST_PER_MILLION_TOKENS.get(model, DEFAULT_COST)
        call_cost = (
            input_tokens * pricing["input"] / 1_000_000
            + output_tokens * pricing["output"] / 1_000_000
        )
        self.total_cost_usd += call_cost
        self.total_input_tokens += input_tokens
        self.total_output_tokens += output_tokens
        self.call_count += 1
        return call_cost

    def summary(self) -> dict[str, float | int]:
        """Return a summary of cumulative usage."""
        return {
            "call_count": self.call_count,
            "total_input_tokens": self.total_input_tokens,
            "total_output_tokens": self.total_output_tokens,
            "total_cost_usd": round(self.total_cost_usd, 6),
            "max_cost_usd": self.max_cost_usd,
            "budget_remaining_usd": round(self.max_cost_usd - self.total_cost_usd, 6),
        }
