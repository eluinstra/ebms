# Plan: Comprehensive Error Handling Improvements

## Overview

This plan addresses 7 suggestions for improving the error handling in the EbMS project. The goal is to create a more robust, maintainable, and debuggable error handling system that follows REST API best practices.

---

## Current State Analysis

### Existing Exception Types (8 total)
| Exception | HTTP Status | Description |
|-----------|-------------|-------------|
| `NotFoundException` | 404 | Generic not found |
| `CPANotFoundException` | 404 | CPA not found |
| `CertificateNotFoundException` | 404 | Certificate not found |
| `URLNotFoundException` | 404 | URL not found |
| `BadRequestException` | 400 | Bad request ( wraps cause message) |
| `CPAControllerException` | 400 | CPA controller error |
| `EbMSControllerException` | 500 | EbMS controller error |
| `CertificateMappingControllerException` | 500 | Certificate mapping error |
| `URLMappingControllerException` | 500 | URL mapping error |

### Current Error Response Format
```java
// Current: Raw string in response entity
entity(exception.getMessage())
```

### Issues Identified
1. No structured error response with metadata (timestamp, error code, request ID)
2. All exceptions logged at ERROR level (no distinction for expected vs unexpected)
3. No HTTP 422 for validation errors
4. No HTTP 401/403 for auth-related errors
5. No exception categorization for metrics
6. No context enrichment for logging

---

## Improvement Suggestions Plan

### 1. Exception Type: UnprocessableEntityException

**File**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/cpa/exception/UnprocessableEntityException.java`

**Purpose**: HTTP 422 for validation failures (vs 400 for malformed requests)

**Properties**:
- `errorCode`: Machine-readable error code (e.g., "VALIDATION_ERROR", "FIELD_INVALID")
- `field`: Optional field name that failed validation
- `invalidValue`: Optional invalid value that was provided

```java
public class UnprocessableEntityException extends RuntimeException {
    private final String errorCode;
    private final String field;
    private final Object invalidValue;
    
    public UnprocessableEntityException(String errorCode) { ... }
    public UnprocessableEntityException(String errorCode, String message) { ... }
    public UnprocessableEntityException(String errorCode, String message, String field, Object invalidValue) { ... }
}
```

**Status**: ❌ Not implemented yet

---

### 2. Exception Type: UnauthorizedException & ForbiddenException

**Files**:
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/security/exception/UnauthorizedException.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/security/exception/ForbiddenException.java`

**Purpose**: HTTP 401/403 for authentication/authorization failures

**Properties**:
- `UnauthorizedException`: Missing or invalid credentials
- `ForbiddenException`: Valid credentials but insufficient permissions

**Status**: ❌ Not implemented yet

---

### 3. Structured Error Response Format

**File**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/Error.java` (NEW)

**Current**: `WithController.Error` class contains only `String message`

**Proposed**:
```java
@Value
public class ErrorResponse {
    Instant timestamp;
    int status;
    String error;
    String message;
    String path;
    String errorCode;  // Optional, for structured error codes
    String requestId;  // Optional, for tracing
}
```

**Controller Error Wrapper**:
```java
public class ControllerErrorResponse extends ErrorResponse {
    // Could include additional controller-specific fields
    List<String> stackTrace;  // Optional, for debug
}
```

**Implementation Strategy**:
- Create new `ErrorResponse` class
- Update `WithController.toWebApplicationException()` to return structured response
- Add `requestId` via MDC or ThreadLocal for tracing

**Status**: ❌ Not implemented yet

---

### 4. Logging Level Configuration

**Approach**: Configurable logging strategy based on exception type

**Current**: All exceptions logged at ERROR level via `log().error()`

**Proposed Options**:

**Option A - Enum-based logging strategy**:
```java
public enum Severity { DEBUG, INFO, WARN, ERROR }

public class LoggingConfig {
    private static final Map<Class<?>, Severity> SEVERITY_MAP = Map.of(
        NotFoundException.class, Severity.DEBUG,
        BadRequestException.class, Severity.WARN,
        RuntimeException.class, Severity.ERROR
    );
    
