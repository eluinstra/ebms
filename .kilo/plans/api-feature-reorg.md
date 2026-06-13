# Plan: Reorganize API package by feature

## Goal

Restructure `nl.clockwork.ebms.api` so classes are grouped by business feature rather than by transport or implementation detail. The reorganization should preserve existing public SOAP/REST behavior and Java package APIs where possible, while making future feature additions and tests easier to navigate.

## Current state

The API package currently mixes feature boundaries, transport adapters, models, repositories, validation, and configuration:

- `nl.clockwork.ebms.api.ebms`
  - SOAP interfaces: `EbMSController`, `EbMSControllerMTOM`
  - SOAP implementation wrappers: `EbMSControllerImpl`, `EbMSControllerMTOMImpl`
  - REST resource: `EbMSRestController`
  - Core handler/service logic: `EbMSControllerHandler`
  - Configuration: `EbMSControllerConfig`
  - Exceptions: `NotFoundException`, `EbMSControllerException`
  - Validator: `MessagePropertiesValidator`
  - Data access contract: `EbMSDAO`
  - Models: `nl.clockwork.ebms.api.ebms.model.*`
- `nl.clockwork.ebms.api.cpa`
  - SOAP interface and implementation: `CPAController`, `CPAControllerImpl`
  - REST resource: `CPARestController`
  - Configuration: `CPAControllerConfig`
  - Exceptions: `BadRequestException`, `CPAControllerException`, `CPANotFoundException`
  - Validator: `CPAValidator`
  - Repository: `CPARepository`
- `nl.clockwork.ebms.api.cpa.url`
  - SOAP interface and implementation: `URLMappingController`, `URLMappingControllerImpl`
  - REST resource: `URLMappingRestController`
  - Configuration: `URLMappingControllerConfig`
  - Exceptions: `URLMappingControllerException`, `URLNotFoundException`
  - Repository: `URLMappingRepository`
- `nl.clockwork.ebms.api.cpa.certificate`
  - SOAP interface and implementation: `CertificateMappingController`, `CertificateMappingControllerImpl`
  - REST resource: `CertificateMappingRestController`
  - Configuration: `CertificateMappingControllerConfig`
  - Exceptions: `CertificateMappingControllerException`, `CertificateNotFoundException`
  - Repository: `CertificateMappingRepository`
  - API model: `CertificateMapping`
- Shared REST error mapping: `nl.clockwork.ebms.api.WithController`

The existing API is exposed through both SOAP and REST in `EmbeddedWebConfig` in both `ebms-admin` and `ebms-core/server`:

- SOAP: `/cpa`, `/urlMapping`, `/certificateMapping`, `/ebms`, `/ebmsMTOM`
- REST: `/rest/v19/cpas`, `/rest/v19/urlMappings`, `/rest/v19/certificateMappings`, `/rest/v19/ebms`

## Proposed package structure

Use feature-first packages under `nl.clockwork.ebms.api`, with transport-specific subpackages inside each feature.

### Suggested layout

