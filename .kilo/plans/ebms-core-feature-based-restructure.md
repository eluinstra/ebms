# EbMS Core Feature-Based Reorganization Plan

## Current State Analysis

The `ebms-core` module is organized using a **layer-based architecture**:
- `common/` - Shared utilities (model, dao, message, protocol, util, security, transaction, event, cache, datasource, jaxb, cpa, xml)
- `client/` - Client-side code (api, async, sync, transport)
- `server/` - Server-side code (config, http, model, processing, servlet, ssl, validation)
- `api/` - REST/Soap APIs (ebms, cpa, certificate, url, controller)

## Target State: Feature-Based Architecture

Organize by feature/functionality with self-contained vertical slices:
```
nl.clockwork.ebms/
├── message/           # Message sending/receiving functionality
│   ├── model/         # Message-related models
│   ├── dao/           # Message data access
│   ├── processing/    # Message processing logic
│   ├── client/        # Client-side message sending
│   ├── server/        # Server-side message receiving
│   ├── validator/     # Message validation
│   └── api/           # Message-related REST/Soap endpoints
├── delivery/          # Delivery management functionality
│   ├── model/         # Delivery task models
│   ├── dao/           # Delivery task data access
│   ├── manager/       # Delivery managers
│   ├── executor/      # Async delivery execution
│   └── handler/       # Delivery task handlers
├── cpa/               # CPA (Collaboration Protocol Agreement) functionality
│   ├── model/         # CPA models
│   ├── dao/           # CPA data access
│   ├── validator/     # CPA validation
│   └── api/           # CPA REST/Soap endpoints
├── certificate/       # Certificate mapping functionality
│   ├── model/         # Certificate models
│   ├── dao/           # Certificate data access
│   └── api/           # Certificate REST/Soap endpoints
├── event/             # Message event handling
├── security/          # Encryption/Signature functionality
│   ├── encrypter/     # Encryption logic
│   ├── signer/        # Signing logic
│   └── validator/     # Signature validation
├── util/              # Shared utilities (XSD validation, logging, etc.)
└── protocol/          # EbMS protocol constants and enums
```

## Benefits

1. **Co-located related functionality** - All message-related code in one place
2. **Easier to find code** - Navigate by feature rather than architectural layer
3. **Better module boundaries** - Each feature can be a separate module if needed
4. **Simpler onboarding** - New developers understand features first
5. **Refactoring support** - Easier to refactor entire features

## Migration Steps

### Phase 1: Setup & Foundation
1. Create new directory structure
2. Create documentation explaining the new structure
3. Update pom.xml files if splitting into modules
4. Create migration script/tool to automate file movement

### Phase 2: Move Core Features (High Priority)
1. **message/** - Move all message-related code
   - `common/model/EbMS*.java` → `message/model/`
   - `common/message/*.java` → `message/`
   - `common/protocol/*.java` → `protocol/` (top-level)
   - `server/processing/*.java` → `message/processing/`
   - `client/sync/*.java` → `message/client/`
   - `common/dao/EbMSDAO*.java` → `message/dao/`
   - `server/validation/*.java` → `message/validator/`

2. **delivery/** - Move delivery-related code
   - `client/async/*.java` → `delivery/`
   - `client/api/Delivery*.java` → `delivery/manager/`
   - `common/event/*.java` → `event/` (top-level)

3. **cpa/** - Move CPA-related code
   - `common/cpa/*.java` → `cpa/`
   - `api/cpa/*.java` → `cpa/api/`
   - `server/validation/CPAValidator.java` → `cpa/validator/`

4. **certificate/** - Move certificate-related code
   - `api/certificate/*.java` → `certificate/`

### Phase 3: Move Supporting Features
5. **security/** - Move security code
   - `common/security/*.java` → `security/`

6. **util/** - Move shared utilities
   - `common/util/*.java` → `util/`
   - `common/xml/*.java` → `util/xml/`
   - `common/datasource/*.java` → `util/datasource/`
   - `common/jaxb/*.java` → `util/jaxb/`

### Phase 4: Cleanup & Finalization
7. Update all import statements throughout the codebase
8. Run tests to verify migration
9. Update documentation
10. Create migration guide for developers

## Dependencies to Address

### Import Redirects (After Move)
| Old Package | New Package |
|-------------|-------------|
| `nl.clockwork.ebms.common.model` | `nl.clockwork.ebms.message.model` |
| `nl.clockwork.ebms.common.message` | `nl.clockwork.ebms.message` |
| `nl.clockwork.ebms.common.protocol` | `nl.clockwork.ebms.protocol` |
| `nl.clockwork.ebms.common.cpa` | `nl.clockwork.ebms.cpa` |
| `nl.clockwork.ebms.common.security` | `nl.clockwork.ebms.security` |
| `nl.clockwork.ebms.common.util` | `nl.clockwork.ebms.util` |
| `nl.clockwork.ebms.common.event` | `nl.clockwork.ebms.event` |
| `nl.clockwork.ebms.client.*` | `nl.clockwork.ebms.message.client.*` |
| `nl.clockwork.ebms.server.*` | `nl.clockwork.ebms.message.server.*` |

### Cross-Feature Dependencies
- `message/processing` depends on `message/validator`, `message/dao`, `event`
- `delivery/` depends on `message/`, `event/`
- `cpa/api` depends on `cpa/validator`, `cpa/dao`
- `security/` is used by `message/processing`, `message/client`, `message/server`

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking imports | High | Use IDE refactoring tools, update systematically |
| Tests fail | Medium | Run tests after each phase |
| Git history | Low | Use `git mv` for file moves |
| Merge conflicts | Medium | Coordinate with team, frequent integration |

## Testing Strategy

1. **Unit tests**: Run after each phase
2. **Integration tests**: Run after major phases (message, delivery, cpa)
3. **End-to-end**: Full test suite after completion
4. **Smoke tests**: Verify key flows (send message, receive message, deliver message)

## Rollback Plan

- Keep original structure in git history
- Create `feature/restructure` branch
- Revert commit if issues detected
- No data migration needed (purely package reorganization)

## Timeline Estimate

- Phase 1 (Setup): 1-2 days
- Phase 2 (Core features): 3-4 days
- Phase 3 (Supporting): 1-2 days
- Phase 4 (Cleanup): 2-3 days
- **Total: ~1-2 weeks**

## Post-Migration Improvements

1. Consider splitting into separate Maven modules per feature
2. Add package-level documentation
3. Create architecture diagrams
4. Update developer onboarding guide
5. Add linting rules to enforce new structure
