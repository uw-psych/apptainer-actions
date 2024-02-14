#!/usr/bin/env bash
[[ "${XTRACE:-0}" != 0 ]] && set -x
set -eEuo pipefail

declare -a apptainer_args=()

for arg in bind build-args build-arg-file disable-cache fakeroot fix-perms force json mount notest section update userns writable-tmpfs; do
	arg_envvar="${arg//-/_}"
	arg_envvar="INPUT_${arg_envvar^^}"
	if [[ -n "${!arg_envvar:-}" ]]; then
		apptainer_args+=("--${arg}=${!arg_envvar}")
	fi
done

IMAGE_PATH="${RUNNER_TEMP}/${IMAGE_NAME}.sif"

if [[ -n "${BUILD_LABELS_PATH:-}" ]] && [[ -f "${BUILD_LABELS_PATH}" ]] && [[ -r "${BUILD_LABELS_PATH}" ]] && test $(wc -l <"${BUILD_LABELS_PATH}" || echo 0) -gt 0; then
	BUILD_DEFFILE="${RUNNER_TEMP}/${IMAGE_NAME}.def"
	cp "${DEFFILE}" "${BUILD_DEFFILE}"
	printf "\n%%files\n\t%q /.build.labels\n" "$(realpath "${BUILD_LABELS_PATH}")" >>"${BUILD_DEFFILE}"
fi

apptainer build "${apptainer_args[@]}" "${IMAGE_PATH}" "${BUILD_DEFFILE:-${DEFFILE}}"
echo -n "Container size:" >&2
du -h "${IMAGE_PATH}" | cut -f1 >&2

echo "Container labels:" >&2
apptainer inspect "${IMAGE_PATH}" >&2

echo "IMAGE_PATH=${IMAGE_PATH}" >>"${GITHUB_ENV}"
