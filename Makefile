SHELL           := /bin/bash

PREFIX          :=
OUT_DIR         := Output
TRANS_DIR       := translations

IMPORT_DIR      := ../Live-initrd
EXPORT_DIR      := ../Xlated-initrd

#INITRD_IDIR	 := ../LiveUSB/14-alpha-2/initrd
DOMAINS_FILE    := ANTIX_NAMES

-include Makefile.local

XLAT_DIR        := $(OUT_DIR)/usr/share/antiX/init-xlat
INITRD_DIR      := Initrd
INITRD_XLAT_DIR := $(INITRD_DIR)/live/locale/xlat

STR_MAKER_DIR   := string-maker
MO_DIR          := $(OUT_DIR)/usr/share/locale

SCRIPT_DIR      := Scripts
STD_OPTS        := --outdir=$(OUT_DIR)
CMD_MAKE_XLAT   := $(SCRIPT_DIR)/make-xlat-files $(STD_OPTS)
CMD_MAKE_MO     := $(SCRIPT_DIR)/make-xlat-files --mo-only $(STD_OPTS)
CMD_MAKE_MO     += --domains $(DOMAINS_FILE)

CMD_VALIDATE    := $(SCRIPT_DIR)/validate-xlat
CMD_REPLACE     := $(SCRIPT_DIR)/replace-strings
XGETTEXT        := xgettext --add-comments --language=Shell --no-location

CP_OPTS    		:= --no-dereference --preserve=mode,ownership,links
FIND_OPTS  		:= -not -type d

SRC_FILES       := $(shell find $(OUT_DIR) $(FIND_OPTS))
TARG_FILES 		:= $(patsubst $(FROM_DIR)%,$(PREFIX)%, $(SRC_FILES))
TARG_DIRS  		:= $(sort $(dir $(TARG_FILES)))
LIVE_INIT_SRC   := Src/initrd/init.src
INITRD_SRC      := $(shell find Src/initrd -name "*.src")

.PHONY:  help help-more all force-all xlat force-xlat mo force-mo validate
.PHONY:  initrd install-initrd install uninstall clean bump import export

help:
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
	@echo "NOTE: INITRD_IDIR variable controls where install-initrd installs"
	@echo "NOTE: Put custom variables in Makefile.local"

all: mo xlat

force-all: force-xlat force-mo

import:
	Scripts/import-files $(IMPORT_DIR) Src/initrd IMPORT_FILES

export:
	rm -rf $(EXPORT_DIR)
	mkdir -p $(EXPORT_DIR)
	cp -a $(IMPORT_DIR)/[a-z]* $(EXPORT_DIR)/
	cp -a Initrd/* $(EXPORT_DIR)/

xlat:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose

force-xlat:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose --force

mo:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_MO) --verbose

force-mo:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_MO) --verbose

initrd:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose $(INITRD_SRC)

force-initrd:
	@[ -d "$(TRANS_DIR)" ] || echo "Can't find directory: $(TRANS_DIR)"
	@[ -d "$(TRANS_DIR)" ] 
	$(CMD_MAKE_XLAT) --verbose --force $(INITRD_SRC)

bump:
	sed -i -r "s/^(\s*VERSION_DATE=).*/\1\"$$(date)\"/" $(LIVE_INIT_SRC)

	minor=$$(sed -rn "s/^\s*VERSION=\".*\.([0-9]+)\"/\1/p" $(LIVE_INIT_SRC) | sed 's/.*\.//'); \
		  next=$$(printf "%0$${#minor}d" $$((minor + 1))); \
		  sed -r -n "s/^(\s*VERSION=\".*\.)([0-9]+)\"/\1$$next\"/p" $(LIVE_INIT_SRC); \
		  sed -r -i "s/^(\s*VERSION=\".*\.)([0-9]+)\"/\1$$next\"/" $(LIVE_INIT_SRC)



validate:
	$(CMD_VALIDATE) $(XLAT_DIR) $(INITRD_XLAT_DIR)

#initrd: Src/initrd/init.src
#	$(CMD_REPLACE) --init --mode=replace -o $(INITRD_DIR)/init $<
#	$(CMD_REPLACE) --init --mode=plain   -o $(INITRD_XLAT_DIR)/en/init.xlat $<

install-initrd:
	$(CMD_MAKE_XLAT) --verbose --force --stop-at=en $(INITRD_SRC)
	@#$(CMD_MAKE_XLAT) --verbose --force init
	chmod a+x $(INITRD_DIR)/init $(INITRD_DIR)/live/bin/*
	/live/bin/sh -n $(INITRD_DIR)/init
	[ -d "$(INITRD_IDIR)" ] && cp -a $(INITRD_DIR)/* $(INITRD_IDIR)

install: $(TARG_FILES)
	@:

$(TARG_FILES): $(PREFIX)% : $(FROM_DIR)% | $(TARG_DIRS)
	@echo "Install $@"
	@cp $(CP_OPTS) $< $@

uninstall:
	rm -f $(TARG_FILES)
	rmdir -p --ignore-fail-on-non-empty $(TARG_DIRS)

$(TARG_DIRS):
	mkdir -p $@

clean:
	rm -rf $(OUT_DIR)/* $(INITRD_DIR) $(STR_MAKER_DIR) mo-files pot-files
