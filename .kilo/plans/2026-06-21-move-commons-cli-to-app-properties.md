# Refactoring Plan: Replace Commons CLI with Application Properties

## Summary

Replace command-line argument parsing (Apache Commons CLI) in `Start.java` and `StartEmbedded.java` with application properties. All configuration properties should use the `api.` prefix.

## Scope

- **Modules**: `ebms-core/server` only
- **Files Impacted**:
  - `Startup.java` - Main start class in ebms-core
  - `StartEmbedded.java` - Embedded start class in ebms-core
  - `default.properties` - Add new `api.` prefixed properties

## Property Mapping

The following command-line options need to be converted to `api.` prefixed properties:

### Web Server Properties (api.* prefix)

| Command-Line Option | Property Key | Default Value | Notes |
|---------------------|--------------|---------------|-------|
| `-host` | `api.host` | `0.0.0.0` | Host for web/SOAP/REST server |
| `-port` | `api.port` | `8080` | Port for web/SOAP/REST server |
| `-path` | `api.path` | `/` | Context path for web/SOAP/REST server |
| `-ssl` | `api.ssl.enabled` | `false` | Enable HTTPS |
| `-keyStoreType` | `api.ssl.keyStoreType` | `PKCS12` | Keystore type |
| `-keyStorePath` | `api.ssl.keyStorePath` | `nl/clockwork/ebms/keystore.p12` | Keystore file path |
| `-keyStorePassword` | `api.ssl.keyStorePassword` | (required) | Keystore password |
| `-protocols` | `api.ssl.protocols` | (none) | SSL protocols |
| `-cipherSuites` | `api.ssl.cipherSuites` | (none) | SSL cipher suites |
| `-clientAuthentication` | `api.ssl.clientAuthentication` | `false` | Enable client cert auth |
| `-trustStoreType` | `api.ssl.trustStoreType` | `PKCS12` | Truststore type |
| `-trustStorePath` | `api.ssl.trustStorePath` | (none) | Truststore path |
| `-trustStorePassword` | `api.ssl.trustStorePassword` | (none) | Truststore password |

### Server-Specific Properties

| Command-Line Option | Property Key | Default Value | Notes |
|---------------------|--------------|---------------|-------|
| `-health` | `api.health.enabled` | `false` | Enable health service |
| `-healthPort` | `api.health.port` | `8008` | Health service port |
| `-connectionLimit` | `api.server.connectionLimit` | (none) | Max connections |
| `-queriesPerSecond` | `api.server.queriesPerSecond` | (none) | Global rate limit |
| `-userQueriesPerSecond` | `api.server.userQueriesPerSecond` | (none) | Per-user rate limit |
| `-auditLogging` | `api.logging.audit.enabled` | `false` | Enable audit logging |
| `-echoHeaderNames` | `api.logging.echoHeaderNames` | (none) | Headers to echo |
| `-mdcHeaderNames` | `api.logging.mdcHeaderNames` | (none) | Headers for MDC |

### JMX Properties

| Command-Line Option | Property Key | Default Value | Notes |
|---------------------|--------------|---------------|-------|
| `-jmx` | `api.jmx.enabled` | `false` | Enable JMX server |
| `-jmxPort` | `api.jmx.port` | `1999` | JMX port |
| `-jmxAccessFile` | `api.jmx.accessFile` | (none) | JMX access file |
| `-jmxPasswordFile` | `api.jmx.passwordFile` | (none) | JMX password file |

### Configuration Directory

| Command-Line Option | Property Key | Default Value | Notes |
|---------------------|--------------|---------------|-------|
| `-configDir` | `api.configDir` | (empty) | Config directory path |

### EbMS Server Properties (keep `ebms.*` prefix)

The EbMS server endpoint (port 8888) will keep `ebms.*` prefix. These are currently used by `StartEmbedded.java`:
- `ebms.host` (keep as-is)
- `ebms.port` (keep as-is)
- `ebms.path` (keep as-is)
- `ebms.ssl` (keep as-is)
- `ebms.connectionLimit` (keep as-is)
- `ebms.queriesPerSecond` (keep as-is)
- `ebms.userQueriesPerSecond` (keep as-is)

## Code Changes

### 1. Start.java (`ebms-core/server/src/main/java/nl/clockwork/ebms/server/embedded/startup/Start.java`)

#### Remove Commons CLI imports
- `org.apache.commons.cli.CommandLine`
- `org.apache.commons.cli.DefaultParser`
- `org.apache.commons.cli.Options`
- `org.apache.commons.cli.help.HelpFormatter`

