GeoToad %VERSION% by Thomas Stromberg
==========================================================================

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
Ruby 1.6 - http://www.ruby-lang.org/ .. Mac OS X and some Linux
distributions already have this installed.

Optionally, if you have gpsbabel - http://gpsbabel.sourceforge.net/ ..
geotoad can output to over a dozen additional GPS formats.


------
Syntax
------
Sample Syntax for the CLI mode:

geotoad.rb -t 2.5 -f vcf -u helixblue:Sallad -o ~/Desktop/charlotte.vcf 28272

Gets every cache in the 100 mile radius of zipcode 28272, with a terrain
score of 2.5 or higher, and that helixblue and Sallad have not visited.
Outputs a VCF format file, which is usable by iPod's and other devices.

geotoad.rb -f html -n -k 'stream|creek|lake|river|ocean' -q state_id 34

Gets every virgin cache in North Carolina that matches those water keywords.

