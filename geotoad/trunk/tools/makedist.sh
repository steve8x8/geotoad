#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.se,v 1.3 2002/04/23 04:05:41 helix Exp $

cd ..
SRC=`pwd`
VERSION=`cat VERSION`
DIST="geotoad-$VERSION"
DEST=/tmp/$DIST
LONGDIST="$DIST"

echo "Creating $DEST"
rm -Rf $DEST
mkdir $DEST
cp -R CLI/._* CLI/.DS* TODO.txt COPYRIGHT.txt geocache CLI/interface $DEST
ditto CLI/*Mac* $DEST
sed s/"%VERSION%"/"$VERSION"/g CLI/geotoad.rb > $DEST/geotoad.rb
sed s/"%VERSION%"/"$VERSION"/g CLI/README.txt > $DEST/README.txt
chmod 755 $DEST/*.rb
rm $DEST/**/*~ 2>/dev/null
rm -Rf $DEST/**/.svn 2>/dev/null

echo "Updating repository..."
svn update
echo "Creating Changelog"
svn log -v > $DEST/ChangeLog.txt
joe $DEST/ChangeLog.txt
rm $DEST/ChangeLog.txt~

# Mac OS X
cd /tmp
echo "Creating zipfile (Mac OS X): zip -r ${LONGDIST}_for_MacOS.zip $DIST"
zip -r ${LONGDIST}_for_MacOS.zip $DIST

# Generic
echo "Creating zipfile (Generic): zip -r $LONGDIST.zip $DIST"
rm $DEST/*.command 
rm $DEST/.* 2>/dev/null
zip -r $LONGDIST.zip $DIST

# Windows
echo "Creating zipfile (Windows): zip -r ../${LONGDIST}_for_Windows.zip *"
cd $DEST
rm -Rf *.rb geocache interface

# convert to Windows newlines
flip -d *.txt

# remove geotoad.rb mentions, since it's an executable.
perl -pi -e  's/([\s])geotoad\.rb/$1geotoad/g' README.txt

cp $SRC/CLI/*.exe .
zip -r ../${LONGDIST}_for_Windows.zip *

echo "Copying to desktop"
cp /tmp/${LONGDIST}* ~/Desktop

#echo "Copying zipfile to webservers"
#scp $LONGDIST.zip $DEST/ChangeLog.txt smtp.stromberg.org:/www/toadstool.se/htdocs/hacks/geotoad/files/
#scp $LONGDIST.zip $DEST/ChangeLog.txt toadstool.se:/www/toadstool.se/htdocs/hacks/geotoad/files/
#echo "http://home.toadstool.se/hacks/geotoad/files/$LONGDIST.zip"

