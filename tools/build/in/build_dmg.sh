#!/bin/bash

# script to be run on a MacOSX machine, with XCode installed

cd $(dirname $0)
DISTNAME=$(ls -d geotoad-* | tail -n1) # highest available version
export PATH=/Developer/Tools:/Applications/Xcode.app/Contents/Developer/usr/bin:${PATH}
cd ${DISTNAME}/
sips -i data/bufos-icon.icns && DeRez -only icns data/bufos-icon.icns > data/icns.rsrc
Rez -append data/icns.rsrc -o "GeoToad for Mac.command"
SetFile -a E "GeoToad for Mac.command"
SetFile -a C "GeoToad for Mac.command"
rm data/icns.rsrc
cd ..
echo "Creating MacOSX package"
hdiutil create -ov -fs "Case-sensitive HFS+" -srcfolder "${DISTNAME}" "${DISTNAME}.dmg"
ls -l "${DISTNAME}.dmg"
echo "Done with MacOSX package"
