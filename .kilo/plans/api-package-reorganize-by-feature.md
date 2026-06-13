# API Package Reorganization Plan

## Current State

The API package structure is organized by technical concerns:
- `nl.clockwork.ebms.api.ebms` - Message processing (14 files)
- `nl.clockwork.ebms.api.cpa` - CPA management (15 files)
- `nl.clockwork.ebms.api.cpa.url` - URL mapping (8 files)
- `nl.clockwork.ebms.api.cpa.certificate` - Certificate mapping (8 files)

## Goal

Reorganize by **feature** (use case-driven) instead of technical layers. Each feature should contain all layers (REST, SOAP, models, exceptions, config) needed to support that feature.

## Proposed Structure

```
nl.clockwork.ebms.api/
├── ebms/                      # EbMS messaging feature (16 files)
│   ├── soap/                  # SOAP/WS-* implementations
│   │   ├── EbMSController.java
│   │   ├── EbMSControllerImpl.java
│   │   ├── EbMSControllerMTOM.java
│   │   ├── EbMSControllerMTOMImpl.java
│   │   └── EbMSControllerConfig.java
│   ├── rest/                  # REST API implementations
│   │   ├── EbMSRestController.java
│   │   └── EbMSControllerHandler.java
│   ├── model/                 # Message-related DTOs and models
│   │   ├── Message.java
│   │   ├── MessageRequest.java
│   │   ├── MessageProperties.java
│   │   ├── MessageRequestProperties.java
│   │   ├── Party.java
│   │   ├── MessageFilter.java
│   │   ├── MessageEvent.java
│   │   ├── MessageStatus.java
│   │   ├── MTOMMessage.java
│   │   ├── MTOMMessageRequest.java
│   │   ├── DataSource.java
│   │   ├── MTOMDataSource.java
│   │   ├── MessageMapper.java
│   │   └── model package README
│   ├── exception/             # EbMS-related exceptions
│   │   ├── EbMSControllerException.java
│   │   └── NotFoundException.java
│   ├── validator/             # Validation logic
│   │   └── MessagePropertiesValidator.java (stays in api.ebms package)
│   └── dao/                   # Data access interfaces
│       ├── EbMSDAO.java
│       └── dao package README
│
├── cpa/                       # CPA management feature (13 files)
│   ├── soap/
│   │   ├── CPAController.java
│   │   ├── CPAControllerImpl.java
│   │   └── CPAControllerConfig.java
│   ├── rest/
│   │   └── CPARestController.java
│   ├── exception/
│   │   ├── CPAControllerException.java
│   │   ├── CPANotFoundException.java
│   │   └── BadRequestException.java
│   ├── repository/            # Repository interfaces (KEEP api.cpa.CPARepository)
│   │   └── CPARepository.java
│   ├── validator/             # Validation logic (KEEP in api.cpa package)
│   │   └── CPAValidator.java
│   └── cpa package README
│
├── url/                       # URL mapping feature (8 files)
│   ├── soap/
│   │   ├── URLMappingController.java
│   │   ├── URLMappingControllerImpl.java
│   │   └── URLMappingControllerConfig.java
│   ├── rest/
│   │   └── URLMappingRestController.java
│   ├── exception/
│   │   ├── URLMappingControllerException.java
│   │   └── URLNotFoundException.java
│   └── repository/            # Repository interfaces (KEEP api.cpa.url.URLMappingRepository)
│       └── URLMappingRepository.java
│
└── certificate/               # Certificate mapping feature (8 files)
    ├── soap/
    │   ├── CertificateMappingController.java
    │   ├── CertificateMappingControllerImpl.java
    │   └── CertificateMappingControllerConfig.java
    ├── rest/
    │   └── CertificateMappingRestController.java
    ├── exception/
    │   ├── CertificateMappingControllerException.java
    │   └── CertificateNotFoundException.java
    └── repository/            # Repository interfaces (KEEP api.cpa.certificate.CertificateMappingRepository)
        └── CertificateMappingRepository.java
```

