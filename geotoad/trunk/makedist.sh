#!/bin/sh
# Builds a new release of geotoad
# $Id: makedist.sh,v 1.3 2002/04/23 04:05:41 helix Exp $


#VERSION=`grep VERSION=  | cut -d\' -f2`
VERSION=`cat VERSION`

DIST="geotoad-$VERSION"
LONGDIST="$DIST"
rm -Rf /tmp/$DIST
mkdir /tmp/$DIST
chmod 755 *.rb *.sh
cp -R README TODO VERSION geocache CLI /tmp/$DIST
sed s/"%VERSION%"/"$VERSION"/g CLI/geotoad.rb > /tmp/$DIST/CLI/geotoad.rb
chmod 755 /tmp/$DIST/**/*.rb
rm /tmp/$DIST/**/*~
rm /tmp/$DIST/*/._*
rm -Rf /tmp/$DIST/**/CVS
#cvs2cl --revisions -f /tmp/$DIST/ChangeLog.txt
cd /tmp
tar -zcvf $LONGDIST.tgz $DIST
#cp /tmp/$LONGDIST.tgz /www/profile.sh/htdocs/hacks/geotoad/files/
#cp /tmp/$DIST/ChangeLog.txt /www/profile.sh/htdocs/hacks/geotoad/files/
#echo
#echo "http://home.profile.sh/hacks/geotoad/files/$LONGDIST.tgz"

