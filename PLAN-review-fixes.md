# Implementation Plan: Review Fixes for ebms-core (cef393df..611c4aac)

> **STATUS (2026-10-15): EXECUTION COMPLETE — all phases done.**
> Delivered on ebms-core `dev` on top of the 78-commit review range (9 fix commits,
> review range now cef393df..HEAD = 87 commits; all `${revision}` untouched):
>
> | Phase | Commit | Result |
> |---|---|---|
> | 1 — C1 proof tests | `7fd0c49d` `test(dao): prove SQL:2008 pagination breaks MariaDB (C1)` | `DialectPaginationIT` (H2/HSQLDB/PostgreSQL/MariaDB 11 green — MariaDB supports offset/fetch since 10.6.1) + manual `DialectRawSqlIT` documenting the MariaDB 10.5 rejection of `offset 0 rows fetch first N rows only`. Matrix-gated out of the default run. **C1 fix itself: out of scope, still open.** |
> | 2 — m3 bind maxNr | `f9fa927a` `refactor(dao): bind maxNr instead of concatenating it (m3)` | |
> | 3 — M1 claiming | `7b6f0224` `feat(client): atomic delivery-task claiming under ShedLock (M1)` | V2.23.0 (nullable claim columns + index) in all 7 db plugins; conditional claim UPDATE; executor claims before dispatch |
> | 4a — R4a | `f39b6c9e` `fix(security): reject IPv6 ULA + IPv4-mapped CPA endpoints (R4a)` | LoopbackUtils rewritten (ULA, link-local, mapped/compatible IPv4-in-IPv6); 30 unit tests |
> | 4b — R4b/m2 | `f1bdaa8c` `refactor(server): log server-start failure via SLF4J (R4b)` | StartEmbedded `@Slf4j` + `log.error` |
> | 4c — R4c | `0d773d7b` `refactor(dao): deduplicate filter SQL conditions into SqlConditionBuilder (R4c)` | Shared builder; both WithMessageFilter copies delegate; 5 unit tests |
> | 5 — m5 | `72606ee9` `build(ci): raise release job timeout to 90 min (minor #5)` | release.yml 60→90 |
> | 6 — m6 | `65ff8af0` `test(log): synchronous log4j2 config in tests (m6)` | 0 disruptor occurrences in test runs |
> | 7 — m7 | `b1174b90` `fix(cli): name the property key in integer parse errors (m7)` | getInt wraps NumberFormatException naming key+value; 2 tests |
> | 8/9 — docs | parent `AGENTS.md` (cross-dialect + HA-model bullets), parent `CHANGELOG.md` (HA trade-off + upgrade guidance + pagination note) | Parent-repo files; committed with the parent, NOT in the submodule |
>
> Verification: `make test` (clean verify, all core modules) BUILD SUCCESS — 1118 tests,
> 0 failures, 0 errors (2 skipped pre-existing); `mvn -B checkstyle:check` reports only
> PRE-EXISTING violations in 2 legacy files (`common/.../PluginProvider.java`,
> `common/.../ThrowingFunction.java` — 2011-era tabs/braces/Javadoc style; the range only
> touched a license-year line + one @SuppressWarnings there; CI does not enforce
> checkstyle, the pom binds it in reporting only). Every Java file touched by the fix
> series: 0 violations.
>
> Follow-ups (not in scope here): the C1 pagination fix itself; DBClean.java:416
> `t.printStackTrace()`; checkstyle normalization of the two legacy files.

Source review: chat review of 78-commit range. This plan covers exactly the items the
user selected. **The C1 fix itself is explicitly OUT OF SCOPE** — only tests proving C1
is needed are implemented.

| ID | Item | Type |
|---|---|---|
| C1 | SQL:2008 `offset/fetch first` pagination breaks MariaDB | proof-tests only |
| M1 | ShedLock leadership without atomic task claiming | full fix |
| R4 | ULA check in LoopbackUtils + StartEmbedded logger + WithMessageFilter/EbMSDAOImpl dedup | full fix |
| m3 | `getTasksBefore` concatenates `maxNr` into SQL | full fix |
| m2 | `e.printStackTrace()` in StartEmbedded | full fix (= R4 item 2, one work item) |
| m5 | release.yml `timeout-minutes: 60` too tight | config fix |
| m6 | Test log4j2 Async loggers without disruptor dep → NoClassDefFoundError noise | config fix |
| m7 | CLI `getInt` throws bare `NumberFormatException` without key name | full fix |

