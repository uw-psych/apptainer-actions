#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

cat "${GITHUB_ENV}"
grep -o '^[^=]*=' "${GITHUB_ENV}" > "${RUNNER_TEMP}/new-env.tmp"
cat "${RUNNER_TEMP}/new-env.tmp"
