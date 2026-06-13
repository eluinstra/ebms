# Refactoring Plan: Remove Commons CLI and Strip `ebms.` Prefix from Properties

## Summary

Remove Apache Commons CLI dependency and strip the `ebms.` prefix from existing properties that start with `ebms.`. Properties without `ebms.` prefix remain unchanged.

## Properties with `ebms.` Prefix (to be changed)

### From `ebms-core/core/src/main/resources/nl/clockwork/ebms/default.properties`

Properties with `ebms.` prefix to be stripped:

| Current Property | New Property |
|-----------------|--------------|
| `ebms.request.maxBytes` | `request.maxBytes` |
| `ebms.logging.maxPayloadChars` | `logging.maxPayloadChars` |
| `ebms.jdbc.driverClassName` | `jdbc.driverClassName` |
| `ebms.jdbc.url` | `jdbc.url` |
| `ebms.jdbc.username` | `jdbc.username` |
| `ebms.jdbc.password` | `jdbc.password` |
| `ebms.jdbc.update` | `jdbc.update` |
| `ebms.jdbc.strict` | `jdbc.strict` |
| `ebms.jdbc.migrationBasePath` | `jdbc.migrationBasePath` |
| `ebms.pool.autoCommit` | `pool.autoCommit` |
| `ebms.pool.connectionTimeout` | `pool.connectionTimeout` |
| `ebms.pool.maxIdleTime` | `pool.maxIdleTime` |
| `ebms.pool.maxLifetime` | `pool.maxLifetime` |
| `ebms.pool.testQuery` | `pool.testQuery` |
| `ebms.pool.minPoolSize` | `pool.minPoolSize` |
| `ebms.pool.maxPoolSize` | `pool.maxPoolSize` |

Properties WITHOUT `ebms.` prefix (UNCHANGED):
- `cache.type`, `cache.configLocation`
- `raft.configLocation`, `raft.clusterName`
- `deliveryTaskHandler.*` (all)
- `deliveryTaskManager.*` (all)
- `deliveryManager.*` (all)
- `messageQueue.*` (all)
- `eventListener.*` (all)
- `http.*` (all)
- `https.*` (all)
- `ebmsMessage.*` (all)
- `logging.mdc`
- `truststore.*` (all)
- `client.keystore.*` (all)
- `signature.keystore.*` (all)
- `encryption.keystore.*` (all)

### From `ebms-core/server/src/main/resources/nl/clockwork/ebms/server/default.properties`

Properties with `ebms.` prefix to be stripped:

| Current Property | New Property |
|-----------------|--------------|
| `service.ebms.url` | `service.url` |
| `ebms.host` | `host` |
| `ebms.port` | `port` |
| `ebms.path` | `path` |
| `ebms.ssl` | `ssl` |
| `ebms.verifyHostnames` | `verifyHostnames` |
| `ebms.echoHeaderNames` | `echoHeaderNames` |
| `ebms.connectionLimit` | `connectionLimit` |
| `ebms.queriesPerSecond` | `queriesPerSecond` |
| `ebms.userQueriesPerSecond` | `userQueriesPerSecond` |
| `ebms.cors.allowOrigins` | `cors.allowOrigins` |
| `ebms.jdbc.driverClassName` | `jdbc.driverClassName` |
| `ebms.jdbc.url` | `jdbc.url` |
| `ebms.jdbc.username` | `jdbc.username` |
| `ebms.jdbc.password` | `jdbc.password` |

Properties WITHOUT `ebms.` prefix (UNCHANGED):
- `maxItemsPerPage`
- `https.protocols`, `https.cipherSuites`, `https.requireClientAuthentication`, `https.clientCertificateHeader` (all)
- `keystore.type`, `keystore.path`, `keystore.password`, `keystore.defaultAlias` (all)
- `truststore.type`, `truststore.path`, `truststore.password` (all)
- `logging.mdc.audit`, `logging.mdc.headerNames` (all)
- `api.*` (all - web server configuration)

## Code Changes Required

### Core Module Changes

#### 1. `ebms-core/core/src/main/resources/nl/clockwork/ebms/default.properties`

Update these properties (remove `ebms.` prefix):

