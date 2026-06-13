# EbMS Core Internal Feature-Based Reorganization Plan

## Overview

Reorganize internal subpackages within `api/`, `client/`, and `server/` layers to follow feature-based organization while keeping the top-level packages intact.

## Current State

### api/ (Interface Layer)
```
api/
├── ebms/          # REST/Soap endpoints for EbMS operations
├── cpa/           # REST/Soap endpoints for CPA management
├── certificate/   # REST/Soap endpoints for certificate mapping
├── url/           # REST/Soap endpoints for URL mapping
├── EbMSExceptionMapper.java
└── WithController.java
```

### client/ (Client Layer)
```
client/
├── api/           # Client API interfaces (EbMSClient, DeliveryManager, etc.)
├── sync/          # Synchronous client operations
├── async/         # Asynchronous delivery task handling
└── transport/     # Transport mechanisms (HTTP, SSL)
```

### server/ (Server Layer)
```
server/
├── config/        # Server configuration
├── http/          # HTTP request/response handlers
├── model/         # Server-side models
├── processing/    # Message processing pipeline
├── servlet/       # Servlet filters and handlers
├── ssl/           # Server SSL configuration
└── validation/    # Message and CPA validation
```

## Proposed Feature-Based Internal Structure

### api/ - Feature-Based Subpackages
```
api/
├── ebms/          # EbMS messaging feature (no change - good structure)
│   ├── model/     # Request/Response models
│   ├── dao/       # Data access for EbMS
│   ├── rest/      # REST endpoints
│   ├── soap/      # SOAP endpoints
│   └── exception/ # Exception mappers
│
├── cpa/           # CPA management feature (no change - good structure)
│   ├── model/     # CPA models (if any in api layer)
│   ├── repository/ # Repository for CPA lookup
│   ├── validator/ # CPA validation
│   ├── rest/      # REST endpoints
│   └── soap/      # SOAP endpoints
│
├── certificate/   # Certificate mapping feature (no change - good structure)
│   ├── model/     # Certificate models
│   ├── repository/ # Repository for certificate lookup
│   ├── rest/      # REST endpoints
│   └── soap/      # SOAP endpoints
│
├── url/           # URL mapping feature (no change - good structure)
│   ├── repository/ # Repository for URL mapping
│   ├── rest/      # REST endpoints
│   └── soap/      # SOAP endpoints
│
└── shared/        # Shared API utilities (NEW)
    ├── exception/ # Common exception mappers
    └── controller/ # Common controller base classes
```

**Rationale**: The current structure in api/ is already quite feature-based. Only add a `shared/` package for common exception mappers and controller utilities.

---

### client/ - Reorganized Feature-Based Subpackages
```
client/
├── client/        # Client-facing API feature (relabel api/ -> client/)
│   ├── api/       # Client API interfaces
│   │   ├── EbMSClient.java
│   │   ├── DeliveryManager.java
│   │   ├── DeliveryTaskManager.java
│   │   ├── DeliveryTaskDispatcher.java
│   │   └── URLMappingRepository.java
│   ├── model/     # Client request/response models
│   └── exception/ # Client-specific exceptions
│
├── delivery/      # Delivery feature (relabel sync/ + async/ -> delivery/)
│   ├── task/      # Delivery task management
│   │   ├── DeliveryTaskDAO.java
│   │   ├── DeliveryTaskDAOImpl.java
│   │   └── DAODeliveryTaskManager.java
│   ├── handler/   # Delivery task handlers
│   │   ├── DeliveryTaskHandler.java
│   │   ├── DAODeliveryTaskExecutor.java
│   │   ├── DirectDeliveryTaskDispatcher.java
│   │   ├── DeliveryTaskHandlerConfig.java
│   │   └── DeliveryTaskManagerConfig.java
│   ├── queue/     # Message queue handling
│   │   ├── EbMSMessageQueue.java
│   │   ├── MessageQueue.java
│   │   └── DefaultDeliveryManager.java
│   ├── config/    # Delivery configuration
│   │   └── DeliveryManagerConfig.java
│   └── status/    # Delivery task status
│       ├── DeliveryTask.java
│       └── DeliveryTaskStatus.java
│
├── transport/     # Transport layer (no change - good structure)
│   ├── http/      # HTTP transport implementation
│   └── ssl/       # SSL/TLS configuration
│
└── config/        # Client configuration (NEW)
    └── EbMSClientConfig.java
```

**Rationale**: Consolidate `api/`, `sync/`, `async/` into more logical features:
- `client/` - The public client API (interfaces)
- `delivery/` - How messages are delivered (both sync and async)
- `transport/` - Network transport protocols
- `config/` - Client configuration

---

