# EbMS Core Reorganization Plan - Preserve API/Client/Server Layers

## Current State Analysis

The `ebms-core` module is organized using a **layer-based architecture**:
- `api/` - REST/Soap API endpoints (interface to clients)
- `client/` - EbMS client functionality (communicates with server)
- `server/` - EbMS server functionality (receives messages from clients)
- `common/` - Shared utilities and models (util, model, protocol, cpa, security, etc.)

## Guidance: Preserve API/Client/Server Structure

The user has requested that the `api`, `client`, and `server` packages remain intact as they represent the main functional boundaries:
- **API** = Interface layer (REST/Soap controllers)
- **Client** = Outbound communication (sends messages to other EbMS servers)
- **Server** = Inbound communication (receives messages from other EbMS clients)

## Revised Target: Feature-Based Within Layers

Organize code **within each layer** in a feature-based manner:

```
nl.clockwork.ebms/
├── api/               # Interface layer (unchanged structure)
│   ├── ebms/          # EbMS API (REST/Soap endpoints)
│   ├── cpa/           # CPA API (REST/Soap endpoints)
│   ├── certificate/   # Certificate API (REST/Soap endpoints)
│   ├── url/           # URL mapping API
│   └── exception/     # Exception mappers
│
├── client/            # Client layer (unchanged structure)
│   ├── api/           # Client APIs (EbMSClient, DeliveryManager)
│   ├── sync/          # Synchronous client operations
│   ├── async/         # Asynchronous delivery task handling
│   └── transport/     # Transport mechanisms (HTTP, SSL)
│       ├── http/      # HTTP transport
│       └── ssl/       # SSL configuration
│
├── server/            # Server layer (unchanged structure)
│   ├── config/        # Server configuration
│   ├── http/          # HTTP handlers
│   ├── model/         # Server-side models
│   ├── processing/    # Message processing pipeline
│   ├── servlet/       # Servlet filters and handlers
│   ├── ssl/           # Server SSL configuration
│   └── validation/    # Message and CPA validation
│
└── common/            # Shared utilities (reorganized feature-based)
    ├── model/         # Data models (EbMSMessage, EbMSDocument, etc.)
    ├── protocol/      # EbMS protocol constants/enums (EbMSAction, EbMSMessageStatus)
    ├── message/       # Message creation/parsing utilities
    ├── cpa/           # CPA (Collaboration Protocol Agreement) functionality
    ├── security/      # Encryption, signing, validation
    ├── dao/           # Data access layer (interfaces + implementations)
    ├── event/         # Message event handling
    ├── cache/         # Caching utilities
    ├── transaction/   # Transaction management
    ├── util/          # Shared utilities (XSD validation, logging, DOM utils)
    ├── datasource/    # DataSource configuration
    ├── jaxb/          # JAXB configuration and utilities
    └── xml/           # XML-related utilities (dsig/, DOMUtils, etc.)
```

## Feature-Based Structure Details

### `common/` Reorganization

#### model/
- **Purpose**: Core domain models (value objects, entities)
- **Contents**: `EbMSMessage`, `EbMSDocument`, `EbMSAttachment`, `Party`, `EbMSMessageProperties`, etc.
- **Characteristics**: Pure data model classes, no business logic

#### protocol/
- **Purpose**: EbMS protocol constants, enums, and predicates
- **Contents**: `EbMSAction`, `EbMSMessageStatus`, `EbMSErrorCode`, `Constants`, `Predicates`
- **Characteristics**: Protocol-level definitions used across the codebase

#### message/
- **Purpose**: Message creation, parsing, and manipulation utilities
- **Contents**: `EbMSMessageBuilder`, `EbMSMessageFactory`, `EbMSMessageReader`, `EbMSMessageUtils`, `EbMSContentHandler`, `EbMSAttachmentFactory`, `EbMSIdGenerator`, `CommonConfig`
- **Characteristics**: Helper classes for working with messages