    public static Severity getSeverity(Exception e) {
        return SEVERITY_MAP.entrySet().stream()
            .filter(entry -> entry.getKey().isAssignableFrom(e.getClass()))
            .map(Map.Entry::getValue)
            .findFirst()
            .orElse(Severity.ERROR);
    }
}
```

**Option B - Annotation-based strategy**:
```java
@Loggable(Severity.DEBUG)
public class NotFoundException extends RuntimeException { ... }

@Loggable(Severity.WARN)
public class BadRequestException extends RuntimeException { ... }
```

**Status**: ❌ Not implemented yet

---

### 5. Exception Context Enrichment

**Current**: `execute()` only accepts `(controller, operation, logContext)`

**Proposed Enhanced Signature**:
```java
static <T> T execute(WithController controller, Supplier<T> operation, 
    String logContext, Map<String, Object> context) {
    try {
        MDC.putAll(context);
        return operation.get();
    } catch (Exception e) {
        controller.log().error(logContext, e);
        throw controller.toWebApplicationException(e);
    } finally {
        MDC.clear();
    }
}
```

**Usage Example**:
```java
WithController.execute(this, 
    () -> service.process(request),
    "ProcessRequest",
    Map.of(
        "requestId", requestId,
        "userId", userId,
        "tenantId", tenantId
    ));
```

**Status**: ❌ Not implemented yet

---

### 6. Exception Grouping for Metrics

**File**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ErrorCategory.java` (NEW)

**Purpose**: Categorize exceptions for monitoring/alerting

**Proposed Categories**:
```java
public enum ErrorCategory {
    CLIENT_ERROR,      // 4xx errors - user/request issue
    SERVER_ERROR,      // 5xx errors - server/internal issue
    VALIDATION_ERROR,  // Validation failures
    AUTH_ERROR,        // Authn/authz failures
    NOT_FOUND,         // Resource not found
    CONFLICT,          // Conflict errors (409)
    RATE_LIMITED,      // Rate limiting (429)
    UNKNOWN            // Unclassified
}
```

**Usage in `WithController`**:
```java
default WebApplicationException toWebApplicationException(Exception exception, String responseType) {
    ErrorCategory category = categorize(exception);
    Metrics.counter("api_errors_total", "category", category.name()).increment();
    
    // ... existing mapping logic
}
```

**Status**: ❌ Not implemented yet

---

### 7. Stack Trace Suppression for Known Exceptions

**Current**: All exceptions include full stack trace in logs

**Proposal**: Configurable suppression for expected exceptions

**Approach A - Severity-based**:
- DEBUG/INFO level: No stack trace
- WARN: Stack trace truncated (first 3 lines)
- ERROR: Full stack trace

**Approach B - Exception-type-based**:
```java
public class TruncatingException extends RuntimeException {
    public static final Set<Class<?>> SUPPRESS_STACK_TRACE = Set.of(
        NotFoundException.class,
        BadRequestException.class
    );
}
```

**Status**: ⚠️ Optional (low priority)

---

## Implementation Plan

### Phase 1: Exception Types (Foundation)

1. Create `UnprocessableEntityException`
2. Create `UnauthorizedException` and `ForbiddenException`
3. Create `ErrorCategory` enum
4. Update `WithController` to handle new exception types

**Files Modified**:
- `WithController.java` - Add new exception type mappings
- `WithControllerTest.java` - Add tests for new types
- New exception classes (9 files)

**Estimated Tests**: 10 new test cases

---

### Phase 2: Structured Error Response

1. Create `ErrorResponse` class
2. Update `WithController.Error` to extend or replace with structured format
3. Update `toWebApplicationException()` to return structured response
4. Add `requestId` support (if not already present)

**Files Modified**:
- `WithController.java` - Major update to error response format
- All REST controllers - No changes needed (inherited)

