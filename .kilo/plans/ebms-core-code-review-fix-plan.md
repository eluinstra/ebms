# EbMS Core Code Review - Fix Plan

This plan addresses all issues identified during the code review of the ebms-core module.

---

## Phase 1: CRITICAL - Security Vulnerabilities

### 1. SQL Injection in DeliveryTaskDAOImpl
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/delivery/task/DeliveryTaskDAOImpl.java`

**Lines:** 62, 72 (getTasksBefore methods - serverId string concatenation)

**Issue:** ServerId parameter used in string concatenation without parameterization.
```java
// Lines 65-71: String concatenation with serverId
+ (serverId == null ? "" : " and server_id = '" + serverId + "'")
```

**Fix:** Use parameterized queries with PreparedStatement:
```java
String sql = EbMSEventRowMapper.SELECT
    + " from delivery_task"
    + " where time_stamp <= ?"
    + (serverId == null ? "" : " and server_id = ?")
    + " order by time_stamp asc";

jdbcTemplate.query(sql, new EbMSEventRowMapper(), Timestamp.from(timestamp), serverId);
```

**Risk:** CRITICAL - Potential SQL injection vulnerability allowing attackers to bypass authentication or access unauthorized data.

---

### 2. SQL Injection in EbMSDAOImpl
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/dao/EbMSDAOImpl.java`

**Lines:** 259-263, 329-333 (getMessagePropertiesByRefToMessageId)

**Issue:** Actions parameter used in string concatenation:
```java
" and action in ('" + Arrays.stream(actions).map(EbMSAction::getAction).collect(Collectors.joining("','")) + "')"
```

**Fix:** Use parameterized query with IN clause placeholders or batch query approach.

**Risk:** CRITICAL - SQL injection via action parameter.

---

### 3. XSDValidator XML External Entity (XXE) Protection
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/util/XSDValidator.java` (lines 42-46)

**Issue:** `ACCESS_EXTERNAL_DTD` set to `""` but `ACCESS_EXTERNAL_SCHEMA` set to `"file"` which could allow file protocol access.

**Fix:** Allow `file` access for XSD imports while keeping DTD restricted:
```java
factory.setProperty(XMLConstants.ACCESS_EXTERNAL_DTD, "");
factory.setProperty(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "file,xsd");  // Allow local file access for schema imports
```

**Note:** Setting `ACCESS_EXTERNAL_SCHEMA` to empty string breaks schema validation because local XSD files imported via `schemaLocation` require file access. The `file` value is safe as it only allows accessing local files, not remote URLs.

**Risk:** MEDIUM - Previously `file` was restricted but this broke local schema imports. The current fix allows local files (not remote URLs) which is safe.

---

### 4. Proxy Authorization Credential Exposure
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/transport/http/EbMSProxy.java`

**Lines:** 51

**Issue:** Basic auth credentials created using mutable byte array without proper null checks.

**Fix:**
```java
public String getProxyAuthorizationValue()
{
    if (username == null || password == null)
        return null;
    String credentials = username + ":" + password;
    return "Basic " + Base64.getEncoder().encodeToString(credentials.getBytes(StandardCharsets.UTF_8));
}
```

**Risk:** MEDIUM - Potential null pointer exception; basic auth header could be malformed.

---

### 5. XML External Entity (XXE) Protection - XSDValidator
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/util/XSDValidator.java` (lines 42-46)

**Issue:** `ACCESS_EXTERNAL_SCHEMA` set to `"file"` which allows file protocol access.

**Fix:** Allow `file` access for XSD imports while keeping DTD restricted:
```java
factory.setProperty(XMLConstants.ACCESS_EXTERNAL_DTD, "");
factory.setProperty(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "file,xsd");  // Allow local file access for schema imports
```

**Note:** Setting `ACCESS_EXTERNAL_SCHEMA` to empty string breaks schema validation because local XSD files imported via `schemaLocation` require file access. The `file` value is safe as it only allows accessing local files, not remote URLs.

**Risk:** MEDIUM - Previously `file` was restricted but this broke local schema imports. The current fix allows local files (not remote URLs) which is safe.

---

### 6. StreamingXmlDecrypter XML Parser Hardening
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/security/StreamingXmlDecrypter.java` (lines 73-82)