#### Remove Option Constants
Remove all `*_OPTION` constants (HELP_OPTION, HOST_OPTION, PORT_OPTION, etc.)

#### Update `createOptions()` method
- Replace with a simpler method that returns an empty `Options` object or remove entirely
- Keep only `HELP_OPTION` if needed (can be handled differently)

#### Update `init()` method
```java
protected void init()
{
    val configDir = getProperty("api.configDir", "");
    setProperty("ebms.configDir", configDir);
    println("Using config directory: " + configDir);
}
```

#### Update `initWebServer()` method
Replace `CommandLine cmd` parameter with property-based configuration:
```java
protected void initWebServer() throws GeneralSecurityException, IOException
{
    val connector = isSslEnabled()
        ? createHttpsConnector(createSslContextFactory())
        : createHttpConnector();
    server.addConnector(connector);
    if (hasConnectionLimit())
        addConnectionLimit(server, connector, getConnectionLimit());
}
```

#### Update `createHttpConnector()` method
```java
private ServerConnector createHttpConnector()
{
    val httpConfig = new HttpConfiguration();
    httpConfig.setSendServerVersion(false);
    val result = new ServerConnector(server, new HttpConnectionFactory(httpConfig));
    result.setHost(getProperty("api.host", DEFAULT_HOST));
    result.setPort(getIntegerProperty("api.port", DEFAULT_PORT));
    result.setName(WEB_CONNECTOR_NAME);
    if (!isHeadless())
        println("Web Server configured on http://" + Utils.getHost(result.getHost()) + ":" + result.getPort() + getPath());
    if (isSoapEnabled())
        println("SOAP Service configured on http://" + Utils.getHost(result.getHost()) + ":" + result.getPort() + SOAP_URL);
    return result;
}
```

#### Update `initHealthServer()` and `createHealthConnector()`
```java
protected void initHealthServer()
{
    val connector = createHealthConnector(server);
    server.addConnector(connector);
}

private ServerConnector createHealthConnector(Server server)
{
    val result = new ServerConnector(server);
    result.setHost(getProperty("api.host", DEFAULT_HOST));
    result.setPort(getIntegerProperty("api.health.port", DEFAULT_HEALTH_PORT));
    result.setName(HEALTH_CONNECTOR_NAME);
    println("Health Service configured on http://" + Utils.getHost(result.getHost()) + ":" + result.getPort() + HEALTH_URL);
    return result;
}
```

#### Update `createSslContextFactory()` method
```java
private SslContextFactory.Server createSslContextFactory() throws GeneralSecurityException, IOException
{
    val keyStorePassword = getProperty("api.ssl.keyStorePassword");
    if (StringUtils.isBlank(keyStorePassword) || "password".equals(keyStorePassword))
        throw new IllegalArgumentException("A non-default keystore password must be provided using api.ssl.keyStorePassword");
    val result = new SslContextFactory.Server();
    val ebMSKeyStore = EbMSKeyStore.of(
            KeyStoreType.valueOf(getProperty("api.ssl.keyStoreType", DEFAULT_KEYSTORE_TYPE)),
            getProperty("api.ssl.keyStorePath", DEFAULT_KEYSTORE_FILE),
            keyStorePassword);
    addKeyStore(result, ebMSKeyStore);
    if (isClientAuthenticationEnabled())
        addTrustStore(result);
    return result;
}
```

#### Update `addKeyStore()` method
```java
private void addKeyStore(SslContextFactory.Server sslContextFactory, EbMSKeyStore ebMSKeyStore)
{
    val protocols = getProperty("api.ssl.protocols");
    if (!StringUtils.isEmpty(protocols))
        sslContextFactory.setIncludeProtocols(StringUtils.stripAll(StringUtils.split(protocols, ',')));
    val cipherSuites = getProperty("api.ssl.cipherSuites");
    if (!StringUtils.isEmpty(cipherSuites))
        sslContextFactory.setIncludeCipherSuites(StringUtils.stripAll(StringUtils.split(cipherSuites, ',')));
    sslContextFactory.setKeyStore(ebMSKeyStore.getKeyStore());
    sslContextFactory.setKeyStorePassword(ebMSKeyStore.getPassword());
}
```

