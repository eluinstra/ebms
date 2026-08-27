---
name: code-review
description: Code review guidelines for EbMS pull requests
---

## Code Review for EbMS

You are reviewing code changes for the EbMS project.

### Review Principles
1. **Scope**: Verify changes are limited to the stated purpose
2. **Impact**: Check downstream effects (core changes affect admin and plugins)
3. **Tests**: Ensure behavior changes include tests
4. **Style**: Follow existing patterns (Lombok, SLF4J, constructor injection)

### Critical Checks
- [ ] API changes in `ebms-core/core` have updated callers in `ebms-admin`
- [ ] Database changes update the correct plugin modules
- [ ] No hardcoded credentials or secrets
- [ ] Version/revision property unchanged (unless explicitly requested)
- [ ] Distribution management unchanged (requires maintainer approval)
- [ ] New dependencies added to the correct parent POM

### Review Checklist
```
- Behavior preserved for existing callers?
- Tests added/updated for changed code?
- Logging appropriate (no System.out, use @Slf4j)?
- Resources closed properly (try-with-resources)?
- Thread-safe where required?
- No circular dependencies introduced?
```

### What to Flag
- Missing null handling in public APIs
- Raw SQL without parameterization
- Missing JavaDoc on public methods
- Overly complex conditionals (>3 nesting levels)
- Duplicate logic across plugins
- Unchecked exceptions leaking from public APIs

### Validation Commands
Ask the author to confirm these passed:
- `mvn -f ebms-core/pom.xml -B verify` (core changes)
- `mvn -f ebms-admin/pom.xml -B verify` (admin changes)
- `mvn checkstyle:check` (style compliance)