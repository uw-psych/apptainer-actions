#!/usr/bin/env bash
set -eu${XTRACE:-} -o pipefail
command -v jq >/dev/null 2>&1 || { echo "jq is required but not found" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh is required but not found" >&2; exit 1; }
command -v apptainer >/dev/null 2>&1 || { echo "apptainer is required but not found" >&2; exit 1; }
command -v oras >/dev/null 2>&1 || { echo "oras is required but not found" >&2; exit 1; }
if [[ -z "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
	GITHUB_TOKEN="$(gh auth token || true)"
	if [[ -z "${GITHUB_TOKEN:-}" ]]; then
		echo "GITHUB_TOKEN is required but not found" >&2
		exit 1
	fi
fi
