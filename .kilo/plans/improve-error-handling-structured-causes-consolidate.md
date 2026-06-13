# Plan: Improved Error Handling for EbMS

## Goal
Implement three specific improvements to error handling:
1. **Structured error response format** (item 3)
2. **Preserve exception cause chains** (item 5)
3. **Consolidate duplicate catch blocks** (item 6)

## Current State Analysis

### Exception Hierarchy
```
RuntimeException
├── BadRequestException
├── NotFoundException (extends EbMSProcessingException)
├── CPANotFoundException (extends CPAControllerException)
├── CPAControllerException (extends RuntimeException with @WebFault)
├── EbMSControllerException (extends RuntimeException with @WebFault)
├── CertificateMappingControllerException (extends RuntimeException with @WebFault)
│   └── CertificateNotFoundException
├── URLMappingControllerException (extends RuntimeException with @WebFault)
│   └── URLNotFoundException
├── EbMSProcessingException (extends EbMSProcessorException)
└── EbMSProcessorException (extends RuntimeException)
```

### Current Issues

1. **No structured error response** - `Error` class in `WithController` only has `message` field
2. **Exception wrapping loses context** - `BadRequestException` wraps causes but others don't preserve chain
3. **Duplicated try-catch blocks** - All REST controllers duplicate the same pattern
4. **Missing error codes** - `EbMSErrorCode` enum exists but is unused

## Improvement 1: Structured Error Response Format

### Design
Create a consistent error response structure that includes:
- Error code (from `EbMSErrorCode` enum)
- Human-readable message
- HTTP status code
- Timestamp
- Optional request ID (from MDC if available)

### Changes

**New file**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ErrorDetails.java`

```java
package nl.clockwork.ebms.api;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import lombok.experimental.FieldDefaults;

@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ErrorDetails
{
    String errorCode;
    String message;
    Integer httpStatus;
    Instant timestamp;
    String requestId;

    @Builder
    public ErrorDetails(String errorCode, String message, Integer httpStatus, Instant timestamp, String requestId)
    {
        this.errorCode = errorCode;
        this.message = message;
        this.httpStatus = httpStatus;
        this.timestamp = timestamp != null ? timestamp : Instant.now();
        this.requestId = requestId;
    }

    public static ErrorDetails builder()
    {
        return new ErrorDetails(null, null, null, null, null);
    }
}
```

**Update `WithController.Error` class** to use `ErrorDetails`:

```java
@Value
public class Error
{
    @NonNull
    ErrorDetails details;
}
```

**Update `toWebApplicationException`** to create structured errors:

```java
default WebApplicationException toWebApplicationException(Exception exception, String responseType)
{
    val errorCode = getErrorCode(exception);
    val message = getErrorMessage(exception);
    val httpStatus = getHttpStatus(exception);
    val requestId = MDC.get("requestId");
    
    val errorDetails = ErrorDetails.builder()
        .errorCode(errorCode)
        .message(message)
        .httpStatus(httpStatus)
        .requestId(requestId)
        .build();
    
    val response = Response.status(httpStatus)
        .type(responseType)
        .entity(errorDetails)
        .build();
    
    return new WebApplicationException(response);
}
```

## Improvement 2: Preserve Exception Cause Chains

### Current Issues
- `BadRequestException` wraps cause but lose original message
- `EbMSControllerException` in `EbMSControllerHandler` wraps `TransformerFactoryConfigurationError` in `RuntimeException` then in `EbMSProcessorException`, losing meaningful context
- Multiple catch blocks wrap exceptions unnecessarily

### Strategy
1. Create custom exception classes that preserve cause chains
2. Add message formatting convenience methods
3. Use exception chaining for better debugging

### Changes

**Update `BadRequestException`**:

```java
public class BadRequestException extends RuntimeException
{
    private static final long serialVersionUID = 1L;

    public BadRequestException(String message)
    {
        super(message);
    }

    public BadRequestException(Throwable cause)
    {
        super(cause);
    }

    public BadRequestException(String message, Throwable cause)
    {
        super(message, cause);
    }
}
```

**Update `EbMSControllerHandler.sendMessageMTOM`** - remove unnecessary wrapping:

```java
catch (TransformerFactoryConfigurationError e)
{
    throw new EbMSProcessorException("Failed to configure transformer", e);
}
```

**Add helper method to `WithController`** for formatted error messages:

```java
default String formatErrorMessage(Exception exception, String context)
{
    return String.format("%s: %s", context, exception.getMessage());
}
```

## Improvement 3: Consolidate Duplicate Catch Blocks

### Current Pattern in All Controllers
```java
try { ... }
catch (SAXException | IllegalArgumentException e) { ... }
catch (IOException | JAXBException | ParserConfigurationException e) { ... }
catch (RuntimeException e) { ... }
```

### Solution 1: Extract Helper Method

**Update `WithController`** to add execution helper:

```java
import java.util.function.Supplier;
import org.slf4j.MDC;

