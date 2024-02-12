# apptainer-actions

This repository contains GitHub Actions related to building [Apptainer](https://github.com/apptainer/apptainer) images in GitHub workflows.

## Actions

- [setup](./setup): This action sets up [Apptainer](https://github.com/apptainer/apptainer) and [oras](https://github.com/oras-project/oras) for use in workflows.
- [make-disk-space](./make-disk-space): This action removes unnecessary tools and packages to free up disk space.
- [build-and-push](./build-and-push): This action will build an Apptainer image and push it to a container registry. It will also generate and add [OpenContainers Annotations](https://specs.opencontainers.org/image-spec/annotations) to the Apptainer image and to the OCI manifest if it is pushed to the GitHub Container Registry.

## Contributing

If you have a feature request or found a bug, please open an issue. If you want to contribute, please open a pull request.

## License

See [LICENSE](LICENSE) for the license of this repository.
