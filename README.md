# dotfiles

Personal workstation dotfiles managed with [chezmoi](https://www.chezmoi.io/).

> [!CAUTION]
> This repository manages real workstation state. Review diffs, generated manifests,
> external resources, and platform-specific scripts before applying on an existing
> machine.

## Status

Windows is the primary tested installation path. Linux and other POSIX-related
files are present, but they are experimental until explicitly validated.

## What this repository does

This repository separates workstation setup into three stages:

1. Bootstrap the machine by installing package-manager prerequisites, selected
   packages, runtimes, Cargo tools, PowerShell completions, VS Code extensions,
   and user-level environment variables.
2. Apply dotfiles with chezmoi after local choices, profile data, and secrets are
   ready.
3. Use Make targets as repeatable wrappers when the host environment provides the
   required tools and privilege model.

The bootstrap phase and the chezmoi apply phase are intentionally separate. The
Windows bootstrap prepares the machine, but it does not automatically run
`chezmoi init` or `chezmoi apply`.

## Platform support

| Platform    | Status           | Entrypoint                                | Documentation                                 |
| ----------- | ---------------- | ----------------------------------------- | --------------------------------------------- |
| Windows     | Primary / tested | `scripts/bootstrap/windows/bootstrap.ps1` | [Windows bootstrap](doc/windows-bootstrap.md) |
| Linux       | Experimental     | `scripts/bootstrap/linux/bootstrap.sh`    | [Linux and POSIX status](doc/linux-posix.md)  |
| Other POSIX | Experimental     | `install.sh`                              | [Linux and POSIX status](doc/linux-posix.md)  |

## Windows quick start

Install Scoop from a non-admin PowerShell session first:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
scoop install git
```

Clone the repository:

```powershell
git clone https://github.com/prettycation/dotfiles.git
cd dotfiles
```

Run the Windows bootstrap from an elevated PowerShell session:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
./scripts/bootstrap/windows/bootstrap.ps1 -ChezmoiRepo "https://github.com/prettycation/dotfiles"
```

If the bootstrap installs PowerShell 7 (`pwsh`) and asks you to restart, close the
current window, open PowerShell 7 as Administrator, return to this repository,
and run the bootstrap command again.

After bootstrap, initialize and apply chezmoi manually:

```powershell
chezmoi init https://github.com/prettycation/dotfiles
chezmoi diff
chezmoi apply
```

If templates need Bitwarden-backed secrets, unlock Bitwarden first:

```powershell
bw login
$env:BW_SESSION = bw unlock --raw
chezmoi diff
chezmoi apply
```

## Documentation

- [Windows bootstrap](doc/windows-bootstrap.md)
- [Applying with chezmoi](doc/chezmoi.md)
- [Repository layout](doc/repository-layout.md)
- [Manifests and generated data](doc/manifests.md)
- [Linux and POSIX status](doc/linux-posix.md)
- [Troubleshooting](doc/troubleshooting.md)

## Common Make targets

The root `Makefile` includes `makefiles/*.mk`. Make targets are convenience
wrappers and should be reviewed before use on a machine with existing
configuration.

| Target                   | Purpose                                                                                 |
| ------------------------ | --------------------------------------------------------------------------------------- |
| `make bootstrap-windows` | Run the Windows bootstrap through PowerShell using the configured superuser wrapper.    |
| `make bootstrap-linux`   | Run the experimental Linux bootstrap script.                                            |
| `make diff`              | Run `chezmoi diff`.                                                                     |
| `make status`            | Run `chezmoi status`.                                                                   |
| `make doctor`            | Run `chezmoi doctor`.                                                                   |
| `make apply`             | Run `chezmoi apply`.                                                                    |
| `make apply-bw`          | Unlock Bitwarden with `bw unlock --raw`, export `BW_SESSION`, then run `chezmoi apply`. |

## License

See [LICENSE](LICENSE).
