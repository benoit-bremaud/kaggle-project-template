.PHONY: setup notebook lint format clean data submit help

VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
JUPYTER := $(VENV)/bin/jupyter

# Default target
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Run initial project setup (venv, deps, hooks)
	@bash setup.sh

notebook: ## Start Jupyter Lab
	@if [ ! -d "$(VENV)" ]; then echo "Run 'make setup' first"; exit 1; fi
	$(JUPYTER) lab --notebook-dir=notebooks

lint: ## Check code quality with ruff
	@if [ ! -d "$(VENV)" ]; then echo "Run 'make setup' first"; exit 1; fi
	$(VENV)/bin/ruff check src/ notebooks/

format: ## Format code with ruff
	@if [ ! -d "$(VENV)" ]; then echo "Run 'make setup' first"; exit 1; fi
	$(VENV)/bin/ruff format src/
	$(VENV)/bin/ruff check --fix src/ notebooks/

clean: ## Remove temporary files
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

data: ## Download competition data (set COMPETITION=name)
ifndef COMPETITION
	@echo "Usage: make data COMPETITION=titanic"
	@echo "Requires: pip install kaggle + API key configured"
else
	@mkdir -p data/raw
	kaggle competitions download -c $(COMPETITION) -p data/raw/
	@echo "Data downloaded to data/raw/"
endif

submit: ## Submit predictions to Kaggle (set COMPETITION=name FILE=path)
ifndef COMPETITION
	@echo "Usage: make submit COMPETITION=titanic FILE=outputs/submissions/submission.csv"
else
ifndef FILE
	@echo "Usage: make submit COMPETITION=titanic FILE=outputs/submissions/submission.csv"
else
	kaggle competitions submit -c $(COMPETITION) -f $(FILE) -m "Submission from $(shell date +%Y-%m-%d)"
endif
endif
