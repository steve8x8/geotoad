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
http://unc.dl.sourceforge.net/sourceforge/rubyinstaller/ruby168-8.exe

Optionally, if you have gpsbabel - http://gpsbabel.sourceforge.net/ ..
geotoad can output to over a dozen additional GPS formats.


------
Syntax
------
syntax: geotoad.rb [options] <search>
    -f format for output. Valid options are:
          html - Simple HTML table format
          mapsource - Garmin Mapsource (requires gpsbabel in PATH)
          easygps - Geocaching.com .loc XML file
          text - Plain ASCII
          vcf - VCF for iPod Contacts export
          mapsend - Magellan MapSend software(requires gpsbabel in PATH)
          gpx - GPX XML format (requires gpsbabel in PATH)
          gpsutil - gpsutil datafile (requires gpsbabel in PATH)
          pcx - Garmin PCX5 (requires gpsbabel in PATH)
          csv - CSV for spreadsheet imports
          gpspoint - gpspoint datafile
          tiger - U.S. Census Bureau Tiger Mapping Service Data (requires
                  gpsbabel in PATH)
          magellan - Magellan GPS Serial Link (requires gpsbabel in PATH)
          gpsman - GPSman datafile (requires gpsbabel in PATH)
 -q [zip|state|country]  query type (zip by default)
 -o [filename]           output file
 -d [0.0-5.0]            difficulty minimum (0)
 -D [0.0-5.0]            difficulty maximum (5)
 -t [0.0-5.0]            terrain minimum (0)
 -T [0.0-5.0]            terrain maximum (5)
 -y [1-500]              distance maximum (zipcode only, 25 default)
 -k [keyword]            keyword (regexp) search. Use | to delimit multiple
 -u [username]           filter out caches found by username. 
                         Use : to delimit multiple users
 -n                      only include not found caches (virgins)
 -b                      only include caches with travelbugs


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

geotoad.rb -f text -o nc.txt q state "North Carolina"

Outputs a text file with all of the caches in North Carolina that are
virgins (have never been found). 

geotoad.rb -t 2.5 -f vcf -u helixblue:Sallad -o charlotte.vcf 28272

Gets every cache in the 100 mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a VCF format file, which is usable by iPod's and other devices.

geotoad.rb -b html -n -k 'stream|creek|lake|river|ocean' -o watery.html -q
country Sweden

Gets every cache in Sweden with travel bugs that matches those water keywords. 
Makes a pretty HTML file out of it.