#### cpa/
- **Purpose**: CPA (Collaboration Protocol Agreement) management
- **Contents**: `CPAManager`, `CPARepository`, `CPARepositoryImpl`, `CPAQuery`, `CPAUtils`, `CPAConfig`
- **Characteristics**: CPA lookup and validation logic

#### security/
- **Purpose**: Security operations (encryption, signing, validation)
- **Contents**: `EbMSKeyStore`, `EbMSTrustStore`, `SigningConfig`, `EncryptionConfig`, `EbMSSignatureGenerator`, `EbMSSignatureValidator`, `EbMSMessageEncrypter`, `EbMSMessageDecrypter`, `StreamingXmlEncrypter`, `StreamingXmlDecrypter`, `KeyStoreConfig`, `DefaultKeyStoreConfig`, `KeyStoreUtils`, `KeyStoreType`
- **Characteristics**: Security-related functionality (shared by client and server)

#### dao/
- **Purpose**: Data access layer (database interaction)
- **Contents**: `EbMSDAO`, `EbMSDAOImpl`, `DAOConfig`, `WithMessageFilter`
- **Characteristics**: Database persistence layer (interface + implementation)

#### event/
- **Purpose**: Message event notification system
- **Contents**: `MessageEventListener`, `MessageEventDAO`, `MessageEventDAOImpl`, `DAOMessageEventListener`, `LoggingMessageEventListener`, `MessageEventListenerConfig`, `MessageEventListenerFilter`, `MessageEventListenerFilterProcessor`, `MessageEventException`, `MessageEventType`
- **Characteristics**: Event-driven notifications for message lifecycle

#### cache/
- **Purpose**: Caching utilities
- **Contents**: `CacheConfig`, `EbMSKeyGenerator`, `MessageHeaderKeyGenerator`
- **Characteristics**: Caching functionality (shared by client and server)

#### transaction/
- **Purpose**: Transaction management
- **Contents**: `TransactionManagerConfig`
- **Characteristics**: Spring transaction management configuration

#### util/
- **Purpose**: General-purpose utility classes
- **Contents**: `DOMUtils`, `StreamUtils`, `SecurityUtils`, `LoggingUtils`, `XSDValidator`, `ValidatorException`, `EbMSValidationException`, `ValidationException`
- **Characteristics**: Reusable utility methods

#### datasource/
- **Purpose**: DataSource configuration
- **Contents**: `DataSourceConfig`
- **Characteristics**: Database connection configuration

#### jaxb/
- **Purpose**: JAXB configuration and utilities
- **Contents**: (if any)
- **Characteristics**: XML binding utilities

#### xml/
- **Purpose**: XML-related utilities
- **Contents**: `dsig/EbMSAttachmentResolver`, `DOMUtils`
- **Characteristics**: XML processing helper classes

## Benefits of This Approach

1. **API/Client/Server remain as primary boundaries** - Clear separation of concerns
2. **Each layer organized by feature** - Easier to find related code within a layer
3. **Common is still common** - Shared code stays in common/ for reusability
4. **Gradual migration path** - Can reorganize common/ independently of API/Client/Server
5. **Backward compatible** - Less breaking changes to public APIs

## Migration Steps

### Phase 1: Reorganize common/ (Low Impact)
1. Create new structure in `common/`
2. Move files by functionality (model/, protocol/, message/, cpa/, security/, dao/, event/, cache/, transaction/, util/, datasource/)
3. Update internal imports within `common/`
4. Run tests to verify no regressions

### Phase 2: Verify API/Client/Server
1. Verify `api/`, `client/`, `server/` packages remain unchanged
2. Ensure all references to moved `common/` classes are correct
3. Run full test suite

### Phase 3: Document Structure
1. Update README with new structure
2. Add package-level documentation
3. Create architecture diagrams showing the three layers

## Dependencies Within common/