```properties
# Datastore - remove ebms. prefix
jdbc.driverClassName=org.h2.Driver
jdbc.url=jdbc:h2:tcp://localhost:9092/tmp/ebms
jdbc.username=sa
jdbc.password=
jdbc.update=false
jdbc.strict=false
jdbc.migrationBasePath=classpath:/db/migration/

pool.autoCommit=true
pool.connectionTimeout=30000
pool.maxIdleTime=600000
pool.maxLifetime=1800000
pool.testQuery=
pool.minPoolSize=16
pool.maxPoolSize=32

# HTTPClient - remove ebms. prefix
request.maxBytes=5242880
logging.maxPayloadChars=8192
```

#### 2. Java Files with `@Value` Annotations

Update `DataSourceConfig.java`:
- `${ebms.jdbc.driverClassName}` → `${jdbc.driverClassName}`
- `${ebms.jdbc.url}` → `${jdbc.url}`
- `${ebms.jdbc.username}` → `${jdbc.username}`
- `${ebms.jdbc.password}` → `${jdbc.password}`
- `${ebms.jdbc.update}` → `${jdbc.update}`
- `${ebms.jdbc.strict}` → `${jdbc.strict}`
- `${ebms.jdbc.migrationBasePath}` → `${jdbc.migrationBasePath}`

Update `DataSourceConfig.java`:
- `${ebms.pool.autoCommit}` → `${pool.autoCommit}`
- `${ebms.pool.connectionTimeout}` → `${pool.connectionTimeout}`
- `${ebms.pool.maxIdleTime}` → `${pool.maxIdleTime}`
- `${ebms.pool.maxLifetime}` → `${pool.maxLifetime}`
- `${ebms.pool.testQuery}` → `${pool.testQuery}`
- `${ebms.pool.minPoolSize}` → `${pool.minPoolSize}`
- `${ebms.pool.maxPoolSize}` → `${pool.maxPoolSize}`

### Server Module Changes

#### 3. `ebms-core/server/src/main/resources/nl/clockwork/ebms/server/default.properties`

Update these properties (remove `ebms.` prefix):

```properties
# Remove ebms. prefix
service.url=http://localhost:8080/adapter
host=0.0.0.0
port=8888
path=/ebms
ssl=true
verifyHostnames=true
echoHeaderNames=
connectionLimit=
queriesPerSecond=
userQueriesPerSecond=
cors.allowOrigins=

# Datastore - remove ebms. prefix
jdbc.driverClassName=org.h2.Driver
jdbc.url=jdbc:h2:tcp://localhost:9092/./h2
jdbc.username=sa
jdbc.password=

# https.* properties unchanged (no ebms. prefix)
https.protocols=TLSv1.2
https.cipherSuites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
https.requireClientAuthentication=false
https.clientCertificateHeader=

# keystore.* properties unchanged (no ebms. prefix)
keystore.type=PKCS12
keystore.path=nl/clockwork/ebms/keystore.p12
keystore.password=password
keystore.defaultAlias=

# truststore.* properties unchanged (no ebms. prefix)
truststore.type=PKCS12
truststore.path=nl/clockwork/ebms/truststore.p12
truststore.password=my-secret-password

# logging.mdc.* properties unchanged (no ebms. prefix)
logging.mdc.audit=DISABLED
logging.mdc.headerNames=

# API Web Server Configuration (unchanged)
api.host=0.0.0.0
api.port=8080
api.path=/
api.ssl.enabled=false
api.ssl.keyStoreType=PKCS12
api.ssl.keyStorePath=nl/clockwork/ebms/keystore.p12
api.ssl.keyStorePassword=password
api.ssl.protocols=
api.ssl.cipherSuites=
api.ssl.clientAuthentication=false
api.ssl.trustStoreType=PKCS12
api.ssl.trustStorePath=
api.ssl.trustStorePassword=
api.ssl.clientTrustStoreType=PKCS12
api.ssl.clientTrustStorePath=
api.ssl.clientTrustStorePassword=

# API Health Service (unchanged)
api.health.enabled=false
api.health.port=8008

# API Server Filters (unchanged)
api.server.connectionLimit=
api.server.queriesPerSecond=
api.server.userQueriesPerSecond=

# API Logging (unchanged)
api.logging.audit.enabled=false
api.logging.echoHeaderNames=
api.logging.mdcHeaderNames=

# API JMX (unchanged)
api.jmx.enabled=false
api.jmx.port=1999
api.jmx.accessFile=
api.jmx.passwordFile=

# API Config (unchanged)
api.configDir=
```

#### 4. `StartEmbedded.java` - Update Property References

