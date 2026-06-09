Contributing to EbMS

Thanks for your interest. Short checklist for contributors:

- Fork the repository and create a branch named feature/<short-desc> or fix/<short-desc>
- Target branch: dev
- Run local build and tests: mvn -B clean verify
- Add unit tests for new behavior under src/test/java
- Follow existing code style and run `mvn checkstyle:check` if needed
- Update CHANGELOG.md with a short note under Unreleased
- Open a PR with a clear description, testing steps, and link to relevant docs

If in doubt, open an issue first.