#### Update `addTrustStore()` method
```java
private void addTrustStore(SslContextFactory.Server sslContextFactory) throws IOException
{
    val trustStoreType = getProperty("api.ssl.trustStoreType", DEFAULT_KEYSTORE_TYPE);
    val trustStorePath = getProperty("api.ssl.trustStorePath");
    val trustStorePassword = getProperty("api.ssl.trustStorePassword");
    val trustStore = getResource(trustStorePath);
    if (trustStore != null && trustStore.exists())
    {
        println("Using trustStore " + trustStore.getURI());
        sslContextFactory.setNeedClientAuth(true);
        sslContextFactory.setTrustStoreType(trustStoreType);
        sslContextFactory.setTrustStoreResource(trustStore);
        sslContextFactory.setTrustStorePassword(trustStorePassword);
    }
    else
    {
        println("Web Server not available: trustStore " + trustStorePath + " not found!");
        exit(1);
    }
}
```

#### Update `createHttpsConnector()` method
```java
private ServerConnector createHttpsConnector(SslContextFactory.Server sslContextFactory)
{
    val httpConfig = new HttpConfiguration();
    httpConfig.setSendServerVersion(false);
    httpConfig.addCustomizer(new SecureRequestCustomizer(!isHostnameVerificationDisabled()));
    val result = new ServerConnector(server, sslContextFactory, new HttpConnectionFactory(httpConfig));
    result.setHost(getProperty("api.host", DEFAULT_HOST));
    result.setPort(getIntegerProperty("api.port", DEFAULT_SSL_PORT));
    result.setName(WEB_CONNECTOR_NAME);
    if (!isHeadless())
        println("Web Server configured on https://" + Utils.getHost(result.getHost()) + ":" + result.getPort() + getPath());
    if (isSoapEnabled())
        println("SOAP Service configured on https://" + Utils.getHost(result.getHost()) + ":" + result.getPort() + SOAP_URL);
    return result;
}
```

#### Update `getPath()` method
```java
protected String getPath()
{
    return getProperty("api.path", DEFAULT_PATH);
}
```

#### Update `initJMX()` method
```java
protected void initJMX(Server server) throws Exception
{
    println("Starting JMX Server...");
    val mBeanContainer = new MBeanContainer(ManagementFactory.getPlatformMBeanServer());
    server.addBean(mBeanContainer);
    val jmxURL = new JMXServiceURL("rmi", null, getIntegerProperty("api.jmx.port", DEFAULT_JMS_PORT), "/jndi/rmi:///jmxrmi");
    val sslContextFactory = isSslEnabled() ? createSslContextFactory() : null;
    val jmxServer = new ConnectorServer(jmxURL, createEnv(), "org.eclipse.jetty.jmx:name=rmiconnectorserver", sslContextFactory);
    server.addBean(jmxServer);
    println("JMX Server configured on " + jmxURL);
}
```

#### Update `createEnv()` method
```java
private Map<String, Object> createEnv()
{
    val result = new HashMap<String, Object>();
    if (hasJmxAccessFile() && hasJmxPasswordFile())
    {
        result.put("jmx.remote.x.access.file", getProperty("api.jmx.accessFile"));
        result.put("jmx.remote.x.password.file", getProperty("api.jmx.passwordFile"));
    }
    return result;
}
```

#### Update `createWebContextHandler()` method
```java
protected ServletContextHandler createWebContextHandler(ContextLoaderListener contextLoaderListener) throws Exception
{
    val result = new ServletContextHandler(ServletContextHandler.SESSIONS);
    result.setVirtualHosts(List.of("@" + WEB_CONNECTOR_NAME));
    result.setInitParameter("configuration", "deployment");
    result.setContextPath(getPath());
    if (hasEchoHeaderNames())
        result.addFilter(createEchoServletFilterHolder(getProperty("api.logging.echoHeaderNames")), "/*", EnumSet.allOf(DispatcherType.class));
    if (hasMdcHeaderNames())
        result.addFilter(createMDCServletFilterHolder(getProperty("api.logging.mdcHeaderNames")), "/*", EnumSet.allOf(DispatcherType.class));
    if (isAuditLoggingEnabled())
        result.addFilter(createRemoteAddressMDCFilterHolder(), "/*", EnumSet.allOf(DispatcherType.class));
    if (hasRateLimit())
        result.addFilter(createRateLimiterFilterHolder(getProperty("api.server.queriesPerSecond")), "/*", EnumSet.allOf(DispatcherType.class));
    if (hasUserRateLimit())
        result.addFilter(createUserRateLimiterFilterHolder(getProperty("api.server.userQueriesPerSecond")), "/*", EnumSet.allOf(DispatcherType.class));
    if (isAuthenticationEnabled())
        addAuthenticationHandler(result);
    if (isSoapEnabled())
        result.addServlet(CXFServlet.class, SOAP_URL + "/*");
    result.setErrorHandler(createErrorHandler());
    result.addEventListener(contextLoaderListener);
    return result;
}
```

