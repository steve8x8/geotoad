#!/bin/bash

# quick and dirty hack to rebuild txt files from wiki pages
# to be run inside a wiki svn working copy

for page in FAQ README README-new
do
    [ -f $page.wiki ] || continue
    (
# pass 1: header line & toc
    cat $page.wiki \
    | awk '{
	if (/^= /){
	    h=substr($0,3,length($0)-4)
	    lh=length(h)
	    for(i=0;i<lh;i++)printf "="
	    print ""
# version number
	    gsub("[0-9]\\.[0-9][0-9]*\\.[0-9][0-9]*","%VERSION%",h)
	    print h
	    for(i=0;i<lh;i++)printf "="
	    print ""
	    print ""
	    next
	}
	if (/^<wiki/){
	    print "Table of Contents:"
	    print "------------------"
	    next
	}
	if (/^== /){
	    h=substr($0,4,length($0)-6)
	    print "*",h
	    next
	}
	}'
# pass 2: full text
    cat $page.wiki \
    | awk '{
# comment lines
	if (/^#/) next
	if (/^<wiki/) next
# skip blank
	if (/.../)p=1
	if (p==0) next
# headings
	if (/^= /){
	    next;
	    h=substr($0,3,length($0)-4)
	    lh=length(h)
	    for(i=0;i<lh;i++)printf "="
	    print ""
# version number
	    gsub("[0-9]\\.[0-9][0-9]*\\.[0-9][0-9]*","%VERSION%",h)
	    print h
	    for(i=0;i<lh;i++)printf "="
	    print ""
	    next
	}
	if (/^== /){
	    h=substr($0,4,length($0)-6)
	    for(i=0;i<length(h);i++)printf "-"
	    print ""
	    print h
	    for(i=0;i<length(h);i++)printf "-"
	    print ""
	    next
	}
# removed
	if (/~~.*~~/) next
# indentations
	gsub("  \\*"," -",$0)
# pre
	if(/{{{/) pre=1
	if(/}}}/) pre=0
	gsub("\\**{{{","",$0)
	gsub("}}}\\**","",$0)
	gsub("_{{{","",$0)
	gsub("}}}_","",$0)
	if(pre){
	    print $0
	    next
	}
# bold face
	gsub("\\*[^\\*]*\\*","*&*",$0)
	gsub("\\*\\*","",$0)
# oblique face
#	gsub("_[^\\*]*_","_&_",$0)
#	gsub("__","",$0)
# links
	if (/\[[^ ][^ ]* [^ ][^ ]*\]/){
	    pre=$0; gsub("\\[.*","",pre)
	    post=$0;gsub(".*\\]","",post)
	    link=$0;gsub(".*\\[","",link);gsub("\\].*","",link)
# "rename" link?
	    if (link ~ /.*  *.*/){
		url=link; gsub(" .*","",url)
		name=link;gsub(".* ","",name)
#		print "link " url " is " name
		if (url ~ /^http:\/\//){
		    link=name " (=> " url ")"
		}else{
		    link="\"" name "\""
		}
	    }
	    print pre link post
	    next
	}
# everything else
	print $0
	}'
    ) > $page.txt
done