default <T> T execute(Supplier<T> operation, String context)
{
    try
    {
        return operation.get();
    }
    catch (Exception e)
    {
        logError(context, e);
        throw toWebApplicationException(e, MediaType.APPLICATION_JSON);
    }
}

default void execute(Runnable operation, String context)
{
    try
    {
        operation.run();
    }
    catch (Exception e)
    {
        logError(context, e);
        throw toWebApplicationException(e, MediaType.APPLICATION_JSON);
    }
}

default void logError(String context, Exception e)
{
    if (MDC.get("requestId") != null)
    {
        log.error("{} (requestId: {})", context, MDC.get("requestId"), e);
    }
    else
    {
        log.error(context, e);
    }
}
```

**Refactored Controller Example**:

```java
@POST
@Path("validate")
@Consumes(MediaType.TEXT_PLAIN)
public void validateCPA(String cpa)
{
    execute(() -> cpaController.validateCPAImpl(cpa), "ValidateCPA\n" + cpa);
}
```

**For operations with special exception handling**:

```java
@POST
@Path("")
@Consumes(MediaType.TEXT_PLAIN)
@Produces({MediaType.TEXT_PLAIN})
public String insertCPA(String cpa, @DefaultValue("false") @QueryParam("overwrite") Boolean overwrite)
{
    return execute(() -> {
        try
        {
            return cpaController.insertCPAImpl(cpa, overwrite);
        }
        catch (SAXException | IllegalArgumentException e)
        {
            throw new BadRequestException(e);
        }
    }, "InsertCPA\n" + cpa);
}
```

## Exception Code Mapping

Add helper methods to map exceptions to codes:

```java
default String getErrorCode(Exception exception)
{
    return Match(exception).of(
        Case($(instanceOf(NotFoundException.class)), o -> EbMSErrorCode.VALUE_NOT_RECOGNIZED.getErrorCode()),
        Case($(instanceOf(CPANotFoundException.class)), o -> EbMSErrorCode.VALUE_NOT_RECOGNIZED.getErrorCode()),
        Case($(instanceOf(CertificateNotFoundException.class)), o -> EbMSErrorCode.VALUE_NOT_RECOGNIZED.getErrorCode()),
        Case($(instanceOf(URLNotFoundException.class)), o -> EbMSErrorCode.VALUE_NOT_RECOGNIZED.getErrorCode()),
        Case($(instanceOf(BadRequestException.class)), o -> EbMSErrorCode.INCONSISTENT.getErrorCode()),
        Case($(), o -> EbMSErrorCode.UNKNOWN.getErrorCode()));
}

default Integer getHttpStatus(Exception exception)
{
    return Match(exception).of(
        Case($(instanceOf(NotFoundException.class)), o -> 404),
        Case($(instanceOf(CPANotFoundException.class)), o -> 404),
        Case($(instanceOf(CertificateNotFoundException.class)), o -> 404),
        Case($(instanceOf(URLNotFoundException.class)), o -> 404),
        Case($(instanceOf(BadRequestException.class)), o -> 400),
        Case($(), o -> 500));
}

default String getErrorMessage(Exception exception)
{
    return exception.getMessage() != null ? exception.getMessage() : exception.getClass().getSimpleName();
}
```

## File Changes Summary

### New Files
1. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ErrorDetails.java` - Structured error response DTO

### Modified Files
1. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/WithController.java`
   - Update `Error` class to use `ErrorDetails`
   - Add helper methods: `execute()`, `getErrorCode()`, `getHttpStatus()`, `getErrorMessage()`

2. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/cpa/exception/BadRequestException.java`
   - Add constructors to preserve cause chains

3. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/cpa/rest/CPARestController.java`
   - Replace try-catch blocks with `execute()` calls

4. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ebms/rest/EbMSRestController.java`
   - Replace try-catch blocks with `execute()` calls

5. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/certificate/rest/CertificateMappingRestController.java`
   - Replace try-catch blocks with `execute()` calls

6. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/url/rest/URLMappingRestController.java`
   - Replace try-catch blocks with `execute()` calls

7. `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ebms/rest/EbMSControllerHandler.java`
   - Fix exception wrapping in `sendMessageMTOM` to preserve cause chain

## Benefits

1. **Structured responses** - Clients receive consistent JSON error structure with codes and metadata
2. **Better debugging** - Exception chains preserved for root cause analysis
3. **Cleaner code** - ~90% reduction in exception handling boilerplate across controllers
4. **Consistent HTTP codes** - Automatic mapping based on exception type
5. **RequestId correlation** - Errors include request ID from MDC for distributed tracing

## Testing Strategy

1. **Unit tests** for new `ErrorDetails` class (no logic, just serialization)
2. **Unit tests** for `WithController.execute()` with lambdas
3. **Integration tests** for each REST endpoint verifying error response format
4. **Verify exception chains** with stack trace assertions in tests

## Backward Compatibility

- **Breaking change**: Response entity changes from plain `Error` (with `message`) to `ErrorDetails`
- **Mitigation**: Keep old `Error` class as inner class for backward compatibility OR update API documentation
