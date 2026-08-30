# Security Policy

## Supported versions

The currently supported release line of EbMS is **2.20.x** (current
development version: 2.20.9). Security fixes are applied to the supported
line and shipped via the release workflow described in
`CONTRIBUTING.md` ("Releasing a version").

| Version | Supported |
| ------- | --------- |
| 2.20.x  | Yes       |
| < 2.20  | No        |

## Reporting a vulnerability

**Please do not open a public issue for a security vulnerability.**

Report it through one of the following channels:

1. **Email** — Edwin Luinstra, `edwin.luinstra@soprasteria.com`
2. **Private issue** — if you prefer a ticket, open an issue in this
   repository and immediately edit the title/body to remove identifying
   details, noting in the first comment that it is a security report and
   should be treated as confidential. A maintainer will move it or reference
   it privately.

### What to include

- The affected version(s).
- A concise description of the vulnerability and its impact.
- A proof-of-concept or reproduction steps where possible.
- Any mitigation you have identified.

## What to expect

- We acknowledge receipt of a valid report as soon as practicable, and aim to
  respond within a few business days.
- We work to a fix on the supported line, then coordinate disclosure.
- After a fix is released we publish a note in the `CHANGELOG.md` and, where
  warranted, a CVE request with the relevant team.
- We credit reporters in the changelog unless they ask otherwise.

## Scope

This policy covers the code in this repository and the `ebms-core`,
`ebms-admin`, `ebms-docker`, and `ebms-perftest-setup` submodules that it
pins. It does not cover third-party software that EbMS depends on (e.g. the
JDK, Maven, or container base images); report those to their respective
maintainers.

## Automated scanning

Repeatable security scanning tooling lives under `security/`:

- `security/run-security-scans.sh` — OWASP Dependency-Check and SpotBugs.
- `security/README.md` — how to run the scans and where artifacts are written.

Dependency vulnerabilities found by these scans are tracked and addressed as
part of normal maintenance.

## Note on AI-assisted contributions

AI-assisted changes to security-relevant code (authentication, authorization,
cryptography, certificate handling, realm management) should be reviewed by a
maintainer before merge and validated against the checklist in
`CONTRIBUTING.md` ("AI-assisted changes checklist").