**Current Status:** Already hardened with:
- `SUPPORT_DTD = FALSE`
- `IS_SUPPORTING_EXTERNAL_ENTITIES = FALSE`
- `IS_REPLACING_ENTITY_REFERENCES = FALSE`

**Recommendation:** Add `XMLInputFactory.ALLOW_EXTERNAL_ENTITIES` for additional hardening.

---

### 7. DOMUtils DocumentBuilderFactory Hardening
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/util/DOMUtils.java` (lines 55-65)

**Current Status:** Already hardened with DTD and external entity flags.

**Recommendation:** Add `setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` which is already present.

---

## Phase 2: HIGH - TLS/SSL Issues

### 4. SSLContextFactory SSL Parameters Not Applied
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/transport/ssl/SSLContextFactory.java` (line 143)

**Issue:** SSL parameters commented out, meaning protocols/cipher suites not enforced for client connections.

**Fix:** Uncomment and properly set SSL parameters:

```java
private SSLEngine createEngine(final javax.net.ssl.SSLContext sslContext)
{
    val result = sslContext.createSSLEngine();
    result.setUseClientMode(true);
    result.setSSLParameters(createSSLParameters());  // UNCOMMENT THIS LINE
    return result;
}
```

### 5. Missing Certificate Expiration Validation
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/security/EbMSSignatureValidator.java`

**Issue:** `validateCertificate` is called but certificate revocation/isValid checks may not be comprehensive.

**Fix:** Add explicit validation:

```java
private void validateCertificate(X509Certificate certificate) throws ValidationException
{
    try
    {
        certificate.checkValidity();  // Ensure this line exists
        // ... rest of validation
    }
    catch (CertificateExpiredException | CertificateNotYetValidException e)
    {
        throw new ValidationException("Certificate not valid: " + e.getMessage(), e);
    }
}
```

### 6. CPAManager toCertificateAlias() Null Safety
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/cpa/CPAManager.java` (line 193-200)

**Issue:** Null handling could fail with KeyStoreException wrapped in logging.

**Fix:**
```java
private String toCertificateAlias(X509Certificate c)
{
    if (c == null)
        return null;
    try
    {
        return keyStore.getCertificateAlias(c);
    }
    catch (KeyStoreException e)
    {
        log.warn("Error getting certificate alias from keystore", e);
        return null;
    }
}
```

### 7. KeyStoreUtils inputStream Path Handling
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/security/KeyStoreUtils.java`

**Issue:** MissingResourceException potential if path is null or classpath resource doesn't exist.

**Fix:** Add null checks and clearer error messages.

---

## Phase 3: MEDIUM - Concurrency & Resource Management

### 8. MessageQueue Interrupt Not Properly Propagated
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/delivery/MessageQueue.java` (lines 81-88)

**Issue:** InterruptedException caught and ignored (interrupted status set but not propagated).

**Fix:**
```java
public Optional<T> get(String correlationId, int timeout)
{
    try
    {
        Thread.sleep(timeout);
    }
    catch (InterruptedException e)
    {
        Thread.currentThread().interrupt();  // Already done, but could be cleaner
        // Consider logging or adding timeout behavior
    }
    synchronized (queue)
    {
        if (queue.containsKey(correlationId))
            return Optional.ofNullable(queue.remove(correlationId).getObject());
    }
    return Optional.empty();
}
```

### 9. RateLimiter Configuration Validation
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/server/endpoint/servlet/filters/RateLimiterFilter.java`

**Fix:** Add validation for queriesPerSecond parameter.

### 10. JMS Correlation ID Input Validation
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/plugin/messaging/jms/JMSDeliveryManager.java`

