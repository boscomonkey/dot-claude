#!/usr/bin/env bash
#
# run-sr-avro-spec.sh - run a :consume_sr_avro RSpec file against the local
# Schema Registry, with the opt-in gate enabled.
#
# usage: run-sr-avro-spec.sh <SPEC_PATH> [WORKTREE_DIR]
#   <SPEC_PATH>     spec file (relative to the worktree, or absolute)
#   [WORKTREE_DIR]  defaults to the current directory
#
# Sets RUN_CONSUME_SR_AVRO_SPECS=true (the harness gate in
# spec/support/consume_sr_avro.rb) and SCHEMA_REGISTRY_URL (defaults to the
# local infra stack), then runs `bundle exec rspec` in the worktree's rvm
# ruby + gemset. Requires the registry stack up (make registry-up in
# ../schemas-submodule). One allowlisted call so backport verification does
# not prompt per spec.
# NB: no `-u` (nounset) - rvm's shell functions reference unset variables.
set -eo pipefail

SPEC="${1:?usage: run-sr-avro-spec.sh <SPEC_PATH> [WORKTREE_DIR]}"
DIR="${2:-$(pwd)}"
cd "$DIR"

export RUN_CONSUME_SR_AVRO_SPECS=true
export SCHEMA_REGISTRY_URL="${SCHEMA_REGISTRY_URL:-http://localhost:8081}"

# shellcheck disable=SC1090,SC1091
source "$HOME/.rvm/scripts/rvm"
ruby_ver="$(cat .ruby-version 2>/dev/null)"
gemset="$(cat .ruby-gemset 2>/dev/null)"
rvm use "${ruby_ver}@${gemset}" >/dev/null

bundle exec rspec "$SPEC"
