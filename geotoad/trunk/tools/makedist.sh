#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.se,v 1.3 2002/04/23 04:05:41 helix Exp $

cd ..
VERSION=`cat VERSION`

DIST="geotoad-$VERSION"
LONGDIST="$DIST"
echo "Creating /tmp/$DIST"
rm -Rf /tmp/$DIST
mkdir /tmp/$DIST
cp -R TODO.txt COPYRIGHT.txt geocache CLI/interface /tmp/$DIST
sed s/"%VERSION%"/"$VERSION"/g CLI/geotoad.rb > /tmp/$DIST/GeoToad.rb
sed s/"%VERSION%"/"$VERSION"/g CLI/README.txt > /tmp/$DIST/README.txt
chmod 755 /tmp/$DIST/*.rb
rm /tmp/$DIST/**/*~ 2>/dev/null
rm /tmp/$DIST/*/._* 2>/dev/null
rm -Rf /tmp/$DIST/**/CVS 2>/dev/null
rm -Rf /tmp/$DIST/**/.svn 2>/dev/null

echo "Updating repository..."
svn update
echo "Creating Changelog"
svn log VERSION COPYRIGHT.txt geocache CLI -v > /tmp/$DIST/ChangeLog.txt

echo "Creating zipfile"
cd /tmp
cd $DIST
ln -s GeoToad.rb "GeoToad for Mac.command"
cd ..

zip -r $LONGDIST.zip $DIST
echo "Copying zipfile to webservers"

scp $LONGDIST.zip /tmp/$DIST/ChangeLog.txt smtp.stromberg.org:/www/toadstool.se/htdocs/hacks/geotoad/files/
scp $LONGDIST.zip /tmp/$DIST/ChangeLog.txt toadstool.se:/www/toadstool.se/htdocs/hacks/geotoad/files/
echo "http://home.toadstool.se/hacks/geotoad/files/$LONGDIST.zip"

