<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>GeoToad: Opensource Geocaching tools</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="/style-blue.css?2003080901" type="text/css" />
<link rel="stylesheet" href="/hacks.css?2003092601" type="text/css" />
</head>
<body>
<? include("../../header.inc"); ?>
<? include("header.inc"); ?>


<div class="hacknews">
	<div class="hackboxtitle">>GeoToad News:</div>

	<div class="hacknewsitem">
		<div class="hacknewstitle">New Year's Eve Beta 2</div>
		<div class="hacknewsdate">31dec2003 15:26</div>
			3.5.0 beta 2 (was 3.2.0) is now in the  <a
href="http://toadstool.se/hacks/geotoad/files/">files area</a>. It's
recommended for everyone, though we still need to add the interactive text
mode before the next beta and final. Be a good tester, report bugs! See the <a
href="http://toadstool.se/hacks/geotoad/files/ChangeLog.txt">ChangeLog</a>
for details.</p>
</div>


	<div class="hacknewsitem">
		<div class="hacknewstitle">Happy Thanksgiving!</div>
		<div class="hacknewsdate">30nov2003 00:53</div>
			I've begun placing 3.2.0 alpha builds <a
href="http://toadstool.se/hacks/geotoad/files/">online</a>. Only recommended
for developers, see the <a
href="http://toadstool.se/hacks/geotoad/files/ChangeLog.txt">ChangeLog</a>
for details.</p>
</div>


	<div class="hacknewsitem">
		<div class="hacknewstitle">Sorry about that folks! (3.0.6
released)</div>
		<div class="hacknewsdate">24nov2003 12:07</div>
			<p>
		Talk about the move that took too long. I moved to
Bloomington, Indiana last month, wrestled for 4 weeks trying to get an
internet connection at home, and then my main web provider became very
unreliable all of a sudden. I've now moved the website to my new place of
work, and though I've still got DNS issues, enough of the infrastructure is
back that I could finally put out a maintenance release for this little
bugger.
</p>
<p>
My sincere apologies to everyone who's e-mailed me bug reports and patches
(thanks again, Mike!). 
</p>
<p>
3.0.6 fixes the geocaching.com page layout change so that it doesn't crash
anymore, and gives a better description for the CacheMate export type. We've
got some patches lying around here that need to be massaged into the code a
little better, but things are rolling again.
</p>
<p>
Who knows, you might get a Thanksgiving gift!</p>
</div>



	<div class="hacknewsitem">
		<div class="hacknewstitle">Geocaching.com site change, 3.0.5
released</div>
		<div class="hacknewsdate">28sep2003 13:34</div>
			<p>
			Geocaching.com changed the way their subscriber only
caches look like to unauthenticated clients, which caused this error to pop
up for GeoToad users:
</p><p>
<tt>./geocache/output.rb:238:in 'FilterInternal': undefined method 'length'
for nil:NilClass (NoMethodError)</tt>
</p>
<p>I also found a strange bug in ruby's 1.6.8 cgi.rb library that I've
issued a workaround for, though I doubt anyone will run into it. 3.0.5 has been issued with a fix to work around this site change. As a bonus, it will
no longer waste your time trying to download subscriber only caches. Enjoy!</p>
</p>
</div>





	<div class="hacknewsitem">
		<div class="hacknewstitle">Minor release, 3.0.4 (now with version checking!)</div>
		<div class="hacknewsdate">27sep2003 13:10</div>
			<p>
A couple of minor bugfixes and changes here. 3.0.3 was never released
because 3.0.4 came out so soon afterwards.
<ul>
<li>Version checking. GeoToad will let you know when it's been
obsoleted</li>
<li>Default distance changed to 10 miles.</li>
<li>Fixed the tempfile location for Windows users</li>
<li>Check for invalid zipcode requests</li>
</ul>
</p>
</div>


	<div class="hacknewsitem">


		<div class="hacknewstitle">3.0.2 - Bugs suck</div>
		<div class="hacknewsdate">26sep2003 15:46</div>
			<p>
Some major bugfixes for users of Windows or Ruby 1.8, minor bugfixes
otherwise. This will most likely be the last release for a little while, as
we get our things together for a web interface.
<ul>
<li>Better HTML parsing for the cache title and author</li>
<li>Coordinate searches now work in Windows (filename issue)</li>
<li>Ruby 1.8.0 users get better compatibility with shadowfetch</li>
<li>Coordinate checks now get screened for valid syntax</li>
<li>Exec filters (gpsbabel or cmconvert) now work if the destination
filename has a space in it</li>
<li>Better text template</li>
<li>Now distributed as a zip file instead of a tgz, to avoid problems with
Windows users</li>
</ul>
</p>
</div>


	<div class="hacknewsitem">
		<div class="hacknewstitle">Surprise, 3.0.1!</div>
		<div class="hacknewsdate">25sep2003 17:02</div>
			<p>
			A few minor fixes/changes got shoved into the tree
