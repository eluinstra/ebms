Project Overview

EbMS (nl.clockwork.ebms) is a Java 21 Maven multi-module implementation of the ebXML Messaging Specification (EbMS 2.0). The repository is a multi-module Maven build (ebms-core with plugins for multiple databases and caches) plus webapp and Docker examples.

Current version: 2.21.0-SNAPSHOT (revision property in ebms-core/pom.xml)

Repository structure (high level)

- ebms-core/                — Maven parent for EbMS core modules (common, core, server, plugins)
- ebms-admin/               — retained legacy admin console (submodule kept, but no longer built/tested/released by the pipelines)
- ebms-docker/              — docker-compose examples and images
- ebms-perftest-setup/      — performance test setup and scripts
- scripts/                  — repo tooling (push-submodule.sh for authenticated submodule pushes)
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

- Java 21 (property: jdk.version = 21 in ebms-core/pom.xml)
- Lombok
- Spring Framework
- Build: Maven multi-module (flattened-pom for version management via ${revision})
- Tests: JUnit (src/test/java present)
- Containers: Docker / docker-compose examples
- Static Analysis: SonarQube (sonar-project.properties) with SonarLint (sonarlint-project.properties)

Build & Run

- Single entry point: `make help` — the Makefile wraps the common mvn commands so
  you don't have to remember the -f/-pl/-am flags:
    - make build     — core clean install (all core modules)
    - make test      — core clean verify (all core tests)
    - make server    — build + test the ebms-server module (embedded SOAP/REST server) with deps
    - make module M=<module-path>   — build one core module with deps (e.g. M=core)
    - make checkstyle / make skip-tests
- The raw mvn equivalents (what the Makefile calls):
  - Install: mvn -B -f ebms-core/pom.xml clean install
  - Run tests: mvn -B -f ebms-core/pom.xml clean verify
  - Build a single module: mvn -B -f ebms-core/pom.xml -pl <module-path> -am package
  - Parallel build: mvn -B -T 1C (used in CI)

Testing

- **Always test before committing.** Never commit (submodule or parent) until the affected module(s) build and their tests pass green. Run at least `mvn -B -pl <module> -am test` (or `verify`) for every module touched and only commit when it succeeds.
- Unit tests located under */src/test/java — run with mvn test
- Integration tests located under */src/test/java — run with mvn verify

CI/CD

- Default branch: dev
- GitHub Actions: ci.yml (PR/push build & test)
- Release: release.yml (workflow_dispatch, inputs: version + optional branch).
  Parent-driven
  release of ebms-core (including the ebms-server module) from the tip of the
  release branch dev-<major>.<minor>.x (derived from the version, e.g.
  2.21.0-M1 -> dev-2.21.x): bump, build
  + test, run the two-adapter smoke test (ebms-core/smoke-test.sh: adapter 1 = the built
  ebms-core server jar (local `nl.clockwork.ebms.server.embedded.startup.StartEmbedded`,
  property-driven) vs adapter 2 = the published docker
  image; failure aborts the release before any tag/push),
  commit + tag + push the submodule, create a GitHub release with the built
  JARs as assets (core jar, ebms-server fat jar, all plugins), bump to
  the next development iteration SNAPSHOT, pin the submodules in
  the parent, wait for CI. Requires secret
  SUBMODULE_GITHUB_TOKEN (minimal: Contents read+write on the ebms-core
  repo; the same PAT also needs Contents read+write on ebms-admin because it is
  released as a companion and because docs-deploy.yml pushes the GitHub Pages
  site there; the job token declares
  only contents:write + actions:read). See
  CONTRIBUTING.md ("Releasing a version") for prerequisites and recovery.
- The GitHub release in ebms-core is the PRIMARY one (created first, gate of
  the pipeline); after it a companion GitHub release is created in the legacy
  eluinstra/ebms-admin repo (admin jar + the same plugin jars, body links to
  the primary). The companion never blocks the primary: if the ebms-admin
  release branch does not exist or its build fails, the companion is skipped
  with a warning (an `admin` step output gates all admin steps) and the
  ebms-core release completes.
