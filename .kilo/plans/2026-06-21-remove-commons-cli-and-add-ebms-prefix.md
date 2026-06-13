# Refactoring Plan: Remove Commons CLI and Add 'ebms.' Prefix to Properties

## Summary

Remove Apache Commons CLI dependency and convert command-line property access to use property files with the `ebms.` prefix for EbMS-related properties that don't already use `api.` or `ebms.` prefixes.

## Scope

### Modules Affected (ebms-core only)
- `ebms-core/core` - Core configuration properties
- `ebms-core/server` - Server configuration properties
- `ebms-core/plugin/*` - Plugin properties

### Files Impacted

#### ebms-core/core
- `nl/clockwork/ebms/default.properties` - Core properties
- Source files in `nl/clockwork/ebms/**`

#### ebms-core/server
- `nl/clockwork/ebms/server/default.properties` - Server properties
- `nl/clockwork/ebms/server/embedded/startup/Start.java`
- `nl/clockwork/ebms/server/embedded/startup/StartEmbedded.java`
- Source files in `nl/clockwork/ebms/server/**`

#### ebms-core/plugin/*
- Database plugin properties (h2, postgres, oracle, mariadb, mssql, db2, hsqldb)
- Messaging plugin properties (kafka, jms)
- Cache plugin properties (hazelcast, ehcache)

## Properties Requiring Migration

### From `ebms-core/core/src/main/resources/nl/clockwork/ebms/default.properties`

