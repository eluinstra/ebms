# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### ebms-core restructure: high availability trade-off (2.21)
- High availability was deliberately simplified in ebms-core:
  - JGroups/Raft clustering and Atomikos XA transactions were removed.
  - Multi-node coordination is now ShedLock on scheduled jobs.
  - Message processing uses local transactions only: a JDBC
    `DataSourceTransactionManager` (replaces XA over the DataSource) and a
    JMS `JmsTransactionManager` in the jms messaging plugin (replaces XA
    over the broker). JMS and Kafka messaging handlers remain available for
    broker-based distribution, but no longer get XA atomicity between the
    broker and the database.
  - Guarantee: at-least-once delivery with idempotence backstops — message
    content dedup keys, and per-task delivery claims (Flyway migration
    V2.23.0: nullable `claimed_by`/`claimed_at` columns + index on
    delivery_task in all db plugins; claimed atomically via a conditional
    `UPDATE ... WHERE claim IS NULL OR EXPIRED`, claim validity bound to the
    ShedLock `lockAtMostFor`). The schema change is additive; no data
    migration is needed.
  - Upgrade guidance for multi-node deployments that previously ran
    `deliveryTaskHandler.type=JMS` + Atomikos: either accept at-least-once
    delivery (dedup keys plus delivery claims already prevent the
    double-dispatch window that motivated the XA setup), or switch to
    `deliveryTaskHandler.type=DEFAULT` (the default; lock-gated DAO executor
    sending directly via HTTP, on the shared database).
- Pagination remains SQL:2008 (`offset ... rows fetch first ... rows only`,
  maxNr bound as a parameter). The new `dialect-matrix` integration tests
  (enabled with `-P dialect-matrix`) prove the production pagination SQL on
  real H2, HSQLDB, PostgreSQL and MariaDB 11; note that MariaDB 10.5-class
  dialects reject `offset 0 rows fetch first N rows only`, so pagination
  stays broken on those until the C1 fix (earlier review recommendation
  carried).
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
