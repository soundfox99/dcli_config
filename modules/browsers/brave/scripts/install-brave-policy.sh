#!/usr/bin/env bash
# Write only Brave's extension policy.
#
# A wrapper rather than a copy: the policy-writing logic lives in
# browsers/scripts/install-browser-policies.sh and both modules share it, so
# the two stay in step. dcli's post_install_hook is a bare path with no way to
# pass arguments, which is the only reason this file exists.

set -euo pipefail

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/install-browser-policies.sh" brave