- The standalone release workflow inside ebms-core
  (ebms-core/.github/workflows/release.yml — self-contained, no parent
  submodule pins) creates the same pair: primary ebms-core release, then the
  companion ebms-admin release via ebms-core/scripts/release-admin-companion.sh
  (tolerant: skipped with a warning when the optional secret EBMS_ADMIN_TOKEN
  is unset in eluinstra/ebms-core, the admin release branch is missing, or the
  admin build fails; idempotent on re-run). See CONTRIBUTING.md ("Alternative:
  the standalone ebms-core workflow").
- Pre-releases (milestones/RCs): release.yml accepts MAJOR.MINOR.PATCH-QUALIFIER
  (2.21.0-M1, 2.21.0-RC1) and creates the GitHub release with prerelease: true.
  The next-iteration bump returns to <base>-SNAPSHOT (the base stays in
  development) rather than the next patch. docker-deploy.yml publishes a
  pre-release under its own version tag only — `latest` and the <major>.<minor>
  tag always stay on the last stable release. All version rules (accept/reject,
  derived branch, snapshot, changelog prev-tag) live in
  scripts/release-version.sh, shared by both workflows; run
  `make release-check` after touching them. `sort -V` alone is NOT enough to
  pick the previous release tag (it puts 2.21.0 before 2.21.0-M1) — use the
  script's `prev-tag`, which resolves ancestry.
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
- Version management uses ${revision} property (currently 2.21.0-SNAPSHOT)

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
- Submodule `ignore = all`: `.gitmodules` sets `ignore = all` on every submodule, which makes `git status` hide gitlink drift AND makes plain `git add <path>` silently skip pointer updates. Use `git add -f <submodule>` to stage a new commit, and commit the parent pointer so CI checks out the intended SHA. `ignore = all` ALSO hides gitlink changes from `git diff` / `git show --stat` (only regular files show), so don't assume a parent commit missed a submodule pin just because it's absent from the stat — verify with `git ls-tree HEAD <submodule>` or `git --no-pager diff --ignore-submodules=none`.
- Submodule version alignment: CI builds only the committed submodule SHAs. After a release, each submodule's dev branch must carry its post-release `-SNAPSHOT` version bump as a real commit (not just a local working-tree edit), and the parent repo must pin that commit — otherwise CI resolves the release version against Maven Central and fails.
- Submodule remotes need auth: submodule push URLs are plain HTTPS, so `git push` inside a submodule prompts for credentials. Use `scripts/push-submodule.sh <path-or-name> [branch]` — it reads SUBMODULE_GITHUB_TOKEN (or GITHUB_TOKEN), pushes to the branch configured in .gitmodules, and then prints the exact `git add -f <submodule>` + commit + push commands to pin the new SHA in the parent. `--dry-run` previews the (token-masked) push URL. It accepts a submodule name OR repo path (note `documentation` is the path, `ebms-admin_documentation` is the name).
- Submodule pins must point at commits that exist on the remote: CI checks out the pinned SHAs with a shallow fetch, so pinning a local/unpushed commit breaks every CI run with `upload-pack: not our ref <sha>`. Push the submodule commit first, then pin it in the parent (happened with the `documentation` submodule in 2026-08: a license commit made on stale local history was pinned but never pushed).
- Do NOT pin + push the parent for every submodule change. For day-to-day work, commit + push each changed submodule to its own branch (via `scripts/push-submodule.sh`) and STOP — leave the parent's gitlinks alone. Pinning the parent on every commit only produces useless pointer-bump commits; the parent is re-pinned to the released submodules during the release (`release.yml`). (Still commit + push a parent when you genuinely change parent-level files such as AGENTS.md or CI, but do not bump submodule pointers in that commit.)
- Running the embedded server (`nl.clockwork.ebms.server.embedded.startup.StartEmbedded`) locally: (1) `Start.getProperty`/`getBooleanProperty` (SystemInterface) read ONLY `-D` system properties — the classpath `default.properties` is seen only by Spring `@Value` beans — so connector flags must be passed as vmArgs, e.g. `-Dapi.ssl.enabled=true -Dapi.ssl.keyStorePassword=... -Dapi.health.enabled=true`. (2) The `-ssl`/`-soap`/`-health` CLI args are no-ops in this module. (3) `database.start=true` is required to start the in-process H2 TCP server on 9092 (otherwise Hikari fails with "Connection refused: localhost:9092"); it is read via `@Value`, so a vmArg or an `ebms-server.properties` in the working dir both work.
- Spring: declare `BeanPostProcessor` factory methods `static` and inject `Environment` instead of relying on `@Value` fields of the enclosing `@Configuration` class. A non-static `@Bean` returning a `BeanPostProcessor` forces early instantiation of the config class, before `@Value` injection, leaving fields as raw `${...}` placeholders (hit in `MessageEventListenerConfig.messageEventListenerFilterProcessor`, fixed 2026-08).
- Shaded fat jars: the parent shade `artifactSet` excludes `commons-logging:commons-logging`, which was safe under Spring 6 (spring-jcl was shaded in) but breaks Spring 7, where spring-core depends on the real commons-logging artifact — `java -jar` then dies with `NoClassDefFoundError: org/apache/commons/logging/LogFactory`. The `server` module overrides `artifactSet` with `combine.self="override"` to keep commons-logging; do that (not touch the parent) for any new Spring-based shaded module. Same trap for `jakarta.jws:jakarta.jws-api`: the parent shade filter strips `jakarta/jws/**` from jakarta.xml.ws-api expecting the dedicated artifact as sole provider, but the parent artifactSet excludes it too, so SOAP endpoints die with `ClassNotFoundException: jakarta.jws.WebService` — keep it in the module override as well. Also verify shade `mainClass` against the real class package (`server` fixed 2026-10: `...server.embedded.startup.StartEmbedded`, not `...server.embedded.StartEmbedded`).