#### Update `createClientCertificateAuthenticationFilterHolder()` method
```java
private FilterHolder createClientCertificateAuthenticationFilterHolder() throws IOException
{
    println("Configuring Web Server client certificate authentication:");
    val result = new FilterHolder(nl.clockwork.ebms.server.endpoint.servlet.filters.ClientCertificateAuthenticationFilter.class);
    val clientTrustStoreType = getProperty("api.ssl.clientTrustStoreType", DEFAULT_KEYSTORE_TYPE);
    val clientTrustStorePath = getProperty("api.ssl.clientTrustStorePath");
    val clientTrustStorePassword = getProperty("api.ssl.clientTrustStorePassword");
    val trustStore = getResource(clientTrustStorePath);
    if (trustStore != null && trustStore.exists())
    {
        println("Using clientTrustStore " + trustStore.getURI());
        result.setInitParameter("trustStoreType", clientTrustStoreType);
        result.setInitParameter("trustStorePath", clientTrustStorePath);
        result.setInitParameter("trustStorePassword", clientTrustStorePassword);
        return result;
    }
    else
    {
        println("Web Server not available: clientTrustStore " + clientTrustStorePath + " not found!");
        exit(1);
        return null;
    }
}
```

#### Update `startService()` method
Remove `CommandLine cmd` parameter completely:

```java
private void startService(String[] args) throws Exception
{
    val options = createOptions();
    if (containsHelpOption(options, args))
    {
        printUsage(options);
        return;
    }
    init();
    server.setHandler(handlerCollection);
    if (isJmxEnabled())
        initJMX(server);
    try (AnnotationConfigWebApplicationContext context = new AnnotationConfigWebApplicationContext())
    {
        context.scan("nl.clockwork.ebms");
        getPluginConfigClasses().forEach(context::register);
        getConfigClasses().forEach(context::register);
        val contextLoaderListener = new ContextLoaderListener(context);
        if (isSoapEnabled() || !isHeadless())
        {
            initWebServer();
            handlerCollection.addHandler(createWebContextHandler(contextLoaderListener));
        }
        if (isHealthEnabled())
        {
            initHealthServer();
            handlerCollection.addHandler(createHealthContextHandler());
        }
        println("Starting Server...");
        try
        {
            server.start();
        }
        catch (Exception e)
        {
            server.stop();
            exit(1);
        }
        println("Server started.");
        server.join();
    }
}
```

### 2. StartEmbedded.java (`ebms-core/server/src/main/java/nl/clockwork/ebms/server/embedded/startup/StartEmbedded.java`)

#### Remove Commons CLI imports
- `org.apache.commons.cli.DefaultParser`
- `org.apache.commons.cli.Options`

#### Update `startEmbeddedService()` method
Remove `CommandLine cmd` parameter and convert property access to use `getProperty()` method:

```java
private void startEmbeddedService(String[] args) throws Exception
{
    val options = createOptions();
    if (containsHelpOption(options, args))
        printUsage(options);
    setProperty("org.apache.activemq.SERIALIZABLE_PACKAGES", "*");
    if (isEbmsClientDisabled())
        setProperty(DELIVERY_TASK_HANDLER_START_PROPERTY, FALSE);
    init();
    server.setHandler(handlerCollection);
    server.addBean(new CustomErrorHandler());
    val properties = getProperties();
    if (isJmxEnabled())
        initJMX(server);
    if (isSoapEnabled() || isHealthEnabled() || !isHeadless() || !isEbmsServerDisabled())
        try (AnnotationConfigWebApplicationContext context = new AnnotationConfigWebApplicationContext())
        {
            context.scan("nl.clockwork.ebms");
            getPluginConfigClasses().forEach(context::register);
            getConfigClasses().forEach(context::register);
            val contextLoaderListener = new ContextLoaderListener(context);
            if (isSoapEnabled() || !isHeadless())
            {
                initWebServer();
                handlerCollection.addHandler(createWebContextHandler(contextLoaderListener));
            }
            if (isHealthEnabled())
            {
                initHealthServer();
                handlerCollection.addHandler(createHealthContextHandler());
            }
            if (!isEbmsServerDisabled())
            {
                initEbMSServer(properties, server);
                handlerCollection.addHandler(createEbMSContextHandler(properties, contextLoaderListener));
            }
            println("Starting Server...");
            try
            {
                server.start();
            }
            catch (Exception e)
            {
                e.printStackTrace();
                server.stop();
                exit(1);
            }
            println("Server started.");
            server.join();
        }
    else
        try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext())
        {
            context.register(EmbeddedAppConfig.class);
            getPluginConfigClasses().forEach(context::register);
            getConfigClasses().forEach(context::register);
            println("Starting Server...");
            context.refresh();
            context.start();
            println("Server started.");
            Thread.currentThread().join();
        }
}
```

