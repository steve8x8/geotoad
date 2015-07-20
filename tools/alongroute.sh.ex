#!/bin/bash

input=input.gpx # some file you picked up at e.g. openrouteservice.org

error=0.25k     # Douglas-Peucker tolerance
distance=1.25k  # interpolation distance
circle=1.00km   # search radius

# note: error/circle ~ 1/4, distance/circle ~ 5/4 will give you
# an approximate coverage of about 2/3 circle radius

# for a half-mile wide corridor along your route: 
#error=0.2m
#distance=1m
#circle=0.8mi

# simplify input with Douglas-Peucker,
# then interpolate for point distance,
# output as series of coordinates suited for geotoad

searchargs=$(
cat $input |
gpsbabel -i gpx -f - \
    -x simplify,crosstrack,error=$error \
         -o gpx -F - |
gpsbabel -i gpx -f - \
    -x interpolate,distance=$distance \
         -o csv -F - |
tr ',' ' ' |
awk '{printf("%.3f,%.3f|",$1,$2)}'

)

echo complete \(with your credentials etc.\) and run:
echo geotoad ... -y$circle -q coord \"$searchargs\"