Update all property constants to remove `ebms.` prefix:

**Update constants:**
- `EBMS_HOST_PROPERTY` → Use `host` directly
- `EBMS_PORT_PROPERTY` → Use `port` directly
- `EBMS_PATH_PROPERTY` → Use `path` directly
- `EBMS_SSL_PROPERTY` → Use `ssl` directly
- `EBMS_VERIFY_HOSTNAMES_PROPERTY` → Use `verifyHostnames` directly
- `EBMS_ECHO_HEADER_NAMES_PROPERTY` → Use `echoHeaderNames` directly
- `EBMS_CONNECTION_LIMIT_PROPERTY` → Use `connectionLimit` directly
- `EBMS_QUERIES_PER_SECOND_PROPERTY` → Use `queriesPerSecond` directly
- `EBMS_USER_QUERIES_PER_SECOND_PROPERTY` → Use `userQueriesPerSecond` directly
- `EBMS_CORS_ALLOW_ORIGINS_PROPERTY` → Use `cors.allowOrigins` directly
- `EBMS_JDBC_DRIVER_CLASS_NAME_PROPERTY` → Use `jdbc.driverClassName` directly
- `EBMS_JDBC_URL_PROPERTY` → Use `jdbc.url` directly
- `EBMS_JDBC_USERNAME_PROPERTY` → Use `jdbc.username` directly
- `EBMS_JDBC_PASSWORD_PROPERTY` → Use `jdbc.password` directly
- `HTTPS_PROTOCOLS_PROPERTY` → Use `https.protocols` directly
- `HTTPS_CIPHER_SUITES_PROPERTY` → Use `https.cipherSuites` directly
- `HTTPS_REQUIRE_CLIENT_AUTHENTICATION_PROPERTY` → Use `https.requireClientAuthentication` directly
- `HTTPS_CLIENT_CERTIFICATE_HEADER_PROPERTY` → Use `https.clientCertificateHeader` directly
- `HTTPS_CLIENT_CERTIFICATE_AUTHENTICATION_PROPERTY` → Use `https.clientCertificateAuthentication` directly
- `KEYSTORE_TYPE_PROPERTY` → Use `keystore.type` directly
- `KEYSTORE_PATH_PROPERTY` → Use `keystore.path` directly
- `KEYSTORE_PASSWORD_PROPERTY` → Use `keystore.password` directly
- `KEYSTORE_DEFAULT_ALIAS_PROPERTY` → Use `keystore.defaultAlias` directly
- `TRUSTSTORE_TYPE_PROPERTY` → Use `truststore.type` directly
- `TRUSTSTORE_PATH_PROPERTY` → Use `truststore.path` directly
- `TRUSTSTORE_PASSWORD_PROPERTY` → Use `truststore.password` directly
- `LOGGING_MDC_AUDIT_PROPERTY` → Use `logging.mdc.audit` directly
- `LOGGING_MDC_HEADER_NAMES_PROPERTY` → Use `logging.mdc.headerNames` directly

### Removing Commons CLI

**Remove from `ebms-core/server/pom.xml`:**
```xml
<dependency>
  <groupId>commons-cli</groupId>
  <artifactId>commons-cli</artifactId>
  <version>1.11.0</version>
</dependency>
```

**Update `Start.java` and `StartEmbedded.java`:**
- Remove Commons CLI imports
- Remove CLI option constants
- Update `createOptions()` to return empty Options
- Remove `containsHelpOption()` CLI parsing logic

## Migration Steps

1. **Update core properties** - Remove `ebms.` prefix from properties in `nl/clockwork/ebms/default.properties`
2. **Update server properties** - Remove `ebms.` prefix from properties in `nl/clockwork/ebms/server/default.properties`
3. **Update Java code** - Update `DataSourceConfig.java` and `StartEmbedded.java` property keys
4. **Remove Commons CLI** - Remove dependency and clean up CLI-related code
5. **Run tests** - Verify tests pass with new property names

## Backward Compatibility

- **Breaking change** - Users must update property files to remove `ebms.` prefix
- Default values maintain current functionality
- Consider adding migration documentation

## Testing

1. Verify core module compiles and tests pass
2. Verify server module compiles and tests pass
3. Verify all plugin modules compile and tests pass
4. Test with custom properties files using properties without `ebms.` prefix
5. Test with default configuration
6. Verify Commons CLI dependency is fully removed
