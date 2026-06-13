# Plan: Improve WithController Interface

## Current State

The `WithController` interface (`nl.clockwork.ebms.api.WithController`) is a shared interface used by all REST controllers in the API layer. It provides a default method `toWebApplicationException()` that maps exceptions to HTTP responses.

### Current Implementation Issues

1. **Duplicated exception handling pattern** - All REST controllers (`CPARestController`, `EbMSRestController`, `CertificateMappingRestController`, `URLMappingRestController`) duplicate identical try-catch blocks:

```java
try
{
    serviceHandler.someOperation();
}
catch (RuntimeException e)
{
    log.error("Operation", e);
    throw toWebApplicationException(e);
}
```

2. **Missing exception type coverage** - The interface's `toWebApplicationException()` method only handles these exception types:
   - `NotFoundException`
   - `CPANotFoundException`
   - `CertificateNotFoundException`
   - `URLNotFoundException`
   - `BadRequestException`
   - `Exception` (catch-all)

   It does **not** handle:
   - `EbMSControllerException`
   - `CertificateMappingControllerException`
   - `URLMappingControllerException`
   - `CPAControllerException`

3. **Inconsistent error messages** - `BadRequestException` uses `exception.getMessage()` in its response, but other exceptions do not expose their messages, losing potentially useful debugging information.

4. **Vavr dependency** - Uses Vavr's pattern matching API (lines 55-61) when Java 17's `instanceof` pattern matching is available.

5. **No test coverage** - No unit tests verify the exception mapping behavior.

## Improvement Goals

1. **Reduce boilerplate** - Eliminate duplicated try-catch blocks in all REST controllers
2. **Consistent error responses** - Ensure all exception types contribute meaningful error messages
3. **Simplify code** - Replace Vavr with standard Java pattern matching
4. **Add test coverage** - Unit tests for exception mapping

## Proposed Changes

### 1. Refactor `WithController` to use Java pattern matching

**File**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/WithController.java`

**Before** (lines 55-63):
```java
val response = Match(exception).of(
        Case($(instanceOf(NotFoundException.class)), o -> Response.status(NOT_FOUND).type(responseType).build()),
        Case($(instanceOf(CPANotFoundException.class)), o -> Response.status(NOT_FOUND).type(responseType).build()),
        Case($(instanceOf(CertificateNotFoundException.class)), o -> Response.status(NOT_FOUND).type(responseType).build()),
        Case($(instanceOf(URLNotFoundException.class)), o -> Response.status(NOT_FOUND).type(responseType).build()),
        Case($(instanceOf(BadRequestException.class)), o -> Response.status(BAD_REQUEST).type(responseType).entity(exception.getMessage()).build()),
        Case($(), o -> Response.status(INTERNAL_SERVER_ERROR).type(responseType).entity(exception.getMessage()).build()));
return new WebApplicationException(response);
```

**After**:
```java
if (exception instanceof NotFoundException)
    return new WebApplicationException(Response.status(NOT_FOUND).type(responseType).build());
if (exception instanceof CPANotFoundException)
    return new WebApplicationException(Response.status(NOT_FOUND).type(responseType).build());
if (exception instanceof CertificateNotFoundException)
    return new WebApplicationException(Response.status(NOT_FOUND).type(responseType).build());
if (exception instanceof URLNotFoundException)
    return new WebApplicationException(Response.status(NOT_FOUND).type(responseType).build());
if (exception instanceof BadRequestException)
    return new WebApplicationException(Response.status(BAD_REQUEST).type(responseType).entity(exception.getMessage()).build());
if (exception instanceof CPAControllerException)
    return new WebApplicationException(Response.status(BAD_REQUEST).type(responseType).entity(exception.getMessage()).build());
if (exception instanceof EbMSControllerException)
    return new WebApplicationException(Response.status(INTERNAL_SERVER_ERROR).type(responseType).entity(exception.getMessage()).build());
if (exception instanceof CertificateMappingControllerException)
    return new WebApplicationException(Response.status(INTERNAL_SERVER_ERROR).type(responseType).entity(exception.getMessage()).build());
if (exception instanceof URLMappingControllerException)
    return new WebApplicationException(Response.status(INTERNAL_SERVER_ERROR).type(responseType).entity(exception.getMessage()).build());
