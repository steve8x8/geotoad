#BUILD = 1

$(GUV)-$(BUILD)_all.deb: $(GTV).tar.gz
	@echo ""
	@echo "========================="
	@echo " BUILD DEBIAN PACKAGE "
	@echo "========================="
	@echo ""
	-rm -rf $(GTV)/ deb/
	tar zxf $(GTV).tar.gz
	ln -sf $(GTV).tar.gz $(GUV).orig.tar.gz
	# fix package version
	if ! head -n1 $(GTV)/debian/changelog | grep -q "\($(VERSION)-$(BUILD)\)" ; then \
	  sed -i "1s/(.*)/($(VERSION)-$(BUILD))/" $(GTV)/debian/changelog ; \
	fi
	head -n1 $(GTV)/debian/changelog
	sh -c "cd $(GTV); dpkg-buildpackage >/dev/null -rfakeroot -us -uc -tc"
	mv $(GTV) deb
	@echo ""
	@echo $@ done.

