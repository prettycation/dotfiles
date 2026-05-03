# Linux and POSIX status

Linux and other POSIX paths are currently experimental. They are useful for
inspection and future validation, but they are not equivalent to the tested
Windows bootstrap flow.

## Linux files

```text
scripts/bootstrap/linux/bootstrap.sh
manifests/linux.arch.packages.json
manifests/linux.ubuntu.packages.json
```

The Linux manifests are intentionally minimal compared with the Windows package
manifest. Review the script and manifests before running them on a real machine.

For inspection only:

```bash
./scripts/bootstrap/linux/bootstrap.sh --dry-run
```

## Other POSIX helper

The top-level `install.sh` is a POSIX helper, not the tested installation path.
It installs chezmoi if needed and then runs `chezmoi init --apply` against this
repository source directory. Because it applies dotfiles immediately, review it
carefully before using it on any machine with existing configuration.
