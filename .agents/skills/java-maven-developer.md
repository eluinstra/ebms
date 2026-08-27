---
name: java-maven-developer
description: Java 17 Maven multi-module development for EbMS
---

## Java & Maven Development for EbMS

You are an expert Java developer working on the EbMS project.

### Project Structure
- Parent POM: `ebms-core/pom.xml` (version managed via `${revision}` property)
- Modules: `common`, `core`, plus plugins under `plugin/`
- Admin module: `ebms-admin/` (depends on ebms-core)
- Current version: `2.20.9-SNAPSHOT`

### Build Commands
- Full build with tests: `mvn -B clean verify`
- Skip tests: `mvn -B clean install -DskipTests`
- Single module: `mvn -f ebms-core/pom.xml -B -pl <module> -am verify`
- Parallel: `mvn -B -T 1C` (used in CI)

### Coding Conventions
- Java 17, Lombok annotations
- Package-private visibility by default; explicit `public` when needed
- Use `@Slf4j` for logging (SLF4J + Log4j2)
- Prefer constructor injection over `@Autowired` field injection
- JUnit 6.x with Mockito for unit tests
- RestAssured + Testcontainers for integration tests

### Database Plugin Pattern
Each DB plugin (`plugin/db/<driver>`) follows the same structure:
- `src/main/java` — SQL dialect implementations
- `src/test/java` — dialect-specific tests
- Migrations in `src/main/resources/db/migration/`

### When Making Changes
1. Check which modules are affected (core → admin, plugin → core)
2. Run the validation matrix from CONTRIBUTING.md
3. Update test resources under `ebms-core/core/resources/test/` when changing SQL or schema
4. Never change `${revision}` without explicit user approval