### server/ - Reorganized Feature-Based Subpackages
```
server/
├── message/       # Message processing feature (relabel processing/ + model/)
│   ├── processor/ # Message processors
│   │   ├── EbMSMessageProcessor.java
│   │   ├── EbMSMessageProcessorConfig.java
│   │   ├── AcknowledgmentProcessor.java
│   │   ├── MessageErrorProcessor.java
│   │   └── DuplicateMessageHandler.java
│   ├── validator/ # Message validation
│   │   ├── EbMSMessageValidator.java
│   │   ├── MessageHeaderValidator.java
│   │   ├── ManifestValidator.java
│   │   └── SignatureValidator.java
│   ├── model/     # Server message models
│   │   └── core/  (move from server/model/)
│   ├── router/    # Message routing
│   │   └── EbMSMessageRouter.java
│   └── exception/ # Processing exceptions
│
├── endpoint/      # Endpoint handlers (relabel http/ + servlet/)
│   ├── http/      # HTTP request/response handlers
│   │   ├── EbMSHttpHandler.java
│   │   └── EbMSInputStreamHandler.java
│   ├── servlet/   # Servlet-based endpoints
│   │   ├── EbMSMessageServlet.java
│   │   ├── EbMSServlet.java
│   │   └── filters/ # Filter chain (keep filters in same package)
│   │       ├── BasicAuthenticationFilter.java
│   │       ├── ClientCertificateAuthenticationFilter.java
│   │       ├── ClientCertificateManagerFilter.java
│   │       ├── EchoServletFilter.java
│   │       ├── HealthServlet.java
│   │       ├── MDCServletFilter.java
│   │       ├── RateLimiterFilter.java
│   │       ├── RemoteAddressMDCFilter.java
│   │       └── UserRateLimiterFilter.java
│   └── soap/      # SOAP endpoint configuration
│       └── servlet/ # Move SOAP-specific servlets if any
│
├── validation/    # Validation feature (no change - good structure)
│   ├── CPAValidator.java
│   ├── ClientCertificateManager.java
│   ├── ClientCertificateValidator.java
│   ├── CPAValidator.java (duplicate - check for uniqueness)
│   ├── DuplicateMessageException.java
│   └── ValidationConfig.java
│
├── security/      # Security feature (relabel ssl/ + validation/*)
│   ├── ssl/       # SSL/TLS configuration
│   │   └── SSLFactoryManager.java
│   └── certificate/ # Client certificate handling
│       ├── ClientCertificateManager.java
│       └── ClientCertificateValidator.java
│
├── config/        # Server configuration (no change - good structure)
│   └── EbMSServerConfig.java
│
└── event/         # Event handling (move from common/event if needed)
    └── DAOMessageEventListener.java
```

**Rationale**:
- `message/` - Core message processing logic (everything about handling messages)
- `endpoint/` - Network endpoints and servlet handling
- `validation/` - CPA and message validation
- `security/` - SSL/TLS and certificate handling
- `config/` - Server configuration
- `event/` - Message lifecycle events

---

## Benefits of This Approach

1. **API/Client/Server top-level preserved** - Main functional boundaries intact
2. **Feature-based within layers** - Easier to find related functionality
3. **Clear ownership** - Each feature has a clearly defined package
4. **Reduced friction** - Related code is co-located

## Migration Steps

### Step 1: Refactor api/ (Low Impact)
- No changes needed to current structure (already feature-based)
- Add `api/shared/` for common utilities

### Step 2: Refactor client/ (Medium Impact)
- Rename `client/api/` → `client/client/`
- Combine `sync/` and `async/` into `delivery/`
- Update all import statements

### Step 3: Refactor server/ (Medium Impact)
- Consolidate `processing/` and `model/` → `message/`
- Consolidate `http/` and `servlet/` → `endpoint/`
- Consolidate `ssl/` and `validation/*` → `security/`
- Update all import statements

## Files to Move (Approximate Count)

| Layer | From | To | Count |
|-------|------|-----|-------|
| client/ | `api/` | `client/` | 7 files |
| client/ | `sync/` | `delivery/` | 5 files |
| client/ | `async/task/` | `delivery/task/` | 3 files |
| client/ | `async/handler/` | `delivery/handler/` | 6 files |
| server/ | `processing/*.java` | `message/processor/` | 10 files |
| server/ | `model/core/*` | `message/model/core/` | 0 files (empty) |
| server/ | `http/` | `endpoint/http/` | 2 files |
| server/ | `servlet/` | `endpoint/servlet/` | 11 files (incl. filters) |
| server/ | `ssl/` | `security/ssl/` | 1 file |

**Total: ~50 files moved**

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking imports | Medium | Use IDE refactoring tools, update systematically |
| Tests fail | Medium | Run tests after each layer |
| Git history | Low | Use `git mv` for file moves |

## Rollback Plan

- Keep original structure in git history
- Create `feature/internal-restructure` branch
- Revert commit if issues detected
- No data migration needed