| Package | Depends On |
|---------|-----------|
| `security/` | `util/` (for utils), `model/` (for models) |
| `message/` | `model/` (for models), `xml/` (for DOM utils) |
| `cpa/` | `model/` (for models), `dao/` (for persistence) |
| `dao/` | `model/` (for models), `transaction/` (for transactions) |
| `event/` | `model/` (for models), `dao/` (for persistence) |
| `util/` | None (lowest level) |
| `protocol/` | None (lowest level - constants) |

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Moving common/ packages breaks API | Medium | Keep API/Client/Server structure frozen, only reorganize internal |
| Import statement updates | Medium | Use IDE refactoring tools for bulk updates |
| Tests fail | Medium | Run tests after each phase |

## Rollback Plan

- Keep original structure in git history
- Create `feature/restructure-common` branch
- Revert commit if issues detected
- No data migration needed

## Post-Migration Improvements

1. Consider introducing package documentation (`package-info.java`)
2. Add dependency rules in checkstyle/pmd
3. Create module boundary diagrams
4. Update developer onboarding guide

## File Count Summary (Approximate)

- `common/model/`: ~20 files
- `common/protocol/`: ~5 files
- `common/message/`: ~8 files
- `common/cpa/`: ~6 files
- `common/security/`: ~12 files
- `common/dao/`: ~4 files
- `common/event/`: ~10 files
- `common/cache/`: ~3 files
- `common/transaction/`: ~1 file
- `common/util/`: ~10 files
- `common/datasource/`: ~1 file
- `common/jaxb/`: ~1 file
- `common/xml/`: ~2 files (EbMSAttachmentResolver, DOMUtils)
- **Total in common/: ~85 files**

- `api/`: ~40 files (unchanged)
- `client/`: ~30 files (unchanged)
- `server/`: ~50 files (unchanged)
- **Total in API/Client/Server: ~120 files**

## Appendix A: Detailed Import Mapping

### Before/After Package Changes (common/)

| Old Package Path | New Package Path | Files Affected |
|------------------|------------------|----------------|
| `nl.clockwork.ebms.common.model.*` | `nl.clockwork.ebms.common.model.*` | ~20 files (no change - already correct) |
| `nl.clockwork.ebms.common.protocol.*` | `nl.clockwork.ebms.common.protocol.*` | ~5 files (no change - already correct) |
| `nl.clockwork.ebms.common.message.*` | `nl.clockwork.ebms.common.message.*` | ~8 files (no change - already correct) |
| `nl.clockwork.ebms.common.cpa.*` | `nl.clockwork.ebms.common.cpa.*` | ~10 files (no change - already correct) |
| `nl.clockwork.ebms.common.security.*` | `nl.clockwork.ebms.common.security.*` | ~12 files (no change - already correct) |
| `nl.clockwork.ebms.common.dao.*` | `nl.clockwork.ebms.common.dao.*` | ~4 files (no change - already correct) |
| `nl.clockwork.ebms.common.event.*` | `nl.clockwork.ebms.common.event.*` | ~10 files (no change - already correct) |
| `nl.clockwork.ebms.common.cache.*` | `nl.clockwork.ebms.common.cache.*` | ~3 files (no change - already correct) |
| `nl.clockwork.ebms.common.transaction.*` | `nl.clockwork.ebms.common.transaction.*` | ~1 file (no change - already correct) |
| `nl.clockwork.ebms.common.util.*` | `nl.clockwork.ebms.common.util.*` | ~10 files (no change - already correct) |
| `nl.clockwork.ebms.common.datasource.*` | `nl.clockwork.ebms.common.datasource.*` | ~1 file (no change - already correct) |
| `nl.clockwork.ebms.common.jaxb.*` | `nl.clockwork.ebms.common.jaxb.*` | 0 files (none found) |
| `nl.clockwork.ebms.common.xml.*` | `nl.clockwork.ebms.common.xml.*` | ~2 files (DOMUtils, dsig/EbMSAttachmentResolver) |

### Import Changes Required in Other Packages

| File Location | Old Import | New Import |
|--------------|------------|------------|
| `client/**/*.java` | `nl.clockwork.ebms.common.*` | Update as needed for moved packages |
| `server/**/*.java` | `nl.clockwork.ebms.common.*` | Update as needed for moved packages |
| `api/**/*.java` | `nl.clockwork.ebms.common.*` | Update as needed for moved packages |