Out of scope (documented, not planned here): the C1 dialect-aware pagination fix itself,
M2 (`SERIALIZABLE_PACKAGES="*"`), M3 (scheduling dependency-check), CPAValidator
package consolidation (follow-up), EbMSEventRowMapper column-constant dedup beyond what
R4's builder unification yields.

---

## Phase 0 — Prep

1. Create branch in the ebms-core submodule: `fix/review-findings-c1-proof-m1-r4-m3` off current HEAD.
2. Baseline: `make test` (runs `mvn -B -f ebms-core/pom.xml clean verify` equivalent) must be green before any change.
   (Verified earlier: clean build = BUILD SUCCESS, 742 tests, 0 failures.)
3. Docker is available locally (verified `docker ps` OK) — Testcontainers ITs can run locally.

## Phase 1 — C1 proof tests (red on MariaDB, green elsewhere)

Goal: demonstrate, in CI-runnable form, that the hand-written pagination SQL
(`offset ? rows fetch first ? rows only`) fails on MariaDB while working on the other
supported databases — proving the C1 fix is required.

**Test matrix:** H2 (in-mem), HSQLDB (in-mem), PostgreSQL (`jdbc:tc:postgresql:18`,
already the core-IT default), MariaDB (`jdbc:tc:mariadb:11`, same image the MariaDB
plugin IT uses). MSSQL/Oracle/DB2 stay profile-gated manual targets (not in this phase's
CI set).

**Mechanics (verified facts this builds on):**
- Core ITs already run against real PostgreSQL via `ContainerDatabaseDriver`
  (`core/src/test/resources/nl/clockwork/ebms/default.properties`:
  `ebms.jdbc.url=jdbc:tc:postgresql:18:///ebms`), and `DataSourceConfig` runs Flyway with
  `locations("classpath:db/migration/default")`.
- Migrations live in the per-DB plugin jars; core already test-scopes
  `ebms-postgres-db-plugin` (core/pom.xml). `jdbc:tc:mariadb:11` is proven by
  `MariaDbFlywayMigrationIT`.

**Steps:**
1. Add test-scope deps to `core/pom.xml`: `ebms-h2-db-plugin`, `ebms-hsqldb-db-plugin`,
   `ebms-mariadb-db-plugin` (versions `${project.version}`; add them to parent
   `dependencyManagement` next to `ebms-postgres-db-plugin`). This puts each DB's
   `db/migration/default` classpath location + JDBC driver on the core test classpath.
2. New IT class in core: `nl.clockwork.ebms.common.dao.DialectPaginationIT`
   (failsafe `*IT` naming; JUnit `@Tag("dialect-matrix")`; parameterized over JDBC URLs).
   For each DB: build DataSource (Hikari or plain DriverManager), run Flyway
   (`locations("classpath:db/migration/" + variant)`), then execute the EXACT production
   SQL through the REAL DAO classes:
   - `DeliveryTaskDAOImpl.getTasksBefore(now, serverId, maxNr)` (default delivery path,
     `DAODeliveryTaskExecutor` uses it when maxTasks>0),
   - `EbMSDAOImpl(core).getMessageIds(filter, RECEIVED, maxNr)` (REST unprocessed polling),
   - `EbMSDAOImpl(server).selectCPAs(first,count)` / `selectMessages(filter, first, count)`
     (admin paging) — these need the server-module DAO; if the server DAO is not on core's
     test classpath, put this third query group in a small IT in the `server` module
     (`server/src/test/java/.../admin/AdminPaginationDialectIT`) reusing the same matrix
     helper.
