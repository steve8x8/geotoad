#!/usr/bin/make -f
# may be called with $PREBUILD set e.g. to "~pre`date +%Y%m%d`"

GITPATH = https://github.com/steve8x8/geotoad.git
WINRUBY = 219
USB_DIR = gt

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

#all:	version tgz deb win mac md5sums.txt Packages.gz
all:	version tgz deb mac md5sums.txt Packages.gz

tgz:	$(GTV).tar.gz

win:	$(GTV)_Installer.exe

mac:	$(GTV).dmg

deb:	$(GUV)-$(BUILD)_all.deb


version:
	@echo ""
	@echo "Building version $(VERSION)"

clean:
	@echo ""
	@echo "========================="
	@echo " CLEANUP "
	@echo "========================="
	@echo ""
	-rm -rf tgz/ win/ deb/ mac/
	-rm -rf $(GTV)/
	@echo $@ done.

fullclean: clean
	@echo ""
	@echo "========================="
	@echo " FULL CLEANUP "
	@echo "========================="
	@echo ""
	-rm  -f geotoad-* geotoad_* md5sums.txt Packages.*
	-rm -rf git/
	@echo $@ done.

git:
	@echo ""
	@echo "========================="
	@echo " CREATE WORKING COPY "
	@echo "========================="
	@echo ""
	-rm -rf git/
	# check out latest trunk head
	git clone --quiet $(GITPATH) git/
	# full ChangeLog
	sh -c "cd git; git log -v > ChangeLog.txt"
	@echo $@ done.

$(GTV).tar.gz: git
	@echo ""
	@echo "========================="
	@echo " BUILD TARBALL"
	@echo "========================="
	@echo ""
	-rm -rf $(GTV)/ tgz/
	rsync -ax git/. $(GTV)/
	# remove local .git copy
	-rm -rf $(GTV)/.git*
	## patch version
	#sed -i s/%VERSION%/$(VERSION)/g $(GTV)/lib/version.rb
	#sed -i s/%VERSION%/$(VERSION)/g $(GTV)/README.txt
	# version file gets ignored !$!$!
	-rm  -f $(GTV)/VERSION
	# fix permissions
	-chmod 755 $(GTV)/*.rb
	-chmod 755 $(GTV)/tools/*.rb
	-chmod 755 $(GTV)/tools/*.sh
	-chmod 755 $(GTV)/debian/rules
	# remove non-distributable stuff
	-rm  -f $(GTV)/tools/convert*.sh
	-rm  -f $(GTV)/tools/build/makedist*.sh
	-rm  -f $(GTV)/data/*.gz
	# create PDF version of manual page
	groff -Tps -mman $(GTV)/geotoad.1 | ps2pdf - $(GTV)/geotoad.pdf
	# pack (with command file)
	tar zcf $@ $(GTV)/
	mv $(GTV) tgz
	@echo $@ done.

$(GUV)-1_all.deb: $(GTV).tar.gz
	@echo ""
	@echo "========================="
	@echo " BUILD DEBIAN PACKAGE "
	@echo "========================="
	@echo ""
	-rm -rf $(GTV)/ deb/
	tar zxf $(GTV).tar.gz
	ln -sf $(GTV).tar.gz $(GUV).orig.tar.gz
	# fix package version
	if ! head -n1 $(GTV)/debian/changelog | grep -q "\($VERSION-1\)" ; then \
	  sed -i "1s/(.*)/($(VERSION)-1)/" $(GTV)/debian/changelog ; \
	fi
	head -n1 $(GTV)/debian/changelog
	sh -c "cd $(GTV); dpkg-buildpackage >/dev/null -rfakeroot -us -uc -tc"
	mv $(GTV) deb
	@echo ""
	@echo $@ done.

$(GTV).dmg: $(GTV).tar.gz
	@echo ""
	@echo "========================="
	@echo " BUILD MACOSX DISK IMAGE "
	@echo "========================="
	@echo ""
	-rm -rf $(GTV)/ mac/
	tar zxf $(GTV).tar.gz
	-rm  -f $(GTV)/geotoad.1
	-rm -rf $(GTV)/debian/
	mkdir mac
	cp -p $(GTV)/tools/build/build_dmg.sh mac/run_mac.sh
	-rm -rf $(GTV)/tools/build/
	mv $(GTV) mac/
	@echo    "*** Insert a USB key with \"$(USB_DIR)\" directory and (wait for) mount"
	@read -p "*** Press ENTER when done: " x
	-mount | grep /media
	-ls -ld /media/`whoami`/*/$(USB_DIR)/
	-rsync -ax mac /media/`whoami`/*/$(USB_DIR)/
	@sync
	@sleep 3
	@sync
	@sleep 3
	-umount `df /media/\`whoami\`/*/$(USB_DIR)/ | tail -n+2 | awk '{print $$NF}'` 2>/dev/null
	-mount | grep /media
	@echo    "*** Remove the (unmounted) USB key."
	@read -p "*** Press ENTER when done: " x
	@echo    "*** On a MacOSX machine, mount USB key and run:"
	@echo    "      bash mac/run_mac.sh"
	@echo    "*** Insert the USB key with \"$(GTV).dmg\" and (wait for) mount"
	@read -p "*** Press ENTER when done: " x
	-mount | grep /media
	-rsync -ax /media/`whoami`/*/$(USB_DIR)/mac ./
	-mv mac/$(GTV).dmg ./
	-umount `df /media/\`whoami\`/*/$(USB_DIR)/ | tail -n+2 | awk '{print $$NF}'` 2>/dev/null
	-mount | grep /media
	@echo    "*** Remove the (unmounted) USB key."
	@read -p "*** Press ENTER when done: " x
	touch $(GTV).dmg
	@echo $@ done.

