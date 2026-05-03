# Troubleshooting

## `Scoop is not available on PATH`

Install Scoop first in a non-admin PowerShell session:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

Close and reopen PowerShell, then rerun the bootstrap from an elevated
PowerShell session.

## The bootstrap says PowerShell 7 was installed

Close the current window, open PowerShell 7 (`pwsh`) as Administrator, return to
the repository, and rerun:

```powershell
./scripts/bootstrap/windows/bootstrap.ps1
```

## Bitwarden secrets are empty

Make sure Bitwarden is unlocked and `BW_SESSION` is exported in the same shell
that runs chezmoi:

```powershell
$env:BW_SESSION = bw unlock --raw
chezmoi diff
```

Personal secrets are loaded only when the machine is classified as personal by
`home/.chezmoi.toml.tmpl` and `BW_SESSION` is available.

## Cargo packages were skipped

The Cargo step is skipped if `-SkipCargo` is passed, if the Cargo package
manifest is missing, or if no applicable Cargo packages are selected. Ensure
Rust/Cargo tooling is available through the selected runtime/package groups, then
rerun without `-SkipCargo`.

## PowerShell completions were skipped

The PowerShell completions step is skipped if `-SkipPSCompletions` is passed or
if no `powershellCompletions` entries are declared in the Windows package
manifest. Refresh the generated manifests from the chezmoi source data, then
rerun without `-SkipPSCompletions`.

## VS Code extensions were skipped

The VS Code step only runs when the `code` command exists. Install VS Code
through the optional editor group or manually, make sure `code` is available on
`PATH`, then rerun the bootstrap without `-SkipVSCode`.

## mise was skipped

The mise step is skipped if `mise` is not installed, if no runtime configuration
exists, or if runtime setup was explicitly disabled with `-SkipMise`. Install or
select the relevant runtime tooling group, then rerun as needed.

## Unknown machine profile

If a host is not recognized by `home/.chezmoi.toml.tmpl`, interactive chezmoi
runs may prompt for `headless` and `ephemeral`. Non-interactive unknown hosts may
default to headless and ephemeral. Review the generated chezmoi config before
applying.

## `chezmoi diff` shows too many changes

Stop and inspect these files first:

```text
home/.chezmoi.toml.tmpl
home/.chezmoiignore.tmpl
home/.chezmoiexternal.toml.tmpl
home/.chezmoiremove.tmpl
```

Then rerun:

```powershell
chezmoi diff
```
