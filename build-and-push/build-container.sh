#!/usr/bin/env bash
set -eu${XTRACE:-} -o pipefail

declare -a apptainer_args=()

for arg in bind build-args build-arg-file disable-cache fakeroot fix-perms force json mount notest section update userns writable-tmpfs; do
	arg_envvar="${arg//-/_}"
	arg_envvar="INPUT_${arg_envvar^^}"
	if [[ -n "${!arg_envvar:-}" ]]; then
		apptainer_args+=("--${arg}=\"${!arg_envvar}\"")
	fi
done

if [[ -n "${DEFFILE:-}" ]] && [[ -n "${BUILD_LABELS_PATH:-}" ]] && [[ -f "${BUILD_LABELS_PATH}" ]] && [[ -r "${BUILD_LABELS_PATH}" ]]; then

	BUILD_DEFFILE_LINES="$(wc -l <"${BUILD_LABELS_PATH}" || true)"
	if [[ "${BUILD_DEFFILE_LINES:-0}" -gt 0 ]]; then
		BUILD_DEFFILE="${RUNNER_TEMP}/${IMAGE_NAME}.def"
		cp "${DEFFILE}" "${BUILD_DEFFILE}"
		printf "\n%%files\n\t%q %q\n" "$(realpath "${BUILD_LABELS_PATH}")" "${APPTAINER_LABELS:-/.build.labels}" >>"${BUILD_DEFFILE}"
	fi
fi

IMAGE_DIR="${INPUT_IMAGE_DIR:-${GITHUB_WORKSPACE}}"
IMAGE_PATH="${INPUT_IMAGE_PATH:-${IMAGE_DIR}/${IMAGE_NAME}.sif}"

mkdir -p "$(dirname "${IMAGE_PATH}")"

printf "::notice::Free space in the image directory \"${IMAGE_DIR}\": %s\n" "$(df -hlT "${IMAGE_DIR}" || true)"

if [[ -n "${INPUT_APPTAINER_TMPDIR:-${APPTAINER_TMPDIR:-}}" ]]; then
	mkdir -p "${APPTAINER_TMPDIR}" && export APPTAINER_TMPDIR="${INPUT_APPTAINER_TMPDIR:-${APPTAINER_TMPDIR}}"
	printf "::notice:: Free space in APPTAINER_TMPDIR \"${APPTAINER_TMPDIR}\": %s\n" "$(df -hlT "${APPTAINER_TMPDIR}" || true)"
	echo "APPTAINER_TMPDIR=${APPTAINER_TMPDIR}" >>"${GITHUB_ENV}"
fi

apptainer build "${apptainer_args[@]}" "${IMAGE_PATH}" "${BUILD_DEFFILE:-${DEFFILE}}"

[[ -n "${APPTAINER_TMPDIR:-}" ]] && [[ -d "${APPTAINER_TMPDIR}" ]] && rm -rf "${APPTAINER_TMPDIR:?}/*"

echo "::notice::Container size:" "$(du -h "${IMAGE_PATH}" | cut -f1 || true)"
printf "::notice::Container labels:\n%s\n" "$(apptainer apptainer inspect "${IMAGE_PATH}" || true)"
printf "::notice::IMAGE_PATH=%q\n" "${IMAGE_PATH}"
echo "IMAGE_PATH=${IMAGE_PATH}" >>"${GITHUB_ENV}"