All properties below need `ebms.` prefix (they don't start with `api.` or `ebms.`):

| Current Property | New Property (with ebms.) | Default Value |
|-----------------|---------------------------|---------------|
| `cache.type` | `ebms.cache.type` | `DEFAULT` |
| `cache.configLocation` | `ebms.cache.configLocation` | (empty) |
| `deliveryTaskHandler.start` | `ebms.deliveryTaskHandler.start` | `true` |
| `deliveryTaskHandler.type` | `ebms.deliveryTaskHandler.type` | `DEFAULT` |
| `deliveryTaskHandler.minThreads` | `ebms.deliveryTaskHandler.minThreads` | `16` |
| `deliveryTaskHandler.maxThreads` | `ebms.deliveryTaskHandler.maxThreads` | `16` |
| `deliveryTaskHandler.default.maxTasks` | `ebms.deliveryTaskHandler.default.maxTasks` | `100` |
| `deliveryTaskHandler.default.executionInterval` | `ebms.deliveryTaskHandler.default.executionInterval` | `1000` |
| `deliveryTaskHandler.default.leaderCheckIntervalMillis` | `ebms.deliveryTaskHandler.default.leaderCheckIntervalMillis` | `1000` |
| `deliveryTaskHandler.default.taskAwaitTimeoutMillis` | `ebms.deliveryTaskHandler.default.taskAwaitTimeoutMillis` | `60000` |
| `deliveryTaskHandler.task.executionInterval` | `ebms.deliveryTaskHandler.task.executionInterval` | `0` |
| `raft.configLocation` | `ebms.raft.configLocation` | `ebms-raft.xml` |
| `raft.clusterName` | `ebms.raft.clusterName` | `ebms-cluster` |
| `deliveryTaskManager.nrAutoRetries` | `ebms.deliveryTaskManager.nrAutoRetries` | `0` |
| `deliveryTaskManager.autoRetryInterval` | `ebms.deliveryTaskManager.autoRetryInterval` | `5` |
| `deliveryManager.type` | `ebms.deliveryManager.type` | `DEFAULT` |
| `deliveryManager.minThreads` | `ebms.deliveryManager.minThreads` | `2` |
| `deliveryManager.maxThreads` | `ebms.deliveryManager.maxThreads` | `8` |
| `messageQueue.maxEntries` | `ebms.messageQueue.maxEntries` | `64` |
| `messageQueue.timeout` | `ebms.messageQueue.timeout` | `30000` |
| `eventListener.type` | `ebms.eventListener.type` | `DEFAULT` |
| `eventListener.filter` | `ebms.eventListener.filter` | (empty) |
| `http.connectTimeout` | `ebms.http.connectTimeout` | `30000` |
| `http.readTimeout` | `ebms.http.readTimeout` | `30000` |
| `http.uuid.headerName` | `ebms.http.uuid.headerName` | (empty) |
| `ebms.request.maxBytes` | `ebms.ebms.request.maxBytes` | `5242880` |
| `ebms.logging.maxPayloadChars` | `ebms.ebms.logging.maxPayloadChars` | `8192` |
| `http.errors.informational.recoverable` | `ebms.http.errors.informational.recoverable` | (empty) |
| `http.errors.redirection.recoverable` | `ebms.http.errors.redirection.recoverable` | (empty) |
| `http.errors.client.recoverable` | `ebms.http.errors.client.recoverable` | `408,429` |
| `http.errors.server.unrecoverable` | `ebms.http.errors.server.unrecoverable` | `501,505,510` |
| `https.protocols` | `ebms.https.protocols` | `TLSv1.3,TLSv1.2` |
| `https.cipherSuites` | `ebms.https.cipherSuites` | (see file) |
| `https.verifyHostnames` | `ebms.https.verifyHostnames` | `true` |
| `https.clientCertificateAuthentication` | `ebms.https.clientCertificateAuthentication` | `false` |
| `https.useClientCertificate` | `ebms.https.useClientCertificate` | `false` |
| `http.proxy.host` | `ebms.http.proxy.host` | (empty) |
| `http.proxy.port` | `ebms.http.proxy.port` | `0` |
| `http.proxy.nonProxyHosts` | `ebms.http.proxy.nonProxyHosts` | `127.0.0.1,localhost` |
| `http.proxy.username` | `ebms.http.proxy.username` | (empty) |
| `http.proxy.password` | `ebms.http.proxy.password` | (empty) |
| `ebmsMessage.deleteContentOnProcessed` | `ebms.ebmsMessage.deleteContentOnProcessed` | `false` |
| `ebmsMessage.attachment.memoryTreshold` | `ebms.ebmsMessage.attachment.memoryTreshold` | `131072` |
| `ebmsMessage.attachment.outputDirectory` | `ebms.ebmsMessage.attachment.outputDirectory` | (empty) |
| `ebmsMessage.attachment.cipherTransformation` | `ebms.ebmsMessage.attachment.cipherTransformation` | (empty) |
| `logging.mdc` | `ebms.logging.mdc` | `DISABLED` |
| `truststore.type` | `ebms.truststore.type` | `PKCS12` |
| `truststore.path` | `ebms.truststore.path` | `nl/clockwork/ebms/truststore.p12` |
| `truststore.password` | `ebms.truststore.password` | `my-secret-password` |
| `client.keystore.type` | `ebms.client.keystore.type` | `PKCS12` |
| `client.keystore.path` | `ebms.client.keystore.path` | `nl/clockwork/ebms/keystore.p12` |
| `client.keystore.password` | `ebms.client.keystore.password` | `my-secret-password` |
| `client.keystore.keyPassword` | `ebms.client.keystore.keyPassword` | `${client.keystore.password}` |
| `client.keystore.defaultAlias` | `ebms.client.keystore.defaultAlias` | (empty) |
| `signature.keystore.type` | `ebms.signature.keystore.type` | `PKCS12` |
| `signature.keystore.path` | `ebms.signature.keystore.path` | `nl/clockwork/ebms/keystore.p12` |
| `signature.keystore.password` | `ebms.signature.keystore.password` | `my-secret-password` |
| `signature.keystore.keyPassword` | `ebms.signature.keystore.keyPassword` | `${signature.keystore.password}` |
| `encryption.keystore.type` | `ebms.encryption.keystore.type` | `PKCS12` |
| `encryption.keystore.path` | `ebms.encryption.keystore.path` | `nl/clockwork/ebms/keystore.p12` |
| `encryption.keystore.password` | `ebms.encryption.keystore.password` | `my-secret-password` |
| `encryption.keystore.keyPassword` | `ebms.encryption.keystore.keyPassword` | `${encryption.keystore.password}` |
| `ebms.jdbc.driverClassName` | `ebms.ebms.jdbc.driverClassName` | (varies) |
| `ebms.jdbc.url` | `ebms.ebms.jdbc.url` | (varies) |
| `ebms.jdbc.username` | `ebms.ebms.jdbc.username` | (varies) |
| `ebms.jdbc.password` | `ebms.ebms.jdbc.password` | (empty) |
| `ebms.jdbc.update` | `ebms.ebms.jdbc.update` | `false` |
| `ebms.jdbc.strict` | `ebms.ebms.jdbc.strict` | `false` |
| `ebms.jdbc.migrationBasePath` | `ebms.ebms.jdbc.migrationBasePath` | `classpath:/db/migration/` |
| `ebms.pool.autoCommit` | `ebms.ebms.pool.autoCommit` | `true` |
| `ebms.pool.connectionTimeout` | `ebms.ebms.pool.connectionTimeout` | `30000` |
| `ebms.pool.maxIdleTime` | `ebms.ebms.pool.maxIdleTime` | `600000` |
| `ebms.pool.maxLifetime` | `ebms.ebms.pool.maxLifetime` | `1800000` |
| `ebms.pool.testQuery` | `ebms.ebms.pool.testQuery` | (empty) |
| `ebms.pool.minPoolSize` | `ebms.ebms.pool.minPoolSize` | `16` |
| `ebms.pool.maxPoolSize` | `ebms.ebms.pool.maxPoolSize` | `32` |

### From `ebms-core/server/src/main/resources/nl/clockwork/ebms/server/default.properties`

| Current Property | New Property (with ebms.) | Default Value |
|-----------------|---------------------------|---------------|
| `service.ebms.url` | `ebms.service.ebms.url` | `http://localhost:8080/adapter` |
| `ebms.host` | `ebms.ebms.host` | `0.0.0.0` |
| `ebms.port` | `ebms.ebms.port` | `8888` |
| `ebms.path` | `ebms.ebms.path` | `/ebms` |
| `ebms.ssl` | `ebms.ebms.ssl` | `true` |
| `ebms.verifyHostnames` | `ebms.ebms.verifyHostnames` | `true` |
| `ebms.echoHeaderNames` | `ebms.ebms.echoHeaderNames` | (empty) |
| `ebms.connectionLimit` | `ebms.ebms.connectionLimit` | (empty) |
| `ebms.queriesPerSecond` | `ebms.ebms.queriesPerSecond` | (empty) |
| `ebms.userQueriesPerSecond` | `ebms.ebms.userQueriesPerSecond` | (empty) |
| `ebms.cors.allowOrigins` | `ebms.ebms.cors.allowOrigins` | (empty) |
| `https.protocols` | `ebms.https.protocols` | `TLSv1.2` |
| `https.cipherSuites` | `ebms.https.cipherSuites` | (see file) |
| `https.requireClientAuthentication` | `ebms.https.requireClientAuthentication` | `false` |
| `https.clientCertificateHeader` | `ebms.https.clientCertificateHeader` | (empty) |
| `logging.mdc.audit` | `ebms.logging.mdc.audit` | `DISABLED` |
| `logging.mdc.headerNames` | `ebms.logging.mdc.headerNames` | (empty) |
| `keystore.type` | `ebms.keystore.type` | `PKCS12` |
| `keystore.path` | `ebms.keystore.path` | `nl/clockwork/ebms/keystore.p12` |
| `keystore.password` | `ebms.keystore.password` | `password` |
| `keystore.defaultAlias` | `ebms.keystore.defaultAlias` | (empty) |
| `maxItemsPerPage` | `ebms.maxItemsPerPage` | `20` |

### Plugin-specific properties

#### JMS plugin (`ebms-core/plugin/messaging/jms`)
| Current Property | New Property (with ebms.) |
|-----------------|---------------------------|
| `jms.broker.config` | `ebms.jms.broker.config` |
| `jms.broker.username` | `ebms.jms.broker.username` |
| `jms.broker.password` | `ebms.jms.broker.password` |
| `jms.broker.start` | `ebms.jms.broker.start` |
| `jms.brokerURL` | `ebms.jms.brokerURL` |
| `jms.pool.minPoolSize` | `ebms.jms.pool.minPoolSize` |
| `jms.pool.maxPoolSize` | `ebms.jms.pool.maxPoolSize` |
| `deliveryTaskHandler.jms.destinationName` | `ebms.deliveryTaskHandler.jms.destinationName` |
| `deliveryTaskHandler.jms.receiveTimeout` | `ebms.deliveryTaskHandler.jms.receiveTimeout` |
| `deliveryTaskHandler.jms.concurrentConsumers` | `ebms.deliveryTaskHandler.jms.concurrentConsumers` |
| `deliveryTaskHandler.jms.maxConcurrentConsumers` | `ebms.deliveryTaskHandler.jms.maxConcurrentConsumers` |
| `eventListener.jms.destinationType` | `ebms.eventListener.jms.destinationType` |

#### Kafka plugin (`ebms-core/plugin/messaging/kafka`)
| Current Property | New Property (with ebms.) |
|-----------------|---------------------------|
| `kafka.bootstrapServers` | `ebms.kafka.bootstrapServers` |
| `kafka.clientId` | `ebms.kafka.clientId` |
| `kafka.consumer.groupIdPrefix` | `ebms.kafka.consumer.groupIdPrefix` |
| `kafka.consumer.autoOffsetReset` | `ebms.kafka.consumer.autoOffsetReset` |
| `kafka.producer.acks` | `ebms.kafka.producer.acks` |
| `kafka.producer.enableIdempotence` | `ebms.kafka.producer.enableIdempotence` |
| `kafka.admin.autoCreate` | `ebms.kafka.admin.autoCreate` |
| `kafka.admin.numPartitions` | `ebms.kafka.admin.numPartitions` |
| `kafka.admin.replicationFactor` | `ebms.kafka.admin.replicationFactor` |
| `kafka.topic.deliveryTask` | `ebms.kafka.topic.deliveryTask` |
| `kafka.topic.messageReplies` | `ebms.kafka.topic.messageReplies` |
| `kafka.topic.eventPrefix` | `ebms.kafka.topic.eventPrefix` |
| `deliveryTaskHandler.kafka.concurrency` | `ebms.deliveryTaskHandler.kafka.concurrency` |
| `deliveryTaskHandler.kafka.pollTimeout` | `ebms.deliveryTaskHandler.kafka.pollTimeout` |
| `deliveryManager.kafka.replyTimeout` | `ebms.deliveryManager.kafka.replyTimeout` |

#### Database plugins
| Current Property | New Property (with ebms.) |
|-----------------|---------------------------|
| `database.start` | `ebms.database.start` |
| `database.dir` | `ebms.database.dir` |
| `ebms.jdbc.driverClassName` | `ebms.ebms.jdbc.driverClassName` |
| `ebms.jdbc.url` | `ebms.ebms.jdbc.url` |
| `ebms.jdbc.username` | `ebms.ebms.jdbc.username` |
| `ebms.jdbc.password` | `ebms.ebms.jdbc.password` |

#### Cache plugins
| Current Property | New Property (with ebms.) |
|-----------------|---------------------------|
| `cache.type` | `ebms.cache.type` |
| `cache.configLocation` | `ebms.cache.configLocation` |

## Code Changes Required

### Core Module

#### 1. ebms-core/core/src/main/resources/nl/clockwork/ebms/default.properties
- Rename all non-prefixed properties to use `ebms.` prefix

#### 2. ebms-core/core/src/main/java/nl/clockwork/ebms/***

Files to update with `@Value` annotations:
- `KeyStoreConfig.java` - Update property keys for truststore, client.keystore, signature.keystore, encryption.keystore
- `EbMSClientConfig.java` - Update property keys for http, https, proxy
- `ValidationConfig.java` - Update property key for https.clientCertificateAuthentication
- `CommonConfig.java` - Update property key for logging.mdc
- `CPAConfig.java` - Update property key for https.useClientCertificate
- `CacheConfig.java` - Update property key for cache.type
- `DeliveryManagerConfig.java` - Update property keys for deliveryManager, messageQueue
- `DeliveryTaskHandlerConfig.java` - Update property keys for deliveryTaskHandler, raft, ebmsMessage, http
- `DataSourceConfig.java` - Update property keys for ebms.jdbc, ebms.pool
- `MessageEventListenerConfig.java` - Update property key for eventListener

Files to update with `context.getEnvironment().getProperty`:
- `CacheConfig.java` - DefaultCacheType class
- `MessageEventListenerConfig.java` - DefaultEventListenerType, DaoEventListenerType classes
- `DeliveryManagerConfig.java` - DefaultDeliveryManagerType class
- `DeliveryTaskHandlerConfig.java` - DefaultTaskHandlerType, TaskHandlerActive classes
- `DataSourceConfig.java` - NotStartDatabaseServerType class
- `DeliveryTaskHandlerConfig.java` - Property access for raft configuration

### Server Module

#### 3. ebms-core/server/src/main/resources/nl/clockwork/ebms/server/default.properties
- Rename all non-prefixed properties to use `ebms.` prefix

#### 4. ebms-core/server/src/main/java/nl/clockwork/ebms/server/embedded/***

Files to update:
- `StartEmbedded.java`:
  - Remove all EBMS_*_PROPERTY constants
  - Update all `properties.getProperty()` calls to use `ebms.` prefix
  - Update property keys for ebms server configuration

### Plugin Modules

#### 5. Database plugins
- Update default.properties files in each plugin directory
- Update Java files that reference `ebms.jdbc.*` properties

#### 6.Messaging plugins
- JMS: Update `default.properties` and plugin config files
- Kafka: Update `default.properties` and plugin config files

#### 7. Cache plugins
- Update `default.properties` files
- Update `CacheConfig.java` in core module for cache.type property

## Migration Steps

1. **Update core properties** - Convert all properties in `nl/clockwork/ebms/default.properties` to use `ebms.` prefix
2. **Update core Java code** - Update all `@Value` annotations and `getProperty` calls in core module
3. **Update server properties** - Convert all properties in `nl/clockwork/ebms/server/default.properties`
4. **Update server Java code** - Update `StartEmbedded.java` to use `ebms.` prefix
5. **Update plugin properties** - Convert properties in each plugin module's `default.properties`
6. **Update plugin Java code** - Update plugin config classes to use `ebms.` prefix
7. **Remove Commons CLI usage** - Update `Start.java` and `StartEmbedded.java` to not parse CLI arguments (from previous plan)
8. **Run tests** - Verify all tests pass with new property names

## Backward Compatibility

- This is a **breaking change** for users
- Existing property files will need to be updated with the `ebms.` prefix
- Consider adding documentation about the migration
- Default values should maintain current functionality

## Testing

1. Verify core module compiles and tests pass
2. Verify server module compiles and tests pass
3. Verify all plugin modules compile and tests pass
4. Test with custom properties files using new `ebms.` prefix
5. Test with default configuration