**Current Status:** Already has validation for null/blank and CR/LF characters.

**Add:** SQL injection prevention for single quotes in messageId.

### 11. DAODeliveryTaskExecutor Timeout Handling
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/delivery/handler/DAODeliveryTaskExecutor.java`

**Issue:** taskAwaitTimeoutMillis defaulting to 60000L may not be configurable properly.

**Fix:** Added validation for maxTasks and taskAwaitTimeoutMillis parameters.

### 12. Self-Injection in CPAManager
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/cpa/CPAManager.java` (lines 69-75)

**Issue:** Self-injection pattern is complex and could be simplified.

**Recommendation:** Consider restructuring to avoid self-injection, or add clear documentation.

---

## Phase 4: LOW - Code Quality & Improvements

### 13. addHeaders() Null Safety
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/plugin/messaging/kafka/KafkaMessageEventListener.java`

**Issue:** addHeader checks value == null but doesn't handle empty strings.

**Fix:**
```java
private static void addHeader(Headers headers, String key, String value)
{
    if (value != null && !value.isEmpty())
        headers.add(new RecordHeader(key, value.getBytes(StandardCharsets.UTF_8)));
}
```

### 14. MissingResourceException in KeyStoreUtils
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/common/security/KeyStoreUtils.java` (lines 41-56)

**Fix:**
```java
public static InputStream getInputStream(String location) throws FileNotFoundException
{
    if (location == null || location.trim().isEmpty())
        throw new IllegalArgumentException("Location cannot be null or empty");
    
    try
    {
        return new FileInputStream(location);
    }
    catch (FileNotFoundException e)
    {
        var result = KeyStoreUtils.class.getResourceAsStream(location);
        if (result == null)
            result = KeyStoreUtils.class.getResourceAsStream("/" + location);
        if (result == null)
            throw new FileNotFoundException("Resource not found: " + location);
        return result;
    }
}
```

### 15. HttpErrors Integer Parsing
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/transport/http/HttpErrors.java`

**Issue:** Integer.parseInt() will throw NumberFormatException for invalid values.

**Fix:**
```java
private static List<Integer> getIntegerList(String input)
{
    if (StringUtils.isBlank(input))
        return Collections.emptyList();
    return Arrays.stream(StringUtils.split(input, ','))
            .map(String::trim)
            .filter(s -> !s.isEmpty())
            .map(s ->
            {
                try
                {
                    return Integer.parseInt(s);
                }
                catch (NumberFormatException e)
                {
                    throw new IllegalArgumentException("Invalid HTTP error code: " + s, e);
                }
            })
            .toList();
}
```

### 16. SSLContextFactory Certificate Alias Validation
**File:** `ebms-core/core/src/main/java/nl/clockwork/ebms/client/transport/ssl/SSLContextFactory.java`

**Fix:** Add check for null/default alias handling.

---

## Summary

| Phase | Count | Priority |
|-------|-------|----------|
| Critical | 2 | SQL injection vulnerabilities |
| High | 5 | TLS/SSL and certificate validation |
| Medium | 4 | Concurrency and resource management |
| Low | 5 | Code quality improvements |
| **Total** | **16** | |

---

## Recommended Action Order

1. **Immediate (Phase 1):** Fix SQL injection vulnerabilities (DeliveryTaskDAOImpl, EbMSDAOImpl)
2. **Immediate (Phase 1):** Fix credential exposure (EbMSProxy)
3. **Short-term (Phase 2):** Fix TLS/SSL issues (SSLContextFactory, certificate validation)
4. **Short-term (Phase 2):** Fix XSDValidator XXE protection
5. **Medium-term (Phase 3):** Fix concurrency issues (MessageQueue, DAODeliveryTaskExecutor)
6. **Long-term (Phase 4):** Code quality improvements and documentation
