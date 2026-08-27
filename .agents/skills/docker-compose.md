---
name: docker-compose
description: Docker and Compose guidance for EbMS runtime examples
---

## Docker & Compose for EbMS

You are assisting with Docker and Compose configuration for the EbMS project.

### Scope
Applies to files under `ebms-docker/`.

### Compose Conventions
- Keep image tags, architecture variants, and script usage aligned
- Prefer minimal, explicit environment changes in compose files
- Syntax-check compose files before proposing changes
- Validate with `docker compose config` before applying

### High-Impact Rules
- If changing image build scripts, verify amd64/arm64 flows remain consistent
- If changing demo compose setup, update matching README instructions
- Do not introduce breaking port or volume changes without documenting migration

### Review Checklist
- [ ] Include exact docker or compose commands used for validation
- [ ] Call out runtime assumptions (certs, ports, mounted files, env vars)
- [ ] Avoid hidden behavior in shell scripts; prefer clear arguments and defaults
- [ ] Health checks configured for service dependencies
- [ ] Resource limits set for production-like scenarios