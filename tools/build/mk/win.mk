USB_DIR = gt
USB_MPT = /media/$(shell whoami)

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
	# prepare for remote machine
	mv $(GTV) win
	@echo "Build Windows package"

	mkdir win/ocra
	rsync -ax win/*.rb      win/ocra/
	rsync -ax win/lib       win/ocra/
	rsync -ax win/interface win/ocra/
	rsync -ax win/templates win/ocra/ # really?
	rsync -ax win/data      win/ocra/ # really?
	 cat win/tools/build/in/buildocra.bat.in > win/buildocra.bat

	mkdir win/inno
	rsync -ax win/*.pdf     win/inno/
	rsync -ax win/*.txt     win/inno/
	rsync -ax win/templates win/inno/
	rsync -ax win/contrib   win/inno/
	rsync -ax win/data      win/inno/
	rsync -ax win/tools     win/inno/
	rm -rf win/inno/tools/build

	sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/in/buildinno.iss.in > win/inno/buildinno.iss
	 sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/in/buildinno.bat.in > win/buildinno.bat
	perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' win/inno/README.txt
	# convert .txt files to MSDOS linebreaks
	flip -mb win/inno/*.txt

	# now do the real stuff
	sed s/XXXVERSIONXXX/$(VERSION)/g win/tools/build/in/build_win.bat > win/run_win.bat

	@echo    "*** Insert a USB key with \"$(USB_DIR)\" directory and (wait for) mount"
	@read -p "*** Press ENTER when done: " x
	-mount | grep $(USB_MPT)
	-ls -ld $(USB_MPT)/*/$(USB_DIR)/
	-rsync -ax win $(USB_MPT)/*/$(USB_DIR)/
	@sync
	@sleep 3
	@sync
	@sleep 3
	-umount `df $(USB_MPT)/*/$(USB_DIR)/ | tail -n+2 | awk '{print $$NF}'` 2>/dev/null
	-mount | grep $(USB_MPT)
	@echo    "*** Remove the (unmounted) USB key."
	@read -p "*** Press ENTER when done: " x
	@echo    "*** On a Windows machine, mount USB key and run:"
	@echo    "      win/run_win.bat"
	@echo    "*** Insert the USB key with \"$(GTV)_Installer.exe\" and (wait for) mount"
	@read -p "*** Press ENTER when done: " x
	-mount | grep $(USB_MPT)
	-rsync -ax $(USB_MPT)/*/$(USB_DIR)/win ./
	-cp -p win/$(GTV)_Installer.exe ./
	-umount `df $(USB_MPT)/*/$(USB_DIR)/ | tail -n+2 | awk '{print $$NF}'` 2>/dev/null
	-mount | grep $(USB_MPT)
	@echo    "*** Remove the (unmounted) USB key."
	@read -p "*** Press ENTER when done: " x
	touch $(GTV)_Installer.exe
	@echo $@ done.
