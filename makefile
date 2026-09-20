SHELL=/bin/sh
-include -e .env
export

.DEFAULT_GOAL := install
.PHONY: install

install:
	@rm -rf $(WOW_ADDONS_FOLDER)/AutoDeposit
	@git submodule update
	@bash .packager/release.sh
	@mv ".release/AutoDeposit" $(WOW_ADDONS_FOLDER)

