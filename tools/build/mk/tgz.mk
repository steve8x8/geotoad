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
	# create PDF version of manual page, A4 paper size
	groff -Tps -P-pa4 -mman $(GTV)/geotoad.1 | ps2pdf - $(GTV)/geotoad.pdf
	# pack (with command file)
	tar zcf $@ $(GTV)/
	mv $(GTV) tgz
	@echo $@ done.

