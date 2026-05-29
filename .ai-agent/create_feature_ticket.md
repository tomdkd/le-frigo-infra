# Task: Create Feature Request Ticket via GitHub MCP

## 🤖 AI Agent Role & Objective
You are a DevOps Automation Agent. Your task is to write a highly detailed, technical GitHub Issue for a new feature request and publish it to the repository using the GitHub MCP tool `github.create_issue`.

---

## 📥 Inputs & Context
Before acting, you must read and analyze:
1. **`.ai-agent/infrastructure.md`**: To understand the global architecture, storage paths (`${APPS_DATA_DIR}`, etc.), stack folders, and security/BFF constraints.
2. **`.github/issue_template/feature_request.md`**: To get the exact Markdown layout and Front Matter configuration.
3. **User Prompt**: The user's rough request specifying the service to add or modify.

---

## ⚙️ Execution Pipeline & Rules

### Step 1: Identify the Target Stack
Analyze `infrastructure.md` to determine which logical stack directory this new service belongs to.
* If it's a media/acquisition app, target `04-downloads`[cite: 1] or `03-multimedia`[cite: 1].
* If it's a security/auth app, target `01-sso`[cite: 1] or `02-core`[cite: 1].
* If it's a monitoring app, target `06-monitoring`[cite: 1].

### Step 2: Enforce Security & BFF Policies
Refer to the "Security & Exposure Policies" in `infrastructure.md`[cite: 1].
* Determine if the service must be **Exposed** (needs Traefik labels) or **Hidden** (internal docker network only)[cite: 1].
* Check if it acts as a backend for a frontend UI (BFF pattern)[cite: 1].
* **Rule:** Databases, workers, and pure backend engines must NEVER have Traefik labels[cite: 1].

### Step 3: Map Storage & Environment Variables
* Use the exact storage conventions from `infrastructure.md` (e.g., `${APPS_DATA_DIR}/<service_name>`)[cite: 1].
* Do not invent new root paths. Use existing environment variables[cite: 1].

### Step 4: Manage Environment Variables & Secrets
* If the new service requires new secrets or specific configurations, add them as environment variables in the `docker-compose.yml` snippet.
* List these new keys clearly under the `Environment Variables` section of the ticket so they can be appended to the target `stack.env.example` file later.
* **CRITICAL RULE:** Cross-reference with existing variables in `infrastructure.md`. **DO NOT duplicate** already existing global or shared environment variables (e.g., global DB tokens, PUID/PGID, base domain names)[cite: 1]. Reuse them.

### Step 5: Database Initialization Check
* Analyze if the service requires a dedicated PostgreSQL database.
* **Rule:** If a database is needed, explicitly state it in the ticket description and include a task to initialize the new database schema/user within the central `postgres-common` container (or dedicated stack DB if specified in `infrastructure.md`)[cite: 1].

### Step 6: Draft the Ticket Content
Fill out the `.github/issue_template/feature_request.md` template text.
* Keep all HTML comments `<!-- -->` intact in the final issue body.
* Write a clean, complete `docker-compose.yml` snippet inside the ticket. Include proper image tags, network attachments, and placeholders for `.env` keys[cite: 1].
* List the exact `mkdir` shell commands needed for host dataset creation if new persistent paths are required[cite: 1].

### Step 7: Publish via MCP
Call the GitHub MCP server tool `github.create_issue` with:
* **title**: `[FEATURE] Add <Service Name>` (as defined in the template Front Matter).
* **labels**: `['feature_request']` (as defined in the template Front Matter).
* **body**: The full Markdown text you just drafted.

---

## 🚨 Critical Constraints for the AI
* **DO NOT** execute any bash commands to create folders right now.
* **DO NOT** modify any `docker-compose.yml` or `.env` files in the workspace yet.
* **Your ONLY output action** is to call the `github.create_issue` tool. Once the issue is created, report the issue number to the user and stop.