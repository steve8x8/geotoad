#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.se,v 1.3 2002/04/23 04:05:41 helix Exp $

# this must be run from the geotoad directory.

# For Windows build, we require: http://github.com/ryanbooker/rubyscript2exe

if [ ! -f VERSION ];  then
  echo "VERSION not found"
  exit 2
fi
base_dir=`pwd`
src_dir="/tmp/namebench-$$"
svn checkout http://geotoad.googlecode.com/svn/trunk/ $src_dir
cd $src_dir
svn log >ChangeLog.txt

VERSION=`cat VERSION`
DISTNAME="geotoad-$VERSION"
DEST="${base_dir}/dist"
GENERIC_DIR=$DEST/$DISTNAME
GENERIC_PKG="${GENERIC_DIR}.zip"
GENERIC_TGZ="${GENERIC_DIR}.tar.gz"

MAC_DIR="$DEST/GeoToad for Mac"
MAC_PKG="$DEST/${DISTNAME}_MacOSX.dmg"

WIN_DIR=$DEST/${DISTNAME}_for_Windows
WIN_PKG="$DEST/${DISTNAME}_Windows.zip"

echo "Erasing old distributions."
rm -Rf "$DEST"

echo "Creating $GENERIC_DIR"
mkdir -p "$GENERIC_DIR"
rsync -a --exclude ".svn/" . $GENERIC_DIR

sed s/"%VERSION%"/"$VERSION"/g lib/version.rb > $GENERIC_DIR/lib/version.rb
sed s/"%VERSION%"/"$VERSION"/g README.txt > $GENERIC_DIR/README.txt
sed s/"%VERSION%"/"$VERSION"/g FAQ.txt > $GENERIC_DIR/FAQ.txt
chmod 755 $GENERIC_DIR/*.rb
rm $GENERIC_DIR/VERSION $GENERIC_DIR/tools/countryrip.rb $GENERIC_DIR/tools/*.sh

# Make a duplicate of it for Macs before we nuke the .command file
cp -Rp $GENERIC_DIR "$MAC_DIR"
rm $GENERIC_DIR/*.command
ln -s geotoad.rb geotoad
cd "$DEST"
zip -r "$GENERIC_PKG" "$DISTNAME"
tar zcf "$GENERIC_TGZ" "$DISTNAME"

# Mac OS X
if [ -d "/Applications" ]; then
  echo "Creating $MAC_DIR"
  rm "$MAC_DIR/geotoad"
  cd "$MAC_DIR"
  sips -i data/bufos-icon.icns && DeRez -only icns data/bufos-icon.icns > data/icns.rsrc
  Rez -append data/icns.rsrc -o "GeoToad for Mac.command"
  SetFile -a E "GeoToad for Mac.command"
  SetFile -a C "GeoToad for Mac.command"
  rm data/icns.rsrc
  echo "Creating $MAC_PKG"
  hdiutil create -srcfolder "$MAC_DIR" "$MAC_PKG"
  echo "done with $MAC_PKG"
else
  echo "Skipping Mac OS X release"
fi

# Windows
if [ ! -x "/usr/local/bin/flip" -o ! -x "/usr/bin/flip" ]; then
  echo "Creating $WIN_DIR"
  cp -Rp "$GENERIC_DIR" "$WIN_DIR"
  cd "$WIN_DIR"
  mkdir compile
  mv *.rb lib interface data compile
  mv compile/geotoad.rb compile/init.rb
  flip -m *.txt
  perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' README.txt

  echo "In Windows, run:"
  echo ""
  echo "cd Z:\\dist\\${DISTNAME}_for_Windows\\compile"
  echo "ruby C:\\ruby\\bin\\rubyscript2exe.rb init.rb"
  echo "move init.exe ..\\geotoad.exe"
  read ENTER
  cd $WIN_DIR
  ls
  if [ -f "geotoad.exe" ]; then
    mv compile/data .
    rm -Rf "$WIN_DIR/compile"
    zip -r "$WIN_PKG" *
  else
    echo "geotoad.exe not found"
  fi
else
  echo "Skipping Windows Release (no flip found)"
fi