today in the form of 3.0.1:
<ul>
<li>CacheMate support in the form of cmconvert</li>
<li>High-ASCII HTML entities removed for more compliant GPX output</li>
<li>Ruby 1.8 fix for searches by state</li>
</ul> 
</p>
</div>
	<div class="hacknewsitem">
		<div class="hacknewstitle">GeoToad 3 Release Party</div>
		<div class="hacknewsdate">27sep2003 14:00</div>
			<p>
			We are pleased to announce the release of GeoToad
3.0.0, which is what we decided to morph 2.7 into after changing the default
output format to GPX. Here's a list of notable changes:
<ul> 
<li>New default output format - GPX. This is understood by more software
than the old EasyGPS LOC format, and contains more information.</li>
<li>No more nasty hacks encoding HTML characters, meaning consistant HTML
output.</li>
<li>Coordinate searches - You can now search by GPS coordinates, which is a
good work around for people who can't use the international search (still
broken).
<li>Combined argument searches - You can now search for 27513:33434, and it
will combine the results from the two zipcodes! Works for all search
types! (Thanks Mike Capito!)</li>
<li>Better automatic file naming - If you don't specify an output filename, we'll make one
up for you that includes the search type, search arguments, and
distance.</li>
<li>Tab Output format - for GPS Connect</li>
<li>Standard bunch of bugfixes related to the geocaching.com website
changing designs</li>
</ul>
			</p>
			<p>
			BTW, the release party is 107 Brampton Lane, Apt 2D,
Cary, NC, 27513 tonight! You can help me pack up for Indiana.</p>
	</div>

	<div class="hacknewsitem">
		<div class="hacknewstitle">Busy working on 2.7</div>
		<div class="hacknewsdate">27sep2003 08:15</div>
			<p>
			Mike Capito has been throwing patches over the wall
to me for geotoad. He's gone ahead and synced up the changes with the new
commenter format, making it so that user inclusion/exclusion works again.
He's also gone ahead and completed the coordinat searching support for me,
and has sent me patches adding the ability to combine multiple queries. I've
implemented all but the last one so far.
			</p>
			<p>
			I've been busy myself with the stubs for
international search support (may be broken for some time), native GPX and
tabbed output (GPS Connect) formats. Look for the alpha builds in the normal
download location.
			</p>
	</div>


	<div class="hacknewsitem">
		<div class="hacknewstitle">International searches broken</div>
		<div class="hacknewsdate">16aug2003 12:31</div>
			<p>
			Jonat Brander gave me another bug report today: Searching for geocaches in other countries does not work. It seems geocaching.com is in the process of making regional searches work
			inside countries outside of North America. Of course, they've implemented this in a way to give page scrapers like GeoToad a hard time. Instead of getting a list of geocaches when I make
			a request for a country code, I get a page in which I need to parse out the encrypted ENVTARGET post variable and resubmit the page with it. Not too hard, I should have it
			done by the end of this week, since I will be leaving for Sweden on Friday.
			</p>
	</div>



	<div class="hacknewsitem">
		<div class="hacknewstitle">2.6.2: Ruby compatibility bugfixes</div>
		<div class="hacknewsdate">12aug2003 10:31</div>
			<p>Jonat Brander reported a bug with the shadowfetch routines in GeoToad 2.6.1. It ends up that the Net::HTTP data semantics changed in ruby 1.8.0, 
so it would break when trying to update the shadow hosts.  I released 2.6.2, tested with ruby 1.8.0 under Windows XP and Mac OS X 10.2.6 today. Thanks to Jonat for the excellent bug report. 
If you spot any issues or have any suggestions, please <a href="mailto:geotoad@toadstool.se">contact us!</a>.
			</p>
			<p>
				In other news, I'm working on the 2.7 series, which will feature native GPX and tabbed-text output, as well as better HTML generation. I hope to freeze the API's at this stage so that I can begin work on the web interface.
			</p>
	</div>

	<div class="hacknewsitem">
		<div class="hacknewstitle">Site changes and the new 2.6
series!</div>
		<div class="hacknewsdate">09aug2003 15:06</div>
			<p>We've begun migrating this website to CSS so it's more easily maintainable. It's still not pretty, but it's easier for us to work
with.</p>
			<p>We've also pushed 2.6.1 (2.6.0 was never
announced)  out the door, with some goodies to boot.
We've nearly exhausted our TODO list now, so don't expect anything but
maintenance releases in the near term, unless any other developers step up
to bat. We really would like to pursue better user interfaces (Web, Windows, MacOS) for future releases. 
			<ul>
				<li>We now output the hint, direction and distance
for each cache in HTML/Text summaries</li>
				<li>Filtering by the last time the geocache was found</li>
				<li>Filtering by the placement time of the geocache</li>
				<li>Filtering by the name of the geocache owner</li>
				<li>More improvements to the HTML processing and minor bug fixes</li>
				<li>Slow-mode. If your query may need more
