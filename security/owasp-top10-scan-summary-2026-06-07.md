## OWASP Top 10 Scan Summary (2026-06-07)

### Scope

- Java projects scanned:
  - ebms-core
  - ebms-admin

### Dependency Vulnerability Status

- ebms-core dependency-check result: NONE: 0
- ebms-admin dependency-check result: NONE: 0 (with configured suppression)

### Code-Level Security Hotspots (Top 10-Oriented)

- A02 Cryptographic Failures:
  - MD5 use in authentication/password handling paths
- A03 Injection:
  - Direct SQL script execution utility path
- A07 Identification and Authentication Failures:
  - Legacy/plain password validation fallback behavior
- A10 Server-Side Request Forgery:
  - URL connectivity check over user-provided URI

### Existing Defensive Controls

- XML parser hardening against XXE is present in DOM and SAX utility code.

### Reference Artifacts

- ebms-core HTML report: `ebms-core/target/dependency-check-report.html`
- ebms-admin HTML report: `ebms-admin/target/dependency-check-report.html`
- Script for repeatable scans: `security/run-security-scans.sh`
