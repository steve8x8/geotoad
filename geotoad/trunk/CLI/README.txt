GeoToad %VERSION% by Thomas Stromberg
==========================================================================
If this file does not view properly, use a better text viewer like WordPad
instead of Notepad. 

-----
About
-----
It's an open-source query tool to query the geocaching.com website. It can
write into a half dozen formats.


---------
Copyright
---------
BSD. If you include the source in your product, please mention me in the
credits. 


------------
Requirements
------------
Ruby 1.6 - An object oriented scripting language, similar to Perl and
Python. Mac OS X and some Linux distributions already have this installed. 
If you are a Windows user, you should use this installer:
http://twtelecom.dl.sourceforge.net/sourceforge/rubyinstaller/ruby180-9.exe

Optionally, if you have gpsbabel - http://gpsbabel.sourceforge.net/ ..
geotoad can output to over a dozen additional GPS formats.


------
Syntax
------
syntax: geotoad.rb [options] <search:search2:search3>

 -f format for output. Formats available are:
   csv       CSV for spreadsheet imports
   easygps   Geocaching.com .loc XML file
   gpspoint  gpspoint datafile
   gpx       GPX XML format
   html      Simple HTML table format
   text      Plain ASCII
   tab       Tabbed text, for GPS Connect
   vcf       VCF for iPod Contacts export

   -- the following require gpsbabel to be installed --
   cetus     Cetus for PalmOS 
   dna       Navitrak DNA marker 
   gpsdrive  GpsDrive 
   gpsman    GPSman datafile 
   gpspilot  GPSPilot for PalmOS 
   gpsutil   gpsutil 
   holux     Holux gm-100  
   magnav    Magellan NAV Companion for PalmOS 
   mapsend   Magellan MapSend software 
   mxf       MapTech Exchange 
   ozi       OziExplorer 
   pcx       Garmin PCX5 
   psp       Microsoft PocketStreets 2002 Pushpin 
   tiger     U.S. Census Bureau Tiger Mapping Service Data 
   tmpro     TopoMapPro Places 
   tpg       National Geographic Topo 
   xmap      Delorme Topo USA4/XMap Conduit 

   -- the following requires cmconvetr to be installed --
   cachemate CacheMate Palm software

 -q [zip|state|coord]    query type (zip by default)
		         [COUNTRY SEARCHES CURRENTLY BROKEN]
 -o [filename]           output file
 -d [0.0-5.0]            difficulty minimum (0)
 -D [0.0-5.0]            difficulty maximum (5)
 -t [0.0-5.0]            terrain minimum (0)
 -T [0.0-5.0]            terrain maximum (5)
 -y [1-500]              distance maximum (zipcode only, 25 default)
 -k [keyword]            keyword (regexp) search. Use | to delimit multiple
 -c [username]           only include caches owned by this person
                         Use : to delimit multiple users
 -C [username]           exclude caches owned by this person
                         Use : to delimit multiple users
 -u [username]           only include caches found by this person
                         Use : to delimit multiple users
 -U [username]           exclude caches found by this person
                         Use : to delimit multiple users
 -p [# days]             only include caches placed in the last X days
 -P [# days]             exclude caches placed in the last X days
 -r [# days]             only include caches found in the last X days
 -R [# days]             exclude caches found in the last X days
 -n                      only include not found caches (virgins)
 -b                      only include caches with travelbugs
 -l                      set waypoint id length (Garmin users can use 16)

-----
Usage
-----

You need to get to a command-line (DOS, cmd.exe, UNIX shell), and go into
the directory you extracted geotoad into. Then you should be able to type
something simple like:

geotoad.rb 27513

If that does not work, try:

ruby geotoad.rb 27513

You've just made a file named geotoad-output.loc containing all the geocaches
nearby the zipcode 27513 suitable to be read by EasyGPS. Here are some more
complex examples that you can work with:


geotoad.rb -q coord 39.44486,-74.561273 -y 5
Search for caches within 5 miles of the above coordinates


geotoad.rb 27513:27502:33434 
You can combine searches with the : delimiter. This works for all types,
though it's most often used with coordinate searches.

geotoad.rb -f text -o nc.txt -n -q state_id "North Carolina"
Outputs a text file with all of the caches in North Carolina that are
virgins (have never been found). 


geotoad.rb -t 2.5 -f vcf -U helixblue:Sallad -o charlotte.vcf 28272
Gets every cache in the 100 mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a VCF format file, which is usable by iPod's and other devices.


geotoad.rb -b html -n -k 'stream|creek|lake|river|ocean' -o watery.html -q country Sweden
Gets every cache in Sweden with travel bugs that matches those water keywords. 
Makes a pretty HTML file out of it.
