SHELL           := /bin/bash

FORCE           :=

DISTRO          := antiX
PREFIX          :=
TRANS_DIR       := tx

IMPORT_DIR      := ../Live-initrd
EXPORT_DIR      := ../Xlated-initrd

#INITRD_IDIR	 := ../LiveUSB/14-alpha-2/initrd
DOMAINS_FILE    := ANTIX_NAMES

-include Makefile.local

INITRD_DIR      := Initrd
INITRD_XLAT_DIR := $(INITRD_DIR)/live/locale/xlat

STR_MAKER_DIR   := string-maker

SCRIPTS_DIR     := Scripts
STD_OPTS        := 
CMD_MAKE_XLAT   := $(SCRIPTS_DIR)/make-xlat-files $(STD_OPTS)
CMD_MAKE_MO     := $(SCRIPTS_DIR)/make-xlat-files --mo-only
CMD_MAKE_MO     += --domains $(DOMAINS_FILE)

CMD_TEXT_MENUS  := $(SCRIPTS_DIR)/make-text-menus
CMD_VALIDATE    := $(SCRIPTS_DIR)/validate-po
CMD_REPLACE     := $(SCRIPTS_DIR)/replace-strings
XGETTEXT        := xgettext --add-comments --language=Shell --no-location

CP_OPTS    		:= --no-dereference --preserve=mode,ownership,links
FIND_OPTS  		:= -not -type d

LIVE_INIT_SRC   := Src/initrd/init.src
#INITRD_SRC      := $(shell find Src/initrd -name "*.src")

RESOURCES       := $(shell grep -v "^\s*\#" ./RESOURCES | sed "s/\s*\#.*//")

.PHONY:  help help-more all force-all xlat force-xlat mo force-mo validate
.PHONY:  initrd install-initrd install uninstall clean bump import export
.PHONY:  push-pot pull-po text-menus

help:
	@echo "FIXME: This is old and outdated"
	@echo ""
	@echo "Common targets for \"make\" command:"
	@echo ""
	@echo "           all: Create everything (= xlat + mo)."
	@echo ""
	@echo "          xlat: Make .xlat files and the scripts that use them."
	@echo ""
	@echo "            mo: Make mo files for programs listed in TEXT_DOMAINS."
	@echo ""
	@echo "      validate: Validate all .xlat files."
	@echo ""
	@echo "         clean: Delete all outputs and intermediate files."
	@echo ""
	@echo "          help: show this simple usage."
	@echo ""
	@echo ""
	@echo "Less common \"make\" targets:"
	@echo ""
	@echo "     force-all: Force creation of all files.  No dependency checking."
	@echo ""
	@echo "    force-xlat: Force create of all .xlat files and programs."
	@echo ""
	@echo "      force-mo: Force creation  of all .mo files."
	@echo ""
	@echo "        initrd: Create /init script and init.xlat files"
	@echo ""
	@echo "  force-initrd: Force creation of /init script and init.xlat files"
	@echo ""
	@echo "install-initrd: Install /init and init.xlat.  Used for testing."
	@echo ""
	@echo "       install: Copy all files under Output/ to / (untested)."
	@echo ""
	@echo "     uninstall: Delete installed files and directories."
	@echo ""
	@echo "NOTE: Use PREFIX variable to install someplace other than ./"
	@echo "NOTE: EXPORT_DIR variable controls where install-initrd installs"
	@echo "NOTE: Put custom variables in Makefile.local"
	@echo
	@echo "$(RESOURCES)"

all: mo xlat

force-all: force-xlat force-mo

import:
	$(SCRIPTS_DIR)/import-files $(IMPORT_DIR) Src/initrd IMPORT_FILES

export:
	mkdir -p $(EXPORT_DIR)
	rm -rf $(EXPORT_DIR)/[a-z]*
	cp -a $(IMPORT_DIR)/[a-z]* $(EXPORT_DIR)/
	cp -a Initrd/* $(EXPORT_DIR)/
	rm -rf $(EXPORT_DIR)/live/locale/xlat/ja*
	rm -rf $(EXPORT_DIR)/live/menus/*.ja*

xlat:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose

force-xlat:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose --force

pull-po:
	$(SCRIPTS_DIR)/pull-po | egrep -v "^(Skipping|Done|Pulling)"

push-pot:
	$(SCRIPTS_DIR)/push-pot

mo:
	@cd ../cli-shell-utils    && ./make-mo
	@cd ../Persist-Scripts    && ./make-mo
	@cd ../console-grid-gui   && ./make-mo
	@cd ../cli-aptiX          && ./make-mo

all-initrd:
	make import
	make initrd
	make export

old-mo:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_MO) --verbose

force-mo:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_MO) --verbose

install-mo: 
	for f in $$(cat $(DOMAINS_FILE)); do find Output -name $$f.mo; done

initrd:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) $(FORCE) --verbose $(shell find Src/initrd -name "*.src")
	$(CMD_TEXT_MENUS) --verbose --dir=Initrd/live/menus master

force-initrd:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose --force $(shell find Src/initrd -name "*.src")

text-menus:
	$(CMD_TEXT_MENUS) --verbose --dir=Initrd/live/custom/$(DISTRO)/menus master

bump:
	sed -i -r "s/^(\s*VERSION_DATE=).*/\1\"$$(date)\"/" $(LIVE_INIT_SRC)

	minor=$$(sed -rn "s/^\s*VERSION=\".*\.([0-9]+)\"/\1/p" $(LIVE_INIT_SRC) | sed 's/.*\.//'); \
		  next=$$(printf "%0$${#minor}d" $$((minor + 1))); \
		  sed -r -n "s/^(\s*VERSION=\".*\.)([0-9]+)\"/\1$$next\"/p" $(LIVE_INIT_SRC); \
		  sed -r -i "s/^(\s*VERSION=\".*\.)([0-9]+)\"/\1$$next\"/" $(LIVE_INIT_SRC)

validate:
	$(CMD_VALIDATE)

#initrd: Src/initrd/init.src
#	$(CMD_REPLACE) --init --mode=replace -o $(INITRD_DIR)/init $<
#	$(CMD_REPLACE) --init --mode=plain   -o $(INITRD_XLAT_DIR)/en/init.xlat $<

install-initrd:
	$(CMD_MAKE_XLAT) --verbose --force --stop-at=en $(shell find Src/initrd -name "*.src")
	@#$(CMD_MAKE_XLAT) --verbose --force init
	chmod a+x $(INITRD_DIR)/init $(INITRD_DIR)/bin/*
	/live/bin/sh -n $(INITRD_DIR)/init
	[ -d "$(EXPORT_DIR)" ] && cp -a $(INITRD_DIR)/* $(EXPORT_DIR)

clean:
	rm -rf $(INITRD_DIR) $(STR_MAKER_DIR) mo-files pot-files

depclean: clean
	rm -rf Src/initrd/* make-xlat-files-err.log
