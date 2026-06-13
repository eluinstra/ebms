# Plan: Reorganize Server Package by Feature

## Goal

Restructure `nl.clockwork.ebms.server` so classes are grouped by functional feature rather than by technical implementation layer (validation, processing, servlet, etc.). The reorganization should preserve existing public API behavior while making the codebase easier to navigate and extend.

## Current State

The server package is organized by technical layer across two modules:

### ebms-core/core (shared core module)

| Package | Classes | Description |
|---------|---------|-------------|
| `nl.clockwork.ebms.server` (root) | `EbMSServerConfig`, `SSLFactoryManager`, `EbMSHttpHandler`, `EbMSInputStreamHandler` | Base server configuration and HTTP handlers |
| `nl.clockwork.ebms.server.validation` | `EbMSMessageValidator`, `CPAValidator`, `SignatureValidator`, `MessageHeaderValidator`, `ManifestValidator`, `ClientCertificateValidator`, `ClientCertificateManager`, `DuplicateMessageException`, `ValidationConfig` | Message validation logic |
| `nl.clockwork.ebms.server.processor` | `EbMSMessageProcessor`, `AcknowledgmentProcessor`, `MessageErrorProcessor`, `StatusResponseProcessor`, `DuplicateMessageHandler`, `PongProcessor`, `EbMSProcessorException`, `EbMSProcessingException`, `EbMSProcessorConfig` | Message processing logic |
| `nl.clockwork.ebms.server.servlet` | `EbMSServlet`, `EbMSMessageServlet`, `BasicAuthenticationFilter`, `ClientCertificateAuthenticationFilter`, `ClientCertificateManagerFilter`, `UserRateLimiterFilter`, `EchoServletFilter`, `RemoteAddressMDCFilter`, `RateLimiterFilter`, `MDCServletFilter`, `HealthServlet` | Servlet and filter components |

### ebms-core/server (embedded server module - depends on core)

| Package | Classes | Description |
|---------|---------|-------------|
| `nl.clockwork.ebms.server.embedded` | `StartEmbedded`, `Start`, `EmbeddedAppConfig`, `DBConfig`, `DBClean`, `DBMigrate`, `DBExecute`, `EbMSKeyStore`, `RealmFileMigrator`, `CPAUtils`, `Constants`, `Utils`, `CustomErrorHandler`, `EbMSPropertySourcesPlaceholderConfigurer`, `SystemInterface` | Embedded server startup and configuration |
| `nl.clockwork.ebms.server.embedded.dao` | `EbMSDAO`, `EbMSDAOImpl`, `AdminDAOConfig`, `DataSourceConfig`, `WithMessageFilter` | Database access objects |
| `nl.clockwork.ebms.server.embedded.model` | `EbMSMessage`, `EbMSAttachment`, `CPA`, `DeliveryTask`, `DeliveryLog` | Embedded server data models |
| `nl.clockwork.ebms.server.embedded.web` | `EmbeddedWebConfig`, `ExtensionProvider`, `Utils` | REST configuration |
| `nl.clockwork.ebms.server.embedded.web.menu` | `MenuItem` | Web UI menu items |
| `nl.clockwork.ebms.server.embedded.web.admin` | `AdminRestController`, `MessageFilterQuery` | Admin REST API |
| `nl.clockwork.ebms.server.embedded.web.message` | `EbMSMessageFilter`, `TimeUnit` | Message query models |

## Core Processing Flow

Understanding the `processRequest` method flow (EbMSMessageProcessor line 170) reveals the server's architecture:

```
HttpRequest → EbMSMessageServlet/EbMSServlet
         → EbMSInputStreamHandler
         → EbMSHttpHandler
         → EbMSMessageProcessor.processRequest()
         → dispatched to specialized processors:
            - AcknowledgmentProcessor (for EbMSAcknowledgment)
            - MessageErrorProcessor (for EbMSMessageError)
            - StatusResponseProcessor (for EbMSStatusResponse)
            - PongProcessor (for EbMSPong)
            - or main message processing flow
```

Current structure obscures this flow by grouping by technology rather than processing responsibility.

## Issues with Current Structure

1. **Technology-first grouping** - Related functionality is scattered (e.g., all validation logic is grouped, but it may relate to specific features)
2. **Large monolithic packages** - `processor` has 9 classes handling different message types
3. **Unclear feature boundaries** - It's difficult to understand what belongs to which feature
4. **Hard to find related code** - Changes to a feature require navigating multiple packages
5. **Obscures processing flow** - Request handling components are not grouped by their role in the processing pipeline

## Proposed Package Structure

```
nl.clockwork.ebms.server/
├── model/                              (NEW: Consolidate all model classes)
│   ├── core/                           (Core server models - move from embedded.model)
│   │   ├── EbMSMessage.java
│   │   ├── EbMSAttachment.java
│   │   ├── CPA.java
│   │   ├── DeliveryTask.java
│   │   └── DeliveryLog.java
│   └── embedded/                       (Embedded-only models)
│       └── web/                        (Move web models here)
│           ├── EbMSMessageFilter.java
│           ├── TimeUnit.java
│           ├── MessageFilterQuery.java
│           └── MenuItem.java
│
├── validation/                         (CURRENT: Keep separate for cross-feature validators)
│   ├──EbMSMessageValidator.java
│   ├── CPAValidator.java
│   ├── SignatureValidator.java
│   ├── MessageHeaderValidator.java
│   ├── ManifestValidator.java
│   ├── ClientCertificateValidator.java
│   ├── ClientCertificateManager.java
│   └── ValidationConfig.java
│
├── processing/                         (RENAME: from processor for clarity)
│   ├──EbMSMessageProcessor.java        (Main orchestrator)
│   ├── EbMSMessageProcessorConfig.java (RENAME: EbMSProcessorConfig →EbMSMessageProcessorConfig)
│   ├── EbMSProcessingException.java
│   ├── EbMSProcessorException.java
│   ├── acknowledgment/                 (NEW: subgroup by responsibility)
│   │   ├──AcknowledgmentProcessor.java
│   │   ├── EbMSMessageProcessor.java (moved acknowledgment logic here)
│   │   └── AcknowledgmentProcessorException.java (if needed)
│   ├── error/                          (NEW)
│   │   ├──MessageErrorProcessor.java
│   │   └── EbMSMessageProcessor.java (moved error handling here)
│   ├── status/                         (NEW)
│   │   ├── StatusResponseProcessor.java
│   │   └──EbMSMessageProcessor.java (moved status handling here)
│   ├── duplicate/                      (NEW)
│   │   ├── DuplicateMessageHandler.java
│   │   └── DuplicateMessageException.java
│   └── pong/                           (NEW)
│       └── PongProcessor.java
│
├── servlet/                            (CURRENT: Keep for filter/servlet grouping)
│   ├──EbMSServlet.java
│   ├──EbMSMessageServlet.java
│   ├── filters/                        (NEW: subpackage for filters)
│   │   ├── BasicAuthenticationFilter.java
│   │   ├── ClientCertificateAuthenticationFilter.java
│   │   ├── ClientCertificateManagerFilter.java
│   │   ├── UserRateLimiterFilter.java
│   │   ├── EchoServletFilter.java
│   │   ├── RemoteAddressMDCFilter.java
│   │   ├── RateLimiterFilter.java
│   │   ├── MDCServletFilter.java
│   │   └── HealthServlet.java
│   └── servlet package README.md
│
├── http/                               (NEW: EbMSHttpHandler, EbMSInputStreamHandler - HTTP handling)
│   ├──EbMSHttpHandler.java
│   └── EbMSInputStreamHandler.java
│
├── ssl/                                (NEW: SSL related - move from root server)
│   └── SSLFactoryManager.java
│
├── embedded/                           (CURRENT: Reorganize structure)
│   ├── startup/                        (NEW: StartEmbedded, Start, Constants)
│   │   ├── StartEmbedded.java
│   │   ├── Start.java
│   │   └── Constants.java
│   ├── config/                         (NEW: Configuration classes)
│   │   ├── EmbeddedAppConfig.java
│   │   ├── DBConfig.java
│   │   ├── EbMSPropertySourcesPlaceholderConfigurer.java
│   │   ├── EbMSKeyStore.java
│   │   └── CustomErrorHandler.java
│   ├── dao/                            (KEEP: ebms-core/server specific DAO)
│   │   ├──EbMSDAO.java
│   │   ├──EbMSDAOImpl.java
│   │   └── AdminDAOConfig.java
│   ├── db/                             (NEW: Database management)
│   │   ├── DBClean.java
│   │   ├── DBMigrate.java
│   │   └── DBExecute.java
│   ├── web/                            (KEEP: Web configuration)
│   │   ├── EmbeddedWebConfig.java
│   │   └── ExtensionProvider.java
│   └── admin/                          (NEW: Admin REST API)
│       └── AdminRestController.java
│
└── config/                             (NEW: Centralized configuration)
    ├── EbMSServerConfig.java           (Move from nl.clockwork.ebms.server root)
    ├── EbMSMessageProcessorConfig.java (Move from nl.clockwork.ebms.server.processor)
    └── ValidationConfig.java
```

## Package Grouping Rationale

### **Core Feature Groups**

1. **Model Package** - All data models consolidated at top level for discoverability
   - Core models from embedded module moved to `model/core/`
   - Web query/filter models moved to `model/embedded/web/`

