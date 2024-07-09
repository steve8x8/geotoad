#!/bin/bash

cd `dirname $0`

#listpath=../data
#outpath=.
#temppath=.

listpath=../data
outpath=../lib
temppath=/tmp
trap "/bin/rm -f ${temppath}/$$.{c,s}; exit" 0 1 2 3 6 9 15

[ -f ${listpath}/country.list ] || exit
[ -f ${listpath}/state.list ] || exit


{
#printf "# country list last updated: `stat -c %y ${listpath}/country.list | cut -c1-10`\n"
printf "\$COUNTRIES = [\n"
cat ${listpath}/country.list \
| awk '
    {
	cn = $1;
	$1 = "";
	nm = substr($0, 2);
	tx = "";
	if (nm ~ "^---") {
	    next;
	}
	if (nm ~ /^\*\*/) {
	    nm = substr(nm, 3);
	    tx = "no full-country search";
	} else {
	    if (nm ~ /^\*/) {
		nm = substr(nm, 2);
		tx = "region search possible";
	    }
	}
	printf("\t[ %3d, \"%s\" ],\n", cn, nm);
    }
    '
printf "]\n\n"
} \
> ${temppath}/$$.c

{
#printf "#   state list last updated: `stat -c %y ${listpath}/state.list | cut -c1-10`\n"
printf "\$STATES = [\n"
cat ${listpath}/state.list \
| grep -v ' --- ' \
| while read line
do
    sn=`echo "${line}" | cut -c1-3 | tr -dc '[0-9]'`
    r=`echo "${line}" | sed -e 's~^[ 0-9][ 0-9]*~~' -e 's~\[.*$~~'`
    c=`echo "${line}" | sed -e 's~^.*\[~~' -e 's~\].*$~~'`
    cn=`grep "\"${c}\"" ${temppath}/$$.c | tr -d '[,' | awk '{print $1}'`
    nm=`echo $r`
    #echo $sn \"$nm\" $cn \"$c\" >&2
    printf "\t[ %3d, \"%s\", %3d, \"%s\" ],\n" $sn "$nm" $cn "$c"
done
printf "]\n\n"
} \
> ${temppath}/$$.s

{
printf "# -*- encoding : utf-8 -*-\n\n"
date +"### Updated %Y-%m-%d ###"
printf "\nmodule CountryStateList\n\n"
cat ${temppath}/$$.[cs]
printf "end\n"
} \
> ${outpath}/country_state_list.rb

exit