### Keystructural Decisions

1. **KEEP Repository Interfaces in API Package**
   - `api.cpa.CPARepository` stays - defines API contract
   - `api.cpa.url.URLMappingRepository` stays - defines API contract
   - `api.cpa.certificate.CertificateMappingRepository` stays - defines API contract
   - `api.ebms.EbMSDAO` stays - API-specific DAO methods

2. **KEEP Validator Interfaces in API Package**
   - `CPAValidator.java` - validation logic specific to API layer
   - `MessagePropertiesValidator.java` - request validation for API

3. **DO NOT MOVE External Types**
   - `CollaborationProtocolAgreement` - external schema, used by API and common
nl.clockwork.ebms.api/
├── ebms/                      # EbMS messaging feature
│   ├── soap/                  # SOAP/WS-* implementations
│   │   ├── EbMSController.java
│   │   ├── EbMSControllerImpl.java
│   │   ├── EbMSControllerMTOM.java
│   │   ├── EbMSControllerMTOMImpl.java
│   │   └── EbMSControllerConfig.java
│   ├── rest/                  # REST API implementations
│   │   ├── EbMSRestController.java
│   │   └──EbMSControllerHandler.java
│   ├── model/                 # Message-related DTOs and models
│   │   ├── Message.java
│   │   ├── MessageRequest.java
│   │   ├── MessageProperties.java
│   │   ├── MessageRequestProperties.java
│   │   ├── Party.java
│   │   ├── MessageFilter.java
│   │   ├── MessageEvent.java
│   │   ├── MessageStatus.java
│   │   ├── MTOMMessage.java
│   │   ├── MTOMMessageRequest.java
│   │   ├── DataSource.java
│   │   ├── MTOMDataSource.java
│   │   ├── MessageMapper.java
│   │   └── model package README
│   ├── exception/             # EbMS-related exceptions
│   │   ├── EbMSControllerException.java
│   │   └── NotFoundException.java
│   └── dao/                   # Data access interfaces
│       ├── EbMSDAO.java
│       └── dao package README
│
├── cpa/                       # CPA management feature
│   ├── soap/
│   │   ├── CPAController.java
│   │   ├── CPAControllerImpl.java
│   │   └── CPAControllerConfig.java
│   ├── rest/
│   │   └── CPARestController.java
│   ├── model/                 # CPA-related DTOs
│   │   ├── CollaborationProtocolAgreement.java (external schema)
│   │   └── model package README
│   ├── exception/
│   │   ├── CPAControllerException.java
│   │   ├── CPANotFoundException.java
│   │   └── BadRequestException.java
│   ├── repository/            # Repository interfaces
│   │   └── CPARepository.java
│   ├── validator/             # Validation logic
│   │   └── CPAValidator.java
│   └── cpa package README
│
├── url/                       # URL mapping feature
│   ├── soap/
│   │   ├── URLMappingController.java
│   │   ├── URLMappingControllerImpl.java
│   │   └── URLMappingControllerConfig.java
│   ├── rest/
│   │   └── URLMappingRestController.java
│   ├── model/                 # URL mapping DTOs
│   │   └── URLMapping.java
│   ├── exception/
│   │   ├── URLMappingControllerException.java
│   │   └── URLNotFoundException.java
│   └── repository/
│       └── URLMappingRepository.java
│
└── certificate/               # Certificate mapping feature
    ├── soap/
    │   ├── CertificateMappingController.java
    │   ├── CertificateMappingControllerImpl.java
    │   └── CertificateMappingControllerConfig.java
    ├── rest/
    │   └── CertificateMappingRestController.java
    ├── model/                 # Certificate mapping DTOs
    │   └── CertificateMapping.java
    ├── exception/
    │   ├── CertificateMappingControllerException.java
    │   └── CertificateNotFoundException.java
    └── repository/
        └── CertificateMappingRepository.java
