#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.se,v 1.3 2002/04/23 04:05:41 helix Exp $
cd ..
SRC=`pwd`
VERSION=`cat VERSION`
DISTNAME="geotoad-$VERSION"
DEST=$HOME/Desktop/GeoToad
GENERIC_DIR=$DEST/$DISTNAME
GENERIC_PKG="${GENERIC_DIR}.zip"

MAC_DIR="$DEST/GeoToad for Mac"
MAC_PKG="$DEST/${DISTNAME}_MacOSX.dmg"

WIN_DIR=$DEST/${DISTNAME}_for_Windows
WIN_PKG="$DEST/${DISTNAME}_Windows.zip"

echo "Updating repository..."
svn update

echo "Erasing old distributions."
rm -Rf "$DEST"

echo "Creating $GENERIC_DIR"
mkdir -p "$GENERIC_DIR"
svn2cl
mv ChangeLog ChangeLog.txt
rsync -a --exclude "*~" --exclude ".svn/" . $GENERIC_DIR
sed s/"%VERSION%"/"$VERSION"/g geotoad.rb > $GENERIC_DIR/geotoad.rb
sed s/"%VERSION%"/"$VERSION"/g README.txt > $GENERIC_DIR/README.txt
sed s/"%VERSION%"/"$VERSION"/g FAQ.txt > $GENERIC_DIR/FAQ.txt
chmod 755 $GENERIC_DIR/*.rb
rm $GENERIC_DIR/VERSION $GENERIC_DIR/tools/tar2rubyscript.rb $GENERIC_DIR/tools/countryrip.rb $GENERIC_DIR/tools/*.sh

# Make a duplicate of it for Macs before we nuke the .command file
cp -Rp $GENERIC_DIR "$MAC_DIR"
rm $GENERIC_DIR/*.command
ln -s geotoad.rb geotoad
cd "$DEST"
zip -r "$GENERIC_PKG" "$DISTNAME"

# Mac OS X
echo "Creating $MAC_DIR"
rm "$MAC_DIR/geotoad"
echo "Using Finder, rename the .command in $MAC_DIR and apply icon from data/bufos.icns"
read 
hdiutil create -srcfolder "$MAC_DIR" "$MAC_PKG"

# Windows
echo "Creating $WIN_DIR"
cp -Rp "$GENERIC_DIR" "$WIN_DIR"
rm "$WIN_DIR/geotoad"
cd "$WIN_DIR"
mkdir compile
mv *.rb lib interface data compile
mv compile/geotoad.rb compile/init.rb
flip -d *.txt
perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' README.txt
echo "Running tar2rubyscript.rb compile"
ruby $SRC/tools/tar2rubyscript.rb compile
if [ -f "compile.rb" ]; then
  echo "Under vmware, run: ruby rubyscript2exe.rb compile.rb"
  read ENTER
  if [ -f "compile.exe" ]; then
    mv compile.exe geotoad.exe
    rm -Rf "$WIN_DIR/compile"
    zip -r "$WIN_PKG" *
  else
    echo "compile.exe not found, FAIL."
  fi
else
  echo "Failed to run tar2rubyscript.rb, get it from http://www.erikveen.dds.nl/tar2rubyscript/index.html"
fi
