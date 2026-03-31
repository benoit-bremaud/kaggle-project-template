"""Agent main loop.

This module will contain the core ReAct (Reason + Act) loop once the SAE
question format is understood. For now it provides a minimal scaffold.

Architecture (to be refined after reading SAE specs):
    1. Receive question
    2. Reason: ask the LLM what to do next
    3. Act: execute a tool if needed
    4. Observe: feed the result back to the LLM
    5. Repeat until the LLM produces a final answer
    6. Return answer
"""

from __future__ import annotations

from src.llm.client import LLMClient


class Agent:
    """Main agent that answers SAE questions.

    This is a placeholder — implement after reading the SAE specs.
    """

    def __init__(self, client: LLMClient | None = None) -> None:
        self.client = client or LLMClient()

    def run(self, question: str) -> str:
        """Answer a single SAE question.

        Args:
            question: The question text from the SAE exam.

        Returns:
            The agent's answer as a string.
        """
        # TODO: implement ReAct loop once SAE format is known
        raise NotImplementedError(
            "Agent.run() is not yet implemented. "
            "Read the SAE specs first, then design the loop."
        )
