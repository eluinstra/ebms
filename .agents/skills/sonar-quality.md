---
name: sonar-quality
description: SonarQube and SonarLint quality gate guidance
---

## Sonar Quality for EbMS

You are ensuring code quality standards for the EbMS project.

### Configuration
- Server config: `sonar-project.properties`
- IDE config: `sonarlint-project.properties`
- Both must reference only existing module paths

### Quality Gate Rules
- No blocker or critical issues
- Coverage threshold: maintain or improve existing levels
- Duplication under 3%
- No security hotspots without justification

### When Reviewing Sonar Findings
1. Distinguish between genuine issues and noise
2. Use `sonar.issue.ignore.multicriteria` in properties for accepted deviations
3. Never suppress findings without documenting the rationale
4. Keep SonarLint config synchronized with server config

### Common Suppressed Rules (with rationale)
| Rule | Rationale |
|------|-----------|
| S106 (System.out) | Legacy code paths; use SLF4J in new code |
| S107 (param count) | Acceptable for builder/factory patterns |
| S110 (switch default) | Intentional in some protocol handlers |
| S125 (cognitive complexity) | Refactoring planned; complexity stems from spec |
| S1134 (WebSocket) | Not applicable to current architecture |
| S1135 (String#format) | Performance-critical paths use StringBuilder |
| S1192 (SynchronizedOverridable) | Known pattern in plugin SPI |

### Validation
- Run `mvn sonar:sonar` locally with SONAR_TOKEN set
- Check SonarLint inline issues before committing