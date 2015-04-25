#!/bin/bash

# example: Berlin/Brandenburg area night caches
listguid="cbb21edf-fb9e-45b5-9b27-c51fd6453cbf"

# extract list of guids from KML file
GUIDS=`
lynx -source "http://www.geocaching.com/kml/bmkml.aspx?bmguid=$listguid" \
| perl -ne 'if(/\?guid=([0-9a-f-]+)/){printf("%s:",$1)}'
`

# now run the real query
geotoad -q guid -x gpx -o `pwd`/list_$listguid.gpx "$GUIDS"
