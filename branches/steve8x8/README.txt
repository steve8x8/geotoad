GeoToad %VERSION% by Thomas Stromberg (c) 2002 - 2011
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
Windows                 - Windows 98 or Higher
Mac OS                  - Mac OS X 10.4 or Higher
Other Operating Systems -  You may need to install Ruby before running GeoToad.
                          * RedHat/Fedora Linux: built-in
                          * Debian Linux: apt-get install ruby
                          * FreeBSD: pkg_add -r ruby

Optionally, if you have gpsbabel - http://gpsbabel.sourceforge.net/
GeoToad can output to over a dozen additional GPS formats.


---------------
Getting Started
---------------
The easiest way to get started with GeoToad is to use the "text user
interface" (TUI). Simply double click on the GeoToad program icon, or from
a command prompt run "geotoad". On UNIX, you may have to run "./geotoad.rb".
You will then see a screen that looks similar to this:

==============================================================================
:::                // GeoToad 3.14.4 Text User Interface //                :::
==============================================================================
(1)  GC.com login [REQUIRED         ] | (2)  search type          [location  ]
(3)  location     [roswell, ga      ] | (4)  distance maximum (mi)     [10   ]
                                      |
(5)  difficulty           [2.0 - 5.0] | (6)  terrain               [0.0 - 5.0]
(7)  fun factor           [1.5 - 5.0] | (8)  cache size            [any - any]
(9)  cache type           [      any] |
(10) virgin caches only           [ ] | (11) travel bug caches only        [ ]
(12) cache age (days)       [  0-any] | (13) last found (days)       [  0-any]
                                      |
(14) title keyword       [          ] | (15) descr. keyword    [             ]
(16) cache not found by  [          ] | (17) cache owner isn't [             ]
(18) cache found by      [          ] | (19) cache owner is    [             ]
(20) EasyName WP length         [  0] | (21) include disabled caches       [ ]
- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -
(22) output format       [kml       ]   (23) filename   [automatic           ]
(24) output directory    [/home/tstromberg/Skrivbord                         ]
==============================================================================

-- Enter menu number, (s) to start, (r) to reset, or (x) to exit -->


At this point, follow the prompt and begin typing the number of the item
you wish to change, pressing enter afterwards. You will need to enter your
login and some basic search criteria first.

Once you have entered in all of your information, press "s" and then
<ENTER> to begin your search. GeoToad will save any options you have
entered for future runs.


-------------------
Command Line Syntax
-------------------

Sometimes people prefer to use the command-line switches instead of the
text user interface. This comes especially in handy when you wish to
automate it so that every morning your iPod or GPS has the freshest list of
geocaches that have not been found in your area.

If you go to the command line, and run geotoad -h, you will get a screen
with a list of of options such as the following:

syntax: geotoad [options] <search:search2:search3>

 -u <username>          Geocaching.com username, required for coordinates
 -p <password>          Geocaching.com password, required for coordinates
 -o [filename]          output file name (automatic otherwise)
 -x [format]            output format type, see list below
 -q [location|user|wid]   query type (location by default)
 -d/-D [1.0-5.0]        difficulty minimum/maximum
 -t/-T [1.0-5.0]        terrain minimum/maximum
 -f/-F [1.0-5.0]        fun factor minimum/maximum
 -y    [1-500]          distance maximum in miles (10)
 -k    [keyword]        title keyword search. Use | to delimit multiple
 -K    [keyword]        desc keyword search (slow). Use | again...
 -i/-I [username]       include/exclude caches owned by this person
 -e/-E [username]       include/exclude caches found by this person
 -s/-S [virtual|small|regular|large]   min/max size of the cache
 -c    [regular|virtual|event|unknown] type of cache (| seperated)
 -j/-J [# days]         include/exclude caches placed in the last X days
 -r/-R [# days]         include/exclude caches found in the last X days
 -z                     include disabled caches
 -n                     only include not found caches (virgins)
 -b                     only include caches with travelbugs
 -l                     set EasyName waypoint id length. (16)
 -P                     HTTP proxy server, http://username:pass@host:port/
 -C                     Clear local browser cache
::: OUTPUT FORMATS:
 cachemate=   cetus+       csv          delorme      delorme-nour
 dna+         easygps      gclist       gcvisits     gpsdrive    
 gpsman       gpspilot+    gpspoint     gpsutil+     gpx         
 gpx-gsak     gpx-wpts     holux+       html         kml+        
 list         magnav+      mapsend+     mxf          myfindgpx   
 myfindlist   ozi          pcx+         psp+         sms         
 tab          text         tiger        tmpro+       tpg+        
 xmap+       
    + requires gpsbabel in PATH           = requires cmconvert in PATH

---------------------
Command-Line Examples
---------------------

You need to get to a command-line (DOS, cmd.exe, UNIX shell), and go into
the directory you extracted geotoad into. Then you should be able to type
something simple like:

geotoad -u user -p password 27513

Why do we need a username and password? In October of 2004, Geocaching.com
began to require a login in order to see the coordinates of a geocache.

If that does not work, try:

ruby geotoad -u user -p password 27513

You've just made a file named geotoad-output.loc containing all the
geocaches nearby the zipcode 27513 suitable to be read by EasyGPS. Here are
some more complex examples that you can work with:

1) geotoad -u user -p password "N56 44.392, E015 52.780"  -y 5
Search for caches within 5 miles of the above coordinates


2) geotoad -u user -p password 27513:27502:33434
You can combine searches with the : delimiter. This works for all types,
though it's most often used with coordinate searches.


3) geotoad -u user -p password -x text -o nc.txt -n -q state "North Carolina"
Outputs a text file with all of the caches in North Carolina that are
virgins (have never been found).

Please note the quotes around "North Carolina". Any parameters with spaces in
them must have quotes around them.


4) geotoad -u user -p password -t 2.5 -x vcf -E "helixblue:Sallad" -o charlotte.vcf 28272
Gets every cache in the 100 mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a VCF format file, which is usable by iPod's and other devices.

Please note: Put quotes around your username if it has any spaces in it.


5) geotoad -u user -p password -x html -b -K 'stream|creek|lake|river|ocean' -o watery.html -q state Indiana
Gets every cache in Indiana with travel bugs that matches those water keywords.
Makes a pretty HTML file out of it.

