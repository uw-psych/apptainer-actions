# GitHub Action: Make Disk Space

This action removes unnecessary tools and packages to free up disk space.

## Usage

To use this action, you can create a workflow in your GitHub repository with the following content:

```yaml
name: Workflow Name
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: uw-psych/apptainer-actions/make-disk-space@main
        with:
        # Example: Remove Android tools, keep .NET tools, remove Chromium, keep Azure CLI
            rm-android: true
            rm-dotnet: false
            rm-chromium: true
            rm-azure-cli: false
```

Replace `Workflow Name` with the name of your workflow. This will create a workflow that runs on every push and pull request to the repository. It will remove Android tools, keep .NET tools, remove Chromium, and keep Azure CLI.

## Inputs

| **Input** | **Description** | **Default** | **Required** |
|---|---|---|---|
| `rm-android` | Whether to remove Android tools | `true` | __false__ |
| `rm-dotnet` | Whether to remove .NET tools | `true` | __false__ |
| `rm-hosted-tool-cache` | Whether to remove the hosted tool cache | `true` | __false__ |
| `rm-powershell` | Whether to remove PowerShell | `true` | __false__ |
| `rm-swift` | Whether to remove Swift | `true` | __false__ |
| `rm-chromium` | Whether to remove Chromium | `true` | __false__ |
| `rm-azure-cli` | Whether to remove Azure CLI | `true` | __false__ |
| `rm-apt-packages` | Remove apt packages | `false` | __false__ |
| `rm-apt-cache` | Clear apt cache | `false` | __false__ |
| `apt-packages-remove-default` | Packages to remove | `ansible azure-cli xorriso zsync esl-erlang firefox gfortran-8 gfortran-9 google-chrome-stable google-cloud-sdk imagemagick libmagickcore-dev libmagickwand-dev libmagic-dev ant ant-optional kubectl mercurial mono-complete libmysqlclient unixodbc-dev yarn chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev snmp pollinate libpq-dev postgresql-client powershell ruby-full sphinxsearch subversion mongodb-org azure-cli microsoft-edge-stable google-cloud-sdk` | __false__ |
| `apt-packages-remove-include` | Additional packages to remove |  | __false__ |
| `apt-packages-remove-exclude` | Packages to keep |  | __false__ |
