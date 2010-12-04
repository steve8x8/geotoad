#!/bin/bash

# extract attribute mapping from "Edit Attributes" page
# output can be inserted directly into lib/details.rb

FILE=${1:-attributes.aspx.html}

if [ ! -f "$FILE" ]
then
    echo "Open a cache of yours, go to Edit Attributes, save page source."
    exit 1
fi

cat $FILE \
| tr "<>" "\012" \
| grep "img id" \
| awk -F'"' '{print $2, $4}' \
| cut -d_ -f4- \
| sed 's~\([^0-9]*\)\([0-9][0-9]*\) \(.*\)~\2 \1 \3~' \
| sort -n \
| tr '[A-Z]' '[a-z]' \
| awk '
    BEGIN{print "    attrmap = {"}
    {if($1)printf("      %-19s=> %d,\n", "\"" $2 "\"", $1)}
    END{print "    }"}
    '