return new WebApplicationException(Response.status(INTERNAL_SERVER_ERROR).type(responseType).entity(exception.getMessage()).build());
```

### 2. Add missing exception type imports

Add these imports to `WithController.java`:
```java
import nl.clockwork.ebms.api.cpa.exception.CPAControllerException;
import nl.clockwork.ebms.api.certificate.exception.CertificateMappingControllerException;
import nl.clockwork.ebms.api.url.exception.URLMappingControllerException;
import nl.clockwork.ebms.api.ebms.exception.EbMSControllerException;
```

### 3. Refactor controllers to remove try-catch boilerplate

**Option 3B - Keep WithController as interface, add static helper methods** (Selected)

Add static utility methods that accept lambdas for the operation. This keeps `WithController` as an interface while reducing boilerplate.

**File**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/WithController.java`

**Add after line 64**:
```java
    static <T> T execute(WithController controller, Supplier<T> operation, String logContext) {
        try {
            return operation.get();
        } catch (Exception e) {
            controller.log().error(logContext, e);
            throw controller.toWebApplicationException(e);
        }
    }

    static void execute(WithController controller, Runnable operation, String logContext) {
        try {
            operation.run();
        } catch (Exception e) {
            controller.log().error(logContext, e);
            throw controller.toWebApplicationException(e);
        }
    }

    default Logger log()
    {
        return LoggerFactory.getLogger(getClass());
    }
```

**How it works**:
- Controllers call `WithController.execute(this, () -> service.operation(), "context")`
- The static method handles try-catch, logging, and exception mapping
- Uses `controller.log()` - requires adding a `log()` default method to the interface

**Updated controller code** (example for CPARestController):
```java
public void validateCPA(String cpa)
{
    WithController.execute(this, () -> cpaController.validateCPAImpl(cpa), "ValidateCPA\n" + cpa);
}
```

**Requirements**:
- Add import: `import org.slf4j.Logger;`
- Add import: `import org.slf4j.LoggerFactory;`
- Add import: `import java.util.function.Supplier;`

**Benefits of Option 3B**:
- No class hierarchy changes - controllers keep implementing an interface
- No breaking changes to existing class structure
- Minimal code changes in controllers
- Clear explicit intent: `WithController.execute(...)` shows exception handling is happening

### 4. Update all REST controllers

The static `execute` method catches all exceptions and passes them to `toWebApplicationException`, so all exception handlers can be simplified to a single lambda.

**File**: `ebms-core/core/src/main/java/nl/clockwork/ebms/api/cpa/rest/CPARestController.java`

**Before** (lines 55-76):
```java
public void validateCPA(String cpa)
{
    try
    {
        cpaController.validateCPAImpl(cpa);
    }
    catch (SAXException | IllegalArgumentException e)
    {
        log.error("ValidateCPA\n" + cpa, e);
        throw toWebApplicationException(new BadRequestException(e));
    }
    catch (IOException | JAXBException | ParserConfigurationException e)
    {
        log.error("ValidateCPA\n" + cpa, e);
        throw toWebApplicationException(e);
    }
    catch (RuntimeException e)
    {
        log.error("ValidateCPA\n" + cpa, e);
        throw toWebApplicationException(e);
    }
}
```

**After**:
```java
public void validateCPA(String cpa)
{
    WithController.execute(this, () -> cpaController.validateCPAImpl(cpa), "ValidateCPA\n" + cpa);
}
```

**For operations that need special handling** (like wrapping in `BadRequestException`):

```java
public void insertCPA(String cpa, @DefaultValue("false") @QueryParam("overwrite") Boolean overwrite)
{
    WithController.execute(this, 
        () -> {
            try {
                return cpaController.insertCPAImpl(cpa, overwrite);
            } catch (SAXException | IllegalArgumentException e) {
                throw new BadRequestException(e);
            }
        }, 
        "InsertCPA\n" + cpa);
}
```

### 5. Add unit tests

**File**: `ebms-core/core/src/test/java/nl/clockwork/ebms/api/WithControllerTest.java`

