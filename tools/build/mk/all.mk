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

md5sums.txt: Makefile $(GTV).tar.gz $(GTV)_Installer.exe $(GTV).dmg #$(GTV)-$(DEB_BUILD)_all.deb
	md5sum $(GTV)* `echo $(GTV) | sed 's~-~_~'`* | grep -v '^d41d8cd98f00b204e9800998ecf8427e' | grep -v '\.orig\.tar\.gz' > md5sums.txt

Packages.gz: md5sums.txt
	dpkg-scanpackages . | gzip -9v > Packages.gz
