#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

# Find the definition file:
if [[ -z "${INPUT_DEFFILE:-}" ]]; then
	FOUND_DEFFILES="$(find "${INPUT_DEFFILES_ROOTDIR:-.}" -type f \( -name 'Apptainer' -or -name 'Singularity' -or -name '*.def' \) -printf '%p\t%f\n' | awk -F$'\t' -v OFS=$'\t' '{print $2 == "Apptainer" ? 1: ($2 == "Singularity" ? 2 : 3), $1}' | awk -F'/' -v OFS=$'\t' '{print NF -1, $0}' | sort --key=1n,2n | cut -f3 | head -n 1 | xargs realpath || true)"
	[[ -z "${FOUND_DEFFILES:-}" ]] && { echo "No definition file found" >&2; exit 1; }
	mapfile -t deffiles_array <<<"${FOUND_DEFFILES}"
	echo "Found ${#deffiles_array[@]} definition files:" >&2
	for deffile in "${deffiles_array[@]}"; do
		printf "\t%q\n" "${deffile}" >&2
	done
	INPUT_DEFFILE="${deffiles_array[0]}"
fi

# Write the definition file to the environment if found:
if [[ -n "${INPUT_DEFFILE:-}" ]]; then
	INPUT_DEFFILE="$(realpath "${INPUT_DEFFILE}")"
	echo "INPUT_DEFFILE=${INPUT_DEFFILE}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"
else
	echo "No definition file found" >&2
	exit 1
fi

# If the input specifies the image version, set it:
if [[ -n "${INPUT_IMAGE_VERSION:-}" ]]; then
	echo "INPUT_IMAGE_VERSION=${INPUT_IMAGE_VERSION}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"
fi

# Set image name:
INPUT_IMAGE_NAME="${INPUT_IMAGE_NAME:-$(basename "$(dirname "$(realpath "${INPUT_DEFFILE}")")")}"
echo "INPUT_IMAGE_NAME=${INPUT_IMAGE_NAME}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"
