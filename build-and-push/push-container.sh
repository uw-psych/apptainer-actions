#!/usr/bin/env bash
set -eu${XTRACE:-} -o pipefail

# Get the image tags:
declare -a image_tags=()
image_tags+=(${INPUT_TAGS:-})     # Add the tags from the input
image_tags+=(${IMAGE_VERSION:-})  # Add the version as a tag
image_tags+=(${INPUT_ADD_TAGS:-}) # Add the additional tags to the list of tags

# If we have a semantic version, and if it is the newest version that is not a pre-release, add the "latest" tag:
if [[ "${IMAGE_VERSION}" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
	echo "::notice::Trying to set IMAGE_VERSION to semantically newest tag if possible"
	SEMANTICALLY_NEWEST_TAG="$({ echo "${IMAGE_VERSION}";
	IMAGE_REPO_URL="${IMAGE_URL#oras://ghcr.io/}"
	IMAGE_REPO_URL="${IMAGE_REPO_URL%:*}"
	IMAGE_REPO_URL="$(jq -rn --arg x "${IMAGE_REPO_URL}" '$x|@uri' || true)"
	gh api "/users/${GITHUB_REPOSITORY_OWNER}/packages/container/${GITHUB_REPOSITORY#*/}%2F${IMAGE_NAME}/versions" --jq '.[].metadata.container.tags[]' ||
		true; } |
		grep -P '^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$' |
		grep -v '\-.*$' | sed -E 's/^v?(.*)$/\1\t\0/g' |
		tr - \~ |
		sort -k1V |
		tr \~ - |
		cut -f2 |
		tail -n1 ||
		true)"

	if [[ -n "${SEMANTICALLY_NEWEST_TAG:-}" ]]; then
		echo "::notice::The semantically newest tag is ${SEMANTICALLY_NEWEST_TAG:-}"
	else
		echo "::notice::No semantically newest tag found ${SEMANTICALLY_NEWEST_TAG:-}"
	fi

	if [[ "${SEMANTICALLY_NEWEST_TAG:-}" == "${IMAGE_VERSION}" ]]; then
		image_tags+=("latest")
	fi

fi

# Remove duplicate tags:
image_tags=($(echo "${image_tags[@]}" | tr [:space:] '\n' | awk '!a[$0]++'))

printf "::notice::Image tags: %s\n" "${image_tags[@]}"

case "${IMAGE_URL:-}" in
oras://ghcr.io/*)

	echo "::notice::Logging in to oras://ghcr.io"

	# Log in:
	apptainer remote login -u "${GITHUB_ACTOR}" -p "${GITHUB_TOKEN}" oras://ghcr.io

	# Push the image:
	echo "::notice::Pushing image to \"${IMAGE_URL}\""
	apptainer push -U "${IMAGE_PATH}" "${IMAGE_URL}"

	# Update OCI manifest using labels in container:

	oras manifest fetch -u "${GITHUB_ACTOR}" -p "${GITHUB_TOKEN}" "${IMAGE_URL#oras://}" >"${RUNNER_TEMP}/manifest.json"
	labels_json="$(apptainer inspect --json --labels "${IMAGE_PATH}" | jq -r '.data.attributes.labels' || true)"
	if [[ -n "${labels_json:-}" ]]; then
		echo "::notice::Adding labels to OCI manifest"
		jq --argjson labels "${labels_json}" '.annotations += $labels' "${RUNNER_TEMP}/manifest.json" >"${RUNNER_TEMP}/manifest-updated.json"
		oras manifest push -u "${GITHUB_ACTOR}" -p "${GITHUB_TOKEN}" --media-type 'application/vnd.oci.image.manifest.v1+json' "${IMAGE_URL#oras://}" "${RUNNER_TEMP}/manifest-updated.json"
	fi
	;;
*)
	echo "::error::Invalid image URL: ${IMAGE_URL}"
	exit 1
	;;
esac

# Tag the image with additional tags if any:
if (("${#image_tags[@]}" > 1)); then
	printf "::notice::Tagging the image with additional tags: %s\n" "${image_tags[@]:1}"
	oras tag -u "${GITHUB_ACTOR}" -p "${GITHUB_TOKEN}" "${IMAGE_URL#oras://}" "${image_tags[@]}"
fi

# Set image-url output:
echo "image-url=${IMAGE_URL}" >>"${GITHUB_OUTPUT}"

echo "::notice::Pushed image to \"${IMAGE_URL}\""