$(GTV)_Installer.exe: $(GTV).tar.gz
	@echo ""
	@echo "========================="
	@echo " BUILD WINDOWS INSTALLER "
	@echo "========================="
	@echo ""
	-rm -rf $(GTV)/ win/
	tar zxf $(GTV).tar.gz
	-rm  -f $(GTV)/geotoad.1
	-rm -rf $(GTV)/debian/
	# prepare for VM
	mv $(GTV) win
	@echo "Build Windows package for ruby version $(WINRUBY)"
	mkdir win/compile
	mv win/*.rb      win/compile/
	mv win/lib       win/compile/
	mv win/interface win/compile/
	mv win/templates win/compile/ # really?
	mv win/data      win/compile/ # really?
	# prepare some more files
	perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' win/README.txt
	# convert .txt files to MSDOS linebreaks
	flip -mb win/*.txt
	sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/buildinno.iss.in > win/buildinno.iss
	sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/buildinno.bat.in > win/buildinno.bat
	sed s/XXXWINRUBYXXX/$(WINRUBY)/g win/tools/build/buildocra.bat.in > win/buildocra.bat
	-rm -rf win/tools/build/
	# now do the real stuff
	@echo    "*** In Windows \"Z:\\\\...\\\\tools\\\\build\\\\win\", run:"
	@echo    "      buildocra.bat"
	@read -p "*** Press ENTER when done (geotoad.exe exists): " x
	#rm -rf win/buildocra.bat
	# we might need better error handling (back to square one?)
	-mv win/compile/geotoad.exe win/
	mv win/compile/templates   win/ # see above
	mv win/compile/data        win/ # see above
	-rm -rf win/compile
	@echo    "*** In Windows \"Z:\\\\...\\\\tools\\\\build\\\\win\", run:"
	@echo    "      buildinno.bat"
	@read -p "*** Press ENTER when done ($(GTV)_Installer.exe exists): " x
	# does it make sense to have the executable alone?
	#cp -p win/geotoad.exe $(GTV).exe
	touch $(GTV)_Installer.exe
	@echo $@ done.

md5sums.txt: Makefile $(GTV).tar.gz $(GTV)_Installer.exe $(GTV).dmg #$(GTV)-1_all.deb
	md5sum $(GTV)* `echo $(GTV) | sed 's~-~_~'`* | grep -v '^d41d8cd98f00b204e9800998ecf8427e' | grep -v '\.orig\.tar\.gz' > md5sums.txt

Packages.gz: md5sums.txt
	dpkg-scanpackages . | gzip -9v > Packages.gz

.PHONY: tgz win mac deb clean fullclean version

.SILENT:
