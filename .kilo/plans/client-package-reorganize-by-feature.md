# Client Package Reorganization Plan

## Overview

Reorganize `nl.clockwork.ebms.client` package from current layer-based grouping to feature-based grouping.

## Current Structure (3 Levels: delivery/, http/, task/)

```
nl.clockwork.ebms.client/
├── delivery/              # High-level delivery interfaces & implementations
│   ├── DeliveryManager.java
│   ├── DefaultDeliveryManager.java
│   ├── DeliveryManagerConfig.java
│   ├── EbMSDAO.java
│   ├── MessageQueue.java
│   └── EbMSMessageQueue.java
├── http/                  # HTTP transport layer (nested under delivery)
│   ├── EbMSClient.java
│   ├── EbMSHttpClient.java
│   ├── EbMSHttpClientFactory.java
│   ├── EbMSClientConfig.java
│   ├── EbMSMessageWriter.java
│   ├── MultipartBodyPublisher.java
│   ├── EbMSResponseHandler.java
│   ├── EbMSProxy.java
│   ├── EbMSProxyFactory.java
│   ├── SSLParametersFactory.java
│   ├── SSLContextFactory.java
│   ├── HttpErrors.java
│   ├── EbMSResponseException.java
│   └── EbMSUnrecoverableResponseException.java
└── task/                  # Async task delivery (nested under delivery)
    ├── DeliveryTask.java
    ├── DeliveryTaskManager.java
    ├── DAODeliveryTaskManager.java
    ├── DeliveryTaskHandler.java
    ├── DeliveryTaskDispatcher.java
    ├── DirectDeliveryTaskDispatcher.java
    ├── DeliveryTaskDAO.java
    ├── DeliveryTaskDAOImpl.java
    ├── DAODeliveryTaskExecutor.java
    ├── URLMappingRepository.java
    ├── DeliveryTaskStatus.java
    ├── TimedTask.java
    ├── DeliveryTaskHandlerConfig.java
    └── DeliveryTaskManagerConfig.java
```

## Target Structure (Feature-First Grouping)

```
nl.clockwork.ebms.client/
├── api/                          # Public APIs and DTOs
│   ├── DeliveryManager.java
│   ├── DeliveryTaskManager.java
│   ├── EbMSClient.java
│   ├── DeliveryTask.java
│   ├── DeliveryTaskStatus.java
│   ├── DeliveryTaskDispatcher.java
│   └── URLMappingRepository.java
│
├── sync/                         # Synchronous delivery (immediate HTTP)
│   ├── DefaultDeliveryManager.java
│   ├── DeliveryManagerConfig.java
│   ├── MessageQueue.java
│   ├── EbMSMessageQueue.java
│   └── EbMSDAO.java
│
├── async/                        # Asynchronous task-based delivery
│   ├── task/                     # Task domain model and management
│   │   ├── DeliveryTask.java
│   │   ├── DeliveryTaskStatus.java
│   │   ├── DeliveryTaskManager.java (implementation)
│   │   ├── DAODeliveryTaskManager.java
│   │   ├── DeliveryTaskDAO.java
│   │   ├── DeliveryTaskDAOImpl.java
│   │   └── URLMappingRepository.java
│   ├── handler/                  # Task execution logic
│   │   ├── DeliveryTaskHandler.java
│   │   ├── DeliveryTaskDispatcher.java (implementation)
│   │   ├── DirectDeliveryTaskDispatcher.java
│   │   ├── DAODeliveryTaskExecutor.java
│   │   ├── TimedTask.java
│   │   ├── DeliveryTaskHandlerConfig.java
│   │   └── DeliveryTaskManagerConfig.java
│   └── config/                   # Main async configuration
│       └── [move configs here if needed]
│
├── transport/                    # HTTP transport layer
│   ├── http/                     # HTTP clients and message handling
│   │   ├── EbMSHttpClient.java
│   │   ├── EbMSHttpClientFactory.java
│   │   ├── EbMSClientConfig.java
│   │   ├── EbMSMessageWriter.java
│   │   ├── MultipartBodyPublisher.java
│   │   ├── EbMSResponseHandler.java
│   │   ├── EbMSProxy.java
│   │   ├── EbMSProxyFactory.java
│   │   ├── HttpErrors.java
│   │   ├── EbMSResponseException.java
│   │   └── EbMSUnrecoverableResponseException.java
│   └── ssl/                      # SSL/TLS configuration (can be in common)
│       ├── SSLParametersFactory.java
│       └── SSLContextFactory.java
│
└── util/                         # Shared utilities (optional)
    └── [move if reused elsewhere]
```

## Benefits

1. **Clear separation**: Sync vs Async vs Transport is immediately visible
2. **Better discoverability**: New developers can find relevant code by use case
3. **Module extraction**: Transport could be extracted as reusable module
4. **Logical grouping**: Related functionality resides together

## Implementation Steps

### Phase 1: Create New Structure
1. Create directories: `api/`, `sync/`, `async/`, `transport/`, `async/task/`, `async/handler/`, `ssl/`
2. Move files in batches with `git mv`
3. Update all import statements across project

