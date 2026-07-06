.PHONY: install install-python install-typescript help

# Default target shows help
.DEFAULT_GOAL := help

install: ## Run interactive installer (Linux/macOS/WSL)
	./install.sh

install-python: ## Install Python stack (non-interactive)
	STACK=python WITH_QA=false ./install.sh

install-typescript: ## Install TypeScript stack (non-interactive)
	STACK=typescript WITH_QA=false ./install.sh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
