#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2312
[[ "${XTRACE:-0}" != 0 ]] && set -x && printenv
set -eEuo pipefail

# Set up arguments array for apptainer:
declare -a apptainer_args=()

# Go through build arguments:
for arg in "${INPUT_BUILD_ARGS[@]:-}"; do
	apptainer_args+=("--build-arg" "${arg}")
done

# Go through arguments with singular values:
for arg in bind build-arg-file disable-cache fakeroot fix-perms force json mount notest section update userns writable-tmpfs; do
	arg_envvar="${arg//-/_}"
	arg_envvar="INPUT_${arg_envvar^^}"
	if [[ -n "${!arg_envvar:-}" ]]; then
		apptainer_args+=("--${arg}=${!arg_envvar}")
	fi
done

# Set up the image output path:
INPUT_IMAGE_PATH="${RUNNER_TEMP}/${INPUT_IMAGE_NAME}.sif"
echo "INPUT_IMAGE_PATH=${INPUT_IMAGE_PATH}" | tee -a "${GITHUB_ENV}" "${SET_GITHUB_ENV}"

# Show the free space on the image output path:
df -h "${RUNNER_TEMP}" >&2

# Go to the directory of the definition file:
pushd "$(dirname "${INPUT_DEFFILE}")"

# If there are build labels, add them to the definition file:
if [[ -n "${INPUT_BUILD_LABELS_PATH:-}" ]] && [[ -f "${INPUT_BUILD_LABELS_PATH}" ]] && [[ -r "${INPUT_BUILD_LABELS_PATH}" ]] && test "$(wc -l <"${INPUT_BUILD_LABELS_PATH}" || echo 0)" -gt 0; then
	BUILD_DEFFILE="${RUNNER_TEMP}/$(basename "${INPUT_DEFFILE}")"
	cp "${INPUT_DEFFILE}" "${BUILD_DEFFILE}"
	printf "\n%%files\n\t%q /.build.labels\n" "$(realpath "${INPUT_BUILD_LABELS_PATH}")" >>"${BUILD_DEFFILE}"
else
	BUILD_DEFFILE="$(basename "${INPUT_DEFFILE}")"
fi

# Build the container:
apptainer build "${apptainer_args[@]}" "${INPUT_IMAGE_PATH}" "${BUILD_DEFFILE}"

# Show the size of the container:
echo -n "Container size:" >&2
du -h "${INPUT_IMAGE_PATH}" | cut -f1 >&2

# Show the labels of the container:
echo "Container labels:" >&2
apptainer inspect "${INPUT_IMAGE_PATH}" >&2

# Write the image path to the output:
echo "image-path=${INPUT_IMAGE_PATH}" >>"${GITHUB_OUTPUT}"
# Return to the original directory:
popd
