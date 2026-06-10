# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- AI-ready configuration added: AGENTS.md, copilot instructions, CI workflows, issue templates, CONTRIBUTING.md
- Added Apache Kafka messaging plugin `nl.clockwork.ebms.plugin.messaging:ebms-kafka-messaging-plugin` mirroring the JMS plugin.
  - Adds `KAFKA` value to `deliveryManager.type` and `deliveryTaskHandler.type`, plus `SIMPLE_KAFKA`, `KAFKA`, and `KAFKA_TEXT` values to `eventListener.type`.
  - Properties: `kafka.bootstrapServers`, `kafka.clientId`, `kafka.consumer.*`, `kafka.producer.*`, `kafka.admin.autoCreate` (default `true`), `kafka.admin.numPartitions`, `kafka.admin.replicationFactor`, `kafka.topic.deliveryTask`, `kafka.topic.messageReplies`, `kafka.topic.eventPrefix`, `deliveryTaskHandler.kafka.concurrency`, `deliveryTaskHandler.kafka.pollTimeout`, `deliveryManager.kafka.replyTimeout`.
  - Replies on the shared `ebms-message-replies` topic are correlated by `refToMessageId`; each plugin instance uses its own UUID consumer group and filters out replies for other instances.
  - Record values use JDK serialization with a security-hardened class allow-list (`nl.clockwork.ebms.*`, `java.*`, `javax.*`, `org.oasis_open.*`, arrays).
  - The plugin is auto-discovered through `META-INF/services/nl.clockwork.ebms.PluginProvider`; the `ebms-admin` webapp bundles it.
- Upgraded `ebms-admin` to Spring Framework 7.0.7 (aligned with `ebms-core`); required to consume Spring Kafka 4.x from the new plugin.
- Replaced deprecated `org.springframework.lang.NonNull` with `org.jspecify.annotations.NonNull` across `ebms-core` and `ebms-admin` (transitively provided by Spring 7's `spring-core` dependency on JSpecify 1.0.0).
- Extracted JMS functionality into a new Maven plugin module `nl.clockwork.ebms.plugin.messaging:ebms-jms-messaging-plugin`.
  - `ebms-core` no longer depends on `jakarta.jms-api`, `spring-jms`, `org.apache.activemq:*`, or `org.apache.xbean:xbean-spring`.
  - Moved into the plugin: the ActiveMQ broker + pooled `ConnectionFactory`, the `JMS` `DeliveryManager`, the `JMS` delivery-task dispatcher + listener, the `SIMPLE_JMS`/`JMS`/`JMS_TEXT` `MessageEventListener` variants, the `nl/clockwork/ebms/activemq.xml` resource (now at `nl/clockwork/ebms/plugin/messaging/jms/activemq.xml`), and the `jms.*` / `deliveryTaskHandler.jms.*` / `eventListener.jms.destinationType` properties.
  - The plugin is auto-discovered through `META-INF/services/nl.clockwork.ebms.PluginProvider`; the `ebms-admin` webapp distribution bundles it.
  - The `EventListenerType`, `DeliveryManagerType` and `DeliveryTaskHandlerType` enum values referencing JMS remain in core as the public configuration contract; their bean wiring lives in the plugin and is activated only when the plugin is on the classpath.
  - Migration notes for embedders consuming `ebms-core` directly: add `nl.clockwork.ebms.plugin.messaging:ebms-jms-messaging-plugin` to your classpath if you use any `*.type=JMS` (or `SIMPLE_JMS`/`JMS_TEXT`) configuration; no changes needed when running the `ebms-admin` webapp.
- Replaced JMS/Quartz delivery-task scheduling with Raft-leader-gated DAO executor (jgroups-raft).
  - Removed `deliveryTaskHandler.type` values `JMS`, `QUARTZ`, `QUARTZ_JMS`; only `DEFAULT` is supported.
  - Removed `transactionManager.type` (and Atomikos XA support) — a single non-XA `DataSourceTransactionManager` is used.
  - Removed Maven dependencies: Quartz, Atomikos `transactions-jdbc`/`transactions-jms`/`transactions-jta`.
  - Added Raft properties `raft.configLocation` (default `ebms-raft.xml`) and `raft.clusterName` (default `ebms-cluster`).
  - Added bundled JGroups stack at `ebms-core/core/src/main/resources/ebms-raft.xml` (TCP+TCPPING, single-node defaults).
  - Database migration `V2.20.0__Drop_Quartz_Tables.sql` removes the `QRTZ_*` tables for upgraders.
  - Migration notes: drop `deliveryTaskHandler.jms.*`, `deliveryTaskHandler.quartz.*`, `transactionManager.type`, `transactionManager.transactionTimeout` from configuration; switch any XA JDBC driver (e.g. `org.postgresql.xa.PGXADataSource`) back to its plain JDBC driver. To scale beyond one node, override JGroups system properties such as `jgroups.raft.id`, `jgroups.raft.members`, and `jgroups.tcpping.initial_hosts`.
