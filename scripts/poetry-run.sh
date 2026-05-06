#!/usr/bin/env bash
# Run a poetry subcommand, auto-sourcing .env from the current working
# directory if present. Avoids the need to chain
#   set -a && source .env && set +a && poetry run <cmd>
# in every invocation.
#
# Usage: poetry-run.sh <subcommand> [args...]
# Examples:
#   poetry-run.sh pytest app/app/tests/unit/kafka/ -v
#   poetry-run.sh mypy app/app/kafka/events/dual_tasking.py
#
# If the project has no .env file, the script runs poetry with the
# ambient environment.

set -eo pipefail
# Note: no `set -u` - .env files often reference unbound vars like
# PYTHONPATH=$PYTHONPATH:... which would otherwise fail to source.

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <poetry-subcommand> [args...]" >&2
    echo "Example: $(basename "$0") pytest app/app/tests/unit/kafka/" >&2
    exit 2
fi

if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

exec poetry run "$@"
