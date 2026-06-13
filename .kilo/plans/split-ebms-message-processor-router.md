# Plan: Split EbMSMessageProcessor into Router and Specific Processor

## Current Architecture

The `EbMSMessageProcessor` class currently:
1. Routes messages based on type (line 176-227 in `processRequest`)
2. Processes `EbMSMessage` type directly (line 314)
3. Delegates to specialized processors: `AcknowledgmentProcessor`, `StatusResponseProcessor`, `PongProcessor`, `MessageErrorProcessor`

## Target Architecture

Follow the same pattern as `AcknowledgmentProcessor`:
- **Generic MessageRouter**: Handles routing logic only
- **Specific EbMSMessageProcessor**: Processes `EbMSMessage` type specifically

## Files to Create

### 1. `server/processing/MessageRouter.java` (NEW)
**Purpose**: Router that dispatches to specific processors based on message type

**Responsibilities**:
- Route messages in `processRequest()` based on type
- Handle: `EbMSMessage`, `EbMSMessageError`, `EbMSAcknowledgment`, `EbMSStatusRequest`, `EbMSStatusResponse`, `EbMSPing`, `EbMSPong`
- Return `null` for async messages, response document for sync

**Structure**:
```java
public class MessageRouter
{
  // Fields: acknowledgmentProcessor, messageErrorProcessor, statusResponseProcessor, pongProcessor
  // processRequest(EbMSDocument) - routing method
  // processMessage(EbMSDocument, EbMSMessage) - delegate to specific processor
}
```

### 2. `server/processing/message/EbMSMessageProcessor.java` (NEW)
**Purpose**: Specific processor for `EbMSMessage` type only

**Keep**:
- `processMessage(Instant, EbMSDocument, EbMSMessage)` logic for message handling
- `processResponse()` methods
- Private helpers: `storeMessage()`, `processMessage(EbMSMessage)`
- `getRequestMessage()`

**Refactor**:
- Move from `server.processing` to `server.processing.message` package
- Keep class name: `EbMSMessageProcessor.java`

## Files to Modify

### 3. `server/processing/message/EbMSMessageProcessorConfig.java` (NEW)
Create new config file in `server.processing.message` package to define `EbMSMessageProcessor` bean

### 4. Update references to `MessageRouter`
The refactored `EbMSMessageProcessor` will only handle `EbMSMessage` type. Update callers:

**`EbMSInputStreamHandler.java`** (line 118):
- `messageProcessor.processRequest(requestDocument)` → needs adapter or keep method

**`EbMSHttpHandler.java`**: No changes needed (uses `EbMSInputStreamHandler`)

**`EbMSMessageServlet.java`**: No changes needed

**`DeliveryTaskHandler.java`** (line 205):
- `messageProcessor.processResponse(requestDocument, responseDocument)` → keep method in new `EbMSMessageProcessor`

**`DeliveryTaskHandlerConfig.java`**: No changes (depends on config)

**`EbMSServerConfig.java`**: Check if needs updates

### 5. `AcknowledgmentProcessor.java` 
Update imports if needed (already has correct package structure)

### 6. Update references to `MessageRouter` and `EbMSMessageProcessor` (now in `server.processing.message` package)

## Model Type Hierarchy

```
EbMSBaseMessage (abstract)
├── EbMSRequestMessage (abstract)
│   ├── EbMSMessage (concrete)
│   ├── EbMSStatusRequest (concrete)
│   └── EbMSPing (concrete)
└── EbMSResponseMessage (abstract)
    ├── EbMSMessageResponse (abstract)
    │   ├── EbMSMessageError (concrete)
    │   ├── EbMSAcknowledgment (concrete)
    │   ├── EbMSStatusResponse (concrete)
    │   └── EbMSPong (concrete)
```

## Implementation Steps

1. Create `MessageRouter` class with routing logic
2. Create `server/processing/message/EbMSMessageProcessor.java` (move from `server.processing`)
3. Update `EbMSMessageProcessorConfig` to define both beans (or move to new `message` package)
4. Update class references throughout the codebase to use correct imports
5. Run tests to verify functionality

## Benefits

1. **Single Responsibility**: Each processor has one clear responsibility
2. **Testability**: Easier to unit test specific processors in isolation
3. **Maintainability**: Clear separation between routing and processing logic
4. **Consistency**: Aligns with existing pattern of `AcknowledgmentProcessor`
5. **Extensibility**: New message types can add processors without touching router

## Testing Considerations

- Unit tests for `MessageRouter` routing logic
- Unit tests for `EbMSMessageProcessor` message handling
- Integration tests should cover end-to-end flow
- Verify all message types are handled correctly
- Test sync vs async response handling
