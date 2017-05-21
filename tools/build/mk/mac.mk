USB_DIR = gt
USB_MPT = /media/`whoami`

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
	cp -p $(GTV)/tools/build/in/build_dmg.sh mac/run_mac.sh
	-rm -rf $(GTV)/tools/build/
	mv $(GTV) mac/
	@echo    "*** Insert a USB key with \"$(USB_DIR)\" directory and (wait for) mount"
	@read -p "*** Press ENTER when done: " x
	-mount | grep $(USB_MPT)
	-ls -ld $(USB_MPT)/*/$(USB_DIR)/
	-rsync -ax mac $(USB_MPT)/*/$(USB_DIR)/
	@sync
	@sleep 3
	@sync
	@sleep 3
	-umount `df $(USB_MPT)/*/$(USB_DIR)/ | tail -n+2 | awk '{print $$NF}'` 2>/dev/null
	-mount | grep $(USB_MPT)
	@echo    "*** Remove the (unmounted) USB key."
	@read -p "*** Press ENTER when done: " x
	@echo    "*** On a MacOSX machine, mount USB key and run:"
	@echo    "      bash mac/run_mac.sh"
	@echo    "*** Insert the USB key with \"$(GTV).dmg\" and (wait for) mount"
	@read -p "*** Press ENTER when done: " x
	-mount | grep $(USB_MPT)
	-rsync -ax $(USB_MPT)/*/$(USB_DIR)/mac ./
	-mv mac/$(GTV).dmg ./
	-umount `df $(USR_MPT)/*/$(USB_DIR)/ | tail -n+2 | awk '{print $$NF}'` 2>/dev/null
	-mount | grep $(USB_MPT)
	@echo    "*** Remove the (unmounted) USB key."
	@read -p "*** Press ENTER when done: " x
	touch $(GTV).dmg
	@echo $@ done.

