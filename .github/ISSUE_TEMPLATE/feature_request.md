---
name: Feature Request
about: Suggest a new idea, service, or improvement for the stack
title: '[FEATURE] '
labels: feature-request
assignees: ''
---

## 🎯 Context
<!-- A clear and concise description of what the problem is or what service you want to add. (e.g., "We need to add service X to handle Y") -->


## 🛠️ Proposed Solution / Changes
<!-- Describe the solution or the technical implementation you have in mind. -->
* **Stack/Folder concerned:** (e.g., `01-sso`, `02-core`,...)
* **Services to add/modify:** 
* **Configuration details:** (e.g., ports, network isolation, specific environment variables)

<!-- To be properly refined, add the compose.yml modifications here -->


## 🔒 Security & Architecture Considerations
<!-- Does this service need to be exposed via the reverse proxy? Does it follow the BFF pattern? Are there any sensitive data considerations? -->
- [ ] Needs public exposure (HTTPS via Reverse Proxy)
- [ ] Remains strictly internal / hidden
- [ ] Requires specific volume persistence or backups


## 🧪 Definition of Done (DoD)
<!-- What needs to be functional for this ticket to be considered complete? -->
- [ ] Service is up and running in the target environment.
- [ ] Core features are tested and working.
- [ ] Network rules and security constraints are verified.


## 📝 Additional Context
<!-- For new services, paste here some documentations who could be helpful. -->