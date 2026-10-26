# ==============================================================================
# AEGIS Makefile
# Provides standard developer commands across Linux, macOS, WSL, and CI environments.
# On Windows PowerShell, you can also use: .\run.ps1 <target>
# ==============================================================================

.DEFAULT_GOAL := help
PYTHON ?= python
VENV_PYTHON = .venv/bin/python
VENV_RUFF = .venv/bin/ruff
VENV_PYTEST = .venv/bin/pytest

# Detect Windows virtual environment path if present
ifeq ($(OS),Windows_NT)
    VENV_PYTHON = .venv/Scripts/python.exe
    VENV_RUFF = .venv/Scripts/ruff.exe
    VENV_PYTEST = .venv/Scripts/pytest.exe
endif

.PHONY: help
help: ## Show this help message
	@echo "AEGIS Development Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Run code linter and formatting checks (Ruff)
	@if [ -f "$(VENV_RUFF)" ]; then \
		$(VENV_RUFF) check . ; \
	else \
		ruff check . ; \
	fi

.PHONY: format
format: ## Format Python source files
	@if [ -f "$(VENV_RUFF)" ]; then \
		$(VENV_RUFF) format . ; \
	else \
		ruff format . ; \
	fi

.PHONY: test
test: ## Run unit tests (pytest)
	@if [ -f "$(VENV_PYTEST)" ]; then \
		$(VENV_PYTEST) -v tests/ ; \
	else \
		pytest -v tests/ ; \
	fi

.PHONY: up
up: ## Start the development cluster & stack (Phase 1+)
	@echo "[AEGIS] 'up' is planned for Phase 1 (kind cluster + monitoring stack)."
	@echo "Current status: Phase 0 (Repository Foundation)."

.PHONY: down
down: ## Tear down the development cluster & stack (Phase 1+)
	@echo "[AEGIS] 'down' is planned for Phase 1 (kind cluster teardown)."
	@echo "Current status: Phase 0 (Repository Foundation)."

.PHONY: clean
clean: ## Remove temporary files, caches, and build artifacts
	@rm -rf .pytest_cache .ruff_cache build dist *.egg-info htmlcov .coverage
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "Caches cleaned."