```text
nl.clockwork.ebms.api
├── shared
│   ├── WithController.java
│   └── Error.java
├── ebms
│   ├── EbMSControllerConfig.java
│   ├── soap
│   │   ├── EbMSController.java
│   │   ├── EbMSControllerImpl.java
│   │   ├── EbMSControllerMTOM.java
│   │   ├── EbMSControllerMTOMImpl.java
│   │   ├── EbMSControllerException.java
│   │   └── NotFoundException.java
│   ├── rest
│   │   └── EbMSRestController.java
│   ├── service
│   │   ├── EbMSControllerHandler.java
│   │   └── MessagePropertiesValidator.java
│   ├── repository
│   │   └── EbMSDAO.java
│   └── model
│       ├── Message.java
│       ├── MessageEvent.java
│       ├── MessageFilter.java
│       ├── MessageMapper.java
│       ├── MessageProperties.java
│       ├── MessageRequest.java
│       ├── MessageRequestProperties.java
│       ├── MessageStatus.java
│       ├── Party.java
│       ├── DataSource.java
│       ├── MTOMDataSource.java
│       ├── MTOMMessage.java
│       └── MTOMMessageRequest.java
├── cpa
│   ├── CPAControllerConfig.java
│   ├── soap
│   │   ├── CPAController.java
│   │   ├── CPAControllerImpl.java
│   │   ├── CPAControllerException.java
│   │   └── CPANotFoundException.java
│   ├── rest
│   │   └── CPARestController.java
│   ├── service
│   │   └── CPAValidator.java
│   ├── repository
│   │   └── CPARepository.java
│   └── BadRequestException.java
├── cpa-url
│   ├── URLMappingControllerConfig.java
│   ├── soap
│   │   ├── URLMappingController.java
│   │   ├── URLMappingControllerImpl.java
│   │   ├── URLMappingControllerException.java
│   │   └── URLNotFoundException.java
│   ├── rest
│   │   └── URLMappingRestController.java
│   └── repository
│       └── URLMappingRepository.java
└── cpa-certificate
    ├── CertificateMappingControllerConfig.java
    ├── soap
    │   ├── CertificateMappingController.java
    │   ├── CertificateMappingControllerImpl.java
    │   ├── CertificateMappingControllerException.java
    │   └── CertificateNotFoundException.java
    ├── rest
    │   └── CertificateMappingRestController.java
    ├── repository
    │   └── CertificateMappingRepository.java
    └── CertificateMapping.java
```

### Package naming note

Prefer hyphenated feature package names such as `cpa-url` and `cpa-certificate` only if the project is comfortable with Java package names containing hyphens. Java package identifiers normally use underscores or words, so the safer alternative is:

```text
nl.clockwork.ebms.api.cpaurL
nl.clockwork.ebms.api.cpacertificate
```

However, those names are less readable. If keeping the existing `nl.clockwork.ebms.api.cpa.url` and `nl.clockwork.ebms.api.cpa.certificate` namespaces is important for compatibility, the reorganization can still be feature-first by moving transport/service/repository/model classes into subpackages while preserving the root feature names:

```text
nl.clockwork.ebms.api.cpa
├── CPAControllerConfig.java
├── soap
├── rest
├── service
├── repository
└── BadRequestException.java

nl.clockwork.ebms.api.cpa.url
├── URLMappingControllerConfig.java
├── soap
├── rest
└── repository

nl.clockwork.ebms.api.cpa.certificate
├── CertificateMappingControllerConfig.java
├── soap
├── rest
├── repository
└── CertificateMapping.java
```

## Recommended migration approach

1. **Inventory public API consumers**
   - Search all imports of `nl.clockwork.ebms.api.*`.
   - Pay special attention to:
     - `ebms-admin` web UI classes
     - `ebms-core/server` embedded web configuration
     - `common` classes that depend on `api.ebms.model.*`
     - test utilities and integration tests
   - Confirm whether any external consumers rely on current package names.

2. **Move classes into feature subpackages**
   - Move SOAP interfaces and implementations into `soap`.
   - Move REST resources into `rest`.
   - Move validators and handlers into `service`.
   - Move repositories/DAOs into `repository`.
   - Move exception types into the owning feature or feature `soap` package if they are SOAP fault types.

3. **Update imports and package declarations**
   - Update Java imports across `ebms-core`, `ebms-admin`, and tests.
   - Update package declarations for moved classes.
   - Keep class names unchanged to reduce churn.

4. **Update Spring/CXF configuration**
   - Update `EbMSControllerConfig`, `CPAControllerConfig`, `URLMappingControllerConfig`, and `CertificateMappingControllerConfig` after moves.
   - Update `EmbeddedWebConfig` in:
     - `ebms-admin/src/main/java/nl/clockwork/ebms/admin/web/EmbeddedWebConfig.java`
     - `ebms-core/server/src/main/java/nl/clockwork/ebms/server/embedded/web/EmbeddedWebConfig.java`

