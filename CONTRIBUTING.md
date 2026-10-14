Contributing to EbMS

Thanks for your interest. Short checklist for contributors:

- Fork the repository and create a branch named feature/<short-desc> or fix/<short-desc>
- Target branch: dev
- Run local build and tests: `make test` (ebms-core, including the ebms-server
  module) or `make server` (ebms-server with deps only) — see Tooling below
- Add unit tests for new behavior under src/test/java
- Follow existing code style and run `make checkstyle` (or `mvn checkstyle:check`) if needed
- Update CHANGELOG.md with a short note under Unreleased
- Open a PR with a clear description, testing steps, and link to relevant docs

Tooling

A Makefile at the repo root wraps the common Maven commands so you don't have to
remember the `-f` / `-pl` / `-am` flags. Start with `make help`.

| Command | What it does |
| --- | --- |
| `make build` | ebms-core clean install (all core modules) |
| `make test` | ebms-core clean verify (all core unit + integration tests) |
| `make server` | build + test the ebms-server module (embedded SOAP/REST server) with its deps |
| `make module M=<path>` | build one core module with its deps (e.g. `make module M=core`) |
| `make checkstyle` | checkstyle across the core reactor |
| `make skip-tests` | quick ebms-core build without tests |
| `make release-check` | self-test the release version rules (scripts/release-version.sh) |

For authenticated submodule pushes (required because submodule remotes are plain
HTTPS and `.gitmodules` sets `ignore = all`), use `scripts/push-submodule.sh`:

```sh
export SUBMODULE_GITHUB_TOKEN=...        # or GITHUB_TOKEN; Contents read+write
scripts/push-submodule.sh <path-or-name> [branch]     # e.g. ebms-core, or documentation
scripts/push-submodule.sh ebms-core --dry-run         # preview the token-masked push URL
```

It pushes to the branch configured in `.gitmodules` (or the one you pass), then
prints the exact `git add -f <submodule>` + commit + push commands to pin the new
SHA in the parent repo.

AI-assisted changes checklist:

- Follow module guidance in .github/copilot-instructions.md and AGENTS.md
- Keep changes scoped to the requested area and avoid unrelated refactors
- Include tests for behavior changes or bug fixes
- Mention exact validation commands and outcomes in the PR description

Validation matrix by change type

The raw mvn commands below are the minimum; the Makefile targets above run the
full equivalents. There is no root `pom.xml`, so always use `mvn -f <module>/pom.xml`.

| Change type | Minimum validation |
| --- | --- |
| Java code in ebms-core/common or ebms-core/core | mvn -f ebms-core/pom.xml -B -pl common,core -am test |
| DB plugin code under ebms-core/plugin/db | mvn -f ebms-core/pom.xml -B -pl plugin/db -am verify |
| API/signature changes in ebms-core/core | mvn -f ebms-core/pom.xml -B verify (covers server and plugins) |
| ebms-server (ebms-core/server) changes | mvn -f ebms-core/pom.xml -B -pl server -am verify |
| Docs-only changes | Build or serve documentation if structure/navigation changed |

When changing schema, SQL, or DB persistence behavior:

- Update affected plugin/db modules
- Update test resources under ebms-core/core/resources/test as needed
- Document migration impact in PR notes and docs when applicable

If in doubt, open an issue first.

Releasing a version (maintainer)

A release is done for ebms-core (which includes the ebms-server embedded
server module) via the GitHub
Actions workflow .github/workflows/release.yml (workflow_dispatch).

Prerequisites:
- Everything that must be part of the release is committed and pushed to the
  release branch of eluinstra/ebms-core (dev-<major>.<minor>.x of the version
  being released, e.g. dev-2.21.x for 2.21.0-M1).
  The workflow releases from the remote tip of that branch, so the
  submodule pin in the parent repo does not matter.
- CI on dev is green.
- Repository secret SUBMODULE_GITHUB_TOKEN is set: a PAT (or GitHub App
  token). Minimal permissions for the release: "Contents: Read and write" on
  eluinstra/ebms-core (used to push the
  release branch, push the tags, create the GitHub release and upload
  the JAR assets) and on eluinstra/ebms-admin (companion release: push the
  release branch and tag, create the companion GitHub release, upload its JAR
  assets). The same secret is reused by docs-deploy.yml, which also needs
  Contents write on eluinstra/ebms-admin (which hosts the docs
  site). No Actions/Workflows/Pull-requests permissions are used.
  The job token can only write to the parent repo, hence a separate token
  for the submodule. The workflow itself declares only contents:write
  (push the pin to dev) and actions:read (CI polling).
