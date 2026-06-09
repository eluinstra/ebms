# EbMS

EbMS is a Java 17 multi-module Maven project with core messaging modules,
an admin application, Docker examples, and performance test scripts.

## Prerequisites

- Java 17
- Maven 3.9+
- Docker (optional, for examples and local SonarQube)
- Node.js (optional, for documentation site work)

## Repository layout

- ebms-core/ - Maven parent for common, core and plugin modules
- ebms-admin/ - SOAP/REST server and web application
- ebms-docker/ - Docker and docker-compose based examples
- ebms-perftest-setup/ - scripts and assets for performance testing
- documentation/ - versioned project documentation site

## Quick start

Build all core modules:

```sh
mvn -f ebms-core/pom.xml -B clean install
```

Run all core tests:

```sh
mvn -f ebms-core/pom.xml -B verify
```

Build admin module (after core install):

```sh
mvn -f ebms-admin/pom.xml -B clean verify
```

## Common commands

Build a single module with dependencies:

```sh
mvn -f ebms-core/pom.xml -pl <module-path> -am -B package
```

Run quick local build without tests:

```sh
mvn -f ebms-core/pom.xml -B -DskipTests=true package
```

## AI and contributor guidance

- Repo-level AI guidance: .github/copilot-instructions.md
- Architecture and maintenance overview: AGENTS.md
- Contribution checklist: CONTRIBUTING.md

## Documentation

- Main project docs: documentation/
- Published docs: https://eluinstra.github.io/ebms-admin/

## Notes

- This repository uses a multi-module layout. Most work should target module
  pom files directly with -f to avoid confusion.
- ebms-admin depends on locally built artifacts from ebms-core. Install
  ebms-core first when building ebms-admin in a fresh environment.