### Phase 2: Update References (89 files use client package)
- ebms-admin/: 7 files
- ebms-core/server/: 11 files
- ebms-core/core/: 3 files (self-references)
- ebms-core/plugin/messaging/jms/: 19 files
- ebms-core/plugin/messaging/kafka/: 19 files
- ebms-core/core/test/: 3 test files

### Phase 3: Verify
1. Run build: `mvn clean install`
2. Run tests: `mvn test verify`
3. Verify no broken imports

## Risk Mitigation

- **Test before refactoring**: Ensure current state passes all tests
- **Use git mv**: Preserve file history
- **Batch changes**: Move and update imports together per package
- **CI validation**: Run full test suite after each phase

## Files to Move (32 source + 3 test = 35 total)

### API (6 files)
- DeliveryManager.java
- DeliveryTaskManager.java (main interface)
- EbMSClient.java
- DeliveryTask.java
- DeliveryTaskStatus.java
- URLMappingRepository.java

### Sync (6 files)
- DefaultDeliveryManager.java
- DeliveryManagerConfig.java
- EbMSDAO.java
- MessageQueue.java
- EbMSMessageQueue.java

### Async - task (7 files)
- DeliveryTask.java ✗ (already there, move to api)
- DeliveryTaskManager.java (main in api)
- DAODeliveryTaskManager.java
- DeliveryTaskDAO.java
- DeliveryTaskDAOImpl.java
- URLMappingRepository.java ✗ (move to api)
- DeliveryTaskStatus.java ✗ (move to api)

### Async - handler (8 files)
- DeliveryTaskHandler.java
- DeliveryTaskDispatcher.java (main in api)
- DirectDeliveryTaskDispatcher.java
- DAODeliveryTaskExecutor.java
- TimedTask.java
- DeliveryTaskHandlerConfig.java
- DeliveryTaskManagerConfig.java

### Transport - http (10 files)
- EbMSHttpClient.java
- EbMSHttpClientFactory.java
- EbMSClientConfig.java
- EbMSMessageWriter.java
- MultipartBodyPublisher.java
- EbMSResponseHandler.java
- EbMSProxy.java
- EbMSProxyFactory.java
- HttpErrors.java
- EbMSResponseException.java
- EbMSUnrecoverableResponseException.java

### Transport - ssl (2 files)
- SSLParametersFactory.java
- SSLContextFactory.java

### Test files (3 files)
- MultipartBodyPublisherTest.java
- SSLParametersFactoryTest.java
- DAODeliveryTaskExecutorTest.java

## Implementation Status

✅ **Completed**: All 32 source files and 3 test files reorganized

### Final Package Structure

```
nl.clockwork.ebms.client/
├── api/                          # Public APIs and DTOs (7 files)
│   ├── DeliveryManager.java
│   ├── DeliveryTaskManager.java
│   ├── EbMSClient.java
│   ├── DeliveryTask.java
│   ├── DeliveryTaskStatus.java
│   ├── DeliveryTaskDispatcher.java
│   └── URLMappingRepository.java
│
├── sync/                         # Synchronous delivery (5 files)
│   ├── DefaultDeliveryManager.java
│   ├── DeliveryManagerConfig.java
│   ├── EbMSDAO.java
│   ├── EbMSMessageQueue.java
│   └── MessageQueue.java
│
├── async/
│   ├── task/                     # Task domain model (3 files)
│   │   ├── DAODeliveryTaskManager.java
│   │   ├── DeliveryTaskDAO.java
│   │   └── DeliveryTaskDAOImpl.java
│   ├── handler/                  # Task execution logic (6 files)
│   │   ├── DAODeliveryTaskExecutor.java
│   │   ├── DeliveryTaskHandler.java
│   │   ├── DeliveryTaskHandlerConfig.java
│   │   ├── DeliveryTaskManagerConfig.java
│   │   ├── DirectDeliveryTaskDispatcher.java
│   │   └── TimedTask.java
│   └── config/                   # Async config (empty)
│
├── transport/
│   ├── http/                     # HTTP transport (11 files)
│   │   ├── EbMSClientConfig.java
│   │   ├── EbMSHttpClient.java
│   │   ├── EbMSHttpClientFactory.java
│   │   ├── EbMSMessageWriter.java
│   │   ├── EbMSProxy.java
│   │   ├── EbMSProxyFactory.java
│   │   ├── EbMSResponseException.java
│   │   ├── EbMSResponseHandler.java
│   │   ├── EbMSUnrecoverableResponseException.java
│   │   ├── HttpErrors.java
│   │   └── MultipartBodyPublisher.java
│   └── ssl/                      # SSL/TLS config (2 files)
│       ├── SSLContextFactory.java
│       └── SSLParametersFactory.java
│
└── util/                         # Shared utilities (empty)
```

### Verification Results

- ✅ Build successful: `mvn clean compile` (16 modules)
- ✅ All tests pass: 282 tests, 0 failures, 0 errors
- ✅ No remaining `nl.clockwork.ebms.client.delivery` references
- ✅ All 89 external files updated with new imports
- ✅ Package structure follows feature-based grouping as specified
