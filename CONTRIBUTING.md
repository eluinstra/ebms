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
