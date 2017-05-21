#!/usr/bin/make -f
# may be called with $PREBUILD set e.g. to "~pre`date +%Y%m%d`"

# get version to build
VERSION0 = $(shell cat 2>/dev/null git/VERSION)
ifeq "$(VERSION0)" ""
# get from local tree
VERSION0 = $(shell cat 2>/dev/null ../../VERSION)
endif
VERSION = $(VERSION0)$(PREBUILD)

# Shortcuts
GTV     = geotoad-$(VERSION)
GUV     = geotoad_$(VERSION)
BUILD   = 1

all:	version tgz deb mac win pkg #upl

tgz:	$(GTV).tar.gz
deb:	$(GUV)-$(BUILD)_all.deb
mac:	$(GTV).dmg
win:	$(GTV)_Installer.exe

pkg:	md5sums.txt Packages.gz

include mk/all.mk
include mk/git.mk
include mk/tgz.mk
include mk/deb.mk
include mk/mac.mk
include mk/win.mk

include mk/upl.mk

.PHONY: tgz deb mac win clean fullclean version

.SILENT:
