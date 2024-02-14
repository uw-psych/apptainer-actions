#!/usr/bin/env bash
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

# Log in:
apptainer remote login -u "${GITHUB_ACTOR}" -p "${GITHUB_TOKEN}" oras://ghcr.io

# Push the image:
echo "Pushing image to \"${IMAGE_URL}\"" >&2
apptainer push -U "${IMAGE_PATH}" "${IMAGE_URL}"
echo "image-url=${IMAGE_URL}" >>"${GITHUB_OUTPUT}"
echo "::notice::Pushed image to \"${IMAGE_URL}\""
