<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>GeoToad: Opensource Geocaching tools</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="/style.css?2003080901" type="text/css" />
</head>
<body>
<? include("../../header.inc"); ?>
<? include("header.inc"); ?>

 <div class="hacktext"> 
	<div class="hackpagetitle">Why GeoToad?</div>
		GeoToad is free software to help speed up the boring part of <a href="http://www.geocaching.com/">geocaching</a>: choosing the cache and collecting the data.
		<ul>
		<li>Sick of cryptic waypoint names like &quot;GC5042&quot; on your GPS?
</li>
			<li>Wish you could store geocache details and hints on your phone, pda, or iPod?</li>
			<li>Want to sync lists of geocaches on-demand to your GPS based on certain characteristics? </li>
			<li>Wish you could print out one long page with cache details for all the local geocaches you haven't done yet? </li>
		</li>
		</ul>
	<div class="hackpagetitle">What does GeoToad actually do?</div>
		<div class="offsetimage">
			<a href="screenshots.php" class="imagelink"><img src="screenshots/Sony-Ericsson-P800-small.jpg" width="163" height="250" border="2">
			<br />GeoToad Data on a Sony-Ericsson P800</a>
		</div>

		<p>GeoToad 
		is an open-source tool that allows you to generate queries against the 
		<a href="http://www.geocaching.com/">Geocaching</a> website, and 
		export the resulting caches to <a href="features.php">numerous devices</a> 
		and <a href="features.php">over 20 file formats</a>. Perfect for lazy 
		geocachers on the go! For instance, you can generate a query that says something 
		like:</p>

		<div class="hackexample">I want the geocaches within 15 miles of 27513 that
I have not yet completed and also have travel bugs</div>

		.. and have it output to a single long webpage! [<a href="http://toadstool.se/hacks/geotoad/samples/27513-travelbugs.html">see sample!</a>]

		<div class="hackexample">Give me all the geocaches in Texas
with a difficulty of 3 or higher that have never been found, match the keywoards river, stream, ocean,
or lake, and don't include any geocaches owned by Elvis.</div>

		<p>.. and have it output to <a href="http://www.easygps.com/">EasyGPS</a>, 
		with all of the applicable geocaches with intelligently named waypoints, so 
		that you can transfer them straight to your GPS unit. [<a
href="http://toadstool.se/hacks/geotoad/samples/texas-d35-water-noelvis.html">see
sample</a>] [<a
href="http://toadstool.se/hacks/geotoad/samples/texas-d35-water-noelvis.loc">download sample .loc</a>] 
</p>




		<p>GeoToad is 
		currently limited to a command-line client, which operates in Windows, 
		Mac OS X, Linux, and other UNIX flavors. We're working on a web client 
		that can be used from cellphones, and are looking for volunteers to 
		write graphical front-ends.</p>
</div>

<div class="hacknews">
	<div class="hackboxtitle">>GeoToad News:</div>
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
	
	<div class="inactivehacknewsitem">	
		<div class="hacknewstitle">GeoToad Broken</div>
			 <div class="hacknewsdate">16jul2003 14:11</div>
		GeoToad is currently broken after the recent Geocaching redesign. We're hard
		at work at the new 2.5 that fixes it. There is currently a beta available,
		but it breaks after 200 waypoints. Sorry! Help always appreciated.
	</div>

	
	<div class="inactivehacknewsitem">
		<div class="hacknewstitle">2.3.3 brings better HTML</div>
		<div class="hacknewsdate">03jun2003 14:11</div>
		2.3.3 now generates validatable HTML 4.0 Transitional output. I did this to see if I could fix an crash with the built-in browser (not Opera) on the Sony-Ericsson P800, but 
		it didn't fix it anyways. The pages look a little nicer though! I also fixed some other bugs too, of course.
		<ul>
			<li>HTML 4.0 Transitional Output, even validator.w3.org likes us</li>
			<li>Geocaches with no short description (OBX) no longer crash geotoad</li>
	
			<li>Better looking HTML output</li>
		</ul>
	<div>

	<div class="inactivehacknewsitem">	
		<div class="hacknewstitle"> Better, Faster, Stronger - 2.3.2 Released</div>
			<div class="hacknewsdate">14may2003 15:07</div>
		I announced 2.3.1, but here is 2.3.2 already! It's mostly minor appearance and performance tweaks, but worth getting:</div>
		<ul>
			<li>virgin caches are now specially marked in the HTML indexes</li>
			<li>Improvements to the help/usage dialog, it now takes up much less room (for 80x25 users)</li>
			<li>Cache tweaks: expiry for caches is now 4 days shadow, 5 days local.Cache expiry for searches is now 12 hours local, 15 hours shadow</li>
			<li>zipcode searches now default to 15 miles</li>
			<li>Delay less for uncached searches</li>
			<li>Fail gracefully if the user specifies an unknown option</li>
		</ul>
	</div>

	<div class="inactivehacknewsitem">	
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
		
	<div class="hacknewstitle">New Web Site!</div>
			<div class="hacknewsdate">26apr2003 09:42</div>
			We've now actually got a 
			website up, Huzzah! Yes, it's a pretty lame little site, I'm not feeling 
			overly creative at the moment. Maybe someone with more inspiration and 
			time can step up to bat and make a better site design. I feel kind of 
			bad having this site done with normal HTML markup, rather than some 
			nice CSS magic. I just have been working on the code too much :)</div>
	</div>
</div>

<? include("footer.inc"); ?>
</html>
