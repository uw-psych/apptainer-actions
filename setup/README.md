# GitHub Action: Set up Apptainer and oras

This action sets up [Apptainer](https://github.com/apptainer/apptainer) and [oras](https://github.com/oras-project/oras) for use in workflows.

## Usage

To use this action, you can create a workflow in your GitHub repository with the following content:

```yaml
name: Workflow Name
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: uw-psych/apptainer-actions/setup@main
        with:
        # Example: Install Apptainer version 1.2.5 and the latest oras version
            apptainer-version: 1.2.5
```

This will install Apptainer version 1.2.5 and the latest oras version on the runner for every push to the repository. Typically, you would then use the installed Apptainer and oras to build and push an Apptainer image.

## Inputs

| **Input** | **Description** | **Default** | **Required** |
|---|---|---|---|
| `apptainer-version` | Version of Apptainer to install | `latest` | __false__ |
| `oras-version` | Version of oras to install | `latest` | __false__ |
| `download-dir` | Directory to download the Apptainer and oras deb and tar.gz files to | `.` | __false__ |

## Outputs

| **Output** | **Description** |
|---|---|
| `apptainer-version` | The installed version of Apptainer |
| `oras-version` | The installed version of oras |
