# Plan: Improve Error Handling in Controllers

## Current State Analysis

### Error Handling Patterns Found

1. **WithController Interface** (`WithController.java`)
   - Centralized `toWebApplicationException()` method using Vavr's Match
   - Handles: `NotFoundException`, `CPANotFoundException`, `CertificateNotFoundException`, `URLNotFoundException`, `BadRequestException`, and default exceptions
   - Uses Vavr functional programming pattern for exception mapping

2. **REST Controllers** (CPARestController, EbMSRestController, URLMappingRestController, CertificateMappingRestController, AdminRestController)
   - Each method has try-catch blocks wrapping controller calls
   - Pattern: catch specific exceptions → log → throw toWebApplicationException
   - Duplicate catch blocks across methods (repeated for each endpoint)

3. **SOAP Controllers** (CPAControllerImpl, EbMSControllerImpl)
   - Similar try-catch pattern but throw wrapped ControllerExceptions
   - More verbose with re-throwing existing ControllerExceptions
   - Some methods catch specific exceptions, others catch RuntimeException only

### Issues Identified

1. **Code Duplication**
   - Identical catch patterns repeated in every controller method
   - Copy-paste of try-catch blocks across 40+ methods

2. **Inconsistent Exception Handling**
   - Some methods wrap specific exceptions in `BadRequestException`, others don't
   - Some methods specify response media type, others use default
   - Inconsistent logging format

3. **Verbose Try-Catch Blocks**
   - 3-4 catch blocks per method (30-40% of method body)
   - Obscures business logic

4. **Missing Error Information**
   - Error response only contains `message` field
   - No error codes, timestamps, or request context
   - No distinguishable error types in REST responses

5. **Lack of Central Exception Handler**
   - No JAX-RS `ExceptionMapper` for global handling
   - Each controller must manually handle exceptions

## Proposed Improvements

### 1. Central Exception Handler (JAX-RS ExceptionMapper)

**Step 1: Create EbmsExceptionMapper class**
Location: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/EbmsExceptionMapper.java`

```java
package nl.clockwork.ebms.api;

import jakarta.ws.rs.MatrixParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.val;
import lombok.extern.slf4j.Slf4j;

@Provider
@Slf4j
public class EbmsExceptionMapper implements ExceptionMapper<Exception>
{
  @Context
  private Request request;

  @Override
  public Response toResponse(Exception ex)
  {
    log.error("Exception in REST endpoint: " + request.getPathWithQuery(), ex);
    val webEx = new WithController().toWebApplicationException(ex);
    return webEx.getResponse();
  }
}
```

**Step 2: Register ExceptionMapper in EmbeddedWebConfig**
Update the `createRestServer` method to include the ExceptionMapper in the providers list:

```java
sf.setProviders(Arrays.asList(
    new EbmsExceptionMapper(),
    createCrossOriginResourceSharingFilter(), 
    createJacksonJsonProvider()
));
```

**Benefits:**
- Single source of truth for all REST exception handling
- Automatically applies to all REST controllers (no code changes needed)
- No verbose try-catch blocks required in controllers
- CXF processes `@Provider` classes automatically

**Considerations:**
- ExceptionMapper runs after controller throws exception
- Logs the exception with full stack trace
- Uses existing `WithController.toWebApplicationException()` logic

### 2. Enhanced Error Response

**Current:**
```java
@Value
public class Error {
    @NonNull
    String message;
}
```

**Enhanced:**
```java
@Value
public class Error {
    @NonNull String code;        // e.g., "E001", "CPA_INVALID"
    @NonNull String message;
    Instant timestamp;
    String path;
}
```

This would require updating `WithController.toWebApplicationException()` to include more context.

### 3. Refactor to Helper Method (Alternative if ExceptionMapper insufficient)

If ExceptionMapper doesn't fully solve the issues, add a helper to `WithController`:

```java
protected default <T> T safeCall(Supplier<T> action, String operation, Object... params) {
    try {
        return action.get();
    } catch (RuntimeException e) {
        log.error(buildLogMessage(operation, params), e);
        throw toWebApplicationException(e);
    }
}

