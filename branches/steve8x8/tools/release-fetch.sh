#!/bin/bash

# fetch latest .tar.gz from Downloads page
# unpack into geotoad-$VERSION/
# create geotoad_$VERSION.orig.tar.gz for Debian packaging

# determine last version
lynx -dump http://code.google.com/p/geotoad/downloads/list \
| egrep '.*/geotoad-([0-9\.]+)\.tar\.gz' \
| sed 's/.*http/http/' \
| tee /dev/stderr \
| sort \
| tail -n1 \
| while read url
do
    # check for new
    version=$(echo $url | sed -e 's~.*/geotoad-~~' -e 's~.zip~~' -e 's~.tar.gz~~')
    echo version $version
    if [ -d geotoad-$version ]
    then
	echo version $version already there
	continue
    else
	# get
	wget -m -nvpdH $url
	# unpack and convert to .orig.tar.gz
	case $url in
	    *.zip)
		unzip -qx geotoad-$version.zip
		tar zcf geotoad_$version.orig.tar.gz geotoad-$version
		;;
	    *.tar.gz)
		tar zxf geotoad-$version.tar.gz
		cp -p geotoad-$version.tar.gz geotoad_$version.orig.tar.gz
		;;
	esac
    fi
done
