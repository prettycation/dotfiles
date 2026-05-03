# Repository layout

```text
.
├── home/                         # chezmoi source root
│   ├── .chezmoidata/             # structured data used by templates and manifest exporters
│   ├── .chezmoiscripts/windows/  # Windows chezmoi scripts and onchange hooks
│   │   ├── export/               # generated manifest export hooks
│   │   └── remove/               # Windows cleanup/remove hooks
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
│   ├── .chezmoiremove.tmpl       # empty placeholder for future removal rules
│   ├── dot_duckdbrc              # DuckDB rc file
│   ├── dot_gitconfig.tmpl        # Git config template
│   ├── dot_zshenv                # zsh environment
│   └── empty_dot_hushlogin       # suppress login message where supported
├── manifests/                    # generated package/runtime/extension manifests
│   ├── cargo.packages.json
│   ├── windows.packages.json
│   ├── windows.runtimes.json
│   ├── windows.vscode-extensions.json
│   ├── linux.arch.packages.json
│   └── linux.ubuntu.packages.json
├── makefiles/                    # modular Make targets
│   ├── bootstrap.mk
│   └── chezmoi.mk
├── scripts/bootstrap/
│   ├── windows/                  # tested Windows bootstrap flow
│   └── linux/                    # experimental Linux bootstrap flow
├── assets/                       # assets for managed apps/tools
├── examples/chezmoi/             # example chezmoi config
├── .chezmoiroot                  # points chezmoi at home/
├── .chezmoiversion               # expected chezmoi version
├── .emmyrc.json                  # Lua language-server/editor metadata
├── .gitignore
├── LICENSE
├── Makefile                      # includes makefiles/*.mk
└── install.sh                    # POSIX helper, not the tested Windows entrypoint
```

## chezmoi metadata

| Path | Purpose |
| --- | --- |
| `home/.chezmoidata/` | Shared source data for templates and generated manifests. |
| `home/.chezmoidata/cargo.packages.yaml` | Source data for Cargo package declarations. Exported to `manifests/cargo.packages.json`. |
| `home/.chezmoidata/windows/scoop.packages.yaml` | Source data for Scoop package groups and package metadata. Exported to `manifests/windows.packages.json`. |
| `home/.chezmoitemplates/` | Reusable template fragments for larger chezmoi templates. |
| `home/.chezmoi.toml.tmpl` | Template for chezmoi's own configuration, local profile data, and secret access. |
| `home/.chezmoiexternal.toml.tmpl` | External resources that chezmoi can fetch/manage. |
| `home/.chezmoiignore.tmpl` | Conditional ignore rules, usually platform-specific. |
| `home/.chezmoiremove.tmpl` | Empty placeholder for future cleanup/removal rules. |

## Shell, Git, SSH, and local state

| Path | Target | Purpose |
| --- | --- | --- |
| `home/dot_gitconfig.tmpl` | `~/.gitconfig` | Git configuration rendered from template data. |
| `home/dot_ssh/` | `~/.ssh` | SSH config and related files. |
| `home/dot_zshenv` | `~/.zshenv` | zsh environment entrypoint. |
| `home/dot_cache/zsh/zcompcache/` | `~/.cache/zsh/zcompcache` | zsh completion cache location. |
| `home/dot_local/share/` | `~/.local/share` | User-level shared application data. |
| `home/dot_local/state/zsh/` | `~/.local/state/zsh` | zsh state files, separated from config and cache. |
| `home/dot_duckdbrc` | `~/.duckdbrc` | DuckDB startup configuration. |
| `home/empty_dot_hushlogin` | `~/.hushlogin` | Suppresses login banners where supported. |

## Application configuration

Most application configuration lives under `home/dot_config/`, which maps to
`~/.config/`.

| Path | Purpose |
| --- | --- |
| `home/dot_config/atuin/` | Atuin shell history configuration. |
| `home/dot_config/bat/` | bat themes/configuration. |
| `home/dot_config/btop/` | btop terminal monitor configuration. |
| `home/dot_config/diny/` | diny configuration. |
| `home/dot_config/exact_zsh/` | zsh-related configuration managed as an exact directory. |
| `home/dot_config/eza/` | eza configuration. |
| `home/dot_config/fastfetch/` | fastfetch system summary configuration. |
| `home/dot_config/gtk-4.0/` | GTK 4 configuration. |
| `home/dot_config/private_gtk-3.0/` | private GTK 3 configuration. |
| `home/dot_config/intelli-shell/` | intelli-shell configuration. |
| `home/dot_config/kitty/` | Kitty terminal configuration. |
| `home/dot_config/wezterm/` | WezTerm terminal configuration. |
| `home/dot_config/mihomo/` | mihomo proxy configuration. |
| `home/dot_config/niri/` | niri Wayland compositor configuration. |
| `home/dot_config/nushell/` | Nushell configuration. |
| `home/dot_config/nvim/` | Neovim configuration. |
| `home/dot_config/opencode/` | opencode configuration. |
| `home/dot_config/private_fcitx5/` | private fcitx5 input method configuration. |
| `home/dot_config/tacky-borders/` | tacky-borders configuration. |
| `home/dot_config/television/` | television configuration. |
| `home/dot_config/xremap/` | xremap key remapping configuration. |
| `home/dot_config/yasb/` | YASB Windows status bar configuration. |
| `home/dot_config/yazi/` | Yazi terminal file manager configuration. |
| `home/dot_config/starship.toml.tmpl` | Starship prompt template. |

Additional Windows-oriented configuration is stored outside `dot_config` where
the target application expects it, for example Windows Terminal state under
`home/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState`.

The effective applied set depends on `home/.chezmoiignore.tmpl`, the platform,
the local profile, and generated template data.
