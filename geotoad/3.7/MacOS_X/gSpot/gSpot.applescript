property filterUser : "nobody"
property distanceMax : "100"
property terrainMax : "5"
property terrainMin : "0"
property difficultyMin : "0"
property difficultyMax : "5"
property searchArg : "none"
property saveFile : "/tmp/savefile"
property execCommand : "geotoad.rb"
property formatType : "iPod (VCF)"

on clicked theObject
	log filterUser
	-- set filterUser to contents of text field "filter user"
	-- log "set filterUser to " & filterUser
	set contents of text field "status" of window "main" to "Collecting Data..."
	
	if name of theObject is "saveas" then
		log "saveas"
		set contents of text field "status" of window "main" to "Displaying Save Panel"
		display save panel attached to window of theObject
	end if
	
	if name of theObject is "go" then
		log "go is here, collecting data"
		set contents of text field "status" of window "main" to "Processing Input"
		tell window "main"
			set distanceMax to contents of text field "distance maximum" of box "searchbox"
			set searchArg to contents of text field "search argument" of box "searchbox"
			set filterUser to contents of text field "filter user" of box "filterbox"
			set formatType to title of current menu item of popup button "format type"
			log distanceMax
		end tell
		
		log formatType
		set execCommand to execCommand & " -y " & distanceMax & " -o " & saveFile & " -u " & filterUser
		log execCommand
		set contents of text field "status" of window "main" to execCommand
	end if
end clicked


on panel ended theObject with result withResult
	if withResult is 1 then
		set saveFile to path name of save panel
		set contents of text field "path name" of window "main" to saveFile
		set contents of text field "status" of window "main" to "Save file is now " & saveFile
	else
		set contents of text field "path name" of window "main" to "(none)"
	end if
end panel ended


on should quit after last window closed theObject
	return true
end should quit after last window closed

on choose menu item theObject
	set form to name of theObject
	set chosen to title of current menu item of popup button of theObject
	log "someone selected: " & form & " with " & chosen
	set title of popup button of "difficulty maximum" to "4.5"
end choose menu item

on will pop up theObject
	log "will pop up"
	(*Add your script here.*)
end will pop up

