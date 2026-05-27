#!/usr/bin/env bash
# Run a `bundle exec` subcommand inside the current project's rvm
# ruby + gemset. Reads .ruby-version and .ruby-gemset from the current
# working directory to figure out which ruby and gemset to switch to;
# avoids the need to chain
#   source ~/.rvm/scripts/rvm && rvm use <X>@<Y> && bundle exec <cmd>
# in every invocation.
#
# Usage: bundle-exec.sh <subcommand> [args...]
# Examples:
#   bundle-exec.sh rubocop app/controllers/foo_controller.rb
#   bundle-exec.sh rspec spec/models/admin_spec.rb
#   bundle-exec.sh rails runner 'puts Admin.count'
#
# If .ruby-version is missing, runs bundle exec with the ambient ruby.
# If .ruby-gemset is missing, switches ruby only (no gemset).

set -eo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <bundle-subcommand> [args...]" >&2
    echo "Example: $(basename "$0") rubocop path/to/file.rb" >&2
    exit 2
fi

# shellcheck disable=SC1091
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
else
    echo "bundle-exec.sh: rvm not found at \$HOME/.rvm/scripts/rvm; running with ambient ruby" >&2
fi

if [[ -f .ruby-version ]]; then
    ruby_version=$(< .ruby-version)
    ruby_version=${ruby_version//[$'\t\r\n ']}
    if [[ -f .ruby-gemset ]]; then
        gemset=$(< .ruby-gemset)
        gemset=${gemset//[$'\t\r\n ']}
        rvm use "${ruby_version}@${gemset}" >/dev/null
    else
        rvm use "${ruby_version}" >/dev/null
    fi
fi

exec bundle exec "$@"
