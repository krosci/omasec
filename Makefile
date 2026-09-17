.PHONY: setup verify test hook icons theme zed micro editors clean help

SHELL := /bin/bash

help:
	@echo "setup       Run full setup (root)"
	@echo "verify      Run verification checks"
	@echo "test        Run comprehensive test suites"
	@echo "hook        Install theme hooks for current user"
	@echo "icons       Apply folder color for current theme"
	@echo "theme       Apply theme hooks (folder color and micro editor)"
	@echo "zed         Install Zed editor configuration"
	@echo "micro       Install Micro editor configuration"
	@echo "editors     Install Zed and Micro editor configurations"
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

zed:
	bash zedconf/install.sh

micro:
	bash microconf/install.sh

editors: zed micro

clean:
	rm -f setup.log
