#!/bin/bash

# Debian packaging for release
# prerequisites: .orig.tar.gz and unpacked geotoad-*/

# get version number
VERSION=$(ls -d geotoad-[0-9]*/ | tr -d / | tail -n1 | cut -d- -f2-)
# build number (usually 1=initial)
BUILD=${1:-1}
echo version $VERSION build $BUILD

# Debian packages love ToDo lists
# we point to the Issues tracker just in case somebody hasn't noticed yet
if [ ! -f geotoad-${VERSION}/TODO.txt ]
then
  echo create TODO.txt
  cat <<EOF > geotoad-${VERSION}/TODO.txt
For open issues, see https://code.google.com/p/geotoad/issues/list
EOF
fi

cd geotoad-${VERSION}

# add new entry to changelog
if ! grep "geotoad ($VERSION-$BUILD)" debian/changelog
then
  # I know there's a helper for this...
  ed debian/changelog <<EOF
0a
geotoad ($VERSION-$BUILD) unstable; urgency=low

  * New release $VERSION

 -- Steffen Grunewald <steve8x8@gmail.com>  $(date --rfc-2822)

.
w
q
EOF
fi

# dpkg-buildpackage is in dpkg-dev package
# do not sign anything, run "debian/rules clean" afterwards
dpkg-buildpackage -rfakeroot -uc -us -tc
