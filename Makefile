# Makefile — common EbMS commands (thin wrappers around Maven).
#
# This repo is a Maven multi-module build with the parent POM at
# ebms-core/pom.xml. The targets below mirror the commands in README.md and
# CONTRIBUTING.md; use them as a single entry point so you don't have to
# remember the exact -f / -pl / -am flags.
#
# Quick help:  make help

MVN := mvn -B

CORE   := ebms-core/pom.xml
ADMIN  := ebms-admin/pom.xml

.PHONY: help build test admin module checkstyle skip-tests

help:
	@echo "EbMS common targets"
	@echo "  make build        Build all ebms-core modules (clean install)"
	@echo "  make test         Build + test all ebms-core modules (verify)"
	@echo "  make admin        Build ebms-core, then build + test ebms-admin"
	@echo "  make module M=X   Build a single core module with deps (M=path, e.g. core)"
	@echo "  make checkstyle   Run checkstyle across the core reactor"
	@echo "  make skip-tests   Quick core build without tests"
	@echo ""
	@echo "Submodules (submodule remotes need token auth):"
	@echo "  scripts/push-submodule.sh <path|name> [branch]   push a submodule branch"

# Build all core modules.
build:
	$(MVN) -f $(CORE) clean install

# Build and run all core tests.
test:
	$(MVN) -f $(CORE) clean verify

# Build admin (installs core first, since admin depends on local core artifacts).
admin:
	$(MVN) -f $(CORE) clean install -DskipTests
	$(MVN) -f $(ADMIN) clean verify

# Build a single core module plus its dependencies. Usage: make module M=core
module:
	@test -n "$(M)" || { echo "usage: make module M=<module-path>  (e.g. M=core)"; exit 1; }
	$(MVN) -f $(CORE) -pl $(M) -am package

# Style check across the core reactor.
checkstyle:
	$(MVN) -f $(CORE) checkstyle:check

# Quick build without running tests.
skip-tests:
	$(MVN) -f $(CORE) -DskipTests=true package
