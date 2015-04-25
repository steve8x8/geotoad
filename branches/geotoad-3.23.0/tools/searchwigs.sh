#!/bin/bash

# pass wig file through, add missing links

cat - \
| sed 's~/not chosen~/not_chosen~' \
| tr '=' ' ' \
| while read gcid guid lat lon dts dummy
do
    case $guid in
	# only overwrite if no GUID exists (may be wrong else)
	_*)
	    # get from wherigo search
	    guid=`
	    lynx -source "http://www.wherigo.com/search/results.aspx?searchlat=$lat&searchlon=$lon&stype=8&rad=2" \
	    | grep /cartridge/details \
	    | grep -v Try.out.the.tutorial \
	    | sed -e 's~.*CGUID=~~' -e "s~'.*~~" \
	    | head -n1`
	    [ -z "$guid" ] && guid="_even_a_wherigo_search_gave_nothing_"
	    ;;
	*)
	    ;;
    esac
    echo -e "$gcid=$guid\t$lat $lon\t$dts\t$dummy"
done \
| sed 's~/not_chosen~/not chosen~'
