# Set the default goal
.DEFAULT_GOAL := help

.PHONY: help lint up down lefrigo multimedia downloads tools monitoring

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

lint: ## Format and lint YAML files using yamlfix via Docker
	docker run --rm -v ${CURDIR}:/workspace -w /workspace python:alpine sh -c "pip install yamlfix --quiet && yamlfix ."

# --- Stack Commands ---
up: ## Start Dockhand + a specific stack (e.g., make up STACK=04-tools)
	@if [ -z "$(STACK)" ]; then echo "❌ Error: Please specify a stack (e.g., make up STACK=04-tools)"; exit 1; fi
	cp ./$(STACK)/stack.env.example ./$(STACK)/.env
	@echo "🚀 Starting base Dockhand configuration..."
	docker compose -f compose.yml up -d
	@echo "⏳ Base ready. Now starting $(STACK) stack..."
	docker compose -f compose.yml -f ./$(STACK)/compose.yml --env-file ./$(STACK)/.env up -d

down: ## Stop a specific stack and Dockhand (e.g., make down STACK=04-tools)
	@if [ -z "$(STACK)" ]; then echo "❌ Error: Please specify a stack (e.g., make down STACK=04-tools)"; exit 1; fi
	docker compose -f compose.yml -f ./$(STACK)/compose.yml --env-file ./$(STACK)/.env down

# --- Convenience Shortcuts ---
core: ## Start Dockhand + 01-core stack
	@$(MAKE) up STACK=01-core

multimedia: ## Start Dockhand + 02-multimedia stack
	@$(MAKE) up STACK=02-multimedia

downloads: ## Start Dockhand + 03-downloads stack
	@$(MAKE) up STACK=03-downloads

tools: ## Start Dockhand + 04-tools stack
	@$(MAKE) up STACK=04-tools

monitoring: ## Start Dockhand + 05-monitoring stack
	@$(MAKE) up STACK=05-monitoring