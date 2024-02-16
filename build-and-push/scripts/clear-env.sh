#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eE

# Clear the environment:
grep -o '^[^=]*=' "${SET_GITHUB_ENV}" | tee "${RUNNER_TEMP}/new-env.tmp"
cat "${RUNNER_TEMP}/new-env.tmp" >> "${GITHUB_ENV}"
rm -f "${RUNNER_TEMP}/new-env.tmp" "${SET_GITHUB_ENV}"