```

## Benefits

1. **Feature Focus**: Developers can find all components for a feature in one place
2. **Reduced Navigation**: Change URL mapping? All related files in `api/url/`
3. **Clear Boundaries**: Each feature is self-contained with minimal cross-feature dependencies
4. **Better Organization**: Follows domain-driven design principles
5. **Easier Testing**: Feature-level test organization matches feature structure

## Migration Steps

### Phase 1: Create New Structure
1. Create new directories: `api/ebms`, `api/cpa`, `api/url`, `api/certificate`
2. Create subdirectories: `soap`, `rest`, `model`, `exception`, `repository`, `validator`, `dao`

## Impact Analysis

### Files To Be Moved (42 total - NOT 45)

**ebms feature: 16 files**
- `EbMSController.java` → `api/ebms/soap/`
- `EbMSControllerImpl.java` → `api/ebms/soap/`
- `EbMSControllerMTOM.java` → `api/ebms/soap/`
- `EbMSControllerMTOMImpl.java` → `api/ebms/soap/`
- `EbMSControllerConfig.java` → `api/ebms/soap/`
- `EbMSRestController.java` → `api/ebms/rest/`
- `EbMSControllerHandler.java` → `api/ebms/rest/`
- `EbMSDAO.java` → `api/ebms/dao/` (KEEP api.ebms.EbMSDAO)
- `MessagePropertiesValidator.java` → `api/ebms/` (stays in api.ebms as validator)
- `NotFoundException.java` → `api/ebms/exception/`
- `EbMSControllerException.java` → `api/ebms/exception/`
- Models (11 files): All move to `api/ebms/model/`

**cpa feature: 13 files**
- `CPAController.java` → `api/cpa/soap/`
- `CPAControllerImpl.java` → `api/cpa/soap/`
- `CPAControllerConfig.java` → `api/cpa/soap/`
- `CPARestController.java` → `api/cpa/rest/`
- `CPAValidator.java` → `api/cpa/` (stays in api.cpa as validator)
- `CPARepository.java` → `api/cpa/repository/` (KEEP api.cpa.CPARepository)
- `CPAControllerException.java` → `api/cpa/exception/`
- `CPANotFoundException.java` → `api/cpa/exception/`
- `BadRequestException.java` → `api/cpa/exception/`
- `CollaborationProtocolAgreement` - EXTERNAL, DO NOT MOVE
- Models: 0 additional models (CPA is external)

**url feature: 8 files**
- `URLMappingController.java` → `api/url/soap/`
- `URLMappingControllerImpl.java` → `api/url/soap/`
- `URLMappingControllerConfig.java` → `api/url/soap/`
- `URLMappingRestController.java` → `api/url/rest/`
- `URLMappingRepository.java` → `api/url/repository/` (KEEP api.cpa.url.URLMappingRepository)
- `URLMappingControllerException.java` → `api/url/exception/`
- `URLNotFoundException.java` → `api/url/exception/`
- Model: 0 additional models (uses common.cpa.url.URLMapping)

**certificate feature: 8 files**
- `CertificateMappingController.java` → `api/certificate/soap/`
- `CertificateMappingControllerImpl.java` → `api/certificate/soap/`
- `CertificateMappingControllerConfig.java` → `api/certificate/soap/`
- `CertificateMappingRestController.java` → `api/certificate/rest/`
- `CertificateMappingRepository.java` → `api/certificate/repository/` (KEEP api.cpa.certificate.CertificateMappingRepository)
- `CertificateMappingControllerException.java` → `api/certificate/exception/`
- `CertificateNotFoundException.java` → `api/certificate/exception/`
- Model: 0 additional models (uses common.cpa.certificate.CertificateMapping)

### Dependent Files (Need Import Updates) - 180+ import statements

**Core Module (ebms-core/core)**:
- `EbMSDAOImpl.java` - imports 11 API models, implements `api.ebms.EbMSDAO`
- `EbMSMessageFactory.java` - imports 6 API models
- `MessagePropertiesValidator.java` - imports 1 API model, uses `common.cpa.CPAManager`

**Admin Module (ebms-admin)**:
- `EmbeddedWebConfig.java` - imports 9 API controllers
- `WithMessageFilter.java` - imports 1 API model
- 25+ web service classes importing API controllers/models

**Server Module (ebms-core/server)**:
- `EmbeddedAppConfig.java` - imports 4 API config classes

**Test Files (ebms-core/core/src/test)**:
- `SigningTest.java` - imports 4 API models
- `EncryptionTest.java` - imports 4 API models
- 9 test files in `api/` package structure

**Other Modules**:
- Any plugin modules that reference API

**Total**: ~180 import statements across 40+ files need updates

### Breaking Changes

### Package Structure Changes
- `nl.clockwork.ebms.api.ebms.*` → `nl.clockwork.ebms.api.ebms.soap.*`, `nl.clockwork.ebms.api.ebms.rest.*`, etc.
- `nl.clockwork.ebms.api.cpa.*` → `nl.clockwork.ebms.api.cpa.soap.*`, `nl.clockwork.ebms.api.cpa.rest.*`, etc.
- `nl.clockwork.ebms.api.cpa.url.*` → `nl.clockwork.ebms.api.url.*`
- `nl.clockwork.ebms.api.cpa.certificate.*` → `nl.clockwork.ebms.api.certificate.*`

### Exceptions (All Stay in API Layer)
- `EbMSControllerException` → `nl.clockwork.ebms.api.ebms.exception.*`
- `NotFoundException` → `nl.clockwork.ebms.api.ebms.exception.*`
- `CPAControllerException` → `nl.clockwork.ebms.api.cpa.exception.*`
- `CPANotFoundException` → `nl.clockwork.ebms.api.cpa.exception.*`
- `BadRequestException` → `nl.clockwork.ebms.api.cpa.exception.*`
- `URLMappingControllerException` → `nl.clockwork.ebms.api.url.exception.*`
- `URLNotFoundException` → `nl.clockwork.ebms.api.url.exception.*`
- `CertificateMappingControllerException` → `nl.clockwork.ebms.api.certificate.exception.*`
- `CertificateNotFoundException` → `nl.clockwork.ebms.api.certificate.exception.*`

### Maintained (DO NOT CHANGE)
- **WSDL Endpoint Names**: SOAP `@WebService` annotations remain unchanged
  - `EbMSMessageService` → endpoint stays at `/service/ebms`
  - `CPAService` → endpoint stays at `/cpa`
  - `UrlMappingService` → endpoint stays at `/urlMapping`
  - `CertificateMappingService` → endpoint stays at `/certificateMapping`
- **External Types**: `CollaborationProtocolAgreement` remains in `org.oasis_open.committees.ebxml_cppa.schema.cpp_cpa_2_0`
- **Repository Interfaces**: `api.cpa.CPARepository`, `api.cpa.url.URLMappingRepository`, `api.cpa.certificate.CertificateMappingRepository` stay in API packages
- **Validator Classes**: `CPAValidator`, `MessagePropertiesValidator` stay in API packages

## Dependencies

### Repository Interface Architecture (Critical Finding)

**Each feature has TWO repository interfaces - one in API, one in common:**

| Feature | API Repository (in api/*) | Common Repository (in common/*) | Usage |
|---------|---------------------------|---------------------------------|-------|
| CPA | `api.cpa.CPARepository` | `common.cpa.CPARepository` | API: Full CRUD; Common: Minimal (exists/get) |
| URL | `api.cpa.url.URLMappingRepository` | `common.cpa.url.URLMappingRepository` | API: Full CRUD; Common: Simple get |
| Certificate | `api.cpa.certificate.CertificateMappingRepository` | `common.cpa.certificate.CertificateMappingRepository` | API: Full CRUD; Common: Simple get |
| EbMS | `api.ebms.EbMSDAO` | `common.dao.EbMSDAO` | API: API-boundary; Common: Core persistence |

**Migration Rule**: 
- Keep ** BOTH ** repository interfaces in their current packages - do NOT move them
- API repository interfaces define the contract for the REST/SOAP layer
- Common repository interfaces are used by domain services (CPAManager, etc.)
- Both coexist and serve different purposes

### Model Classes

#### Party Model Conflict (Already Documented)
- `nl.clockwork.ebms.api.ebms.model.Party` - API DTO used by EbMSController
- `nl.clockwork.ebms.common.model.Party` - Domain model used internally
- **Action**: Keep both - API version is authoritative for API boundaries

#### CertificateMapping DTO
- `nl.clockwork.ebms.api.cpa.certificate.CertificateMapping` - API DTO with base64 strings AND conversion methods
- `nl.clockwork.ebms.common.cpa.certificate.CertificateMapping` - Domain model with X509Certificate
- **Action**: Keep both - API version handles serialization, common version handles domain logic

#### CPA (CollaborationProtocolAgreement)
- FROM external schema: `org.oasis_open.committees.ebxml_cppa.schema.cpp_cpa_2_0.CollaborationProtocolAgreement`
- **Action**: Do NOT move - external type used across multiple packages

### External Package Dependencies (Updated)
- `nl.clockwork.ebms.common.cpa` - CPA domain services (CPAManager, CPAUtils, CPARepositoryImpl) - KEEP
- `nl.clockwork.ebms.common.cpa.url` - URL domain services - KEEP
- `nl.clockwork.ebms.common.cpa.certificate` - Certificate domain services - KEEP
- `nl.clockwork.ebms.common.dao` - Core EbMSDAO interface - KEEP (api.ebms.EbMSDAO also exists there)
- `nl.clockwork.ebms.common.model` - Shared models like Party - KEEP

### Cross-Feature Dependencies
- `CPAManager` - Depends on common.cpa.CPARepository, used by MessagePropertiesValidator
- `MessagePropertiesValidator` - Uses CPAManager and common.model.Party
- `CollaborationProtocolAgreement` - External schema type used across cp, url, certificate features
- **Action**: Keep these in their current locations - they're domain services, not API layer

## Recommendations

### Keep in Common Package (Domain Layer)
- `Party` in `nl.clockwork.ebms.common.model` - Domain model, shared across features
- `CPAManager` in `nl.clockwork.ebms.common.cpa` - Domain service, uses common repository
- `CollaborationProtocolAgreement` - External schema type, used by both API and common

### Keep in API Package (API Layer)
- **Repository Interfaces**: Define the API contract
  - `api.cpa.CPARepository` - Full CRUD operations
  - `api.cpa.url.URLMappingRepository` - Full CRUD operations
  - `api.cpa.certificate.CertificateMappingRepository` - Full CRUD operations
  - `api.ebms.EbMSDAO` - API-specific DAO methods

- **Validator Classes**: Validation logic specific to API layer
  - `api.cpa.CPAValidator` - Validates CPA XML against schema and business rules
  - `api.ebms.MessagePropertiesValidator` - Validates message request properties

- **Model DTOs**: Data transfer objects for API boundaries
  - All models in `api.ebms.model` - Message-related DTOs
  - `Common` models should NOT be in API layer

### Do NOT Move
- External schema types (from `org.oasis_open.committees.ebxml_cppa.schema.cpp_cpa_2_0`)
- Common repository implementations (in `common.cpa` package)
- Common domain services (`CPAManager`, `CPAUtils`, etc.)

### Staged Rollout Strategy
1. Phase 1: Create new directory structure without moving files
2. Phase 2: Create "redirect" packages that import from new locations
3. Phase 3: Update all import statements across codebase
4. Phase 4: Remove old packages (after all consumers updated)
5. Phase 5: Cleanup redirect packages

## Estimated Effort

- Migration: 2-3 developer days
- Testing: 1-2 developer days
- Documentation: 0.5-1 developer day

## Success Criteria

- [ ] All files migrated successfully
- [ ] All tests pass
- [ ] Build succeeds with no warnings
- [ ] Import statements updated across codebase
- [ ] Package README files created
- [ ] No circular dependencies introduced
