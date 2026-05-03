.PHONY: apply apply-bw diff status doctor

apply:
	chezmoi apply

apply-bw:
	$(eval export BW_SESSION := $(shell bw unlock --raw))
	chezmoi apply

diff:
	chezmoi diff

status:
	chezmoi status

doctor:
	chezmoi doctor