5. **Update tests and test utilities**
   - Move or update test classes under `src/test/java/nl/clockwork/ebms/api`.
   - Preserve existing test behavior for SOAP and REST integration tests.
   - Add focused package-structure tests only if the team wants to prevent future drift.

6. **Update generated API specs and documentation if affected**
   - Existing REST specs are split by feature:
     - `ebms-core/core/resources/api/rest/ebms.json`
     - `ebms-core/core/resources/api/rest/cpas.json`
     - `ebms-core/core/resources/api/rest/urlMappings.json`
     - `ebms-core/core/resources/api/rest/certificateMappings.json`
   - If package names appear in docs or generated spec metadata, update them.
   - Otherwise, no user-facing API behavior should change.

7. **Run verification**
   - Compile the affected modules.
   - Run core tests for the API package.
   - Run admin/server compile/tests if imports changed there.
   - Verify REST/SOAP endpoint paths remain unchanged.

## Risk areas

- `nl.clockwork.ebms.api.ebms.model.*` is imported outside the API package by common DAO/message factory code and admin UI code. Moving these models will require broad import updates.
- `WithController` is shared by REST controllers and admin REST code. Moving it to `shared` will require updating imports but should not change behavior.
- SOAP exception classes are annotated with `@WebFault`; moving them can affect generated fault names only if package metadata or WSDL generation is sensitive to package names. Keep class names and annotations unchanged.
- Existing tests and docs reference the current package paths. Internal tests should be updated; external docs may need compatibility notes if old package names are removed.

## Acceptance criteria

- All API classes are grouped by feature.
- SOAP, REST, service, repository, model, exception, and config responsibilities are separated within each feature.
- Existing SOAP and REST endpoint paths remain unchanged.
- Existing public Java class names remain unchanged unless compatibility wrappers are intentionally added.
- All Java imports compile after the move.
- Existing API integration tests pass or are updated with equivalent coverage.

## Potential improvements for WithController

Looking at the current `WithController` interface, here are specific improvements to consider:

1. **Centralize exception mapping** - Currently in `WithController`, the `toWebApplicationException` method uses Vavr's `Match` to map exceptions to HTTP responses. This could be moved to a dedicated `ExceptionMapper` utility to:
   - Reduce coupling between REST controllers and exception types
   - Allow exception mappings to be updated independently of controller interfaces
   - Support multiple response content types more cleanly

2. **Add MTOM support notification** - The MTOM message operations (`getMessageMTOM`, `sendMessageMTOM`) use `multipart/form-data`. Consider adding a method to determine if a given endpoint supports MTOM, or adding a constant to indicate MTOM capability.

3. **Add consistent error response structure** - The current `Error` class is a simple value object but the error response body could be standardized to include:
   - `type` / `code` field for machine-readable error identification
   - `timestamp` for request correlation
   - `path` for REST endpoint identification
   - `debugId` for logging correlation

4. **Consider moving to a base class** - Since REST controllers (like `EbMSRestController`, `CPARestController`) currently implement `WithController`, consider whether `WithController` should be a `@Default` interface (Java 8+) or a base abstract class to provide more default behavior while allowing feature-specific overrides.

5. **Remove dependency on Vavr** - The current implementation uses Vavr's pattern matching API. Consider replacing with Java's `instanceof` pattern matching (available in Java 16+) for simpler, more standard code:
   ```java
   default WebApplicationException toWebApplicationException(Exception exception, String responseType) {
     if (exception instanceof NotFoundException) {
       return new WebApplicationException(Response.status(NOT_FOUND).type(responseType).build());
     }
     if (exception instanceof CPANotFoundException) {
       return new WebApplicationException(Response.status(NOT_FOUND).type(responseType).build());
     }
     // ... etc
   }
   ```
