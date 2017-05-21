GITPATH = https://github.com/steve8x8/geotoad.git

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