**Estimated Tests**: 8 new test cases

---

### Phase 3: Logging & Context Improvements

1. Implement `LoggingConfig` for configurable severity
2. Update `execute()` to support context enrichment
3. Update all REST controller calls to include context

**Files Modified**:
- `WithController.java` - Add `executeWithLogging()` and context enhancements
- All REST controllers - Update calls to include context
- New: `LoggingConfig.java`

**Estimated Tests**: 4 new test cases

---

### Phase 4: Optional Enhancements (If Time Permits)

1. Stack trace suppression configuration
2. Exception categories in metrics
3. Documentation updates

---

## Risk Assessment

| Improvement | Risk | Breaking Change | Migration Complexity |
|-------------|------|-----------------|---------------------|
| New Exception Types | Low | Yes | Low |
| Structured Response | Medium | Yes (response body format) | Medium |
| Logging Configuration | Low | No | Low |
| Context Enrichment | Low | No | Medium |
| Exception Categories | Low | No | Low |
| Stack Trace Suppression | Very Low | No | Low |

**Overall Risk**: MEDIUM
- Breaking changes only in error response format (can be documented)
- Backward compatible with proper response parsing

---

## Migration Guide

### For API Clients

**Before**:
```json
{
  "message": "CPA not found: ABC123"
}
```

**After** (with structured response):
```json
{
  "timestamp": "2026-06-13T15:10:00.000Z",
  "status": 404,
  "error": "Not Found",
  "message": "CPA not found: ABC123",
  "path": "/api/cpas/ABC123",
  "requestId": "req-12345"
}
```

### For Controller Implementers

**Before**:
```java
public void process(String id) {
    try {
        service.process(id);
    } catch (RuntimeException e) {
        log.error("Process " + id, e);
        throw toWebApplicationException(e);
    }
}
```

**After**:
```java
public void process(String id) {
    WithController.execute(this, 
        () -> service.process(id),
        "Process " + id,
        Map.of("id", id));
}
```

---

## Testing Strategy

### Unit Tests
- `WithControllerTest` - Exception mappings (10 tests)
- `ErrorResponseTest` - Response format validation (8 tests)
- `LoggingConfigTest` - Severity configuration (4 tests)
- `CPARestControllerTest` - Integration (15 tests)
- `EbMSRestControllerTest` - Integration (12 tests)
- `AdminRestControllerTest` - Integration (16 tests)

### Integration Tests
- Verify error response format
- Verify logging behavior
- Verify request context propagation
- Verify exception categorization

---

## Success Metrics

- ✅ All 10 new exception type tests pass
- ✅ All structured response format tests pass
- ✅ All existing tests continue to pass
- ✅ API response size increases by ~15% (expected overhead)
- ✅ Logging verbosity reduced for expected exceptions

---

## Timeline Estimate

| Phase | Estimate |
|-------|----------|
| Phase 1: Exception Types | 2-3 hours |
| Phase 2: Structured Response | 2-3 hours |
| Phase 3: Logging & Context | 2-3 hours |
| Testing & Documentation | 2-3 hours |
| **Total** | **8-12 hours** |

---

## Open Questions

1. **Structured Response Timing**: Should we include timestamps in all responses or only errors?
2. **Request ID来源**: Should `requestId` come from HTTP headers or be auto-generated?
3. **Logging Backwards Compatibility**: Should we add a configuration flag to enable/disable new logging behavior?
4. **Exception Categories**: Should categories be added to the response for client visibility?

---

## Related Files

- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/WithController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/WithController.Error`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/cpa/rest/CPARestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ebms/rest/EbMSRestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/certificate/rest/CertificateMappingRestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/url/rest/URLMappingRestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/server/embedded/web/admin/AdminRestController.java`

---

## Notes

- Consider adding a configuration profile (dev/prod) to control verbose error reporting
- Ensure all new exception types are properly documented
- Consider adding custom Jackson serializers for consistent JSON output
- The plan assumes no external consumers rely on exact response format (internal API)
