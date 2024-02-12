# GitHub Action: Build and push an Apptainer image

This action will build an Apptainer image and push it to a container registry. The action assumes that Apptainer and oras are installed on the runner. Typically, you would use the [setup](../setup) action to install Apptainer and oras.

The action automatically generates and adds [OpenContainers Annotations](https://specs.opencontainers.org/image-spec/annotations) to the Apptainer image and to the OCI manifest if it is pushed to the GitHub Container Registry.

## Usage

To use this action, you can create a workflow in your GitHub repository with the following content:

```yaml
name: Build and push Apptainer image
on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'
      - 'v*.*.*-*'

jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    name: Build Apptainer image
    permissions:
        contents: read
        packages: write
    steps:
      - name: Install Apptainer
        uses: uw-psych/apptainer-actions/setup@main
      - name: Clear disk space
        uses: uw-psych/apptainer-actions/make-disk-space@main
      - name: Check out code for the container build
        uses: actions/checkout@v4
      - name: Get version
        shell: bash
        run: |
          if [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
            case "${GITHUB_REF_NAME:-}" in
              v?*) IMAGE_VERSION="${GITHUB_REF_NAME#v}";;
              *) echo "Invalid tag: \"${GITHUB_REF_NAME:-}\"" >&2; exit 1;;
            esac
            echo "IMAGE_VERSION=${IMAGE_VERSION}" >> "${GITHUB_ENV}"
          fi
      - name: Build and push Apptainer image
        uses: uw-psych/apptainer-actions/build-and-push@main
        with:
          deffile: Singularity
          image-version: ${{ env.IMAGE_VERSION }}
```

This will create a workflow that runs on every push to the repository. It will build an Apptainer image specified in the `Singularity` file and push it to the container registry. The image version will be set to the tag name without the leading `v`. If the tag name does not start with `v`, the workflow will not run. The URL to the built image will be available in the `image-url` output and is by default set to `oras://ghcr.io/<owner>/<repo>/<name>:<version>`. The `owner` and `repo` are taken from the repository where the workflow is running. The `name` is the name of the directory where the definition file is located. The `version` is the tag name without the leading `v`.

If semantic versioning is used, the version is not a pre-release, and the tag is newer than the previous latest tag, the `latest` tag will be added to the image. If the tag is a pre-release, the `latest` tag will not be added.

## Inputs

| **Input** | **Description** | **Default** | **Required** |
|---|---|---|---|
| `bind` | A list of a user-bind path specifications. spec has the format src[:dest[:opts]],where src and dest are outside and inside paths. If dest is not given, it is set equal to src. Mount options ('opts') may be specified as 'ro'(read-only) or 'rw' (read/write, which is the default). Multiple bind paths can be given by a comma separated list. |  | __false__ |
| `build-args` | List of build-time variables, e.g. 'foo=bar' |  | __false__ |
| `build-arg-file` | Path to the file containing build-time variables |  | __false__ |
| `disable-cache` | Do not use cache when building the image | `true` | __false__ |
| `fakeroot` | Build with the appearance of running as root (default when building from a definition file unprivileged) |  | __false__ |
| `fix-perms` | Ensure owner has rwX permissions on all container content for oci/docker sources |  | __false__ |
| `force` | Force image build even if it exists | `true` | __false__ |
| `json` | interpret build definition as JSON |  | __false__ |
| `mount` | List of mount specifications, e.g. 'type=bind,source=/opt,destination=/hostopt' |  | __false__ |
| `notest` | Skip the %test section |  | __false__ |
| `section` | Only run specific section(s) of deffile (setup, post, files, environment, test, labels, none) (default [all]) |  | __false__ |
| `update` | Run definition over existing container (skips header) |  | __false__ |
| `userns` | Build with the appearance of running as root (default when building from a definition file unprivileged) |  | __false__ |
| `writable-tmpfs` | During the %test section, makes the file system accessible as read-write with non  persistent data (with overlay support only) |  | __false__ |
| `tags` | List of tags (will replace the default tags) |  | __false__ |
| `add-tags` | List of tags to add to the image |  | __false__ |
| `deffile` | Path to the definition file. Default is (Apptainer\|Singularity)([.](.+))[.]def in the root of the repository, or the first definition file found with this pattern in a subdirectory (provided there is only one definition file in the entire repository). |  | __false__ |
| `deffiles-rootdir` | Root directory to search for definition files | `.` | __false__ |
| `name` | What to name the image to build. Default is the name of the directory where the definition file is located. |  | __false__ |
| `image-url` | URL to the built image |  | __false__ |
| `image-version` | Version of the image |  | __false__ |


| **Output** | **Description** |
|---|---|
| `image-url` | URL to the built image |
