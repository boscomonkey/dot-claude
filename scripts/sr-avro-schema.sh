#!/usr/bin/env bash
# Fetch the latest registered Avro schema for a Schema Registry subject.
#
# Usage: sr-avro-schema.sh <SUBJECT> [VERSION]
# Example: sr-avro-schema.sh com.hingehealth.communication.sms_message_delivered
#          sr-avro-schema.sh com.hingehealth.communication.sms_message_delivered 1
#
# VERSION defaults to "latest". Prints the registry response JSON, with the
# embedded schema string pretty-printed for readability.
#
# Reads env var (with a localhost default for the dev/test infra stack):
#   SCHEMA_REGISTRY_URL - base URL of the Schema Registry (default
#                         http://localhost:8081)

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $(basename "$0") <SUBJECT> [VERSION]" >&2
    echo "Example: $(basename "$0") com.example.some_event" >&2
    exit 2
fi

SUBJECT="$1"
VERSION="${2:-latest}"
REGISTRY_URL="${SCHEMA_REGISTRY_URL:-http://localhost:8081}"

curl -s "${REGISTRY_URL}/subjects/${SUBJECT}/versions/${VERSION}" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'error_code' in r:
    print(f'Error {r[\"error_code\"]}: {r.get(\"message\", \"\")}', file=sys.stderr)
    sys.exit(1)
if isinstance(r.get('schema'), str):
    try:
        r['schema'] = json.loads(r['schema'])
    except (ValueError, TypeError):
        pass
print(json.dumps(r, indent=2))
"
