GeoToad %VERSION% by Thomas Stromberg (c) 2003
$Id$

==========================================================================

Table of Contents:
------------------
* About
* Requirements
* Getting Started
* Command-Line Syntax
* Usage Guide



-----
About
-----
It's an open-source query tool to query the geocaching.com website. It can
write into a half dozen formats. To see what's new in this release, see the
ChangeLog.txt file.


------------
Requirements
------------
Windows - Windows 98 or Higher
Mac OS - Mac OS X 10.2 or Higher
Other Operating Systems -  You may need to install Ruby before running GeoToad.

  * RedHat/Fedora Linux: built-in
  * Debian Linux: apt-get install ruby
  * FreeBSD: pkg_add -r ruby

Optionally, if you have gpsbabel - http://gpsbabel.sourceforge.net/
geotoad can output to over a dozen additional GPS formats.

---------------
Getting Started
---------------
There are two modes to GeoToad, an interactive mode, which most people will
use, and a command line interface, which is mostly for people scripting
GeoToad. To get to the interactive mode:

In Windows  -- double click on the "geotoad.exe" file.
In Mac OS X -- double click on the "GeoToad" file.
In UNIX     -- run ./geotoad.rb in a shell.

The rest should be somewhat obvious. You get to a screen where you can
change your query and filter options, and once you are done with that, press
's' and it will perform the magic.

GeoToad will automatically save any options defined in the text interface
for the next time it is loaded.


-------------------
Command Line Syntax
-------------------

The command-line interface used to be the only way to use GeoToad. In 3.5.0,
we have introduced a TUI (Text-User Interface), but have kept the
command-line interface for those who's preference it is, and of course for
people scripting or embedding GeoToad into their applications.


syntax: geotoad.rb [options] <search:search2:search3>

 -f format for output. Formats available are:
   csv           CSV for spreadsheet imports
   delorme       DeLorme TXT import datafile  
   easygps       Geocaching.com .loc XML file
   gpsdrive      GpsDrive
   gpspoint      gpspoint datafile
   gpx           GPX XML format
   html          Simple HTML table format
   html-decrypt  Simple HTML table format with decrypted hints
   mxf           MapTech Exchange
   ozi           OziExplorer
   text          Plain ASCII
   text-decrypt  Plain ASCII with decrypted hints
   tab           Tabbed text, for GPS Connect
   tiger         U.S. Census Bureau Tiger Mapping Service Data
   vcf           VCF for iPod Contacts export

   -- the following require gpsbabel to be installed --
   cetus         Cetus for PalmOS
   dna           Navitrak DNA marker
   gpsman        GPSman datafile
   gpspilot      GPSPilot for PalmOS
   gpsutil       gpsutil
   holux         Holux gm-100
   magnav        Magellan NAV Companion for PalmOS
   mapsend       Magellan MapSend software
   pcx           Garmin PCX5
   psp           Microsoft PocketStreets 2002 Pushpin
   tmpro         TopoMapPro Places
   tpg           National Geographic Topo
   xmap          Delorme Topo USA4/XMap Conduit

   -- the following requires cmconvetr to be installed --
   cachemate     CacheMate Palm software

 -u <username>          Geocaching.com username, required for coordinates
 -p <password>          Geocaching.com password, required for coordinates

 -o [filename]          output file name (automatic otherwise)
 -x [format]            output format type, see list below
 -q [zip|state|coord]   query type (zip by default)

 -d/-D [0.0-5.0]        difficulty minimum/maximum
 -t/-T [0.0-5.0]        terrain minimum/maximum
 -f/-F [0.0-5.0]        fun factor minimum/maximum
 -y    [1-500]          distance maximum in miles (10)
 -k    [keyword]        title keyword search. Use | to delimit multiple
 -K    [keyword]        desc keyword search. Use | to delimit multiple
 -i/-I [username]       include/exclude caches owned by this person
 -s/-S [username]       include/exclude caches found by this person
                            (use : to delimit multiple users!)
 -j/-J [# days]         include/exclude caches placed in the last X days
 -r/-R [# days]         include/exclude caches found in the last X days
 -n                     only include not found caches (virgins)
 -b                     only include caches with travelbugs
 -l                     set EasyName waypoint id length. (16)     



-----
Usage
-----
You need to get to a command-line (DOS, cmd.exe, UNIX shell), and go into
the directory you extracted geotoad into. Then you should be able to type
something simple like:

geotoad.rb -u user -p password 27513

Why do we need a username and password? In October of 2004, Geocaching.com
began to require a login in order to see the coordinates of a geocache.

If that does not work, try:

ruby geotoad.rb -u user -p password 27513

You've just made a file named geotoad-output.loc containing all the geocaches
nearby the zipcode 27513 suitable to be read by EasyGPS. Here are some more
complex examples that you can work with:

1) geotoad.rb -u user -p password q coord "N56 44.392, E015 52.780"  -y 5
Search for caches within 5 miles of the above coordinates


2) geotoad.rb -u user -p password 27513:27502:33434
You can combine searches with the : delimiter. This works for all types,
though it's most often used with coordinate searches.


3) geotoad.rb -u user -p password -f text -o nc.txt -n -q state "North Carolina"
Outputs a text file with all of the caches in North Carolina that are
virgins (have never been found).

Please note the quotes around North Carolina. Any parameters with spaces in
them must have quotes around them.


4) geotoad.rb -u user -p password -t 2.5 -f vcf -U "helixblue:Sallad" -o charlotte.vcf 28272
Gets every cache in the 100 mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a VCF format file, which is usable by iPod's and other devices.

Please note: Put quotes around your username if it has any spaces in it.


5) geotoad.rb -u user -p password -f html -b -K 'stream|creek|lake|river|ocean' -o watery.html -q state Indiana
Gets every cache in Sweden with travel bugs that matches those water keywords.
Makes a pretty HTML file out of it.
