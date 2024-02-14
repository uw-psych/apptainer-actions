#!/usr/bin/env bash
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

# Get image version from the definition file if possible:
[[ -n "${IMAGE_VERSION:-}" ]] && IMAGE_VERSION="$(awk '/^\s*%labels/{flag=1;next}/^\s*%\S+/{flag=0}flag' "${DEFFILE}" | grep -m1 -oiP '^\s*version\s+\K.+' | sed 's/^\s*//g; s/\s*$//g' || true)"

# Get the labels from the input and set them:
if [[ -n "${INPUT_LABELS:-}" ]]; then
	echo "${INPUT_LABELS:-}" | jq -r 'to_entries[] | "\("labels." + .key |@sh) \(.value|@sh)"' >>"${BUILD_LABELS_PATH}"
fi

IMAGE_VERSION="${IMAGE_VERSION:-${INPUT_IMAGE_VERSION:-"$(date +%s --date="${IMAGE_CREATED}")"}}"
IMAGE_AUTHORS="${IMAGE_AUTHORS:-"$(gh api "/users/${GITHUB_ACTOR}" --jq 'if .name == "" then .login else .name end' || echo "${GITHUB_ACTOR:-}")"}"
IMAGE_SOURCE="${IMAGE_SOURCE:-https://github.com/${GITHUB_REPOSITORY}}"
IMAGE_REVISION="${IMAGE_REVISION:-${GITHUB_SHA}}"
IMAGE_URL="${IMAGE_URL:-${INPUT_IMAGE_URL:-oras://ghcr.io/${GITHUB_REPOSITORY}/${IMAGE_NAME}:${IMAGE_VERSION}}}"
IMAGE_VENDOR="${IMAGE_VENDOR:-${GITHUB_REPOSITORY_OWNER}}"
IMAGE_LICENSES="${IMAGE_LICENSES:-"$(gh api "/repos/${GITHUB_REPOSITORY}" --jq '.license.spdx_id?' || true)"}"
IMAGE_TITLE="${IMAGE_TITLE:-"${IMAGE_NAME:-"${GITHUB_REPOSITORY##*/}"}"}"

HELP_SECTION="$(awk '/^\s*%help/{flag=1;next}/^\s*%\S+/{flag=0}flag' Singularity | tr '\n' ' ' | sed -E 's/^\s*//g; s/\s*$//g; s/\s+/ /g' || true)"
if [[ -n "${HELP_SECTION}" ]]; then
	IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-"${HELP_SECTION}"}"
fi
IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-"$(gh api "/repos/${GITHUB_REPOSITORY}" --jq '.description?' || true)"}"

IMAGE_FROM="$(grep -oiP '^\s*From:\s*\K\S+' "${DEFFILE}" || true)"
if [[ -n "${IMAGE_FROM:-}" ]]; then
	grep -qiE '^\s*Bootstrap:\s*docker' "${DEFFILE}" && IMAGE_FROM="docker.io/${IMAGE_FROM}"
fi
IMAGE_BASE_NAME="${IMAGE_BASE_NAME:-${IMAGE_FROM:-}}"

# Write each image label to the file if the label is set:
test -n "${IMAGE_VERSION:-}" && echo org.opencontainers.image.version "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_VERSION=${IMAGE_VERSION}" >>"${GITHUB_ENV}"
test -n "${IMAGE_AUTHORS:-}" && echo org.opencontainers.image.authors "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_AUTHORS=${IMAGE_AUTHORS}" >>"${GITHUB_ENV}"
test -n "${IMAGE_SOURCE:-}" && echo org.opencontainers.image.source "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_SOURCE=${IMAGE_SOURCE}" >>"${GITHUB_ENV}"
test -n "${IMAGE_REVISION:-}" && echo org.opencontainers.image.revision "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_REVISION=${IMAGE_REVISION}" >>"${GITHUB_ENV}"
test -n "${IMAGE_URL:-}" && echo org.opencontainers.image.url "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_URL=${IMAGE_URL}" >>"${GITHUB_ENV}"
test -n "${IMAGE_VENDOR:-}" && echo org.opencontainers.image.vendor "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_VENDOR=${IMAGE_VENDOR}" >>"${GITHUB_ENV}"
test -n "${IMAGE_LICENSES:-}" && echo org.opencontainers.image.licenses "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_LICENSES=${IMAGE_LICENSES}" >>"${GITHUB_ENV}"
test -n "${IMAGE_TITLE:-}" && echo org.opencontainers.image.title "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_TITLE=${IMAGE_TITLE}" >>"${GITHUB_ENV}"
test -n "${IMAGE_DESCRIPTION:-}" && echo org.opencontainers.image.description "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_DESCRIPTION=${IMAGE_DESCRIPTION}" >>"${GITHUB_ENV}"
test -n "${IMAGE_BASE_NAME:-}" && echo org.opencontainers.image.base.name "$_" >>"${BUILD_LABELS_PATH}" && echo "IMAGE_BASE_NAME=${IMAGE_BASE_NAME}" >>"${GITHUB_ENV}"

# Reverse the order of the labels so that custom labels added as an input are not overridden by the default ones:
tac "${BUILD_LABELS_PATH}" >"${BUILD_LABELS_PATH}.tmp" && mv "${BUILD_LABELS_PATH}.tmp" "${BUILD_LABELS_PATH}"