3. Gate: run these ITs only under a new Maven profile `dialect-matrix` (failsafe include
   filter on the `dialect-matrix` tag), so the default `make test`/CI stays green while
   the MariaDB variant is expectedly red. Document the invocation:
   `mvn -B -f ebms-core/pom.xml -P dialect-matrix -pl core,server -am verify`.
4. Acceptance criteria:
   - H2/HSQLDB/PostgreSQL variants pass (today's SQL is valid there).
   - MariaDB variants fail with a MariaDB syntax error mentioning `fetch`/`offset` —
     the concrete proof of C1.
   - The failure output (stack trace + SQL) is captured in the run log for the review record.
5. Note in the test class Javadoc: "Runs only under -P dialect-matrix; the MariaDB cases
   are expected to FAIL until the C1 dialect fix lands."

## Phase 2 — minor #3: bind `maxNr` (parameterize, stop concatenating)

1. `core/src/main/java/nl/clockwork/ebms/client/delivery/task/DeliveryTaskDAOImpl.getTasksBefore(Instant,String,int)`:
   replace `" offset 0 rows" + " fetch first " + maxNr + " rows only"` with
   `" offset ? rows fetch first ? rows only"` and pass `0, maxNr` as parameters
   (matches the style of `EbMSDAOImpl` pagination, keeps ORDER BY for MSSQL).
2. Test: extend the new H2 variant of `DialectPaginationIT` (Phase 1) — or add a
   focused H2 unit-style IT — asserting `getTasksBefore` with `maxNr` returns exactly
   `maxNr` rows, oldest first. This proves the binding change is behavior-preserving.
3. Deliberate sequencing note: this change still uses SQL:2008 syntax, so the MariaDB
   variant of Phase 1 stays red — demonstrating that m3 alone does not fix C1 (m3 is
   hygiene, C1 is dialect support). When the actual C1 fix lands later, this method is
   the one it rewrites; keeping m3 separate now makes that future diff smaller and
   reviewable.

## Phase 3 — M1: atomic delivery-task claiming (full fix)

Design: keep the ShedLock lock as the coarse cluster gate (unchanged), add a
**per-task claim** so a second node can never re-fetch in-flight tasks even when the
lock expires mid-cycle.

**HA context (why this matters — verified against the base tree):** pre-range HA relied
on THREE cooperating pieces: (1) JGroups/Raft leader election, (2) the JMS task
handler — ActiveMQ broker + `DefaultMessageListenerContainer(sessionTransacted=true)`
pushing `DeliveryTask`s to any node — and (3) Atomikos JTA: `UserTransactionImp` /
`UserTransactionManager` + `AtomikosDataSourceBean` (XA-pooled JDBC) +
`AtomikosConnectionFactoryBean` (XA JMS), so JMS receive and DB writes shared ONE
transaction (effectively-once task distribution). At HEAD, Atomikos is fully removed
(verified: no atomikos/XA imports anywhere in main code; `TransactionManagerConfig` is
a plain `DataSourceTransactionManager`; `JmsBrokerConfig.jmsTransactionManager` is a
plain local `JmsTransactionManager`). So the old guarantee stack is gone and the
DEFAULT path's only coordination is ShedLock — which is exactly why M1's claim is the
necessary compensating control. The residual at-least-once semantics are backstopped
by existing idempotence: `delivery_task.message_id` UNIQUE (duplicate task insert
rejected), conditional `updateMessage(messageId, oldStatus, newStatus)` state
transitions, and `delivery_log` replay rows.

**3a. Schema — new Flyway migration `V2.23.0__AddDeliveryTaskClaim.sql` in all 7 plugin
migration dirs** (`plugin/db/{db2,h2,hsqldb,mariadb,mssql,oracle,postgres}/src/main/resources/db/migration/default/`):
- H2/HSQLDB/MariaDB/PostgreSQL: `ALTER TABLE delivery_task ADD COLUMN claimed_by VARCHAR(256) NULL;` + `claimed_at TIMESTAMP NULL` (per-dialect exact syntax; write each file dialect-correct, e.g. MariaDB single `ADD COLUMN` per statement, PostgreSQL both in one, MSSQL `ADD claimed_by VARCHAR(256), claimed_at DATETIME2`, Oracle `ADD (claimed_by VARCHAR2(256), claimed_at TIMESTAMP)`, DB2 `ADD COLUMN claimed_by VARCHAR(256)`).
- Add index `i_delivery_task_claim` on `(claimed_at)` for the reclaim scan (name it consistently; index syntax is per-dialect too — the existing migrations already demonstrate per-dialect DDL style).
- **Never touch existing migration files** (Flyway checksums; license-maven-plugin excludes `db/migration/**` — keep the static copyright header style used by `V2.22.0__CreateShedLockTable.sql`).
- `V2.23.0` is free (verified: newest is `V2.22.0__CreateShedLockTable.sql` in every plugin).

**3b. DAO claim logic — `core/.../client/delivery/task/DeliveryTaskDAOImpl` (+ interface):**
- Replace the plain fetch with a transactional fetch+claim (single `@Transactional`
  method or same-connection pair):
  1. select candidate `message_id`s with the existing paginated query (bound params per
     Phase 2);
  2. atomic claim: `update delivery_task set claimed_by = ?, claimed_at = CURRENT_TIMESTAMP
     where message_id in (:ids) and (claimed_by is null or claimed_at < :expiry)` via
     `NamedParameterJdbcTemplate`; portability kept: no `SKIP LOCKED`, no
     `RETURNING`, `CURRENT_TIMESTAMP` everywhere (valid on all 7 supported DBs);
  3. re-select the claimed rows for dispatch.
- Claim expiry = existing `lockAtMostForMillis` (semantic symmetry: "how long a taken
  thing may stay taken"; no new config property). Tasks never explicitly released —
  expired claims are reclaimable via the `claimed_at < ?` predicate; the clock is the
  **DB clock** (no host-skew issue; ShedLock JDBC mode already relies on DB time).
- Duplicate-dispatch window shrinks from `lockAtMostFor` (5 min) to
  `claim-expiry − actual-cycle-time` and, more importantly, from "any second node whose
  lock attempt wins after expiry" to "only tasks whose claim has expired".

**3c. Executor wiring — `core/.../client/delivery/handler/DAODeliveryTaskExecutor`:**
- pass the claim window through to the DAO call; log claimed-vs-fetched counts at debug.
- No change to the ShedLock acquisition flow.

**3d. Tests:**
1. **Real-DB race test (no mocks)** — new `DeliveryTaskDAOClaimConcurrencyIT` (H2 in-mem):
   two threads race `getTasksBefore`/claim over a shared set of inserted tasks with
   latches; assert the returned/claimed sets are disjoint and no task is dispatched twice.
   Also assert re-claim of an expired claim works (insert with past `claimed_at`).
2. **Executor unit test** (mocked DAO/dispatcher — justified: scheduling harness only,
   per existing `DAODeliveryTaskExecutorTest` conventions): claim window value
   propagated, claimed count drives dispatch, tasks not claimed are not dispatched.
3. **Cross-dialect claim IT** — extend `DialectPaginationIT`'s matrix helper with a
   claim scenario (insert 5 tasks, claim from two "nodes", assert disjoint claims) run on
   the same H2/HSQLDB/PG/MariaDB matrix (the claim UPDATE is dialect-portable so it goes
   green, but the paginated SELECT inside the claim still carries the Phase-2 SQL:2008
   syntax, so the MariaDB claim IT stays red until C1 — document this interaction so
   nobody misreads a partial-green run).
4. Update existing migration ITs: nothing to change (they run all migrations; the new
   V2.23.0 files are exercised automatically in each plugin's `*FlywayMigrationIT`).
5. **JMS-handler regression note (M1 follow-up, doc-only):** the JMS task handler lost
   XA (Atomikos) — receive and DB updates are now separate local transactions
   (`JmsBrokerConfig.jmsTransactionManager` = local JMS tx; `sessionTransacted=true`
   gives at-least-once redelivery). Add a short section to the 2.21 release notes /
   docs: cluster delivery guarantees moved from effectively-once (Raft + JMS/XA) to
   at-least-once (ShedLock + claims + local transactions), with the idempotence
   backstops named (UNIQUE message_id, conditional status transitions, delivery_log).
   Optionally add one integration test: redelivered JMS task (same message_id) does NOT
   produce a duplicate send.


### M1 status (2026-10-15, session log)

**IMPLEMENTED, all green.** Delivered as the "durable leader gate / per-task claim"
workstream; 3a–3d.4 all in place, verified by `mvn -B -pl core -am test` (318 tests,
0 failures) plus the targeted ITs:
- 3a: `V2.23.0__AddDeliveryTaskClaimColumns.sql` in all 7 plugin migration dirs
  (existing files untouched — Flyway checksums safe).
- 3b: `DeliveryTaskDAOImpl.claimTasksBefore` — transactional select + claim + re-select,
  DB clock (`CURRENT_TIMESTAMP`), claim validity = `lockAtMostForMillis`.
- 3c: `DAODeliveryTaskExecutor` claims with `(serverId, maxTasks, lockAtMostForMillis)`,
  debug log of claimed count; ShedLock flow unchanged.
- 3d.1: `DeliveryTaskClaimIT` (default suite, H2 + real Flyway): concurrent claims are
  disjoint (union = all pending), fresh claim not reclaimable, expired claim reclaimed,
  and `maxNr` pagination honoured across sequential claims (3 + 3 + 4).
- 3d.2: `DAODeliveryTaskExecutorTest.propagatesClaimWindowToDAO` — non-default window
  (12345) + maxTasks (7) proven to reach the DAO call.
- 3d.3: `DialectPaginationIT.claim` on the tagged dialect matrix (H2/HSQLDB/PG/MariaDB 11
  green; MariaDB ≤10.5 stays red on the pagination SELECT until C1 — documented expected red).
- 3d.4: no changes needed (migration ITs exercise V2.23.0 automatically).
- 3d.5 (JMS doc note): deferred to the docs phase.

**Design deviations from the plan (both deliberate, verified by test):**
1. **Per-row claim + row-count re-select** instead of the planned single IN-list
   `UPDATE ... where claimed_by is null or claimed_at < ?` + re-select. Reason: the
   read-back cannot distinguish which rows THIS transaction claimed when two workers with
   the same `serverId` race (identical `claimed_by`, same-second `claimed_at`), and
   `claimed_at = ?` equality is fragile against per-dialect sub-second timestamp
   truncation. Per-row `update ... where message_id = ? and (claimed_by is null or
   claimed_at < ?)` (update count = taken) keeps the same portability constraints (no
   SKIP LOCKED / RETURNING / DB-specific clock) with exact per-row semantics.
2. **`updateTask` releases the claim** (`claimed_by = null, claimed_at = null`) — the
   plan said "tasks never explicitly released". Without release, every reschedule (the
   retry path via `createNextTask`, same `message_id`) would leave the task invisible to
   ALL workers for the full claim validity. Safe: only the owning worker reschedules
   while it still holds the claim; a crashed worker's stale claim is cleared by the
   reclaiming worker's own `updateTask` later.
   Also `Timestamp.from(now.truncatedTo(SECONDS))` for claim cutoffs/stamps: Java
   `Instant` nanos vs DB timestamp precision (H2 TIMESTAMP(0)) otherwise makes
   `claimed_at < cutoff` flaky within the same second.

Note: `insertTask(task, serverId)` sets `claimed_by = serverId` at insert (new tasks
start claimed by their creator — a fresh task can never be immediately re-fetched by
another node before the creator polls it).

## Phase 4 — R4 (three work items; m2 = item 2)

**4a. ULA / IPv4-mapped gap in `LoopbackUtils.isPrivateOrLocalHost`** (F1/F3 hardening):
- Add `isUniqueLocalAddress(Inet6Address)` covering `fc00::/7` (first byte `0xfc`/`0xfd`)
  and unwrap IPv4-mapped literals (`::ffff:a.b.c.d`) to check the embedded IPv4 address
  through the existing IPv4 path.
- Include both in `isPrivateOrLocalHost`; keep the `UnknownHostException → true`
  fail-closed behavior.
- Tests: new/extended `LoopbackUtilsTest`:
  `fd12:3456:789a::1 → true`, `fc00::1 → true`, `::ffff:10.0.0.1 → true`,
  `fe80::1 → true` (already link-local), `2001:db8::1 → false` (documentation-range
  public v6 — assert NOT flagged), `8.8.8.8 → false`, `192.168.1.1 → true`,
  unresolvable host → true. Plus one CPAValidator-level test if cheap (the validator
  calls the helper for endpoint URIs).

**4b. StartEmbedded error logging (= minor #2):**
- `server/.../startup/StartEmbedded.java:130`: replace `e.printStackTrace()` with
  `log.error("Error starting server", e)` (`@Slf4j` on the class; module uses SLF4J+Log4j2;
  the `println` startup banners stay — that's the module's convention for stdout).
- Test: none needed (logging-only change); verify via `make module M=server` compile.

**4c. WithMessageFilter / EbMSDAOImpl dedup:**
- Verified: the two `EbMSDAO` interfaces are deliberately disjoint (core = messaging
  DAO; server-embedded = admin/reporting DAO) — do NOT merge the DAOs. The genuine
  duplication is the SQL-condition-building primitives in the two `WithMessageFilter`
  default-method implementations (~60 lines of identical `appendEquals`/party logic,
  differing only in column prefixes and filter model types).
- Move a shared builder to core, e.g. `nl.clockwork.ebms.common.dao.SqlConditionBuilder`
  (static `appendEquals`, `appendParty`, `appendIn` helpers taking column names as
  arguments). Both `WithMessageFilter` interfaces keep their public
  `getMessageFilter(...)` shape (different filter models: `api.ebms.model.MessageFilter`
  vs `server.model.embedded.web.EbMSMessageFilter`) but delegate condition assembly to
  the shared builder.
- Tests: unit tests for `SqlConditionBuilder` (null-safety: null value appends nothing;
  party null skips both columns; parameters list grows in append order). Behavior
  preservation is additionally covered by existing filter-path tests (admin
  `AdminRestControllerTest`, CPA/filter ITs).
- Note: while consolidating, parameterize the server variant's
  `appendServiceMessage` (`service = 'urn:...'` constant → bind as `?`), keeping
  semantics identical.

## Phase 5 — minor #5: release workflow timeout

- `.github/workflows/release.yml:99`: `timeout-minutes: 60` → `90` (build+test+smoke+
  companion release + up to 30 min CI-wait polling is measured at ~32 min wait alone in
  the worst observed case; 90 leaves comfortable headroom). No other workflow changes.

## Phase 6 — minor #6: synchronous log4j2 in tests

- `core/src/test/resources/log4j2.xml`: `<AsyncRoot>` → `<Root>`, `<AsyncLogger ...>`
  → `<Logger ...>` (same names/levels). Removes the
  `NoClassDefFoundError: com/lmax/disruptor/EventHandler` + "Null object returned for
  AsyncLogger" noise without adding a disruptor test dependency (sync loggers are also
  deterministic and slightly faster in unit tests).
- Also align `server/src/test/resources/log4j2.xml` if it uses Async loggers (check both).
- Acceptance: `make test` output contains zero `com/lmax/disruptor` occurrences.

## Phase 7 — minor #7: CLI getInt error messages

- `cli/src/main/java/nl/clockwork/ebms/cli/properties/ServerPropertiesReader.getInt`
  (line ~75): wrap `Integer.parseInt` in try/catch `NumberFormatException` → throw
  `IllegalArgumentException("Invalid integer value for property '" + key + "': " + value)`.
  (Message names the key; verify against the CLI's exception handler that
  IllegalArgumentException maps to the expected usage-error exit path, and mirror `getBool`
  if it needs the same treatment.)
- Tests: add to `cli/src/test/java/nl/clockwork/ebms/cli/properties/` (new
  `ServerPropertiesMalformedValueTest` or extend `ServerPropertiesRoundTripTest`):
  malformed `ebms.port=notanumber` → exception message contains `ebms.port`; valid
  values unchanged.

## Phase 8 — Verification, sequencing, delivery

- **Run order:** Phase 2 → Phase 4 → 5 → 6 → 7 (all green immediately) can go in one
  commit series; Phase 1 and the red MariaDB variants land with the profile gate; Phase 3
  (M1) is its own commit (schema + DAO + executor + tests) because it changes persisted
  schema.
- **Suggested commit series** (all in the submodule, never touching `${revision}`):
  1. `test(dao): prove SQL:2008 pagination breaks MariaDB (C1)` — Phase 1 (+ matrix helper)
  2. `refactor(dao): bind maxNr instead of concatenating it (m3)` — Phase 2
  3. `feat(client): atomic delivery-task claiming under ShedLock (M1)` — Phase 3
  4. `fix(security): reject IPv6 ULA + IPv4-mapped CPA endpoints (R4a)` — Phase 4a
  5. `refactor(server): log server-start failure instead of printStackTrace (R4b/m2)` — Phase 4b
  6. `refactor(dao): extract shared SQL condition builder (R4c)` — Phase 4c
  7. `build(ci): raise release job timeout to 90 minutes (m5)` — Phase 5
  8. `test(log): synchronous log4j2 config in tests (m6)` — Phase 6
  9. `fix(cli): name the property key in integer parse errors (m7)` — Phase 7
- **Validation per repo conventions** (AGENTS.md: always test before committing):
  - `make test` (clean verify, all core modules) — must be green for series 2,4,5,6,7,8,9.
  - `mvn -B -f ebms-core/pom.xml -P dialect-matrix -pl core,server -am verify` — expect
    green except the MariaDB pagination cases (documented proof of C1; the claim-IT
    MariaDB case goes green after Phase 3 only for the claim SQL — see 3d.3 note).
  - `mvn -B -f ebms-core/pom.xml checkstyle:check` after Java edits.
- **AGENTS.md:** extend the existing cross-dialect bullet with "paginated SQL is
  matrix-tested under -P dialect-matrix; MariaDB red until C1 fix" once Phase 1 lands.
- **Release note (2.21):** M1 schema migration V2.23.0 is additive (two nullable columns
  + index) — no data migration needed; C1 MariaDB pagination remains broken until its
  fix (carry the earlier review recommendation).

## Phase 9 — documentation (new, from HA-history context)

1. Release-note paragraph (2.21) covering the full HA trade-off chain in one place:
   Raft/JGroups removed → ShedLock lock (+ M1 claims); Atomikos XA removed → local
   transactions (JDBC `DataSourceTransactionManager`, JMS `JmsTransactionManager` with
   `sessionTransacted=true`); guarantee = at-least-once with the named idempotence
   backstops; JMS/Kafka handlers remain available for broker-based distribution but no
   longer get XA atomicity. Include upgrade guidance: multi-node deployments that
   previously ran `deliveryTaskHandler.type=JMS` + Atomikos now either accept
   at-least-once or use DEFAULT + claims.
2. AGENTS.md: one bullet on the HA model evolution (Atomikos/JGroups gone, ShedLock +
   claims, at-least-once) so future reviews don't re-derive it.

## Risks & mitigations

- **Testcontainers image pulls** (mariadb:11, postgresql:18) — first local run downloads;
  CI has a Maven cache but not a Docker cache; acceptable (images are small).
- **Per-dialect migration DDL mistakes** — each plugin's `*FlywayMigrationIT` runs the new
  V2.23.0 file against its real DB container, so a wrong dialect variant fails there.
- **IN-list size** — maxTasks is bounded (default 100, config-capped); fine for IN-list
  binding on all dialects.
- **JMS/Kafka delivery paths** — verified: no `getTasksBefore` callers in plugins; the
  claim only affects the DAO/default handler path.
- **Red tests in CI** — prevented by the `dialect-matrix` profile gate; keep the tag in
  failsafe excludes for the default profile so an accidental invocation cannot break CI.
- **Flyway discipline** — only NEW migration files; existing files untouched (checksum
  safety per AGENTS.md).
