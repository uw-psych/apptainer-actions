#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312,SC2250
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

declare -A labels_dct

# Read the labels from the definition file:
while read -r line; do
	read -r k v <<<"$line"
	labels_dct["${k}"]="${v:-}"
done < <(awk '/^\s*%labels/{flag=1;next}/^\s*%\S+/{flag=0}flag' Singularity | sed -E '/^\s*$/d; s/^\s*//g; s/\s*$//g; s/[^\\][#].*$//g; s/^(\S+)\s{2,}/\1 /g')

# Get image version from the definition file if possible:

# Get the labels from the input and set them:
if [[ -n "${INPUT_LABELS:-}" ]]; then
	echo "${INPUT_LABELS:-}" | jq -r 'to_entries[] | "\("labels." + .key |@sh) \(.value|@sh)"' >>"${BUILD_LABELS_PATH}"
	while read -r line; do
		read -r k v <<<"${line}"
		"${labels_dct["${k}"]:-}" && echo "Label \"${k}\" is already set to \"${labels_dct["${k}"]}\". Overriding with \"${v:-}\"." >&2
		labels_dct["${k}"]="${v:-}"
	done < <(sed -E '/^\s*$/d; s/^\s*//g; s/\s*$//g; s/[^\\][#].*$//g; s/^(\S+)\s{2,}/\1 /g' "${BUILD_LABELS_PATH}")
fi

# Set labels from the environment or fill in the defaults:

# Set the image version:
IMAGE_VERSION="${INPUT_IMAGE_VERSION:-}"
if [[ -z "${IMAGE_VERSION:-}" ]]; then
	IMAGE_VERSION="${labels_dct["org.opencontainers.image.version"]:-${labels_dct["org.label-schema.version"]:-${labels_dct["version"]:-${labels_dct["VERSION"]:-${labels_dct["Version"]:-${GITHUB_SHA:-$(date +%s)}}}}}}"
fi

# Set the image authors:
IMAGE_AUTHORS="${IMAGE_AUTHORS:-${labels_dct["org.opencontainers.image.authors"]:-${labels_dct["org.label-schema.author"]:-${labels_dct["author"]:-${labels_dct["AUTHOR"]:-${labels_dct["Author"]:-}}}}}}"
IMAGE_AUTHORS="${IMAGE_AUTHORS:-"$(gh api "/users/${GITHUB_ACTOR}" --jq 'if .name == "" then .login else .name end' || true)"}"
IMAGE_AUTHORS="${IMAGE_AUTHORS:-${GITHUB_ACTOR:-}}"

# Set the image source:
IMAGE_SOURCE="${IMAGE_SOURCE:-${labels_dct["org.opencontainers.image.source"]:-${labels_dct["org.label-schema.vcs-url"]:-${GITHUB_REPOSITORY+https://github.com/${GITHUB_REPOSITORY}}}}}"

# Set the image revision:
IMAGE_REVISION="${IMAGE_REVISION:-${labels_dct["org.opencontainers.image.revision"]:-${labels_dct["org.label-schema.vcs-ref"]:-${GITHUB_SHA:-}}}}"

# Set the image URL:
IMAGE_URL="${IMAGE_URL:-${INPUT_IMAGE_URL:-oras://ghcr.io/${GITHUB_REPOSITORY}/${IMAGE_NAME}:${IMAGE_VERSION}}}"
echo "IMAGE_URL=${IMAGE_URL}" >>"${GITHUB_ENV}"

# Set the image vendor:
IMAGE_VENDOR="${IMAGE_VENDOR:-${labels_dct["org.opencontainers.image.vendor"]:-${labels_dct["org.label-schema.vendor"]:-${GITHUB_REPOSITORY_OWNER:-}}}}"

# Set the image license(s):
IMAGE_LICENSES="${IMAGE_LICENSES:-${labels_dct["org.opencontainers.image.licenses"]:-}}"
IMAGE_LICENSES="${IMAGE_LICENSES:-"$(gh api "/repos/${GITHUB_REPOSITORY}" --jq '.license.spdx_id?' || true)"}"

# Set the image title:
IMAGE_TITLE="${IMAGE_TITLE:-${labels_dct["org.opencontainers.image.title"]:-${labels_dct["org.label-schema.name"]:-${IMAGE_NAME:-${GITHUB_REPOSITORY##*/}}}}}"

# Set the image description:
IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-${labels_dct["org.opencontainers.image.description"]:-${labels_dct["org.label-schema.description"]:-${labels_dct["description"]:-${labels_dct["DESCRIPTION"]:-${labels_dct["Description"]:-}}}}}}"
if [[ -n "${IMAGE_DESCRIPTION:-}" ]]; then
	# Get the description from the definition file's help section if possible:
	HELP_SECTION="$(awk '/^\s*%help/{flag=1;next}/^\s*%\S+/{flag=0}flag' "${DEFFILE}" | tr '\n' ' ' | sed -E 's/^\s*//g; s/\s*$//g; s/\s+/ /g' || true)"
	if [[ -n "${HELP_SECTION}" ]]; then
		IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-"${HELP_SECTION}"}"
	fi
fi
IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-"$(gh api "/repos/${GITHUB_REPOSITORY}" --jq '.description?' || true)"}"

if ((${#IMAGE_DESCRIPTION} > 300)); then
	echo "The description is too long. It must be less than 300 characters. Truncating." >&2
	IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:0:297}..."
fi

# Get the base image name from the definition file if possible for org.opencontainers.image.base.name:
IMAGE_BASE_NAME="${IMAGE_BASE_NAME:-${labels_dct["org.opencontainers.image.base.name"]:-"$(grep -oiP '^\s*From:\s*\K\S+' "${DEFFILE}" || true)"}}"

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

# Add the labels to the build labels file:
if [[ -n "${BUILD_LABELS_PATH:-}" ]] && [[ -f "${BUILD_LABELS_PATH}" ]]; then
	# Reverse the order of the labels so that custom labels added as an input are not overridden by the default ones:
	tac "${BUILD_LABELS_PATH}" >"${BUILD_LABELS_PATH}.tmp" && mv "${BUILD_LABELS_PATH}.tmp" "${BUILD_LABELS_PATH}"
fi
