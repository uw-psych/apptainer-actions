#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

# Log in:
apptainer remote login -u "${GITHUB_ACTOR}" -p "${GH_TOKEN}" oras://ghcr.io

# Push the image:
echo "Pushing image to \"${INPUT_IMAGE_URL}\"" >&2
apptainer push -U "${INPUT_IMAGE_PATH}" "${INPUT_IMAGE_URL}"
echo "image-url=${INPUT_IMAGE_URL}" >>"${GITHUB_OUTPUT}"
echo "::notice::Pushed image to \"${INPUT_IMAGE_URL}\""

rm -f "${INPUT_IMAGE_PATH}" # Remove the image file to save space