than 350 caches to download, reduce the load on geocaching.com by slowing
down the queries</li>
			</ul>
	</div>



	<div class="hacknewsitem">
		<div class="hacknewstitle">Quick on the draw, 2.5.1 out with some bugfixes</div>
		<div class="hacknewsdate">08aug2003 13:35</div>
		Looks like we had some bugs in the last version that snuck by our elite QA department.
			<ul>
				<li>Better HTML output. Less spacing, and bullet normalization.</li>
				<li>Sync to some website layout changes between 2.5.0b1 and 2.5.0 final. This fixes the virgin false-alarm and unknown cache type bugs</li>
				<li>Fixed regular expression substitution so that ruby 1.8.0 doesn't complain</li>
			</ul>
	</div>

	<div class="hacknewsitem">
			<div class="hacknewstitle">2.5.0 finally out - GeoToad works again!</div>
			<div class="hacknewsdate">07aug2003 23:17</div>
		This release brings compatibility with the new geocaching.com site design.
		It's a required upgrade, so come and get it. Here goes:
	
		<ul>
			<li>Compatibility with the new geocaching.com redesign</li>
			<li>Added -l, which is the length of your waypoint ID's. It defaults to 8 to make everyone happy, but I think newer Garmin owners can set it to 16 without a problem.</li>
			<li>Changed -u to -U (user exclusion)</li>
			<li>Added -u (user inclusion)</li>
			<li>Web fetching now supports redirects (301)</li>
		</ul>
	</div>
	
	<div class="hacknewsitem">	
		<div class="hacknewstitle">GeoToad Broken</div>
			 <div class="hacknewsdate">16jul2003 14:11</div>
		GeoToad is currently broken after the recent Geocaching redesign. We're hard
		at work at the new 2.5 that fixes it. There is currently a beta available,
		but it breaks after 200 waypoints. Sorry! Help always appreciated.
	</div>

	
	<div class="hacknewsitem">
		<div class="hacknewstitle">2.3.3 brings better HTML</div>
		<div class="hacknewsdate">03jun2003 14:11</div>
		2.3.3 now generates validatable HTML 4.0 Transitional output. I did this to see if I could fix an crash with the built-in browser (not Opera) on the Sony-Ericsson P800, but 
		it didn't fix it anyways. The pages look a little nicer though! I also fixed some other bugs too, of course.
		<ul>
			<li>HTML 4.0 Transitional Output, even validator.w3.org likes us</li>
			<li>Geocaches with no short description (OBX) no longer crash geotoad</li>
	
			<li>Better looking HTML output</li>
		</ul>
	</div>

	<div class="hacknewsitem">	
		<div class="hacknewstitle"> Better, Faster, Stronger - 2.3.2 Released</div>
			<div class="hacknewsdate">14may2003 15:07</div>
		I announced 2.3.1, but here is 2.3.2 already! It's mostly minor appearance and performance tweaks, but worth getting:
		<ul>
			<li>virgin caches are now specially marked in the HTML indexes</li>
			<li>Improvements to the help/usage dialog, it now takes up much less room (for 80x25 users)</li>
			<li>Cache tweaks: expiry for caches is now 4 days shadow, 5 days local.Cache expiry for searches is now 12 hours local, 15 hours shadow</li>
			<li>zipcode searches now default to 15 miles</li>
			<li>Delay less for uncached searches</li>
			<li>Fail gracefully if the user specifies an unknown option</li>
		</ul>
	</div>

	<div class="hacknewsitem">	
		<div class="hacknewstitle"> First Public Release - 2.3.0</div>
		<div class="hacknewsdate">26apr2003 11:09</div>
		Our first public release 
		of GeoToad is finally out the door. A couple of important changes have 
		been made recently:
		<ul>
			<li>Drastically better documentation. (still not good enough)</li>
			<li>Updated the list of formats we support through gpsbabel (not all tested)</li>
			<li>We now will lookup the country/state codes for you. </li>
			<li>We now export to a file named geotoad_output.(format extension) instead of stdout if you give it no arguments.</li>
		</ul>
		
		Please submit any bug reports, confusion, or suggestions to <a href="mailto:geotoad@toadstool.sh">geotoad+web@toadstool.sh</a>
	</div>
	<div class="hacknewsitem">	
		<div class="hacknewstitle">New Web Site!</div>
			<div class="hacknewsdate">26apr2003 09:42</div>
			We've now actually got a 
			website up, Huzzah! Yes, it's a pretty lame little site, I'm not feeling 
			overly creative at the moment. Maybe someone with more inspiration and 
			time can step up to bat and make a better site design. I feel kind of 
			bad having this site done with normal HTML markup, rather than some 
			nice CSS magic. I just have been working on the code too much :)</div>
	</div>

	<div class="hacknewsitem">	
		<div class="hacknewstitle">The Beginning</div>
			<div class="hacknewsdate">01apr2002 09:42</div>
			Being the bored geek I am, I begin writing GeoToad.
Within a month, version 1.0 is done, but Jeremy of Groundspeak asks me not
to release it until the paid membership goes into effect.
	</div>


</div>

<? include("footer.inc"); ?>
</html>
