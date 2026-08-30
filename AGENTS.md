Project Overview

EbMS (nl.clockwork.ebms) is a Java 17 Maven multi-module implementation of the ebXML Messaging Specification (EbMS 2.0). The repository is a multi-module Maven build (ebms-core with plugins for multiple databases and caches) plus webapp and Docker examples.

Current version: 2.20.9-SNAPSHOT (revision property in ebms-core/pom.xml)

Repository structure (high level)

- ebms-core/                — Maven parent for EbMS core modules (common, core, plugins)
- ebms-admin/               — SOAP/REST server and webapp
- ebms-docker/              — docker-compose examples and images
- ebms-perftest-setup/      — performance test setup and scripts
- ebms-core/core/resources/ — core resources, including test resources and documentation assets
- documentation/            — docs site and versioned docs

Available plugins (ebms-core/plugin/)

- Cache: ehcache, hazelcast
- Database: db2, h2, hsqldb, mariadb, mssql, oracle, postgres

Documentation

- Project documentation is located under documentation/ and versioned with the code
- REST OpenAPI specification is located at ebms-core/core/resources/api/rest/*.json
- SOAP API WSDL specification is located at ebms-core/core/resources/api/soap/*.wsdl
- Manual test resources are located at ebms-core/core/resources/test/*
- EbMS 2.0 specification reference is located at documentation/static/assets/ebMS_v2_0.pdf

Tech stack

- Java 17 (property: jdk.version = 17 in ebms-core/pom.xml)
- Lombok
- Spring Framework
- Build: Maven multi-module (flattened-pom for version management via ${revision})
- Tests: JUnit (src/test/java present)
- Containers: Docker / docker-compose examples
- Static Analysis: SonarQube (sonar-project.properties) with SonarLint (sonarlint-project.properties)

Build & Run

- Install: mvn -B install
- Run tests: mvn -B test or mvn -B verify
- Build a single module: mvn -pl module-path -am package
- Parallel build: mvn -B -T 1C (used in CI)

Testing

- Unit tests located under */src/test/java — run with mvn test
- Integration tests located under */src/test/java — run with mvn verify

CI/CD

- Default branch: dev
- GitHub Actions: ci.yml (PR/push build & test)
- Release: release.yml (workflow_dispatch, input: version). Parent-driven
  release of ebms-core + ebms-admin from the tip of dev-2.20.x: bump, build
  + test, run the two-adapter smoke test (smoke-test.sh: built jar vs the
  published docker image; failure aborts the release before any tag/push),
  commit + tag + push both submodules, create GitHub releases with the built
  JARs as assets, bump both to <next patch>-SNAPSHOT, pin the submodules in
  the parent, wait for CI. Requires secret
  SUBMODULE_GITHUB_TOKEN (minimal: Contents read+write on both submodule
  repos; the job token declares only contents:write + actions:read). See
  CONTRIBUTING.md ("Releasing a version") for prerequisites and recovery.
- Dependabot: weekly updates for maven, npm (documentation), and github-actions
- Static analysis: SonarQube integration configured

AI Readiness

- AGENTS.md: This file (persistent memory for AI agents)
- .github/copilot-instructions.md: Copilot-specific instructions
- .mcp.json: MCP configuration for Java/Maven development
- SonarQube + SonarLint: Code quality and static analysis

Key patterns & conventions

- Multi-module Maven parent at ebms-core/pom.xml. Changes to the core module commonly require updating plugins under plugin/* and modules that depend on core.
- Database plugins live in ebms-core/plugin/db/* — changing persistence schema will require updating migrations (if used) and tests in core/resources/test.
- Version management uses ${revision} property (currently 2.20.9-SNAPSHOT)

Adding a new module

1. Add module directory and a pom.xml
2. Add module name to ebms-core/pom.xml <modules>
3. Update any distributionManagement or dependencyManagement if releasing
4. Add CI job or ensure the CI build covers -pl <module> if long-running

Common pitfalls

- JDK mismatch: project sets jdk.version=17 in ebms-core/pom.xml
- Multi-database plugins: tests may use H2/HSQDB locally; ensure CI uses a deterministic DB or matrix
- Sonar configuration: sonar-project.properties and sonarlint-project.properties must reference only existing plugin paths (no messaging plugins)
- Flyway migrations keep a static copyright header on purpose: `src/main/resources/db/migration/**` is excluded from license-maven-plugin (added in ebms-core pom.xml, 2026). Flyway checksums are content-based — editing an applied migration's header (or any byte) breaks existing databases on startup with FlywayValidateException. Never run header/format tools over db/migration.
- Version consistency: update ${revision} in ebms-core/pom.xml and ensure sonarlint-project.properties matches
- Submodule `ignore = all`: `.gitmodules` sets `ignore = all` on every submodule, which makes `git status` hide gitlink drift AND makes plain `git add <path>` silently skip pointer updates. Use `git add -f <submodule>` to stage a new commit, and commit the parent pointer so CI checks out the intended SHA.
- Submodule version alignment: CI builds only the committed submodule SHAs. After a release, each submodule's dev branch must carry its post-release `-SNAPSHOT` version bump as a real commit (not just a local working-tree edit), and the parent repo must pin that commit — otherwise CI resolves the release version against Maven Central and fails.
- Submodule remotes need auth: submodule push URLs are plain HTTPS, so `git push` inside a submodule prompts for credentials. Push with the token, e.g. `git push https://x-access-token:${TOKEN}@github.com/eluinstra/<repo>.git <branch>`.
- Submodule pins must point at commits that exist on the remote: CI checks out the pinned SHAs with a shallow fetch, so pinning a local/unpushed commit breaks every CI run with `upload-pack: not our ref <sha>`. Push the submodule commit first, then pin it in the parent (happened with the `documentation` submodule in 2026-08: a license commit made on stale local history was pinned but never pushed).
- Running the embedded server (`nl.clockwork.ebms.server.embedded.startup.StartEmbedded`) locally: (1) `Start.getProperty`/`getBooleanProperty` (SystemInterface) read ONLY `-D` system properties — the classpath `default.properties` is seen only by Spring `@Value` beans — so connector flags must be passed as vmArgs, e.g. `-Dapi.ssl.enabled=true -Dapi.ssl.keyStorePassword=... -Dapi.health.enabled=true`. (2) The `-ssl`/`-soap`/`-health` CLI args are no-ops in this module. (3) `database.start=true` is required to start the in-process H2 TCP server on 9092 (otherwise Hikari fails with "Connection refused: localhost:9092"); it is read via `@Value`, so a vmArg or an `ebms-server.properties` in the working dir both work.
- Spring: declare `BeanPostProcessor` factory methods `static` and inject `Environment` instead of relying on `@Value` fields of the enclosing `@Configuration` class. A non-static `@Bean` returning a `BeanPostProcessor` forces early instantiation of the config class, before `@Value` injection, leaving fields as raw `${...}` placeholders (hit in `MessageEventListenerConfig.messageEventListenerFilterProcessor`, fixed 2026-08).
