#!/usr/bin/env bash
set -euo pipefail

NVD_API_KEY="${NVD_API_KEY:-}"
if [[ -z "$NVD_API_KEY" ]]; then
  echo "NVD_API_KEY is required"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_TAG="$(date +%F)"
OUT_DIR="$ROOT_DIR/security/artifacts/$DATE_TAG"
mkdir -p "$OUT_DIR"

echo "[1/4] OWASP dependency check - ebms-core"
(
  cd "$ROOT_DIR/ebms-core"
  mvn -B -DskipTests \
    -DnvdApiKey="$NVD_API_KEY" \
    -Ddependency-check.nvd.apiKey="$NVD_API_KEY" \
    -Dformats=HTML,JSON \
    org.owasp:dependency-check-maven:12.2.1:aggregate
  cp -f target/dependency-check-report.html "$OUT_DIR/ebms-core-dependency-check-report.html"
  cp -f target/dependency-check-report.json "$OUT_DIR/ebms-core-dependency-check-report.json"
)

echo "[2/4] OWASP dependency check - ebms-admin"
(
  cd "$ROOT_DIR/ebms-admin"
  mvn -B -DskipTests \
    -DnvdApiKey="$NVD_API_KEY" \
    -Ddependency-check.nvd.apiKey="$NVD_API_KEY" \
    -Dformats=HTML,JSON \
    dependency-check:aggregate
  cp -f target/dependency-check-report.html "$OUT_DIR/ebms-admin-dependency-check-report.html"
  cp -f target/dependency-check-report.json "$OUT_DIR/ebms-admin-dependency-check-report.json"
)

echo "[3/4] SpotBugs report - ebms-core"
(
  cd "$ROOT_DIR/ebms-core"
  mvn -B -DskipTests com.github.spotbugs:spotbugs-maven-plugin:spotbugs || true
  SPOTBUGS_FILE="$(find target -type f -name spotbugsXml.xml | head -n 1 || true)"
  if [[ -n "$SPOTBUGS_FILE" ]]; then
    cp -f "$SPOTBUGS_FILE" "$OUT_DIR/ebms-core-spotbugs.xml"
  fi
)

echo "[4/4] SpotBugs report - ebms-admin"
(
  cd "$ROOT_DIR/ebms-admin"
  mvn -B -DskipTests com.github.spotbugs:spotbugs-maven-plugin:spotbugs || true
  SPOTBUGS_FILE="$(find target -type f -name spotbugsXml.xml | head -n 1 || true)"
  if [[ -n "$SPOTBUGS_FILE" ]]; then
    cp -f "$SPOTBUGS_FILE" "$OUT_DIR/ebms-admin-spotbugs.xml"
  fi
)

echo "Artifacts written to: $OUT_DIR"