```java
import static jakarta.ws.rs.core.Response.Status.BAD_REQUEST;
import static jakarta.ws.rs.core.Response.Status.INTERNAL_SERVER_ERROR;
import static jakarta.ws.rs.core.Response.Status.NOT_FOUND;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import jakarta.ws.rs.WebApplicationException;
import nl.clockwork.ebms.api.WithController;
import nl.clockwork.ebms.api.certificate.exception.CertificateNotFoundException;
import nl.clockwork.ebms.api.cpa.exception.BadRequestException;
import nl.clockwork.ebms.api.cpa.exception.CPANotFoundException;
import nl.clockwork.ebms.api.ebms.exception.NotFoundException;
import nl.clockwork.ebms.api.url.exception.URLNotFoundException;
import org.junit.jupiter.api.Test;

class WithControllerTest {

    private final TestController controller = new TestController();

    @Test
    void shouldMapNotFoundExceptionTo404() {
        var exception = new NotFoundException("test");
        var webEx = controller.toWebApplicationException(exception);
        assertEquals(NOT_FOUND.getStatusCode(), webEx.getResponse().getStatus());
    }

    @Test
    void shouldMapCPANotFoundExceptionTo404() {
        var exception = new CPANotFoundException();
        var webEx = controller.toWebApplicationException(exception);
        assertEquals(NOT_FOUND.getStatusCode(), webEx.getResponse().getStatus());
    }

    @Test
    void shouldMapCertificateNotFoundExceptionTo404() {
        var exception = new CertificateNotFoundException();
        var webEx = controller.toWebApplicationException(exception);
        assertEquals(NOT_FOUND.getStatusCode(), webEx.getResponse().getStatus());
    }

    @Test
    void shouldMapURLNotFoundExceptionTo404() {
        var exception = new URLNotFoundException();
        var webEx = controller.toWebApplicationException(exception);
        assertEquals(NOT_FOUND.getStatusCode(), webEx.getResponse().getStatus());
    }

    @Test
    void shouldMapBadRequestExceptionTo400() {
        var cause = new IllegalArgumentException("invalid");
        var exception = new BadRequestException(cause);
        var webEx = controller.toWebApplicationException(exception);
        assertEquals(BAD_REQUEST.getStatusCode(), webEx.getResponse().getStatus());
        assertTrue(webEx.getResponse().getEntity().toString().contains("invalid"));
    }

    @Test
    void shouldMapUnknownExceptionTo500() {
        var exception = new RuntimeException("unexpected");
        var webEx = controller.toWebApplicationException(exception);
        assertEquals(INTERNAL_SERVER_ERROR.getStatusCode(), webEx.getResponse().getStatus());
        assertTrue(webEx.getResponse().getEntity().toString().contains("unexpected"));
    }

    private static class TestController implements WithController {}
}
```

## Migration Steps

1. Update `WithController.java` with new pattern matching code and exception imports
2. Add helper methods to reduce controller boilerplate
3. Update `CPARestController` to use refactored exception handling
4. Update `EbMSRestController` to use refactored exception handling
5. Update `CertificateMappingRestController` to use refactored exception handling
6. Update `URLMappingRestController` to use refactored exception handling
7. Create unit tests for `WithController`
8. Run tests to verify all exception mappings work correctly
9. Run full build to ensure no breaking changes

## Benefits

- **Cleaner code**: Eliminate ~90+ lines of duplicated try-catch blocks across 4 REST controllers
- **Better error messages**: All exceptions now expose their messages in responses
- **Standard Java**: Remove Vavr dependency for pattern matching
- **Test coverage**: Ensure exception mappings work as expected
- **Extensibility**: Easy to add new exception types in the future

## Risk Assessment

- **Low risk**: Changes are isolated to exception mapping logic
- **Backward compatible**: HTTP status codes remain the same
- **Behaviorally equivalent**: Same exception handling, just cleaner implementation

## Related Files

- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/WithController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/cpa/rest/CPARestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/ebms/rest/EbMSRestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/certificate/rest/CertificateMappingRestController.java`
- `ebms-core/core/src/main/java/nl/clockwork/ebms/api/url/rest/URLMappingRestController.java`
- `ebms-core/server/src/main/java/nl/clockwork/ebms/server/embedded/web/admin/AdminRestController.java`
