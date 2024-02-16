#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312,SC2250
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

declare -A labels_dct

# Read the labels from the definition file:
while read -r line; do
	read -r k v <<<"$line"
	labels_dct["${k}"]="${v:-}"
done < <(awk '/^\s*%labels/{flag=1;next}/^\s*%\S+/{flag=0}flag' "${INPUT_DEFFILE}" | sed -E '/^\s*$/d; s/^\s*//g; s/\s*$//g; s/[^\\][#].*$//g; s/^(\S+)\s{2,}/\1 /g')

# Get image version from the definition file if possible:

# Get the labels from the input and set them:
if [[ -n "${INPUT_LABELS:-}" ]]; then
	echo "${INPUT_LABELS:-}" | jq -r 'to_entries[] | "\("labels." + .key |@sh) \(.value|@sh)"' >>"${INPUT_BUILD_LABELS_PATH}"
	while read -r line; do
		read -r k v <<<"${line}"
		"${labels_dct["${k}"]:-}" && echo "Label \"${k}\" is already set to \"${labels_dct["${k}"]}\". Overriding with \"${v:-}\"." >&2
		labels_dct["${k}"]="${v:-}"
	done < <(sed -E '/^\s*$/d; s/^\s*//g; s/\s*$//g; s/[^\\][#].*$//g; s/^(\S+)\s{2,}/\1 /g' "${INPUT_BUILD_LABELS_PATH}")
fi

# Set labels from the environment or fill in the defaults:

# Set the image version:
if [[ -z "${INPUT_IMAGE_VERSION:-}" ]]; then
	INPUT_IMAGE_VERSION="${labels_dct["org.opencontainers.image.version"]:-${labels_dct["org.label-schema.version"]:-${labels_dct["version"]:-${labels_dct["VERSION"]:-${labels_dct["Version"]:-$(date +%s)}}}}}"
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
INPUT_IMAGE_URL="${INPUT_IMAGE_URL:-oras://ghcr.io/${GITHUB_REPOSITORY}/${INPUT_IMAGE_NAME}:${INPUT_IMAGE_VERSION}}"
echo "INPUT_IMAGE_URL=${INPUT_IMAGE_URL}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"

# Set the image vendor:
IMAGE_VENDOR="${IMAGE_VENDOR:-${labels_dct["org.opencontainers.image.vendor"]:-${labels_dct["org.label-schema.vendor"]:-${GITHUB_REPOSITORY_OWNER:-}}}}"

# Set the image license(s):
IMAGE_LICENSES="${IMAGE_LICENSES:-${labels_dct["org.opencontainers.image.licenses"]:-}}"
IMAGE_LICENSES="${IMAGE_LICENSES:-"$(gh api "/repos/${GITHUB_REPOSITORY}" --jq '.license.spdx_id?' || true)"}"

# Set the image title:
IMAGE_TITLE="${IMAGE_TITLE:-${labels_dct["org.opencontainers.image.title"]:-${labels_dct["org.label-schema.name"]:-${INPUT_IMAGE_NAME:-${GITHUB_REPOSITORY##*/}}}}}"

# Set the image description:
IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-${labels_dct["org.opencontainers.image.description"]:-${labels_dct["org.label-schema.description"]:-${labels_dct["description"]:-${labels_dct["DESCRIPTION"]:-${labels_dct["Description"]:-}}}}}}"
if [[ -n "${IMAGE_DESCRIPTION:-}" ]]; then
	# Get the description from the definition file's help section if possible:
	HELP_SECTION="$(awk '/^\s*%help/{flag=1;next}/^\s*%\S+/{flag=0}flag' "${INPUT_DEFFILE}" | tr '\n' ' ' | sed -E 's/^\s*//g; s/\s*$//g; s/\s+/ /g' || true)"
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
IMAGE_BASE_NAME="${IMAGE_BASE_NAME:-${labels_dct["org.opencontainers.image.base.name"]:-}}"

# Write each image label to the file if the label is set:
test -n "${INPUT_IMAGE_VERSION:-}" && echo org.opencontainers.image.version "$_" >>"${INPUT_BUILD_LABELS_PATH}" && echo "INPUT_IMAGE_VERSION=${INPUT_IMAGE_VERSION}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"
test -n "${IMAGE_AUTHORS:-}" && echo org.opencontainers.image.authors "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${IMAGE_SOURCE:-}" && echo org.opencontainers.image.source "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${IMAGE_REVISION:-}" && echo org.opencontainers.image.revision "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${INPUT_IMAGE_URL:-}" && echo org.opencontainers.image.url "$_" >>"${INPUT_BUILD_LABELS_PATH}" && echo "INPUT_IMAGE_URL=${INPUT_IMAGE_URL}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"
test -n "${IMAGE_VENDOR:-}" && echo org.opencontainers.image.vendor "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${IMAGE_LICENSES:-}" && echo org.opencontainers.image.licenses "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${IMAGE_TITLE:-}" && echo org.opencontainers.image.title "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${IMAGE_DESCRIPTION:-}" && echo org.opencontainers.image.description "$_" >>"${INPUT_BUILD_LABELS_PATH}"
test -n "${IMAGE_BASE_NAME:-}" && echo org.opencontainers.image.base.name "$_" >>"${INPUT_BUILD_LABELS_PATH}"

# Add the labels to the build labels file:
if [[ -n "${INPUT_BUILD_LABELS_PATH:-}" ]] && [[ -f "${INPUT_BUILD_LABELS_PATH}" ]]; then
	# Reverse the order of the labels so that custom labels added as an input are not overridden by the default ones:
	tac "${INPUT_BUILD_LABELS_PATH}" >"${INPUT_BUILD_LABELS_PATH}.tmp" && mv "${INPUT_BUILD_LABELS_PATH}.tmp" "${INPUT_BUILD_LABELS_PATH}"
fi
