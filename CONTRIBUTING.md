Contributing to EbMS

Thanks for your interest. Short checklist for contributors:

- Fork the repository and create a branch named feature/<short-desc> or fix/<short-desc>
- Target branch: dev
- Run local build and tests: mvn -B clean verify
- Add unit tests for new behavior under src/test/java
- Follow existing code style and run `mvn checkstyle:check` if needed
- Update CHANGELOG.md with a short note under Unreleased
- Open a PR with a clear description, testing steps, and link to relevant docs

AI-assisted changes checklist:

- Follow module guidance in .github/copilot-instructions.md and AGENTS.md
- Keep changes scoped to the requested area and avoid unrelated refactors
- Include tests for behavior changes or bug fixes
- Mention exact validation commands and outcomes in the PR description

Validation matrix by change type:

| Change type | Minimum validation |
| --- | --- |
| Java code in ebms-core/common or ebms-core/core | mvn -f ebms-core/pom.xml -B -pl common,core -am test |
| DB plugin code under ebms-core/plugin/db | mvn -f ebms-core/pom.xml -B -pl plugin/db -am verify |
| API/signature changes in ebms-core/core | mvn -f ebms-core/pom.xml -B verify and mvn -f ebms-admin/pom.xml -B test |
| ebms-admin web/service changes | mvn -f ebms-admin/pom.xml -B verify |
| Docs-only changes | Build or serve documentation if structure/navigation changed |

When changing schema, SQL, or DB persistence behavior:

- Update affected plugin/db modules
- Update test resources under ebms-core/core/resources/test as needed
- Document migration impact in PR notes and docs when applicable

If in doubt, open an issue first.

Releasing a version (maintainer)

A release is done for ebms-core and ebms-admin together via the GitHub
Actions workflow .github/workflows/release.yml (workflow_dispatch).

Prerequisites:
- Everything that must be part of the release is committed and pushed to the
  dev-2.20.x branch of both eluinstra/ebms-core and eluinstra/ebms-admin.
  The workflow releases from the remote tip of those branches, so the
  submodule pins in the parent repo do not matter.
- CI on dev is green.
- Repository secret SUBMODULE_GITHUB_TOKEN is set: a PAT (or GitHub App
  token). Minimal permissions: "Contents: Read and write" on
  eluinstra/ebms-core and eluinstra/ebms-admin (used to push the
  dev-2.20.x branch, push the tags, create the GitHub releases and upload
  the JAR assets). Nothing else is required - the other submodules are
  only read, and Actions/Workflows/Pull-requests permissions are not used.
  The job token can only write to the parent repo, hence a separate token
  for the submodules. The workflow itself declares only contents:write
  (push the pin to dev) and actions:read (CI polling).

Trigger:
1. GitHub -> eluinstra/ebms -> Actions -> Release -> Run workflow
2. Branch: dev, version: e.g. 2.20.9 (must match MAJOR.MINOR.PATCH)

What the workflow does (in order):
1. Bump the version in ebms-core/pom.xml (<revision>) and ebms-admin/pom.xml
2. Build ebms-core (skipTests) and build + test ebms-admin
3. Commit "release <v>" and tag ebms-core-<v> / ebms-admin-<v>, push branch + tags
4. Create a GitHub release on each submodule repo with the built JARs as
   assets (core jar / admin fat jar + all db + cache plugins) and an
   auto-generated changelog (commit subjects since the previous release tag)
5. Bump both to <next patch>-SNAPSHOT, commit and push
6. Pin the new submodule commits in the parent repo and push to dev
7. Wait for the CI run on dev to finish green

Results:
- https://github.com/eluinstra/ebms-core/releases/tag/ebms-core-<v>
- https://github.com/eluinstra/ebms-admin/releases/tag/ebms-admin-<v>

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