- The ebms-admin release branch (dev-<major>.<minor>.x) exists if the
  companion release is wanted; when it is missing the companion is skipped
  with a warning and only the primary ebms-core release is created.

Trigger:
1. GitHub -> eluinstra/ebms -> Actions -> Release -> Run workflow
2. Branch: dev, version: e.g. 2.20.9 (MAJOR.MINOR.PATCH) or 2.21.0-M1
   (pre-release); branch is optional and defaults to dev-<major>.<minor>.x
   derived from the version

Pre-releases (milestones / RCs):
- A version with a qualifier (2.21.0-M1, 2.21.0-RC1, 2.21.0-beta.1) is a
  pre-release of MAJOR.MINOR.PATCH. It is tagged ebms-core-<v> and its GitHub
  release is marked "pre-release".
- The <revision> is bumped to the pre-release version, then returned to
  MAJOR.MINOR.PATCH-SNAPSHOT (the base version stays in development), instead
  of moving to the next patch like a stable release.
- Pre-release Docker images (docker-deploy.yml) publish only their own version
  tag; the floating latest / <major>.<minor> tags always stay on the last
  stable release.
- The smoke test still messages the release candidate against the published
  adapter image built from the last stable release, so a milestone that
  intentionally changes wire behaviour can fail that gate by design.
- Version rules live in scripts/release-version.sh (shared by both workflows);
  verify them with `make release-check` after any change.

What the workflow does (in order):
1. Bump the version in ebms-core/pom.xml (<revision>) and — when the companion
   is active — in ebms-admin/pom.xml (project <version>)
2. Build and test the ebms-core reactor (common, core, server, plugins), then
   build and test the legacy ebms-admin project
3. Commit "release <v>" and tag ebms-core-<v> (+ ebms-admin-<v> for the
   companion), push branch + tag
4. Create the PRIMARY GitHub release on the ebms-core repo with the built JARs
   as assets (core jar / ebms-server fat jar + all db + cache + messaging
   plugins) and an auto-generated changelog (commit subjects since the previous
   release tag on this branch; marked pre-release for a milestone), then the
   companion ebms-admin GitHub release (admin console jar + the same plugin
   jars), whose body links to the primary ebms-core release
5. Bump to the next development iteration SNAPSHOT (<next patch>-SNAPSHOT for a
   stable release, <base>-SNAPSHOT for a pre-release), commit and push
6. Pin the new submodule commits in the parent repo and push to dev
7. Wait for the CI run on dev to finish green

The ebms-core release is the primary one: it is created first, and the legacy
ebms-admin companion can never block it — when ebms-admin's release branch does
not exist, or its build fails, the companion is skipped with a warning and the
ebms-core release completes as normal.

Results:
- https://github.com/eluinstra/ebms-core/releases/tag/ebms-core-<v>  (primary)
- https://github.com/eluinstra/ebms-admin/releases/tag/ebms-admin-<v>  (companion)

Alternative: the standalone ebms-core workflow

ebms-core also has its own release workflow
(ebms-core/.github/workflows/release.yml, workflow_dispatch, same version/branch
inputs), which releases the core reactor without touching the parent repo's
submodule pins. It is self-contained, and it creates the SAME releases: the
primary ebms-core GitHub release, then the companion ebms-admin GitHub release
via ebms-core/scripts/release-admin-companion.sh (admin jar + plugin jars, body
links to the primary). The companion is tolerant and can never fail the
ebms-core release: it is skipped with a warning when the optional repository
secret EBMS_ADMIN_TOKEN is not set in eluinstra/ebms-core (PAT with Contents
read+write on eluinstra/ebms-admin), when the ebms-admin release branch does
not exist, or when the ebms-admin build fails. If a release was created without
the companion (e.g. before the secret was configured), the companion can be
created afterwards by running the script manually from a checkout of ebms-core
at the release tag, with the core artifacts of the version installed in the
local Maven repository (`mvn clean install`) and EBMS_ADMIN_TOKEN exported; the
script is idempotent and refuses to touch an already existing companion release
(do NOT re-run the whole workflow for this: its core release steps are not
re-runnable once the tag exists).

Notes:
- Nothing is published to Maven Central or GitHub Packages; the JARs are
  only attached to the GitHub releases.
- The workflow is safe to re-run when it fails before "Commit and tag
  releases" (e.g. build or test failure): just fix the cause and re-run.
  Once the release commits/tags have been pushed it is NOT safe to re-run
  (the version bump would be a no-op commit); repair manually instead -
  the tags already exist, and a GitHub release can be created for an
  existing tag or the existing release for the tag is reused.
- Keep CHANGELOG.md updated under Unreleased before triggering, since the
  release body is generated from commit subjects, not from CHANGELOG.md.
