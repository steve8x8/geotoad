==========================================================================
GeoToad %VERSION% by Thomas Stromberg and The GeoToad Project (c) 2002 - 2017
==========================================================================


------------------
Table of Contents:
------------------
 - About GeoToad
 - System Requirements
 - Getting Started
 - Command-Line Syntax
 - Command-Line Examples

-------------
About GeoToad
-------------
GeoToad is an open-source query tool to query the geocaching.com website.
It supports exporting your results into a dozen or more formats such as
GPX (also variants suited for GSAK, or your road nav device) and HTML.


-------------------
System Requirements
-------------------
 - Windows
   - Windows 98 or Higher with
     - a sufficiently recent Ruby version
     - a SSL certificate chain required for HTTPS (also provided with GeoToad)
 - Mac OS
   - Mac OS X 10.4 or Higher
 - Other Operating Systems
   - You may need to install Ruby before running GeoToad.
     - RedHat/Fedora Linux: built-in
     - Debian/Ubuntu Linux: apt-get install ruby libopenssl-ruby, then dpkg -i geotoad_*.deb
     - FreeBSD: pkg_add -r ruby

Optionally, if you have gpsbabel (=> http://www.gpsbabel.org/)
GeoToad can output to over a dozen additional GPS formats.


---------------
Getting Started
---------------
The easiest way to get started with GeoToad is to use the "text user
interface" (TUI). Simply double click on the GeoToad program icon, or from
a command prompt run "geotoad". On UNIX, you may have to run "./geotoad.rb".
You will then see a screen that looks similar to this:

==============================================================================
:::                // GeoToad %VERSION% Text User Interface //                :::
==============================================================================
(1)  GC.com login [REQUIRED         ] | (2)  search type          [location  ]
(3)  location     [Dead Sea         ] | (4)  distance maximum (km)  [      25]
- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -
(5)  difficulty           [2.0 - 5.0] | (6)  terrain               [1.0 - 3.5]
(7)  fav factor           [0.0 - 5.0] | (8)  cache size            [any - any]
(9)  cache type   [                                                       any]
(10) caches not found by me       [ ] | (11) caches not found by anyone    [ ]
(12) cache age (days)     [  0 - any] | (13) last found (days ago) [  0 - any]
(14) title keyword       [          ] | (15) descript. keyword [             ]
(16) cache not found by  [          ] | (17) cache owner isn't [             ]
(18) cache found by      [          ] | (19) cache owner is    [             ]
(20) EasyName WP length         [  0] | (21) include disabled caches       [X]
(22) caches with trackables only  [ ] | (23) no Premium Member Only caches [ ]
- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -
(24) output format  [gpx|list|text  ] | (25) filename   [automatic           ]
(26) output directory    [/home/user/geocaching/geotoad                      ]
==============================================================================
** Verbose (debug) mode disabled, (v) to change
-- Enter menu number, (s) to start, (r) to reset, or (x) to exit --> 


At this point, follow the prompt and begin typing the number of the item
you wish to change, pressing enter afterwards. You will need to enter your
login and some basic search criteria first.

Once you have entered in all of your information, press "s" and then
<ENTER> to begin your search. GeoToad will save any options you have
entered for future runs.


-------------------
Command-Line Syntax
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
 -m [delimiters]        set delimiter(s) (default "|:") for multiple selections
 -o [filename]          output file name (automatic otherwise)
 -x [format]            output format type, see list below (default: gpx)
 -q [location|coord|user|owner|country|state|keyword|wid|guid|bookmark]
                        query type (default: location)
 -d/-D [1.0-5.0]        difficulty minimum/maximum
 -t/-T [1.0-5.0]        terrain minimum/maximum
 -g/-G [0.0-5.0]        fav factor minimum/maximum
 -y    [0.01-500]       distance maximum, in miles, or suffixed "km" (10)
 -k    [keyword]        title keyword(s) search
 -K    [keyword]        desc keyword(s) search (slow!)
 -i/-I [username]       include/exclude caches owned by this person
 -e/-E [username]       include/exclude caches found by this person
 -s/-S [virtual|not_chosen|other|micro|small|regular|large]
                        min/max size of the cache
 -c    [traditional|multicache|unknown|virtual|event|...]
                        type(s) of cache
 -j/-J [# days]         include/exclude caches placed in the last X days
 -r/-R [# days]         include/exclude caches found in the last X days
 -a/-A [attribute]      include/exclude caches with attributes set
 -z                     include disabled caches
 -n                     only include not found caches (virgins)
 -N                     only caches not yet found by login user
 -b                     only include caches with travelbugs
 -w [length]            set EasyName waypoint id length. (0=use WID)
 -L [count]             limit number of search pages (0=unlimited)
 -l [count]             limit number of log entries (default: 10)
 -Y                     do not fetch cache descriptions, search only
 -Z                     don't overwrite existing cache descriptions
 -O                     exclude Premium Member Only caches
 -Q                     select only Premium Member Only caches
 -P                     HTTP proxy server, http://username:pass@host:port/
 -M                     download my cache logs (/my/logs.aspx?s=1)
 -W                     download my trackable logs (/my/logs.aspx?s=2)
 -X                     emergency switch: disable early filtering
 -C                     selectively clear local browser cache
 -U                     use unbuffered output
 -V                     show version, then exit

::: OUTPUT FORMATS:
 cachemate(=)  cetus(+)      csv           delorme       delorme-nourl
 dna(+)        easygps       gclist        gcvisits(%)   gpsdrive     
 gpsman(+)     gpspilot(+)   gpspoint      gpspoint2(+)  gpsutil(+)   
 gpx           gpx-gsak      gpx-nuvi      gpx-pa        gpx-wpts     
 holux(+)      html          kml(+)        list          magnav(+)    
 mapsend(+)    mxf           myfindgpx     myfindlist    ozi          
 pcx(+)        poi-nuvi(+)   psp(+)        sms           sms2         
 tab           text          tiger         tmpro(+)      tpg(+)       
 vcf           wherigo       wp2guid       xmap(+)       yourfindgpx  
 yourfindlist 
 (+) requires gpsbabel  (=) requires cmconvert  (%) requires iconv in PATH

::: EXAMPLES:
 geotoad.rb -u helixblue -p password 27502
   find zipcode 27502 (Apex, NC 27502, USA), search 10mi around, write gpx
 geotoad.rb -u john -p password -c unknown -d 3 -x csv -o NC.csv -q state 34
   will find all mystery caches with difficulty >= 3 in all of North Carolina
   (Be careful: NC has more that 24k active caches!)
 geotoad.rb -u ... -p ... -z -Y -H -c cito -x list -o cito.list -q country 11
   creates a list (with dates, but no coordinates) of all CITO events in the UK
 for more examples - and options explanations - see manual page and README


---------------------
Command-Line Examples
---------------------
You need to get to a command-line (DOS, cmd.exe, UNIX shell), and go into
the directory you extracted geotoad into. Then you should be able to type
something simple like:

 - geotoad.rb -u user -p password 35466

Why do we need a username and password? In October of 2004, Geocaching.com
began to require a login in order to see the coordinates of a geocache.

If that does not work, try:

 - ruby geotoad.rb -u user -p password 35466

You've just made a file named gt_35466-y10.gpx containing all the geocaches
nearby the zipcode 35466 (Gordo, Alabama) suitable to be read by a Garmin device.

Here are some more complex examples that you can work with:

 - geotoad.rb -u user -p password -q coord "N56 44.392, E015 52.780"  -y 3
Search for caches within 3 miles of the above coordinates

 - geotoad.rb -u user -p password -q coord "56 44.392 15 52.780"  -y 5km
Search for caches within 5 kilometres.

 - geotoad.rb -u user -p password -x gpx -o threezipcodes.gpx 35466:99722:99788
You can combine searches with the : delimiter. This works for all types,
though it's most often used with coordinate searches.

 - geotoad.rb -u user -p password -x text -o nc.txt -n -q state 34
Outputs a text file with all of the caches in North Carolina (state ID: 34)
that are virgins (have never been found).

GeoToad's TUI can assist you to find the state ID: select search type
"state", then enter a pattern for country/state in a form like
"states/no.*caro". Pick the numeric ID for command line queries.
(Should your pattern be ambiguous, GeoToad will let you select from a list.)

 - geotoad.rb -u user -p password -t 2.5 -x gpx -E "helixblue:Sallad" -o charlotte.gpx 28272
Gets every cache in the 10-mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a GPX format file, which is usable by many GPSr's and other devices.

Please note: Put quotes around your username if it has any spaces in it.

Another note: This kind of query will put a high load on GroundSpeak's servers
and may change your account status to "banned". Be careful.

 - geotoad.rb -u user -p password -x html -b -K 'stream|creek|lake|river|ocean' -o watery.html -q country 72
Gets every cache in Finland (country ID: 72) with travel bugs that matches those water keywords.
Makes a pretty HTML file out of it.

 - geotoad.rb -u user -p password -q user -x myfindgpx -o myfinds.gpx -- -aBcDe-
If your search item starts with a dash, not to confuse the command line parser
you will have to insert a '--' (double dash) into the command line right at the
end of all options.

 - geotoad.rb ... -A 15- ...
Exclude all caches which are tagged as "Not available for winter".
(See the FAQ for a list of attributes.)

 - geotoad.rb ... -a 52 ...
Select only "night cache"s.

 - geotoad.rb ... -a 6 -A 57 ...
Select caches "recommended for kids" not longer than 10km.

See the manual page for more examples.
