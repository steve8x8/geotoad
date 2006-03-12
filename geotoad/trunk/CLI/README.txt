GeoToad %VERSION% by Thomas Stromberg (c) 2003
$Id$

==========================================================================

Table of Contents:
------------------
* About
* Requirements
* Getting Started
* Command-Line Syntax
* Command-Line examples



-----
About
-----
It's an open-source query tool to query the geocaching.com website. It
supports exporting your results into a dozen or more formats such as GPX,
HTML, or VCF for your iPod.


------------
Requirements
------------
Windows - Windows 98 or Higher
Mac OS - Mac OS X 10.4 or Higher (10.2 or higher if Ruby 1.8 is installed)
Other Operating Systems -  You may need to install Ruby before running GeoToad.

  * RedHat/Fedora Linux: built-in
  * Debian Linux: apt-get install ruby
  * FreeBSD: pkg_add -r ruby

Optionally, if you have gpsbabel - http://gpsbabel.sourceforge.net/
geotoad can output to over a dozen additional GPS formats.


---------------
Getting Started
---------------
The easiest way to get started with GeoToad is to use the "text user
interface" (TUI). Simply double click on the GeoToad program icon, or from 
a command prompt run "geotoad" or if you are on UNIX, run "./geotoad.rb". You
will then see a screen that looks similar to this:

==============================================================================
:::            // GeoToad 3.9-CURRENT Text User Interface //               :::
==============================================================================
(1)  GC.com login     [wally        ] | (2)  search type          [zipcode   ]
(3)  zipcode          [47408        ] | (4)  distance maximum            [10 ]
                                      |
(5)  difficulty           [2.0 - 5.0] | (6)  terrain               [1.5 - 5.0]
(7)  fun factor           [0.0 - 5.0] |
(8) virgin caches only            [ ] | (9) travel bug caches only         [X]
(10) cache age (days)       [  0-120] | (11) last found (days)       [  0-any] 
                                      |
(12) title keyword       [          ] | (13) descr. keyword    [             ]
(14) cache not found by  [helixblue:] | (15) cache owner isn't [             ]
(16) cache found by      [          ] | (17) cache owner is    [             ]
(18) EasyName WP length         [  8] | 
- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -
(19) output format       [html      ]   (20) filename   [automatic           ]
(21) output directory    [/Users/thomas/Desktop                              ]
==============================================================================

-- Enter menu number, (s) to start, (r) to reset, or (x) to exit --> 
                                                                              
At this point, follow the prompt and begin typing the number of the item you
wish to change, pressing enter afterwards. You will need to enter your login
and some basic search criteria first.

Once you have entered in all of your information, press "s" and then <ENTER>
to begin your search. GeoToad will save any options you have entered for
future runs.


-------------------
Command Line Syntax
-------------------

Sometimes people prefer to use the command-line switches instead of the text user
interface. This comes especially in handy when you wish to automate it so
that every morning your iPod or GPS has the freshest list of geocaches that have
not been found in your area.

If you go to the command line, and run geotoad -h, you will get a screen
with a list of of options such as the following:

syntax: geotoad [options] <search:search2:search3>

 -x format for output. Formats available are:
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



---------------------
Command-Line Examples
---------------------

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


3) geotoad.rb -u user -p password -x text -o nc.txt -n -q state "North Carolina"
Outputs a text file with all of the caches in North Carolina that are
virgins (have never been found).

Please note the quotes around North Carolina. Any parameters with spaces in
them must have quotes around them.


4) geotoad.rb -u user -p password -t 2.5 -x vcf -S "helixblue:Sallad" -o charlotte.vcf 28272
Gets every cache in the 100 mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a VCF format file, which is usable by iPod's and other devices.

Please note: Put quotes around your username if it has any spaces in it.


5) geotoad.rb -u user -p password -x html -b -K 'stream|creek|lake|river|ocean' -o watery.html -q state Indiana
Gets every cache in Sweden with travel bugs that matches those water keywords.
Makes a pretty HTML file out of it.
