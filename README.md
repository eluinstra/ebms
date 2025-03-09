# EbMS

## Build project

### create settings.xml

```sh
cat >> ~/.m2/settings.xml << EOF
<settings>
  <mirrors>
    <mirror>
      <id>releases.java.net</id>
      <mirrorOf>external:http:*</mirrorOf>
      <url>http://maven.java.net/content/repositories/releases/</url>
      <blocked>false</blocked>
    </mirror>
    <mirror>
      <id>snapshots.java.net</id>
      <mirrorOf>external:http:*</mirrorOf>
      <url>http://maven.java.net/content/repositories/snapshots/</url>
      <blocked>false</blocked>
    </mirror>
  </mirrors>
</settings>
EOF
```

### Install project

```sh
mvn install
```