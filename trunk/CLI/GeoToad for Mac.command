#!/bin/sh
# This is a wrapper so that Mac users have something to click on in Finder 
# to open up a Terminal window with GeoToad running in it. This is similar
# to how Windows users run things, except that .rb isn't associated with a
# terminal out of the box -- but .command is!

clear

# We need to quote everything so that spaces in filenames (like this one!)
# are not a problem.

dir=`dirname "$0"`
"$dir/geotoad.rb"
