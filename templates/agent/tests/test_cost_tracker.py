"""Tests for the cost tracker."""

from __future__ import annotations

import pytest

from src.llm.cost_tracker import CostLimitExceededError, CostTracker


def test_initial_state():
    tracker = CostTracker(max_cost_usd=1.0)
    assert tracker.total_cost_usd == 0.0
    assert tracker.call_count == 0
    assert tracker.summary()["budget_remaining_usd"] == pytest.approx(1.0)


def test_record_increments_cost():
    tracker = CostTracker(max_cost_usd=10.0)
    cost = tracker.record(model="claude-sonnet-4-6", input_tokens=1000, output_tokens=500)
    assert cost > 0
    assert tracker.total_cost_usd == pytest.approx(cost)
    assert tracker.call_count == 1


def test_check_limit_raises_when_exceeded():
    tracker = CostTracker(max_cost_usd=0.0)
    with pytest.raises(CostLimitExceededError):
        tracker.check_limit()


def test_check_limit_does_not_raise_below_limit():
    tracker = CostTracker(max_cost_usd=100.0)
    tracker.check_limit()  # should not raise


def test_summary_keys():
    tracker = CostTracker(max_cost_usd=5.0)
    summary = tracker.summary()
    expected_keys = {
        "call_count",
        "total_input_tokens",
        "total_output_tokens",
        "total_cost_usd",
        "max_cost_usd",
        "budget_remaining_usd",
    }
    assert set(summary.keys()) == expected_keys


def test_unknown_model_uses_default_pricing():
    tracker = CostTracker(max_cost_usd=10.0)
    cost = tracker.record(model="unknown-model-xyz", input_tokens=1_000_000, output_tokens=0)
    assert cost == pytest.approx(3.00)  # DEFAULT_COST input rate
