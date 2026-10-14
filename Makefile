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

.PHONY: help build test server module checkstyle skip-tests release-check

help:
	@echo "EbMS common targets"
	@echo "  make build        Build all ebms-core modules (clean install)"
	@echo "  make test         Build + test all ebms-core modules (verify)"
	@echo "  make server       Build + test the ebms-server module with its deps"
	@echo "  make module M=X   Build a single core module with deps (M=path, e.g. core)"
	@echo "  make checkstyle   Run checkstyle across the core reactor"
	@echo "  make skip-tests   Quick core build without tests"
	@echo "  make release-check  Self-test the release version rules (scripts/release-version.sh)"
	@echo ""
	@echo "Submodules (submodule remotes need token auth):"
	@echo "  scripts/push-submodule.sh <path|name> [branch]   push a submodule branch"

# Build all core modules.
build:
	$(MVN) -f $(CORE) clean install

# Build and run all core tests.
test:
	$(MVN) -f $(CORE) clean verify

# Build and test the embedded server module (ebms-server shaded jar) plus the
# modules it depends on (common, core, plugins).
server:
	$(MVN) -f $(CORE) -pl server -am clean verify

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

# Self-test the release version rules used by release.yml and docker-deploy.yml.
release-check:
	scripts/release-version.sh --self-test
