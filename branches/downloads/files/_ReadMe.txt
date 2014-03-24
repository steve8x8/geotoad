Which package do I need? 

Note: You need sufficient administrator privileges.
   For Unixoid systems, this may require prefixing commands with "sudo".


1. What's your OS?

1A. Windows ..................................................... proceed to 11
1B. MacOSX ...................................................... proceed to 21
1C. Debian/Ubuntu Linux ......................................... proceed to 31
1D. another Unix(oid) system .................................... proceed to 12
1E. something else .............................................. proceed to 98


11. Do you prefer an all-in-one package, or to keep things separate?

11A. I want to be in control of everything, even if that means some
   additional work!
   .............................................................. proceed to 12
11B. I just want to run GeoToad, not worry about stuff. I want to go
   geocaching, y'know?
   .............................................................. proceed to 15


12. Do you have Ruby (1.9.1 or higher) installed?

12A. No ......................................................... proceed to 13
12B. Yes ........................................................ proceed to 14


13. Go to http://rubyinstaller.org/downloads/, install Ruby.
   (Hint: You may also want to "gem install pik" to set your PATH.)
   .............................................................. proceed to 14


14. Get the tarball (geotoad-*.tar.gz), unpack it to a location of your choice.
    Optionally create a link on your desktop (tick "Run in terminal"!)
   .............................................................. proceed to 90


15. Get the Windows Installer package (geotoad-*_Windows_Installer.exe), and
   run it.
   Be warned: You may get complaints from the personal firewall later.
   .............................................................. proceed to 90


21. Do you have Ruby (1.9.1 or higher) installed?

21A. No ......................................................... proceed to 22
21B. Yes ........................................................ proceed to 23


22. Go to https://www.ruby-lang.org/en/downloads/, install Ruby.
   .............................................................. proceed to 23


23. Get the MacOSX package (geotoad-*_MacOSX.dmg), and install it.
   .............................................................. proceed to 90


31. Do you want automatic updates via apt, and dependencies resolved
   automatically?

31A. No ......................................................... proceed to 34
31B. Yes ........................................................ proceed to 32


32. Add a single line to your /etc/apt/sources.list:
       deb http://geotoad.googlecode.com/ svn/trunk/data/
   then run "apt-get update" (or its equivalent for "your" package manager)
   .............................................................. proceed to 33


33. Run "apt-get install geotoad" (or its equivalent).
   It will fetch all required dependencies (including Ruby itself).
   .............................................................. proceed to 90


34. Get the Debian package (geotoad_*-*.deb), and install it using "dpkg -i".
   You may need to resolve dependencies by hand, but you chose to do so.
   .............................................................. proceed to 90


90. Done - you are now ready to run GeoToad!
   Now check the manual page and the README file for some examples.
   .............................................................. proceed to 99


98. We apologize, GeoToad will probably not work for you.
   (But we'd like to learn if you managed to get it working!)
   ...............................................................proceed to 99


99. Don't forget to give us feedback
   -> follow @GeoToad_ on Twitter
   -> by e-mail (see project page on Google Code)
   -> contribute to the GeoToad handbook effort (see Issue 282)
