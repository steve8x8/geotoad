WINRUBY = 219

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
	sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/in/buildinno.iss.in > win/buildinno.iss
	sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/in/buildinno.bat.in > win/buildinno.bat
	sed s/XXXWINRUBYXXX/$(WINRUBY)/g win/tools/build/in/buildocra.bat.in > win/buildocra.bat
	-rm -rf win/tools/build/
	# now do the real stuff
	@echo    "*** In Windows \"...\\\\tools\\\\build\\\\win\", run:"
	@echo    "      buildocra.bat"
	@read -p "*** Press ENTER when done (geotoad.exe exists): " x
	#rm -rf win/buildocra.bat
	# we might need better error handling (back to square one?)
	-mv win/compile/geotoad.exe win/
	mv win/compile/templates   win/ # see above
	mv win/compile/data        win/ # see above
	-rm -rf win/compile
	@echo    "*** In Windows \"...\\\\tools\\\\build\\\\win\", run:"
	@echo    "      buildinno.bat"
	@read -p "*** Press ENTER when done ($(GTV)_Installer.exe exists): " x
	# does it make sense to have the executable alone?
	#cp -p win/geotoad.exe $(GTV).exe
	touch $(GTV)_Installer.exe
	@echo $@ done.

