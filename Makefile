# Set the default goal
.DEFAULT_GOAL := help

.PHONY: help lint up down lefrigo multimedia downloads tools monitoring

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

lint: ## Format and lint YAML files using yamlfix via Docker
	docker run --rm -v ${CURDIR}:/workspace -w /workspace python:alpine sh -c "pip install yamlfix --quiet && yamlfix ."

# --- Stack Commands ---
down: ## Stop a specific stack and Dockhand (e.g., make down STACK=05-tools)
	@if [ -z "$(STACK)" ]; then echo "❌ Error: Please specify a stack (e.g., make down STACK=05-tools)"; exit 1; fi
	docker compose -f compose.yml -f ./$(STACK)/compose.yml --env-file ./$(STACK)/.env down

up: ## Start Dockhand + a specific stack (e.g., make up STACK=05-tools)
	@if [ -z "$(STACK)" ]; then echo "❌ Error: Please specify a stack (e.g., make up STACK=05-tools)"; exit 1; fi
	cp ./$(STACK)/stack.env.example ./$(STACK)/.env
	@echo "🚀 Starting base Dockhand configuration..."
	docker compose -f compose.yml up -d
	@echo "⏳ Base ready. Now starting $(STACK) stack..."
	docker compose -f compose.yml -f ./$(STACK)/compose.yml --env-file ./$(STACK)/.env up -d

# --- Convenience Shortcuts ---
sso: ## Start Dockhand + SSO stack
	@$(MAKE) up STACK=01-sso

core: ## Start Dockhand + Core stack
	@$(MAKE) up STACK=02-core

multimedia: ## Start Dockhand + Multimedia stack
	@$(MAKE) up STACK=03-multimedia

downloads: ## Start Dockhand + Downloads stack
	@$(MAKE) up STACK=04-downloads

tools: ## Start Dockhand + Tools stack
	@$(MAKE) up STACK=05-tools

monitoring: ## Start Dockhand + Monitoring stack
	@$(MAKE) up STACK=06-monitoring