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
