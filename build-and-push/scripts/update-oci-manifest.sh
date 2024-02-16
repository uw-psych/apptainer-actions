#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

# Fetch the manifest from the newly pushed image:
oras manifest fetch -u "${GITHUB_ACTOR}" -p "${GH_TOKEN}" "${INPUT_IMAGE_URL#oras://}" >"${RUNNER_TEMP}/manifest.json"

# Get the annotations from the image:
labels_json="$(apptainer inspect --json --labels "${INPUT_IMAGE_PATH}" | jq -r '.data.attributes.labels' || true)"

# If the labels are not empty, append the existing labels to the manifest annotations:
if [[ -n "${labels_json:-}" ]]; then
	# Get the build date:
	label_schema_build_date="$(apptainer inspect --json --labels looping_latest.sif | jq '.data.attributes.labels."org.label-schema.build-date"' || true)"
	if [[ -n "${label_schema_build_date}" ]]; then
		if echo "${label_schema_build_date}" | tr -cd '_' | wc -c | xargs -I _ test _ -eq 5; then
			build_date="$(echo "${label_schema_build_date}" | tr '_' ' ' | xargs -I _ date --date "_" || true)"
			if [[ -n "${build_date:-}" ]]; then
				labels_json="$(echo "${labels_json}" | jq -r --arg build_date "${build_date}" '. += { "org.opencontainers.image.created": $build_date }')"
			fi
		fi
	fi

	# Add the labels to the manifest:
	jq --argjson labels "${labels_json}" '.annotations += $labels' "${RUNNER_TEMP}/manifest.json" >"${RUNNER_TEMP}/manifest-updated.json"

	# Push the updated manifest:
	oras manifest push -u "${GITHUB_ACTOR}" -p "${GH_TOKEN}" --media-type 'application/vnd.oci.image.manifest.v1+json' "${INPUT_IMAGE_URL#oras://}" "${RUNNER_TEMP}/manifest-updated.json"
fi
