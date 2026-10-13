# EbMS

EbMS is a Java 21 multi-module Maven project with core messaging modules,
an embedded SOAP/REST server (ebms-server), Docker examples, and performance
test scripts.

## Prerequisites

- Java 21
- Maven 3.9+
- Docker (optional, for examples and local SonarQube)
- Node.js (optional, for documentation site work)

## Repository layout

- ebms-core/ - Maven parent for common, core, server and plugin modules;
  ebms-core/server builds the ebms-server embedded SOAP/REST server (the
  successor of the former ebms-admin project)
- ebms-admin/ - retained legacy admin console, no longer built, tested or
  released by this repo's pipelines
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

Build and test the embedded server module (ebms-server, with its deps):

```sh
mvn -f ebms-core/pom.xml -B -pl server -am clean verify
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
- The embedded SOAP/REST server (ebms-core/server, artifact ebms-server) is
  part of the ebms-core reactor, so one build covers it together with common,
  core and the plugins. The retained ebms-admin/ checkout is legacy and is no
  longer built, tested or released by the CI/release pipelines.