"""Anthropic API client wrapper with integrated cost tracking and structured logging.

Provides a thin layer over the Anthropic SDK that:
- Loads the API key from environment variables
- Checks the cost limit before every call
- Records token usage after every call
- Emits structured JSON log entries for observability
"""

from __future__ import annotations

import json
import logging
import os
import time
from typing import Any

import anthropic

from src.llm.cost_tracker import CostTracker

logger = logging.getLogger(__name__)


class LLMClient:
    """Wrapper around the Anthropic Messages API.

    Usage:
        client = LLMClient()
        response = client.complete(
            model="claude-sonnet-4-6",
            system="You are a helpful assistant.",
            messages=[{"role": "user", "content": "Hello"}],
        )
        print(response.content[0].text)
    """

    def __init__(self, cost_tracker: CostTracker | None = None) -> None:
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            raise EnvironmentError(
                "ANTHROPIC_API_KEY is not set. "
                "Copy .env.example to .env and fill in your API key."
            )
        self._client = anthropic.Anthropic(api_key=api_key)
        self.cost_tracker = cost_tracker or CostTracker()

    def complete(
        self,
        messages: list[dict[str, Any]],
        model: str = "claude-sonnet-4-6",
        system: str = "",
        max_tokens: int = 4096,
        **kwargs: Any,
    ) -> anthropic.types.Message:
        """Send a message to the API and return the full response.

        Args:
            messages: Conversation history in Anthropic format.
            model: Claude model ID to use.
            system: System prompt (optional).
            max_tokens: Maximum tokens in the response.
            **kwargs: Additional parameters passed to the Anthropic API.

        Returns:
            The Anthropic Message response object.

        Raises:
            CostLimitExceededError: If the cost limit has been reached.
        """
        self.cost_tracker.check_limit()

        start = time.monotonic()
        response = self._client.messages.create(
            model=model,
            system=system,
            messages=messages,
            max_tokens=max_tokens,
            **kwargs,
        )
        latency_ms = round((time.monotonic() - start) * 1000, 1)

        call_cost = self.cost_tracker.record(
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
        )

        self._log(
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            cost_usd=call_cost,
            latency_ms=latency_ms,
            stop_reason=response.stop_reason,
        )

        return response

    def _log(self, **fields: Any) -> None:
        """Emit a structured JSON log entry for this API call."""
        entry = {"event": "llm_call", **fields, **self.cost_tracker.summary()}
        logger.info(json.dumps(entry))
