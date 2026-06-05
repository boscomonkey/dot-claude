#!/usr/bin/env bash
#
# sentry-api.sh - thin wrapper around the Sentry REST API.
#
# Reads credentials from the environment, falling back to ~/.nocommit_profile:
#   SENTRY_AUTH_TOKEN  (required)  Bearer token (read-only is fine)
#   SENTRY_HOST        (required)  e.g. https://hingehealth.sentry.io  (trailing slash ok)
#   SENTRY_ORG         (required)  org slug, substituted for {org} in the path
#   SENTRY_ORG_ID      (optional)  numeric org id, substituted for {org_id}
#
# Usage:
#   sentry-api.sh <api-path> [extra curl args...]
#     <api-path> is relative to <SENTRY_HOST>/api/0/ ; {org}/{org_id} are substituted.
#
# Examples:
#   sentry-api.sh 'organizations/{org}/issues/6792801113/'
#   sentry-api.sh 'organizations/{org}/issues/6792801113/events/latest/'
#   sentry-api.sh 'organizations/{org}/projects/'
#   sentry-api.sh 'organizations/{org}/issues/' -G --data-urlencode 'query=is:unresolved'
#
# Outputs the raw JSON response on stdout (pipe through `jq`/`python3 -m json.tool`).
# On HTTP >= 400 it prints the status to stderr and exits non-zero.
# The auth token is never echoed.

set -eo pipefail

# Load creds from ~/.nocommit_profile only if not already present in the env.
if [ -z "${SENTRY_AUTH_TOKEN:-}" ] && [ -f "$HOME/.nocommit_profile" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$HOME/.nocommit_profile"
fi

: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN not set (add it to ~/.nocommit_profile)}"
: "${SENTRY_HOST:?SENTRY_HOST not set (add it to ~/.nocommit_profile)}"
: "${SENTRY_ORG:?SENTRY_ORG not set (add it to ~/.nocommit_profile)}"

if [ "$#" -lt 1 ]; then
  echo "usage: sentry-api.sh <api-path> [extra curl args...]" >&2
  echo "  path is relative to <SENTRY_HOST>/api/0/ ; {org} and {org_id} are substituted" >&2
  echo "  e.g. sentry-api.sh 'organizations/{org}/issues/6792801113/'" >&2
  exit 2
fi

path="$1"; shift
path="${path#/}"
path="${path//\{org\}/$SENTRY_ORG}"
path="${path//\{org_id\}/${SENTRY_ORG_ID:-}}"

host="${SENTRY_HOST%/}"
url="$host/api/0/$path"

body="$(mktemp)"
trap 'rm -f "$body"' EXIT

code="$(curl -sS -o "$body" -w '%{http_code}' \
  -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  -H 'Accept: application/json' \
  "$url" "$@")"

cat "$body"

if [ "$code" -ge 400 ]; then
  echo "" >&2
  echo "sentry-api: HTTP $code for $url" >&2
  exit 1
fi
