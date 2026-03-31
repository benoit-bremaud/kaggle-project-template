"""Agent tools (function calling).

Define tools that the agent can invoke during its reasoning loop.
Each tool is a plain Python function with a docstring and type annotations.
The tool definitions (name, description, input schema) are derived from these
functions and passed to the Anthropic API.

Tools to add (TBD after reading SAE specs):
    - code_execution: run Python code and return stdout/stderr
    - web_search: search the web and return results
    - calculator: evaluate a mathematical expression

Example tool structure:
    def tool_name(param: str) -> str:
        "Short description shown to the model."
        ...
"""

from __future__ import annotations

# TODO: define tools after reading SAE specs
TOOLS: list[dict] = []
