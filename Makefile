# ==============================================================================
# Home Media Server - Development Tasks & Linting
# ==============================================================================
#
# Usage: make <target>
# Examples:
#   make lint          - Run all linters
#   make lint-shell    - Lint shell scripts only
#   make lint-markdown - Lint markdown files only
#   make format        - Auto-format files
#   make validate      - Validate configuration files
#   make help          - Show all available targets
#
# ==============================================================================

.PHONY: help lint lint-shell lint-markdown lint-json validate format clean

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ==============================================================================
# HELP TARGET
# ==============================================================================
help:
	@echo "$(BLUE)📋 Home Media Server - Available Targets$(NC)"
	@echo ""
	@echo "$(GREEN)Linting Targets:$(NC)"
	@echo "  make lint              - Run all linters"
	@echo "  make lint-shell        - Lint shell scripts (ShellCheck)"
	@echo "  make lint-markdown     - Lint markdown files (markdownlint)"
	@echo "  make lint-json         - Validate JSON files (jq)"
	@echo "  make lint-container    - Validate Podman Quadlet files"
	@echo ""
	@echo "$(GREEN)Format & Validate:$(NC)"
	@echo "  make format            - Auto-format files with Prettier"
	@echo "  make validate          - Validate all configuration files"
	@echo "  make validate-env      - Validate environment variables"
	@echo ""
	@echo "$(GREEN)Utility Targets:$(NC)"
	@echo "  make clean             - Remove temporary files"
	@echo "  make install-tools     - Install required linting tools"
	@echo "  make help              - Show this help message"
	@echo ""

# ==============================================================================
# LINTING TARGETS
# ==============================================================================

lint: lint-shell lint-markdown lint-json lint-container
	@echo "$(GREEN)✓ All linters completed!$(NC)"

lint-shell:
	@echo "$(BLUE)🔍 Linting shell scripts...$(NC)"
	@if command -v shellcheck > /dev/null; then \
		shellcheck -x setup.sh && echo "$(GREEN)✓ setup.sh passed$(NC)" || exit 1; \
	else \
		echo "$(YELLOW)⚠ ShellCheck not installed. Run: make install-tools$(NC)"; \
	fi

lint-markdown:
	@echo "$(BLUE)🔍 Linting markdown files...$(NC)"
	@if command -v markdownlint > /dev/null; then \
		markdownlint README.md && echo "$(GREEN)✓ README.md passed$(NC)" || exit 1; \
	else \
		echo "$(YELLOW)⚠ markdownlint not installed. Run: make install-tools$(NC)"; \
	fi

lint-json:
	@echo "$(BLUE)🔍 Validating JSON files...$(NC)"
	@if command -v jq > /dev/null; then \
		for file in $$(find . -name "*.json" -not -path "./node_modules/*" -not -path "./.git/*"); do \
			jq . "$$file" > /dev/null && echo "$(GREEN)✓ $$file passed$(NC)" || exit 1; \
		done \
	else \
		echo "$(YELLOW)⚠ jq not installed. Run: make install-tools$(NC)"; \
	fi

lint-container:
	@echo "$(BLUE)🔍 Validating Podman Quadlet files...$(NC)"
	@for file in configs/*.container; do \
		if [ -f "$$file" ]; then \
			echo "Checking $$file..." && \
			grep -q "^\[Unit\]" "$$file" && \
			grep -q "^\[Container\]" "$$file" && \
			grep -q "^\[Service\]" "$$file" && \
			grep -q "^\[Install\]" "$$file" && \
			echo "$(GREEN)✓ $$file passed$(NC)" || (echo "$(RED)✗ $$file failed$(NC)" && exit 1); \
		fi; \
	done

# ==============================================================================
# VALIDATION TARGETS
# ==============================================================================

validate: validate-env validate-container
	@echo "$(GREEN)✓ All validations completed!$(NC)"

validate-env:
	@echo "$(BLUE)🔍 Validating environment variables...$(NC)"
	@echo "Checking variables.env.example..."
	@bash -n variables.env.example && echo "$(GREEN)✓ variables.env.example syntax valid$(NC)" || exit 1
	@echo "Checking setup.sh..."
	@bash -n setup.sh && echo "$(GREEN)✓ setup.sh syntax valid$(NC)" || exit 1
	@echo "Extracting all \$${VAR} placeholders from configs..."
	@grep -roh '\$${[A-Z_]*}' configs/ | sort -u > /tmp/required_vars.txt
	@echo "Required variables:"
	@cat /tmp/required_vars.txt
	@echo ""

validate-container:
	@echo "$(BLUE)🔍 Validating Podman Quadlet structure...$(NC)"
	@for file in configs/*.container; do \
		if [ -f "$$file" ]; then \
			echo "Validating $$file..." && \
			grep -q "^\[Unit\]" "$$file" || (echo "$(RED)✗ Missing [Unit] section in $$file$(NC)" && exit 1) && \
			grep -q "^\[Container\]" "$$file" || (echo "$(RED)✗ Missing [Container] section in $$file$(NC)" && exit 1) && \
			grep -q "^\[Service\]" "$$file" || (echo "$(RED)✗ Missing [Service] section in $$file$(NC)" && exit 1) && \
			grep -q "^\[Install\]" "$$file" || (echo "$(RED)✗ Missing [Install] section in $$file$(NC)" && exit 1) && \
			echo "$(GREEN)✓ $$file structure valid$(NC)"; \
		fi; \
	done

# ==============================================================================
# FORMAT TARGETS
# ==============================================================================

format:
	@echo "$(BLUE)🎨 Formatting files with Prettier...$(NC)"
	@if command -v prettier > /dev/null; then \
		prettier --write README.md .vscode/extensions.json variables.env.example && \
		echo "$(GREEN)✓ Files formatted$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Prettier not installed. Run: make install-tools$(NC)"; \
	fi

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

install-tools:
	@echo "$(BLUE)📦 Installing linting tools...$(NC)"
	@echo "Installing ShellCheck..."
	@command -v shellcheck > /dev/null || sudo apt-get install -y shellcheck
	@echo "Installing jq..."
	@command -v jq > /dev/null || sudo apt-get install -y jq
	@echo "Installing Node.js and npm (required for markdownlint and prettier)..."
	@command -v npm > /dev/null || sudo apt-get install -y nodejs npm
	@echo "Installing markdownlint..."
	@command -v markdownlint > /dev/null || sudo npm install -g markdownlint-cli
	@echo "Installing Prettier..."
	@command -v prettier > /dev/null || sudo npm install -g prettier
	@echo "$(GREEN)✓ All tools installed$(NC)"

clean:
	@echo "$(BLUE)🧹 Cleaning temporary files...$(NC)"
	@rm -f /tmp/required_vars.txt
	@find . -name "*.log" -delete
	@find . -name "*.tmp" -delete
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

# ==============================================================================
# CI/CD TARGETS (for GitHub Actions, GitLab CI, etc.)
# ==============================================================================

ci-lint: lint validate
	@echo "$(GREEN)✓ CI linting passed!$(NC)"

check: ci-lint
	@echo "$(GREEN)✓ All checks passed!$(NC)"

# ==============================================================================
# END OF MAKEFILE
# ==============================================================================