2. **Validation Package** - Kept separate as validators are often cross-cutting concerns
   - `EbMSMessageValidator` - General message validation
   - `CPAValidator` - CPA validation (used by both processing and external services)
   - `SignatureValidator`, `MessageHeaderValidator`, `ManifestValidator` - Header-level validators
   - `ClientCertificateValidator`, `ClientCertificateManager` - SSL/TLS validation

3. **Processing Package** - Reorganized from monolithic processor package based on message type processing
    - `EbMSMessageProcessor` - Main orchestrator (keeps core responsibility) that dispatches to specialized processors:
      - `EbMSMessage` → `processMessage()` → validates, stores, sends ack
      - `EbMSMessageError` → `messageErrorProcessor` → handles errors
      - `EbMSAcknowledgment` → `acknowledgmentProcessor` → handles acknowledgments
      - `EbMSStatusRequest` → `processStatusRequest()` → creates status responses
      - `EbMSStatusResponse` → `statusResponseProcessor` → handles status responses
      - `EbMSPing` → `processPing()` → creates pongs
      - `EbMSPong` → `pongProcessor` → handles pongs
    - Subpackages by processing responsibility: `acknowledgment/`, `error/`, `status/`, `duplicate/`, `pong/`
    - Exceptions (`EbMSProcessingException`, `EbMSProcessorException`) in `processing/`

4. **Servlet Package** - Kept for servlet/filter grouping but refined
   - Main servlets at root level (`EbMSServlet`, `EbMSMessageServlet`)
   - Filters organized in `filters/` subpackage

5. **HTTP Package** - New package for HTTP-specific handling
   - `EbMSHttpHandler` - HTTP request/response handling
   - `EbMSInputStreamHandler` - Input stream processing

6. **SSL Package** - New package for security-related functionality
   - `SSLFactoryManager` - SSL/TLS factory management

7. **Embedded Package** - Reorganized for clarity
   - `startup/` - Application startup
   - `config/` - Spring configuration
   - `dao/` - Database access
   - `db/` - Database migration/tools
   - `web/` - REST configuration
   - `admin/` - Admin REST endpoints

8. **Config Package** - Centralized configuration at root level
   - All Spring `@Configuration` classes
   - Configuration utility classes

## Migration Steps

### Phase 1: Create New Structure
1. Create new directories under `nl.clockwork.ebms.server`
2. Create subdirectories for each feature group
3. Create package README files explaining each package's purpose

### Phase 2: Move Files (One Phase at a Time)
1. **Move models** - Move `embedded.model.*` to `model/core/` and `model/embedded/web/`
2. **Move http classes** - Move `EbMSHttpHandler`, `EbMSInputStreamHandler` to `http/`
3. **Move ssl classes** - Move `SSLFactoryManager` to `ssl/`
4. **Move config classes** - Move root-level config to `config/`
5. **Rename processor package** - Rename `processor` to `processing`
6. **Subpackage processing** - Organize processors into subpackages
7. **Reorganize servlet** - Refactor servlet package structure
8. **Reorganize embedded** - Reorganize embedded module structure

### Phase 3: Update Imports
1. Update all `import nl.clockwork.ebms.server.*` statements
2. Update package declarations for moved classes
3. Verify no circular dependencies introduced

### Phase 4: Configuration Updates
1. Update `EmbeddedAppConfig.java` imports
2. Update `EmbeddedWebConfig.java` imports
3. Update test configuration files
4. Update Spring component scan paths (if applicable)

### Phase 5: Test Updates
1. Update test class package declarations
2. Update test imports
3. Run all tests to verify functionality

### Phase 6: Cleanup
1. Remove old directories after successful migration
2. Update documentation
3. Update any API specs or external references

## Impact Analysis

### Files To Be Moved (44 total)

**ebms-core/core (26 files):**
- root server: `EbMSServerConfig.java`, `SSLFactoryManager.java`, `EbMSHttpHandler.java`, `EbMSInputStreamHandler.java` (4 → move to `config/`, `ssl/`, `http/`)
- validation: 9 files → keep or `validation/`
- processor: 9 files → rename to `processing/` with subpackages
- servlet: 11 files → reorganize in `servlet/`

**ebms-core/server (18 files):**
- embedded: 13 files → reorganize in `embedded/`
- embedded.dao: 5 files → move to `embedded/dao/`
- embedded.model: 5 files → move to `model/core/`
- embedded.web: 4 files → keep or reorganize
- embedded.web.admin: 2 files → move to `embedded/admin/`
- embedded.web.message: 2 files → move to `model/embedded/web/`
- embedded.web.menu: 1 file → move to `model/embedded/web/`

**Total: ~44 files to reorganize**

