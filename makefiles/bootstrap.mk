SUDO ?= sudo

.PHONY: bootstrap bootstrap-windows bootstrap-linux

bootstrap-windows:
	$(SUDO) pwsh -NoProfile -ExecutionPolicy Bypass -File "$(DOTFILES_DIR)/scripts/bootstrap/windows/bootstrap.ps1"

bootstrap-linux:
	$(SUDO) sh "$(DOTFILES_DIR)/scripts/bootstrap/linux/bootstrap.sh"
