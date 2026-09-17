.PHONY: setup verify test hook icons theme clean help

SHELL := /bin/bash

help:
	@echo "setup       Run full setup (root)"
	@echo "verify      Run verification checks"
	@echo "test        Run comprehensive test suites"
	@echo "hook        Install theme hooks for current user"
	@echo "icons       Apply folder color for current theme"
	@echo "theme       Apply theme hooks (folder color and micro editor)"
	@echo "clean       Remove setup log"

setup:
	sudo bash scripts/setup.sh

verify:
	bash scripts/verify.sh

test:
	bash tests/run-all.sh

hook:
	@mkdir -p ~/.config/omarchy/hooks/theme-set.d
	cp hooks/theme-set.d/* ~/.config/omarchy/hooks/theme-set.d/
	chmod +x ~/.config/omarchy/hooks/theme-set.d/*

icons:
	@bash hooks/theme-set.d/folder-color

theme:
	@bash hooks/theme-set.d/folder-color
	@bash hooks/theme-set.d/micro-theme

clean:
	rm -f setup.log
