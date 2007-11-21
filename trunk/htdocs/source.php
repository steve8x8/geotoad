<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>GeoToad Source</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="/style-blue.css?2003080901" type="text/css" />
<link rel="stylesheet" href="/hacks.css?2003092601" type="text/css" />
</head>

<body>
<? include("../../header.inc"); ?>
<? include("header.inc"); ?>
<div class="hacktext">
	<div class="hackpagetitle">GeoToad Source</div>
        <p>GeoToad is written 
          in an interpreted scripting language, <a href="http://www.ruby-lang.org/en/">Ruby</a>, it already comes with the source 
          code in the non-Windows distributions. For Windows we use rbext to
compile it into an .exe file, so if you would like to modify the script,
grab the generic download from the <a href="downloads.php">Downloads</a>
page.
	</p><p>

	<p>
	However, if you would like to check-out the latest unreleased development source code, 
          you'll need to grab a <a href="http://subversion.tigris.org/">Subversion</a> 
          client. You can then anonymously checkout the repository via:
	</p>
	<div class="hackexample">svn co http://12.223.243.231/svn/repos/ geotoad/trunk</div>
	<h4>Submitting Changes</h4>
<p>

        If you see a bug, or are 
          just interested in helping out, <a href="mailto:geotoad@toadstool.se">contact 
          me</a> and I can give you write access to the repository.
</p>
<p>
 If you
wish to submit patches, please use unified diff format. Here is an example
of how I generate patches, assuming you have two directories: One version of
geotoad with your fix (+locfix) and one directory with the original source
code in it.
</p>
	<div class="hackexample">
		cd geotoad-3.0.4+locfix/<br />
		diff -ubBr ../geotoad-3.0.4/ . > ~/3.0.4-locationfix.patch
	</div>
	

      </div>
<? include("footer.inc"); ?>
</html>
