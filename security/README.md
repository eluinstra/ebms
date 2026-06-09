## Security Scan Artifacts

This folder contains repeatable scan tooling and captured artifacts for Java security checks.

### Run

```bash
NVD_API_KEY=<your-key> ./security/run-security-scans.sh
```

### Output Location

Artifacts are written to:
- `security/artifacts/YYYY-MM-DD/`

Expected files:
- `ebms-core-dependency-check-report.html`
- `ebms-core-dependency-check-report.json`
- `ebms-admin-dependency-check-report.html`
- `ebms-admin-dependency-check-report.json`
- `ebms-core-spotbugs.xml` (if generated)
- `ebms-admin-spotbugs.xml` (if generated)

### OWASP Top 10 Coverage

- A06 Vulnerable and Outdated Components: OWASP Dependency-Check
- A02/A03/A07/A10 code pattern coverage: SpotBugs plus manual review findings

### Notes

- Admin suppression file used by dependency-check:
  - `ebms-admin/dependency-check-suppressions.xml`
- Admin OWASP plugin is configured in `ebms-admin/pom.xml` for suppression usage.

### Realm Password Migration

To migrate plaintext realm entries to BCrypt and create a backup:

```bash
cd ebms-admin
mvn -B -DskipTests compile
java -cp target/classes:$(mvn -q -Dexec.classpathScope=compile -Dexec.executable=echo --non-recursive org.codehaus.mojo:exec-maven-plugin:3.5.0:exec) nl.clockwork.ebms.admin.RealmFileMigrator --file realm.properties
```

The migrator writes `realm.properties.bak` and updates the original file.
Legacy `MD5:`, `OBF:`, and `CRYPT:` entries are reported for manual reset.

### Realm User Management

Add a user (stored as BCrypt):

```bash
cd ebms-admin
java -cp target/classes:$(mvn -q -Dexec.classpathScope=compile -Dexec.executable=echo --non-recursive org.codehaus.mojo:exec-maven-plugin:3.5.0:exec) nl.clockwork.ebms.admin.RealmFileMigrator --file realm.properties --add-user --username alice --password "change-me" --role user
```

Update a user password (and optionally role):

```bash
cd ebms-admin
java -cp target/classes:$(mvn -q -Dexec.classpathScope=compile -Dexec.executable=echo --non-recursive org.codehaus.mojo:exec-maven-plugin:3.5.0:exec) nl.clockwork.ebms.admin.RealmFileMigrator --file realm.properties --update-user --username alice --password "new-password"
```

Remove a user:

```bash
cd ebms-admin
java -cp target/classes:$(mvn -q -Dexec.classpathScope=compile -Dexec.executable=echo --non-recursive org.codehaus.mojo:exec-maven-plugin:3.5.0:exec) nl.clockwork.ebms.admin.RealmFileMigrator --file realm.properties --remove-user --username alice
```

Notes:
- Add/update passwords are always stored as BCrypt hashes.
- Add/update passwords must be at least 8 characters.
- Add/update passwords must be at most 128 characters.
- Add/update passwords must be alphanumeric and include at least one letter and one digit.
- Update/remove returns a non-zero exit code if the user does not exist.
- Every write operation creates `realm.properties.bak` before updating the file.