### Dependent Files (Need Import Updates)

**ebms-core/core:**
- `EbMSMessageProcessor.java` - 2 imports to validation
- `AcknowledgmentProcessor.java` - 2 imports to validation
- `MessageErrorProcessor.java` - 2 imports to validation
- `StatusResponseProcessor.java` - 1 import to validation
- `DuplicateMessageHandler.java` - 1 import to validation
- `PongProcessor.java` - 1 import to validation
- `EbMSProcessorConfig.java` - 1 import to validation
- `EbMSHttpHandler.java` - 2 imports to processor
- `EbMSInputStreamHandler.java` - 2 imports to processor
- `EbMSServlet.java` - 2 imports to processor, 1 to http
- `EbMSMessageServlet.java` - 2 imports to processor, 1 to http
- `ClientCertificateManagerFilter.java` - 1 import to validation
- `UserRateLimiterFilter.java` - 1 import to validation
- `ClientCertificateAuthenticationFilter.java` - 1 import to validation
- `EbMSServerConfig.java` - 2 imports to processor

**ebms-core/server:**
- `EmbeddedAppConfig.java` - 7 imports (server config, processor config, validation config, embedded dao/web, servlet)
- `EmbeddedWebConfig.java` - 2 imports (embedded dao, admin)
- `WithMessageFilter.java` - 1 import to embedded.web.message
- `EbMSDAO.java` - 5 imports to embedded.model, embedded.web.message
- `EbMSDAOImpl.java` - 6 imports to embedded.model, embedded.web
- `StartEmbedded.java` - 2 imports (embedded, servlet)
- `Start.java` - 2 imports (embedded.web, servlet)
- `AdminRestController.java` - 5 imports (embedded dao, model, web.message)

**ebms-admin:**
- `EmbeddedAppConfig.java` - 3 imports (server config, processor config, validation config)
- `StartEmbedded.java` - 1 import to servlet
- `Start.java` - 1 import to servlet

**ebms-core plugins:**
- `JMSDeliveryManager.java` - 2 imports to processor
- `KafkaDeliveryManager.java` - 2 imports to processor
- `EbMSMessageEncrypter.java` - 2 imports to processor
- `EbMSMessageDecrypter.java` - 2 imports to processor
- `EbMSSignatureGenerator.java` - 2 imports to processor
- `EbMSMessageBuilder.java` - 1 import to processor
- `EbMSMessageFactory.java` - 2 imports to processor
- `DefaultDeliveryManager.java` - 2 imports to processor
- `DeliveryManager.java` - 1 import to processor
- `EbMSClient.java` - 1 import to processor
- `EbMSResponseException.java` - 1 import to processor
- `EbMSHttpClient.java` - 2 imports to processor
- `EbMSResponseHandler.java` - 1 import to processor
- `DeliveryTaskHandler.java` - 1 import to processor
- `DeliveryTaskHandlerConfig.java` - 1 import to processor
- `SecurityUtils.java` - 1 import to processor

**Total: ~50+ files need import updates**

### Breaking Changes

**None** - This is a refactoring only. Public APIs remain unchanged:
- SOAP/WSDL endpoints remain the same
- REST endpoints remain the same
- Public class names remain the same
- Only package structure changes

## Benefits

1. **Feature-focused organization** - Developers can find all components for a feature in one package
2. **Smaller, manageable packages** - No more 10+ class monolithic packages
3. **Clearer boundaries** - Each package has a well-defined responsibility
4. **Better test organization** - Tests can mirror the source structure
5. **Easier navigation** - Related functionality is colocated
6. **Processing pipeline clarity** - Handlers and processors grouped by their role in the request flow

## Risks

1. **Wide impact** - 50+ files need import updates
2. **Search/replace errors** - May miss some imports during batch updates
3. **Test disruption** - All test imports must be updated
4. **Merge conflicts** - If multiple developers are working on server package

## Mitigation

1. **Phased migration** - One package at a time with verification
2. **Use IDE refactoring** - Leverage IDE's "Move" and "Update Imports" features
3. **Run tests after each phase** - Verify no regressions
4. **Git workflow** - Use feature branch with small, incremental commits

## Acceptance Criteria

- [ ] All server classes organized by feature
- [ ] All imports updated across codebase
- [ ] All tests pass (`mvn test` succeeds)
- [ ] Build succeeds without warnings (`mvn compile`)
- [ ] Package README files created explaining each package
- [ ] No circular dependencies introduced
- [ ] Public API behavior unchanged (endpoints, class names, SOAP/WSDL)

## Estimated Effort

- Migration: 2-3 developer days
- Testing: 1-2 developer days
- Documentation: 0.5 developer day
- **Total: 3-6 developer days**
