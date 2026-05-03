# Applying with chezmoi

This repository uses `home/` as the chezmoi source root. File and directory names
inside `home/` follow chezmoi conventions, for example `dot_config` maps to
`~/.config` and `dot_gitconfig.tmpl` renders to `~/.gitconfig`.

The repository records the expected chezmoi version in `.chezmoiversion`.
Upgrade chezmoi before applying if your local version is older or incompatible.

## First apply

Initialize the source:

```powershell
chezmoi init https://github.com/prettycation/dotfiles
```

Inspect changes before writing to the target home directory:

```powershell
chezmoi diff
chezmoi apply
```

If the repository is already initialized as your source:

```powershell
chezmoi source-path
chezmoi diff
chezmoi apply
```

Always review `chezmoi diff` before applying changes on a machine with existing
configuration.

## Bitwarden and secrets

Some templates can read values from Bitwarden. Unlock Bitwarden and export
`BW_SESSION` before running `chezmoi diff` or `chezmoi apply`:

```powershell
bw login
$env:BW_SESSION = bw unlock --raw
chezmoi diff
chezmoi apply
```

If GitHub API access is needed by chezmoi externals or templates, set
`CHEZMOI_GITHUB_ACCESS_TOKEN` before rendering templates:

```powershell
$env:CHEZMOI_GITHUB_ACCESS_TOKEN = "<token>"
```

If `CHEZMOI_GITHUB_ACCESS_TOKEN` is not set and `BW_SESSION` is available, the
chezmoi config template may attempt to read the GitHub token from Bitwarden.

## Host and profile detection

Review `home/.chezmoi.toml.tmpl` before first apply. It controls local profile
data such as:

- `personal`
- `work`
- `headless`
- `ephemeral`
- `osid`
- email and account fields
- selected secret values
- GitHub token exposure
- Bitwarden command behavior

Known personal hostnames are classified as personal. The placeholder work host
is classified as work. Unknown interactive hosts ask whether they are headless or
ephemeral. Unknown non-interactive hosts default to headless and ephemeral.

Personal Bitwarden-backed secrets are loaded only when the machine is classified
as personal and `BW_SESSION` is available. This protects non-personal and
non-interactive environments from silently receiving personal secrets.

## Conditional files

`home/.chezmoiignore.tmpl` controls which files apply on each platform and
profile. Many checked-in files are intentionally ignored depending on:

- `.chezmoi.os`
- Linux, Darwin, or Windows platform checks
- whether the profile is personal
- package metadata that declares `ignore_path`
- generated template data

The file list shown in repository documentation is therefore the source tree, not
necessarily the exact target tree that will be applied on a given host.

## External resources

`home/.chezmoiexternal.toml.tmpl` declares external resources that chezmoi can
fetch or update. Review it before applying on a new machine. External downloads
may require network access to GitHub and may benefit from an authenticated GitHub
token.

## Removal rules

`home/.chezmoiremove.tmpl` is currently an empty placeholder for future
conditional cleanup/removal rules. If removal rules are added later, review them
carefully before applying on a machine with existing configuration.
