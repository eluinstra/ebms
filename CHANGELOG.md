# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- AI-ready configuration added: AGENTS.md, copilot instructions, CI workflows, issue templates, CONTRIBUTING.md
- Release pipeline supports pre-releases (milestones/RCs): release.yml accepts
  `MAJOR.MINOR.PATCH-QUALIFIER` (e.g. `2.21.0-M1`), creates the GitHub release
  marked pre-release, returns the `<revision>` to `<base>-SNAPSHOT` afterwards,
  and derives the ebms-core release branch from the version. docker-deploy.yml
  publishes a pre-release under its own tag only, keeping `latest` and the
  `<major>.<minor>` tag on the last stable release. Shared version rules live in
  `scripts/release-version.sh` (`make release-check`).
- ebms-docker: `bump.sh` accepts pre-release versions, and the image scripts
  (build/push/manifest) move only the exact version tag for a pre-release,
  so `latest` and `<major>.<minor>` stay on the last stable release
- Release pipeline creates a companion GitHub release in the legacy
  eluinstra/ebms-admin repo (admin console jar + the same plugin jars, tagged
  `ebms-admin-<v>`, body links to the primary release) next to the ebms-core
  one. The ebms-core GitHub release is the primary/first one: it is created
  before the companion, and the companion can never block it — a missing
  ebms-admin release branch or a failing ebms-admin build skips the companion
  with a warning instead of failing the release
- The standalone ebms-core release workflow
  (ebms-core/.github/workflows/release.yml) creates the same companion
  ebms-admin GitHub release via the new
  `ebms-core/scripts/release-admin-companion.sh` (tolerant + idempotent;
  gated on the optional secret `EBMS_ADMIN_TOKEN`, skipped with a warning
  when it is unset, the admin release branch is missing, or the admin build
  fails)
