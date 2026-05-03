# Windows bootstrap

The Windows bootstrap is the primary tested installation path for this
repository.

## Permission model

Use two different PowerShell contexts:

1. Install Scoop from a non-admin PowerShell session, because Scoop is a
   user-level package manager.
2. Run this repository's Windows bootstrap from an elevated PowerShell session,
   because the bootstrap can configure machine-level prerequisites, environment
   state, package managers, runtimes, completions, and developer tools that may
   require administrator privileges.

The `make bootstrap-windows` target is a convenience wrapper around PowerShell.
It is appropriate only when the current environment provides compatible `make`,
`pwsh`, and superuser semantics. On native Windows, the important requirement is
that the bootstrap runs with superuser / administrator privileges.

## Prerequisites

Install Scoop first:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

If Git is not installed yet, install it with Scoop:

```powershell
scoop install git
```

Then clone the repository:

```powershell
git clone https://github.com/prettycation/dotfiles.git
cd dotfiles
```

If Git is unavailable before bootstrap, download the repository ZIP from GitHub,
extract it, and open PowerShell in the extracted directory. The bootstrap can
install Git later as part of the required Scoop group.

## Run the bootstrap

Open PowerShell as Administrator, then run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
./scripts/bootstrap/windows/bootstrap.ps1 -ChezmoiRepo "https://github.com/prettycation/dotfiles"
```

Optional flags:

```powershell
# Skip mise runtime setup
./scripts/bootstrap/windows/bootstrap.ps1 -SkipMise

# Skip Cargo package setup
./scripts/bootstrap/windows/bootstrap.ps1 -SkipCargo

# Skip PowerShell completions setup
./scripts/bootstrap/windows/bootstrap.ps1 -SkipPSCompletions

# Skip VS Code extension synchronization
./scripts/bootstrap/windows/bootstrap.ps1 -SkipVSCode

# Show a custom chezmoi repository hint in the final manual steps
./scripts/bootstrap/windows/bootstrap.ps1 -ChezmoiRepo "https://github.com/prettycation/dotfiles"
```

If the bootstrap installs PowerShell 7 (`pwsh`) and asks you to restart, close the
current window, open PowerShell 7 as Administrator, return to the repository
directory, and run the bootstrap command again.

## What the bootstrap runs

The Windows bootstrap is an orchestrator. It loads shared helpers, prepares a
context object, reads manifests, and runs step scripts in order.

```text
scripts/bootstrap/windows/
├── bootstrap.ps1
├── bootstrap.common.psm1
├── steps/
│   ├── 00-preflight.ps1
│   ├── 05-xdg-env.ps1
│   ├── 10-scoop-core.ps1
│   ├── 15-bootstrap-required.ps1
│   ├── 20-scoop-groups.ps1
│   ├── 40-mise.ps1
│   ├── 50-cargo-packages.ps1
│   ├── 60-pscompletions.ps1
│   └── 70-vscode.ps1
└── tasks/
    ├── add-pscompletions.ps1
    ├── install-cargo-packages.ps1
    └── install-vscode-extensions.ps1
```

| Step | Purpose |
| --- | --- |
| `00-preflight.ps1` | Checks paths, loaded manifests, manifest shape, execution policy, Scoop availability, and tool status. |
| `05-xdg-env.ps1` | Creates XDG-style user directories and user-level environment variables. |
| `10-scoop-core.ps1` | Adds Scoop buckets declared in the Windows package manifest. |
| `15-bootstrap-required.ps1` | Installs required bootstrap packages first. |
| `20-scoop-groups.ps1` | Prompts for default and optional Scoop package groups. |
| `40-mise.ps1` | Optionally configures mise and installs declared runtimes. |
| `50-cargo-packages.ps1` | Optionally installs declared Cargo packages using the Cargo package manifest. |
| `60-pscompletions.ps1` | Optionally installs declared PowerShell completions from the Windows package manifest. |
| `70-vscode.ps1` | Optionally installs VS Code extensions when `code` is available. |

## What the bootstrap intentionally does not do

The bootstrap does not automatically:

- create `~/.config/chezmoi/chezmoi.toml`;
- run `chezmoi init`;
- run `chezmoi apply`;
- sync the PowerShell profile.

These steps remain manual because they may depend on Bitwarden secrets, local
profile choices, and review of pending changes.

## XDG environment on Windows

The bootstrap initializes a Unix-style layout on Windows so cross-platform tools
can share configuration paths.

| Variable | Target |
| --- | --- |
| `XDG_CONFIG_HOME` | `%USERPROFILE%/.config` |
| `XDG_DATA_HOME` | `%USERPROFILE%/.local/share` |
| `XDG_STATE_HOME` | `%USERPROFILE%/.local/state` |
| `XDG_CACHE_HOME` | `%USERPROFILE%/.cache` |
| `YAZI_CONFIG_HOME` | `%USERPROFILE%/.config/yazi` |
| `INTELLI_CONFIG` | `%USERPROFILE%/.config/intelli-shell/config.toml` |

These directories line up with the checked-in `home/dot_config`,
`home/dot_local/share`, `home/dot_local/state`, and `home/dot_cache` trees.

## Continue with chezmoi

After bootstrap, continue with [Applying with chezmoi](chezmoi.md).