#### Update `initEbMSServer()` method
```java
private void initEbMSServer(Properties properties, Server server) throws GeneralSecurityException, IOException
{
    val connector = isEbmsSslEnabled(properties)
        ? createEbMSHttpsConnector(properties, createEbMSSslContextFactory(properties))
        : createEbMSHttpConnector(properties);
    server.addConnector(connector);
    val connectionLimit = properties.getProperty(EBMS_CONNECTION_LIMIT_PROPERTY);
    if (StringUtils.isNotEmpty(connectionLimit))
        addConnectionLimit(server, connector, Integer.parseInt(connectionLimit));
}
```

### 3. EmbeddedAppConfig.java

#### Add configuration for ebms-client authentication filter
The `ClientCertificateAuthenticationFilter` requires properties that are currently set via command-line options. These need to be configured as Spring beans:

```java
@Bean
@Primary
public EbMSPropertySourcesPlaceholderConfigurer propertySourcesPlaceholderConfigurer()
{
    val result = new EbMSPropertySourcesPlaceholderConfigurer();
    val configDir = System.getProperty("ebms.configDir");
    val resources = new Resource[]{
        new ClassPathResource("nl/clockwork/ebms/default.properties"),
        new ClassPathResource("nl/clockwork/ebms/server/default.properties"),
        new FileSystemResource(configDir + "ebms-server.advanced.properties"),
        new FileSystemResource(configDir + "ebms-server.properties")
    };
    result.setLocations(resources);
    result.setIgnoreResourceNotFound(true);
    return result;
}
```

#### Add helper methods to SystemInterface for property access

Update `SystemInterface.java` to include helper methods:

```java
public interface SystemInterface
{
    default void setProperty(String key, String value)
    {
        System.setProperty(key, value);
    }

    default String getProperty(String key)
    {
        return System.getProperty(key);
    }

    default String getProperty(String key, String defaultValue)
    {
        return System.getProperty(key, defaultValue);
    }

    default int getIntegerProperty(String key, int defaultValue)
    {
        val value = System.getProperty(key);
        return value != null ? Integer.parseInt(value) : defaultValue;
    }

    default boolean getBooleanProperty(String key, boolean defaultValue)
    {
        val value = System.getProperty(key);
        return value != null ? Boolean.parseBoolean(value) : defaultValue;
    }

    default void println(String s)
    {
        System.out.println(s);
    }

    default void printWarn(String s)
    {
        System.err.println(s);
    }

    default void exit(int status)
    {
        System.exit(status);
    }
}
```

## New Properties to Add

### ebms-core/server/src/main/resources/nl/clockwork/ebms/server/default.properties

Add the new `api.` prefixed properties:

```properties
# API Web Server Configuration
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

# API Health Service
api.health.enabled=false
api.health.port=8008

# API Server Filters
api.server.connectionLimit=
api.server.queriesPerSecond=
api.server.userQueriesPerSecond=

# API Logging
api.logging.audit.enabled=false
api.logging.echoHeaderNames=
api.logging.mdcHeaderNames=

# API JMX
api.jmx.enabled=false
api.jmx.port=1999
api.jmx.accessFile=
api.jmx.passwordFile=

# API Config
api.configDir=
```

## Migration Steps

1. **Add new properties** to `default.properties` with sensible defaults
2. **Update SystemInterface.java** with helper methods for property access
3. **Modify Start.java** to remove Commons CLI parsing and use property-based configuration
4. **Modify StartEmbedded.java** to use property-based configuration
5. **Update filter configuration** to read from properties
6. **Update tests** if any directly test command-line parsing
7. **Update documentation** to reflect property-based configuration

## Backward Compatibility

- Existing command-line arguments will be ignored
- Users must migrate to property files
- Default property values maintain current defaults

## Testing

1. Verify all existing tests pass with the new configuration approach
2. Test SSL configuration via properties
3. Test health service configuration
4. Test rate limiting configuration
5. Test JMX configuration
