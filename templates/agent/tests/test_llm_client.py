"""Tests for the LLM client (all API calls are mocked)."""

from __future__ import annotations

import os
from unittest.mock import MagicMock, patch

import pytest

from src.llm.client import LLMClient
from src.llm.cost_tracker import CostLimitExceededError, CostTracker


@pytest.fixture()
def mock_env(monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")
    monkeypatch.setenv("MAX_COST_USD", "10.00")


def _make_mock_response(input_tokens: int = 100, output_tokens: int = 50) -> MagicMock:
    response = MagicMock()
    response.usage.input_tokens = input_tokens
    response.usage.output_tokens = output_tokens
    response.stop_reason = "end_turn"
    response.content = [MagicMock(text="Test response")]
    return response


def test_client_raises_without_api_key(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    with pytest.raises(EnvironmentError, match="ANTHROPIC_API_KEY"):
        LLMClient()


def test_complete_records_cost(mock_env):
    tracker = CostTracker(max_cost_usd=10.0)
    client = LLMClient(cost_tracker=tracker)

    with patch.object(client._client.messages, "create", return_value=_make_mock_response()):
        client.complete(messages=[{"role": "user", "content": "Hello"}])

    assert tracker.call_count == 1
    assert tracker.total_cost_usd > 0


def test_complete_raises_when_cost_limit_reached(mock_env):
    tracker = CostTracker(max_cost_usd=0.0)
    client = LLMClient(cost_tracker=tracker)

    with pytest.raises(CostLimitExceededError):
        client.complete(messages=[{"role": "user", "content": "Hello"}])
