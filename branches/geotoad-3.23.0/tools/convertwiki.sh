#!/bin/bash

# quick and dirty hack to rebuild txt files from wiki pages
# to be run inside a wiki svn working copy
# doesn't work properly with links and some lists!

#for page in `ls *.wiki | sed -e 's~\.wiki~~'`
pages=${@:-README FAQ OtherSearches ReportingBugs DebianUbuntuRepository GCmaintenances Templates}
for page in $pages
do
    [ -f $page.wiki ] || continue
    echo $page
    (
# pass 1: header line & toc
    cat $page.wiki \
    | awk '
	function links(line) {
	if (line ~ /\[.+\]/) {
	    pref=line; gsub("\\[.*","",pref)
	    post=line; gsub(".*\\]","",post)
	    link=line; gsub(".*\\[","",link); gsub("\\].*","",link)
	    if (link ~ /[^ ]+ +.*/) {
		url=link;  gsub(" .*$","",url)
		name=link; gsub("^[^ ]* ","",name)
		if (url ~ /^https*:\/\//) {
		    link=name " (=> " url ")"
		} else if (url == name) {
		    link="\"" url "\""
		} else {
		    link=name " (=> Wiki:" url ")"
		}
	    }
	    return pref link post
	} else {
	    return line
	}
	}
	{
	if (/^= /) {
	    h=substr($0,3,length($0)-4)
	    h=links(h)
	    lh=length(h)
	    for(i=0;i<lh;i++) printf "="
	    print ""
# version number
	    gsub("[0-9]\\.[0-9][0-9]*\\.[0-9][0-9]*","%VERSION%",h)
	    print h
	    for(i=0;i<lh;i++) printf "="
	    print ""
	    print ""
	    next
	}
	if (/^<wiki:toc/) {
	    print "Table of Contents:"
	    print "------------------"
	    next
	}
# skip comments
	if (/^<wiki:comment/) {
	    while ($0 !~ /^<\/wiki:comment/) getline
	    next
	}
	if (/^== /) {
	    h=substr($0,4,length($0)-6)
	    h=links(h)
	    print "*",h
	    next
	}
	}'
# pass 2: full text
    cat $page.wiki \
    | awk '
	function links(line) {
	if (line~/\[.+\]/) {
	    pref=line; gsub("\\[.*","",pref)
	    post=line; gsub(".*\\]","",post)
	    link=line; gsub(".*\\[","",link); gsub("\\].*","",link)
	    if (link ~ /[^ ]+ +.*/) {
		url=link;  gsub(" .*$","",url)
		name=link; gsub("^[^ ]* ","",name)
		if (url ~ /^https*:\/\//) {
		    link=name " (=> " url ")"
		} else if (url == name) {
		    link="\"" url "\""
		} else {
		    link=name " (=> Wiki:" url ")"
		}
	    }
	    return pref link post
	} else {
	    return line
	}
	}
	{
# comment lines
	if (/^#/ && NR<5) next
	if (/^<wiki:toc/) next
# skip blank
	if (/.../) p=1
	if (p==0) next
# skip comments
	if (/^<wiki:comment/) {
	    while ($0 !~ /^<\/wiki:comment/) getline
	    next
	}
# headings
	if (/^= /) {
	    next;
	    h=substr($0,3,length($0)-4)
	    h=links(h)
	    lh=length(h)
	    for(i=0;i<lh;i++) printf "="
	    print ""
# version number
	    gsub("[0-9]\\.[0-9][0-9]*\\.[0-9][0-9]*","%VERSION%",h)
	    print h
	    for(i=0;i<lh;i++) printf "="
	    print ""
	    next
	}
	if (/^== /) {
	    h=substr($0,4,length($0)-6)
	    h=links(h)
	    for(i=0;i<length(h);i++) printf "-"
	    print ""
	    print h
	    for(i=0;i<length(h);i++) printf "-"
	    print ""
	    next
	}
# version number in TUI
	if (/\/\/ .* \/\//) {
	    l=$0
	    l=links(l)
	    gsub("[0-9]\\.[0-9][0-9]*\\.[0-9][0-9]*","%VERSION%",l)
	    print l
	    next
	}
# separations
	if (/^----$/) {
	    for(i=0;i<50;i++) printf "~"
	    print ""
	    next
	}
# removed
	if (/~~.*~~/) next
# indentations
	gsub("  \\*"," -",$0)
# pre
	if(/{{{/) pre=1
	if(/^{{{$/) next
	if(/}}}/) pre=0
	if(/^}}}$/) next
	gsub("\\**{{{","",$0)
	gsub("}}}\\**","",$0)
	gsub("_{{{","",$0)
	gsub("}}}_","",$0)
	if(pre){
	# indent by 3 blanks
	#    print "   " $0
	    print $0
	    next
	}
# bold face
	gsub("\\*[^\\*]*\\*","*&*",$0)
	gsub("\\*\\*","",$0)
# oblique face
#	gsub("_[^\\*]*_","_&_",$0)
#	gsub("__","",$0)
# everything else
	print links($0)
	}'
    ) > $page.txt.new
    diff 2>/dev/null -q $page.txt $page.txt.new || {
	echo new $page
	mv $page.txt.new $page.txt
    }
    rm -f 2>/dev/null $page.txt.new
done
