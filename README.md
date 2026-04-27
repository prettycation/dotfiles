# dotfiles

Personal Windows and Arch/Linux dotfiles managed with [chezmoi](https://www.chezmoi.io/).

> **Current status**
>
> The **Windows** bootstrap flow is the only installation path that has been tested and is expected to work. Linux and other POSIX-related files are present, but should be treated as work in progress until they are explicitly validated.

## Overview

This repository is organized as a two-stage workstation setup:

1. **Bootstrap the machine**: install package manager prerequisites, Scoop buckets, selected packages, runtime tooling, and user-level environment variables.
2. **Apply dotfiles with chezmoi**: render templates and place configuration files after local choices and secrets are ready.

The bootstrap phase and the chezmoi apply phase are intentionally separate. The Windows bootstrap prepares the machine, but it does not automatically apply all dotfiles.

## Repository layout

```text
.
├── home/                         # chezmoi source root
│   ├── .chezmoidata/             # structured data used by chezmoi templates
│   ├── .chezmoiscripts/windows/  # Windows scripts executed by chezmoi apply/onchange hooks
│   ├── .chezmoitemplates/        # shared template fragments
│   ├── AppData/Local/Packages/   # Windows app data managed through chezmoi
│   ├── Documents/                # user document-level configuration or shortcuts
│   ├── dot_cache/                # files mapped to ~/.cache
│   ├── dot_config/               # files mapped to ~/.config
│   ├── dot_espanso/              # espanso configuration
│   ├── dot_glzr/glazewm/         # GlazeWM configuration
│   ├── dot_local/                # files mapped to ~/.local
│   ├── dot_ssh/                  # SSH configuration
│   ├── .chezmoi.toml.tmpl        # chezmoi config template
│   ├── .chezmoiexternal.toml.tmpl# external resources managed by chezmoi
│   ├── .chezmoiignore.tmpl       # conditional ignore rules
│   ├── .chezmoiremove.tmpl       # conditional removal rules
│   ├── dot_duckdbrc              # DuckDB rc file
│   ├── dot_gitconfig.tmpl        # Git config template
│   ├── dot_zshenv                # zsh environment
│   └── empty_dot_hushlogin       # suppress login message where supported
├── manifests/                    # package/runtime/extension manifests
│   ├── windows.packages.json
│   ├── windows.runtimes.json
│   ├── windows.vscode-extensions.json
│   ├── linux.arch.packages.json
│   └── linux.ubuntu.packages.json
├── scripts/bootstrap/
│   ├── windows/                  # tested Windows bootstrap flow
│   └── linux/                    # experimental Linux bootstrap flow
├── assets/                       # assets for managed apps/tools
├── examples/chezmoi/             # example chezmoi config
├── .chezmoiroot                  # points chezmoi at home/
├── .chezmoiversion               # chezmoi version constraint
├── .emmyrc.json                  # Lua language-server/editor metadata
├── .gitignore
├── LICENSE
└── install.sh                    # POSIX helper, not the tested Windows entrypoint
```

## Managed home files

The `home/` directory is the chezmoi source tree. File and directory names follow chezmoi naming conventions, for example `dot_config` becomes `~/.config`, `dot_local` becomes `~/.local`, and `dot_gitconfig.tmpl` becomes a rendered `~/.gitconfig`.

### chezmoi metadata

| Path                              | Purpose                                                                                            |
| --------------------------------- | -------------------------------------------------------------------------------------------------- |
| `home/.chezmoidata/`              | Shared data for templates. Use this for structured values that multiple templates/scripts need.    |
| `home/.chezmoitemplates/`         | Reusable template fragments. Useful for keeping large templates maintainable.                      |
| `home/.chezmoi.toml.tmpl`         | Template for chezmoi's own configuration. This may depend on local identity, platform, or secrets. |
| `home/.chezmoiexternal.toml.tmpl` | External resources that chezmoi can fetch/manage. Review before applying on a new machine.         |
| `home/.chezmoiignore.tmpl`        | Conditional ignore rules, usually platform-specific.                                               |
| `home/.chezmoiremove.tmpl`        | Conditional cleanup/removal rules. Review before applying on a machine with existing config.       |

### Shell, Git, SSH, and local state

| Path                             | Target                    | Purpose                                           |
| -------------------------------- | ------------------------- | ------------------------------------------------- |
| `home/dot_gitconfig.tmpl`        | `~/.gitconfig`            | Git configuration rendered from template data.    |
| `home/dot_ssh/`                  | `~/.ssh`                  | SSH config and related files.                     |
| `home/dot_zshenv`                | `~/.zshenv`               | zsh environment entrypoint.                       |
| `home/dot_cache/zsh/zcompcache/` | `~/.cache/zsh/zcompcache` | zsh completion cache location.                    |
| `home/dot_local/share/`          | `~/.local/share`          | User-level shared application data.               |
| `home/dot_local/state/zsh/`      | `~/.local/state/zsh`      | zsh state files, separated from config and cache. |
| `home/dot_duckdbrc`              | `~/.duckdbrc`             | DuckDB startup configuration.                     |
| `home/empty_dot_hushlogin`       | `~/.hushlogin`            | Suppresses login banners where supported.         |

### Application configuration

Most application configuration lives under `home/dot_config/`, which maps to `~/.config/`.

| Path                                 | Purpose                                                  |
| ------------------------------------ | -------------------------------------------------------- |
| `home/dot_config/atuin/`             | Atuin shell history configuration.                       |
| `home/dot_config/bat/`               | bat themes/configuration.                                |
| `home/dot_config/diny/`              | diny configuration.                                      |
| `home/dot_config/exact_zsh/`         | zsh-related configuration managed as an exact directory. |
| `home/dot_config/eza/`               | eza configuration.                                       |
| `home/dot_config/fastfetch/`         | fastfetch system summary configuration.                  |
| `home/dot_config/gtk-4.0/`           | GTK 4 configuration.                                     |
| `home/dot_config/private_gtk-3.0/`   | private GTK 3 configuration.                             |
| `home/dot_config/intelli-shell/`     | intelli-shell configuration.                             |
| `home/dot_config/kitty/`             | Kitty terminal configuration.                            |
| `home/dot_config/wezterm/`           | WezTerm terminal configuration.                          |
| `home/dot_config/mihomo/`            | mihomo proxy configuration.                              |
| `home/dot_config/niri/`              | niri Wayland compositor configuration.                   |
| `home/dot_config/nushell/`           | Nushell configuration.                                   |
| `home/dot_config/nvim/`              | Neovim configuration.                                    |
| `home/dot_config/opencode/`          | opencode configuration.                                  |
| `home/dot_config/private_fcitx5/`    | private fcitx5 input method configuration.               |
| `home/dot_config/tacky-borders/`     | tacky-borders configuration.                             |
| `home/dot_config/television/`        | television configuration.                                |
| `home/dot_config/xremap/`            | xremap key remapping configuration.                      |
| `home/dot_config/yasb/`              | YASB Windows status bar configuration.                   |
| `home/dot_config/yazi/`              | Yazi terminal file manager configuration.                |
| `home/dot_config/starship.toml.tmpl` | Starship prompt template.                                |

Additional Windows-oriented configuration is stored outside `dot_config` where the target application expects it, for example Windows Terminal state under `home/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState`.

## Platform support

| Platform            | Status           | Entrypoint                                   |
| ------------------- | ---------------- | -------------------------------------------- |
| Windows             | Tested           | `scripts/bootstrap/windows/bootstrap.ps1`    |
| Arch/Linux          | Work in progress | `scripts/bootstrap/linux/bootstrap-linux.sh` |
| Other POSIX systems | Work in progress | `install.sh`                                 |

The Windows path is the primary supported path. Do not treat the Linux bootstrap script or the top-level `install.sh` as equivalent to the Windows installer.

## Windows

### Prerequisites

The Windows bootstrap assumes that Scoop is already installed and available on `PATH`. Install Scoop manually before running this repository's bootstrap script.

Open a **non-admin PowerShell** window and run the official Scoop install command:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

If Git is not installed yet, install it with Scoop:

```powershell
scoop install git
```

### Clone the repository

```powershell
git clone https://github.com/prettycation/dotfiles.git
cd dotfiles
```

If Git is unavailable before bootstrap, download the repository ZIP from GitHub, extract it, and open PowerShell in the extracted directory. The bootstrap can install Git later as part of the required Scoop group.

### Run the bootstrap

Open **PowerShell as Administrator**, then run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
./scripts/bootstrap/windows/bootstrap.ps1 -ChezmoiRepo "https://github.com/prettycation/dotfiles"
```

Optional flags:

```powershell
# Skip VS Code extension synchronization
./scripts/bootstrap/windows/bootstrap.ps1 -SkipVSCode

# Skip mise runtime setup
./scripts/bootstrap/windows/bootstrap.ps1 -SkipMise

# Show a custom chezmoi repository hint in the final manual steps
./scripts/bootstrap/windows/bootstrap.ps1 -ChezmoiRepo "https://github.com/prettycation/dotfiles"
```

If the bootstrap installs PowerShell 7 (`pwsh`) and asks you to restart, close the current window, open PowerShell 7 as Administrator, return to the repository directory, and run the bootstrap command again.

### What the Windows bootstrap does

The Windows bootstrap is an orchestrator. It loads shared helpers, prepares a context object, reads manifests, and runs step scripts in order.

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
│   └── 60-vscode.ps1
└── tasks/
    └── install-vscode-extensions.ps1
```

| Step                        | Purpose                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------ |
| `00-preflight.ps1`          | Checks paths, loaded manifests, manifest shape, execution policy, Scoop availability, and tool status. |
| `05-xdg-env.ps1`            | Creates XDG-style user directories and user-level environment variables.                               |
| `10-scoop-core.ps1`         | Adds Scoop buckets declared in the Windows package manifest.                                           |
| `15-bootstrap-required.ps1` | Installs required bootstrap packages first.                                                            |
| `20-scoop-groups.ps1`       | Prompts for default and optional package groups.                                                       |
| `40-mise.ps1`               | Optionally configures mise and installs declared runtimes.                                             |
| `60-vscode.ps1`             | Optionally installs VS Code extensions when `code` is available.                                       |

The bootstrap intentionally does **not**:

- create `~/.config/chezmoi/chezmoi.toml` automatically;
- run `chezmoi init` automatically;
- run `chezmoi apply` automatically;
- sync your PowerShell profile automatically.

Those steps are manual because they may depend on Bitwarden secrets, local choices, and review of pending changes.

### XDG environment on Windows

The bootstrap initializes a Unix-style layout on Windows so that cross-platform tools can share the same configuration paths.

| Variable           | Target                                            |
| ------------------ | ------------------------------------------------- |
| `XDG_CONFIG_HOME`  | `%USERPROFILE%/.config`                           |
| `XDG_DATA_HOME`    | `%USERPROFILE%/.local/share`                      |
| `XDG_STATE_HOME`   | `%USERPROFILE%/.local/state`                      |
| `XDG_CACHE_HOME`   | `%USERPROFILE%/.cache`                            |
| `YAZI_CONFIG_HOME` | `%USERPROFILE%/.config/yazi`                      |
| `INTELLI_CONFIG`   | `%USERPROFILE%/.config/intelli-shell/config.toml` |

These directories line up with the checked-in `home/dot_config`, `home/dot_local/share`, `home/dot_local/state`, and `home/dot_cache` trees.

### Windows package manifests

Windows packages are declared in:

```text
manifests/windows.packages.json
```

The manifest is split into:

- `scoopBuckets`: Scoop bucket names and URLs to add before package installation.
- `scoopGroups`: categorized package groups with selection behavior.

Group selection modes:

| Selection  | Meaning                                                      |
| ---------- | ------------------------------------------------------------ |
| `required` | Installed first; needed by the bootstrap flow.               |
| `default`  | Offered as the default selection during interactive install. |
| `optional` | Not installed unless selected interactively.                 |

Package install modes:

| Mode              | Meaning                                                   |
| ----------------- | --------------------------------------------------------- |
| `auto` or omitted | Installed by Scoop when the package's group is selected.  |
| `manual`          | Not installed automatically; shown as a manual follow-up. |
| `skip`            | Ignored by the bootstrap.                                 |

The required bootstrap group currently covers core bootstrap tools such as archive support, download acceleration, Git, and PowerShell 7. Other groups cover CLI utilities, shell workflow tools, Git/development tools, build/runtime tooling, file/PDF/image tools, terminals, fonts, input methods, browsers, window management, desktop customization, editors, AI tooling, media, networking, security, and system utilities.

### Runtime and VS Code manifests

| Manifest                                   | Purpose                                                                                   |
| ------------------------------------------ | ----------------------------------------------------------------------------------------- |
| `manifests/windows.runtimes.json`          | Runtime/toolchain declarations for mise.                                                  |
| `manifests/windows.vscode-extensions.json` | VS Code extension recommendations installed by the VS Code task when `code` is available. |

These steps can be skipped with `-SkipMise` and `-SkipVSCode`.

### Apply dotfiles with chezmoi

After the Windows bootstrap finishes, authenticate secrets and apply dotfiles manually.

If your chezmoi templates require Bitwarden secrets:

```powershell
bw login
bw unlock
$env:BW_SESSION = "<paste session token here>"
```

Then initialize and apply chezmoi:

```powershell
chezmoi init https://github.com/prettycation/dotfiles
chezmoi diff
chezmoi apply
```

If this repository has already been initialized as your chezmoi source, use:

```powershell
chezmoi source-path
chezmoi diff
chezmoi apply
```

Always review `chezmoi diff` before applying changes on a machine with existing configuration.

## Linux / Arch

Linux support is currently experimental.

Related files:

```text
scripts/bootstrap/linux/bootstrap-linux.sh
manifests/linux.arch.packages.json
manifests/linux.ubuntu.packages.json
```

The Linux manifests are still minimal, and this path has not been tested like the Windows bootstrap. Review the script and manifest before running anything on a real machine.

For inspection/testing only:

```bash
./scripts/bootstrap/linux/bootstrap-linux.sh --dry-run
```

## Other POSIX systems

The top-level `install.sh` is a POSIX helper, but it is not the tested installation path.

It installs `chezmoi` if needed and then runs `chezmoi init --apply` against this repository source directory. Because it applies dotfiles immediately, review it carefully before using it on any machine with existing configuration.

## Troubleshooting

### `Scoop is not available on PATH`

Install Scoop first in a non-admin PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

Close and reopen PowerShell, then rerun the bootstrap from an administrator PowerShell.

### The bootstrap says PowerShell 7 was installed

Close the current window, open PowerShell 7 (`pwsh`) as Administrator, return to the repository, and rerun:

```powershell
./scripts/bootstrap/windows/bootstrap.ps1
```

### VS Code extensions were skipped

The VS Code step only runs when the `code` command exists. Install VS Code through the optional editor group or manually, make sure `code` is available on `PATH`, then rerun the bootstrap without `-SkipVSCode`.

### mise was skipped

The mise step is skipped if `mise` is not installed, if no runtime configuration exists, or if runtime setup was explicitly disabled with `-SkipMise`. Install or select the relevant runtime tooling group, then rerun as needed.
