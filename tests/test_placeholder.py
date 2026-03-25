"""Placeholder test to ensure pytest runs successfully on a fresh project.

Replace this file with real tests when you create src/ functions.
See ADR-017: tests are written for reusable code in src/ only.
"""


def test_project_setup():
    """Verify the project is set up correctly."""
    from pathlib import Path

    project_root = Path(__file__).parent.parent
    assert (project_root / "src" / "__init__.py").exists()
    assert (project_root / "notebooks" / "notebook.ipynb").exists()
    assert (project_root / "Makefile").exists()
