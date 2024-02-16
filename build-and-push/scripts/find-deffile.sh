#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

# Find the definition file:
if [[ -z "${DEFFILE:=${INPUT_DEFFILE:-}}" ]]; then
	FOUND_DEFFILES="$(find "${INPUT_DEFFILES_ROOTDIR:-.}" -type f \( -name 'Apptainer' -or -name 'Singularity' -or -name '*.def' \) -printf '%p\t%f\n' | awk -F$'\t' -v OFS=$'\t' '{print $2 == "Apptainer" ? 1: ($2 == "Singularity" ? 2 : 3), $1}' | awk -F'/' -v OFS=$'\t' '{print NF -1, $0}' | sort --key=1n,2n | cut -f3 | head -n 1 || true)"
	[[ -z "${FOUND_DEFFILES:-}" ]] && { echo "No definition file found" >&2; exit 1; }
	mapfile -t deffiles_array <<<"${FOUND_DEFFILES}"
	echo "Found ${#deffiles_array[@]} definition files:" >&2
	for deffile in "${deffiles_array[@]}"; do
		printf "\t%q\n" "${deffile}" >&2
	done
	DEFFILE="${deffiles_array[0]}"
fi

# Write the definition file to the environment if found:
if [[ -n "${DEFFILE:-}" ]]; then
	echo "DEFFILE=${DEFFILE}" >>"${GITHUB_ENV}"
else
	echo "No definition file found" >&2
	exit 1
fi

# If the input specifies the image version, set it:
if [[ -n "${INPUT_IMAGE_VERSION:-}" ]]; then
	echo "IMAGE_VERSION=${INPUT_IMAGE_VERSION}" >>"${GITHUB_ENV}"
fi

# Set image name:
IMAGE_NAME="${INPUT_IMAGE_NAME:-$(basename "$(dirname "$(realpath "${DEFFILE}")")")}"
echo "IMAGE_NAME=${IMAGE_NAME}" >>"${GITHUB_ENV}"
