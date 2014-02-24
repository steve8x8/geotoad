#!/bin/bash

CENTER=GC77       # or whatever should be the center of your search
DISTANCE=2km      # radius around $CENTER

# extract coordinates for $CENTER cache
geotoad -q wid -x list -o `pwd`/$CENTER.list $CENTER

# get coordinates from list
COORDS=`awk '{printf("%s,%s\n",$2,$3)}' $CENTER.list`

# now run the real query
geotoad -q coord -x gpx -o `pwd`/$CENTER-prox.gpx "$COORDS"
