#!/bin/bash

cd `dirname $0`
[ -f ../data/country.list ] || exit
[ -f ../data/state.list ] || exit

trap "/bin/rm -f /tmp/$$.{c,s}; exit" 0 1 2 3 6 9 15

{
printf "# country list last updated: `stat -c %y ../data/country.list | cut -c1-10`\n"
printf "\$COUNTRIES = [\n"
cat ../data/country.list \
| awk '
    {
	cn=$1; $1=""; nm=substr($0,2);
	printf("\t[ %3d, \"%s\" ],\n", cn, nm);
    }
    '
printf "]\n\n"
} \
> /tmp/$$.c

{
printf "#   state list last updated: `stat -c %y ../data/state.list | cut -c1-10`\n"
printf "\$STATES = [\n"
cat ../data/state.list \
| sed -e 's~\(.*\) \[\(.*\)\]$~\2=\1~'\
| while read line
do
    c=${line%%=*}
    r=${line##*=}
    cn=`grep "\"$c\"" /tmp/$$.c | tr -d '[,' | awk '{print $1}'`
    sn=`echo $r | awk '{print $1}'`
    nm=`echo $r | awk '{$1=""; print substr($0,2);}'`
    printf "\t[ %3d, \"%s\", %3d, \"%s\" ],\n" $sn "$nm" $cn "$c"
done
printf "]\n\n"
} \
> /tmp/$$.s

{
printf "module CountryStateList\n\n"
cat /tmp/$$.[cs]
printf "end\n"
} \
> ../lib/country_state_list.rb

exit

