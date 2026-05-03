# Manifests and generated data

Generated manifests are runtime inputs for bootstrap scripts. Treat the YAML and
template data under `home/.chezmoidata/` as the preferred source of truth when
editing package metadata.

## Windows package manifest

Windows packages are declared in:

```text
manifests/windows.packages.json
```

This manifest is generated from:

```text
home/.chezmoidata/windows/scoop.packages.yaml
```

It contains Scoop bucket declarations, package groups, package metadata, and
PowerShell completion specifications.

### Scoop package group selection

| Selection | Meaning |
| --- | --- |
| `required` | Installed first; needed by the bootstrap flow. |
| `default` | Offered as the default selection during interactive install. |
| `optional` | Not installed unless selected interactively. |

### Package install modes

| Mode | Meaning |
| --- | --- |
| `auto` or omitted | Installed by Scoop when the package's group is selected. |
| `manual` | Not installed automatically; shown as a manual follow-up. |
| `skip` | Ignored by the bootstrap. |

The required bootstrap group covers core bootstrap tools such as archive support,
download acceleration, Git, and PowerShell 7. Other groups cover CLI utilities,
shell workflow tools, Git/development tools, build/runtime tooling, file/PDF/image
tools, terminals, fonts, input methods, browsers, window management, desktop
customization, editors, AI tooling, media, networking, security, and system
utilities.

## Runtime, Cargo, and VS Code manifests

| Manifest | Purpose |
| --- | --- |
| `manifests/windows.runtimes.json` | Runtime/toolchain declarations for mise. |
| `manifests/cargo.packages.json` | Cargo package declarations consumed by the Windows bootstrap Cargo step. |
| `manifests/windows.vscode-extensions.json` | VS Code extension recommendations installed by the VS Code task when `code` is available. |

These steps can be skipped with `-SkipMise`, `-SkipCargo`,
`-SkipPSCompletions`, and `-SkipVSCode`.

## Generated manifest hooks

Generated manifests are refreshed by chezmoi onchange export hooks under:

```text
home/.chezmoiscripts/windows/export/
├── run_onchange_after_convert-cargo-export.ps1.tmpl
├── run_onchange_after_convert-pscompletions-export.ps1.tmpl
└── run_onchange_after_convert-scoop-export.ps1.tmpl
```

The JSON files under `manifests/` are consumed by bootstrap scripts. Do not edit
those JSON files as the long-term source of truth unless the generation flow is
also updated.