private String buildLogMessage(String operation, Object... params) {
    return operation + (params.length > 0 ? " " + params : "");
}
```

Then use in controllers:
```java
@GET
@Path("{id}")
public String get(@PathParam("id") String id) {
    return safeCall(() -> controller.getMethod(id), "GetMethod", id);
}
```

### 4. Simplify SOAP Controllers

Remove redundant try-catch for ControllerException re-throw:

**Current:**
```java
@Override
public void validateCPA(String cpa) throws CPAControllerException {
    try {
        validateCPAImpl(cpa);
    } catch (CPAControllerException e) {
        log.error(...);
        throw e; // Redundant
    } catch (...) {
        ...
    }
}
```

**Simplified:**
```java
@Override
public void validateCPA(String cpa) throws CPAControllerException {
    try {
        validateCPAImpl(cpa);
    } catch (Exception e) {
        log.error("ValidateCPA\n" + cpa, e);
        throw new CPAControllerException(e);
    }
}
```

## Implementation Steps

### Phase 1: Add ExceptionMapper (30 min)
1. Create `EbmsExceptionMapper.java` in `ebms-core/core/src/main/java/nl/clockwork/ebms/api/`
2. Implement `toResponse()` using existing `WithController.toWebApplicationException()`
3. Update `EmbeddedWebConfig.createRestServer()` to include `EbmsExceptionMapper` in providers list
4. Test exception mappings work for all REST endpoints (CPARestController, EbMSRestController, URLMappingRestController, CertificateMappingRestController, AdminRestController)
5. **Optional:** Remove manual try-catch from REST controllers (can coexist initially, allows gradual migration)

### Phase 2: Enhance Error Response (30 min) - Optional
1. Add fields to `WithController.Error` (code, timestamp, path)
2. Update `toWebApplicationException()` to populate new fields
3. Update `EbmsExceptionMapper` to include additional context
4. Verify consumer applications can handle new response format

### Phase 3: Refactor REST Controllers (45 min) - Optional
- **Option A:** Keep ExceptionMapper, remove manual try-catch blocks for cleaner code
- **Option B:** Keep try-catch blocks for explicit error handling per method

### Phase 4: Simplify SOAP Controllers (30 min) - Separate
- Remove redundant try-catch for ControllerException re-throw
- Simplify exception wrapping pattern in CPAControllerImpl, EbMSControllerImpl, URLMappingControllerImpl, CertificateMappingControllerImpl

## Benefits

- **Zero code changes to existing controllers** - ExceptionMapper automatically applies
- **Single source of truth** for all REST exception handling
- **Consistent responses** - All REST errors use same format from WithController
- **Cleaner controller code** - No verbose try-catch blocks needed
- **Centralized logging** - ExceptionMapper logs all exceptions with path info
- **Backward compatible** - Existing responses remain unchanged

## Tradeoffs

- **ExceptionMapper:** Already integrated into `JAXRSServerFactoryBean` via `setProviders()` - no additional config needed beyond adding to list
- **No breaking changes** - ExceptionMapper wraps existing `WithController` logic
- **CXF handles @Provider** - No need for Spring bean registration

## Questions for User

1. **JAX-RS ExceptionMapper** - Should I proceed with this implementation?

2. **Controller refactoring** - After implementing ExceptionMapper, should I remove the try-catch blocks from all REST controllers? (Optional - can coexist)

3. **Enhanced Error Response** - Do you want to add error codes, timestamps, and path to the Error response? (Not required for basic ExceptionMapper implementation)

4. **SOAP controllers** - Should I apply simplifications to SOAP controllers (CPAControllerImpl, EbMSControllerImpl, etc.)? (Separate concern)
