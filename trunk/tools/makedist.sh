#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.se,v 1.3 2002/04/23 04:05:41 helix Exp $
cd ..
SRC=`pwd`
VERSION=`cat VERSION`
DISTNAME="geotoad-$VERSION"
DEST=$HOME/Desktop/GeoToad
DIST_SRC=$DEST/$DISTNAME
DIST_MAC=$DEST/${DISTNAME}_for_Mac
DIST_WIN=$DEST/${DISTNAME}_for_Windows

echo "Updating repository..."
svn update

echo "Erasing old distributions."
rm -Rf $DEST

echo "Creating $DIST_SRC"
mkdir -p $DIST_SRC
rsync -a --exclude "*~" --exclude ".svn/" . $DIST_SRC
sed s/"%VERSION%"/"$VERSION"/g geotoad.rb > $DIST_SRC/geotoad.rb
sed s/"%VERSION%"/"$VERSION"/g README.txt > $DIST_SRC/README.txt
sed s/"%VERSION%"/"$VERSION"/g FAQ.txt > $DIST_SRC/FAQ.txt
chmod 755 $DIST_SRC/*.rb
svn log > $DIST_SRC/ChangeLog.txt
rm $DIST_SRC/VERSION $DIST_SRC/tools/tar2rubyscript.rb $DIST_SRC/tools/countryrip.rb

# Make a duplicate of it for Macs before we nuke the .command file
cp -Rp $DIST_SRC $DIST_MAC
rm $DIST_SRC/*.command
ln -s geotoad.rb geotoad
zip -r ${DIST_SRC}.zip $DIST_SRC

# Mac OS X
echo "Creating $DIST_MAC"
rm $DIST_MAC/geotoad
echo "Using Finder, rename the .command in $DIST_MAC and apply icon from data/bufos.icns"
read 
hdiutil create -srcfolder $DIST_MAC ${DIST_MAC}.dmg

# Windows
echo "Creating $DIST_WIN"
cp -Rp $DIST_SRC $DIST_WIN
rm $DIST_WIN/geotoad
cd $DIST_WIN
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
    rm -Rf $DIST_WIN/compile
    zip -r $DIST_WIN.zip $DIST_WIN
  else
    echo "compile.exe not found, FAIL."
  fi
else
  echo "Failed to run tar2rubyscript.rb, get it from http://www.erikveen.dds.nl/tar2rubyscript/index.html"
fi
